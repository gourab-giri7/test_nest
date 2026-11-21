import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../feature/domain/teacher/data/models/student_model.dart';
import '../../model/batch_model.dart';
import '../../model/batch_student_model.dart';
import '../../model/join_request_model.dart';
import '../../model/organization_model.dart';
import 'teacher_salary_service.dart';

class OrganizationService {
  final FirebaseFirestore? _explicitFirestore;

  OrganizationService({FirebaseFirestore? firestore})
    : _explicitFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  /// Creates a new Organization (e.g., Coaching Institute or Personal Workspace).
  /// Atomically writes:
  /// 1. `organizations/{orgId}`
  /// 2. `organizations/{orgId}/members/{ownerId}` (role: admin)
  /// 3. `users/{ownerId}/memberships/{orgId}`
  Future<OrganizationModel> createOrganization({
    required String name,
    required String type,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    Map<String, dynamic> metadata = const {},
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Organization name cannot be empty');
    }
    if (!OrganizationType.isValid(type)) {
      throw ArgumentError('Invalid organization type: $type');
    }

    final orgRef = _firestore.collection('organizations').doc();
    final orgId = orgRef.id;
    final now = DateTime.now();

    final orgModel = OrganizationModel(
      id: orgId,
      name: cleanName,
      type: type,
      ownerId: ownerId,
      ownerName: ownerName.trim(),
      createdAt: now,
      status: OrganizationStatus.active,
      metadata: metadata,
    );

    final memberModel = OrganizationMemberModel(
      uid: ownerId,
      email: ownerEmail.toLowerCase().trim(),
      name: ownerName.trim(),
      role: OrganizationRole.admin,
      status: OrganizationStatus.active,
      joinedAt: now,
    );

    final membershipModel = UserMembershipModel(
      organizationId: orgId,
      organizationName: cleanName,
      organizationType: type,
      role: OrganizationRole.admin,
      status: OrganizationStatus.active,
      joinedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(orgRef, orgModel.toMap());
    batch.set(orgRef.collection('members').doc(ownerId), memberModel.toMap());
    batch.set(
      _firestore
          .collection('users')
          .doc(ownerId)
          .collection('memberships')
          .doc(orgId),
      membershipModel.toMap(),
    );

    await batch.commit();
    return orgModel;
  }

  /// Ensures an independent workspace is registered for legacy or newly registered teachers.
  /// Does not copy, overwrite, or mutate any existing `user/{teacherId}` data.
  Future<OrganizationModel> ensureIndependentWorkspace({
    required String teacherId,
    required String teacherName,
    required String teacherEmail,
  }) async {
    final membershipRef = _firestore
        .collection('users')
        .doc(teacherId)
        .collection('memberships')
        .doc(teacherId);

    final membershipDoc = await membershipRef.get();
    final now = DateTime.now();

    final orgModel = OrganizationModel(
      id: teacherId,
      name: teacherName.isNotEmpty ? teacherName : 'Personal Workspace',
      type: OrganizationType.independent,
      ownerId: teacherId,
      ownerName: teacherName,
      createdAt: now,
      status: OrganizationStatus.active,
    );

    if (!membershipDoc.exists) {
      final orgRef = _firestore.collection('organizations').doc(teacherId);
      final orgDoc = await orgRef.get();

      final memberModel = OrganizationMemberModel(
        uid: teacherId,
        email: teacherEmail.toLowerCase().trim(),
        name: teacherName,
        role: OrganizationRole.admin,
        status: OrganizationStatus.active,
        joinedAt: now,
      );

      final membershipModel = UserMembershipModel(
        organizationId: teacherId,
        organizationName: orgModel.name,
        organizationType: OrganizationType.independent,
        role: OrganizationRole.admin,
        status: OrganizationStatus.active,
        joinedAt: now,
      );

      final batch = _firestore.batch();
      if (!orgDoc.exists) {
        batch.set(orgRef, orgModel.toMap());
      }
      batch.set(
        orgRef.collection('members').doc(teacherId),
        memberModel.toMap(),
        SetOptions(merge: true),
      );
      batch.set(
        membershipRef,
        membershipModel.toMap(),
        SetOptions(merge: true),
      );
      await batch.commit();
    }

    return orgModel;
  }

  /// Stream of user memberships for fast workspace list and selector rendering.
  Stream<List<UserMembershipModel>> streamUserMemberships(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('memberships')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserMembershipModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Future fetch of user memberships.
  Future<List<UserMembershipModel>> getUserMemberships(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .get()
          .timeout(const Duration(seconds: 3));

      return snapshot.docs
          .map((doc) => UserMembershipModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches an Organization by ID.
  Future<OrganizationModel?> getOrganization(String orgId) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .get()
          .timeout(const Duration(seconds: 3));
      if (!doc.exists || doc.data() == null) return null;
      return OrganizationModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }

  /// Stream of organization members.
  Stream<List<OrganizationMemberModel>> streamOrganizationMembers(
    String orgId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrganizationMemberModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Updates a member's role (admin / teacher).
  Future<void> updateMemberRole({
    required String orgId,
    required String memberUid,
    required String newRole,
  }) async {
    if (!OrganizationRole.isValid(newRole)) {
      throw ArgumentError('Invalid role: $newRole');
    }

    final batch = _firestore.batch();
    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(memberUid);
    final userMembershipRef = _firestore
        .collection('users')
        .doc(memberUid)
        .collection('memberships')
        .doc(orgId);

    batch.update(memberRef, {'role': newRole});
    batch.update(userMembershipRef, {'role': newRole});

    await batch.commit();
  }

  /// Removes a member from an organization.
  Future<void> removeMember({
    required String orgId,
    required String memberUid,
  }) async {
    final batch = _firestore.batch();
    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(memberUid);
    final userMembershipRef = _firestore
        .collection('users')
        .doc(memberUid)
        .collection('memberships')
        .doc(orgId);

    batch.delete(memberRef);
    batch.delete(userMembershipRef);

    await batch.commit();
  }

  /// Creates a student join request for a coaching institute.
  /// Path: `organizations/{orgId}/joinRequests/{requestId}`
  Future<JoinRequestModel> createStudentJoinRequest({
    required String orgId,
    required String orgName,
    required String studentUid,
    required String studentName,
    required String studentEmail,
    String phone = '',
    String? batchId,
    String? batchName,
  }) async {
    final ref = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('joinRequests')
        .doc();
    final now = DateTime.now();
    final model = JoinRequestModel(
      id: ref.id,
      studentUid: studentUid,
      studentName: studentName.trim(),
      studentEmail: studentEmail.trim().toLowerCase(),
      phone: phone.trim(),
      status: 'pending',
      timestamp: now,
      orgId: orgId,
      orgName: orgName.trim(),
      assignedBatchId: batchId,
      assignedBatchName: batchName,
      batchId: batchId ?? '',
      batchName: batchName ?? '',
    );
    await ref.set(model.toJson());
    return model;
  }

  /// Owner approves a student join request.
  /// Atomically executes:
  /// 1. Updates `organizations/{orgId}/joinRequests/{requestId}` status to 'approved'
  /// 2. Creates/updates `organizations/{orgId}/members/{studentUid}` (role: 'student')
  /// 3. Creates `users/{studentUid}/memberships/{orgId}`
  /// 4. If assignedBatchId provided, creates `organizations/{orgId}/batches/{batchId}/students/{studentUid}`
  ///    and increments batch `student_count`.
  /// 5. Upserts `organizations/{orgId}/students/{studentUid}` profile record.
  Future<void> approveStudentJoinRequest({
    required String orgId,
    required String orgName,
    required String requestId,
    required String studentUid,
    required String studentName,
    required String studentEmail,
    String studentPhone = '',
    required String reviewerUid,
    String? assignedBatchId,
    String? assignedBatchName,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    final joinRequestRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('joinRequests')
        .doc(requestId);

    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(studentUid);

    final userMembershipRef = _firestore
        .collection('users')
        .doc(studentUid)
        .collection('memberships')
        .doc(orgId);

    final studentDocRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('students')
        .doc(studentUid);

    final assignedBatches =
        (assignedBatchId != null && assignedBatchId.trim().isNotEmpty)
        ? [assignedBatchId.trim()]
        : <String>[];

    // 1. Update Join Request
    batch.update(joinRequestRef, {
      'status': 'approved',
      'reviewed_by': reviewerUid,
      'reviewed_at': FieldValue.serverTimestamp(),
      if (assignedBatchId != null) 'assigned_batch_id': assignedBatchId,
      if (assignedBatchName != null) 'assigned_batch_name': assignedBatchName,
    });

    // 2. Org Member Doc
    final memberModel = OrganizationMemberModel(
      uid: studentUid,
      email: studentEmail.trim().toLowerCase(),
      name: studentName.trim(),
      role: OrganizationRole.student,
      status: OrganizationStatus.active,
      joinedAt: now,
      assignedBatchIds: assignedBatches,
    );
    batch.set(memberRef, memberModel.toMap(), SetOptions(merge: true));

    // 3. User Membership Index
    final membershipModel = UserMembershipModel(
      organizationId: orgId,
      organizationName: orgName.trim(),
      organizationType: OrganizationType.institute,
      role: OrganizationRole.student,
      status: OrganizationStatus.active,
      joinedAt: now,
    );
    batch.set(
      userMembershipRef,
      membershipModel.toMap(),
      SetOptions(merge: true),
    );

    // 4. Batch Student Enrollment if batch specified
    if (assignedBatchId != null && assignedBatchId.trim().isNotEmpty) {
      final batchStudentRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('batches')
          .doc(assignedBatchId.trim())
          .collection('students')
          .doc(studentUid);

      final batchStudentModel = BatchStudentModel(
        studentUid: studentUid,
        orgId: orgId,
        batchId: assignedBatchId.trim(),
        batchName: assignedBatchName ?? '',
        studentName: studentName.trim(),
        studentEmail: studentEmail.trim().toLowerCase(),
        studentPhone: studentPhone.trim(),
        status: 'active',
        enrolledAt: now,
        updatedAt: now,
      );
      batch.set(
        batchStudentRef,
        batchStudentModel.toJson(),
        SetOptions(merge: true),
      );

      final batchDocRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('batches')
          .doc(assignedBatchId.trim());
      batch.set(batchDocRef, {
        'student_count': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }

    // 5. Org Student profile
    final studentModel = StudentModel(
      name: studentName.trim(),
      batch: assignedBatchName ?? '',
      batchId: assignedBatchId,
      id: studentUid,
      password: '',
      docId: studentUid,
      email: studentEmail.trim().toLowerCase(),
      authUid: studentUid,
      phone: studentPhone.trim(),
      status: 'Active',
      orgId: orgId,
    );
    batch.set(studentDocRef, studentModel.toJson(), SetOptions(merge: true));

    await batch.commit();
  }

  /// Owner rejects a student join request.
  Future<void> rejectStudentJoinRequest({
    required String orgId,
    required String requestId,
    required String reviewerUid,
    String? reason,
  }) async {
    final joinRequestRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('joinRequests')
        .doc(requestId);

    await joinRequestRef.update({
      'status': 'rejected',
      'reviewed_by': reviewerUid,
      'reviewed_at': FieldValue.serverTimestamp(),
      if (reason != null && reason.trim().isNotEmpty)
        'rejection_reason': reason.trim(),
    });
  }

  /// Enrolls an active institute student in a specific batch.
  Future<void> enrollStudentInBatch({
    required String orgId,
    required String batchId,
    required String batchName,
    required String studentUid,
    required String studentName,
    required String studentEmail,
    String studentPhone = '',
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    final batchStudentRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId)
        .collection('students')
        .doc(studentUid);

    final batchStudentModel = BatchStudentModel(
      studentUid: studentUid,
      orgId: orgId,
      batchId: batchId,
      batchName: batchName,
      studentName: studentName.trim(),
      studentEmail: studentEmail.trim().toLowerCase(),
      studentPhone: studentPhone.trim(),
      status: 'active',
      enrolledAt: now,
      updatedAt: now,
    );

    batch.set(
      batchStudentRef,
      batchStudentModel.toJson(),
      SetOptions(merge: true),
    );

    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(studentUid);
    batch.update(memberRef, {
      'assignedBatchIds': FieldValue.arrayUnion([batchId]),
    });

    final batchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId);
    batch.set(batchRef, {
      'student_count': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Removes a student from a batch without removing their organization membership.
  Future<void> removeStudentFromBatch({
    required String orgId,
    required String batchId,
    required String studentUid,
  }) async {
    final batch = _firestore.batch();

    final batchStudentRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId)
        .collection('students')
        .doc(studentUid);
    batch.delete(batchStudentRef);

    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(studentUid);
    batch.update(memberRef, {
      'assignedBatchIds': FieldValue.arrayRemove([batchId]),
    });

    final batchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId);
    batch.set(batchRef, {
      'student_count': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Atomically transfers a student from one batch to another.
  Future<void> transferStudentBatch({
    required String orgId,
    required String fromBatchId,
    required String toBatchId,
    required String toBatchName,
    required String studentUid,
    required String studentName,
    required String studentEmail,
    String studentPhone = '',
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    // Remove from old batch
    final oldBatchStudentRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(fromBatchId)
        .collection('students')
        .doc(studentUid);
    batch.delete(oldBatchStudentRef);

    final oldBatchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(fromBatchId);
    batch.set(oldBatchRef, {
      'student_count': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    // Add to new batch
    final newBatchStudentRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(toBatchId)
        .collection('students')
        .doc(studentUid);

    final batchStudentModel = BatchStudentModel(
      studentUid: studentUid,
      orgId: orgId,
      batchId: toBatchId,
      batchName: toBatchName,
      studentName: studentName.trim(),
      studentEmail: studentEmail.trim().toLowerCase(),
      studentPhone: studentPhone.trim(),
      status: 'active',
      enrolledAt: now,
      updatedAt: now,
    );
    batch.set(
      newBatchStudentRef,
      batchStudentModel.toJson(),
      SetOptions(merge: true),
    );

    final newBatchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(toBatchId);
    batch.set(newBatchRef, {
      'student_count': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Update member assignedBatchIds
    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(studentUid);
    batch.update(memberRef, {
      'assignedBatchIds': FieldValue.arrayRemove([fromBatchId]),
    });
    batch.update(memberRef, {
      'assignedBatchIds': FieldValue.arrayUnion([toBatchId]),
    });

    await batch.commit();
  }

  /// Assigns a teacher to a batch.
  Future<void> assignTeacherToBatch({
    required String orgId,
    required String batchId,
    required String teacherUid,
  }) async {
    final batch = _firestore.batch();
    final batchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId);
    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(teacherUid);

    batch.update(batchRef, {
      'assigned_teacher_ids': FieldValue.arrayUnion([teacherUid]),
    });
    batch.update(memberRef, {
      'assignedBatchIds': FieldValue.arrayUnion([batchId]),
    });

    await batch.commit();
  }

  /// Unassigns a teacher from a batch.
  Future<void> unassignTeacherFromBatch({
    required String orgId,
    required String batchId,
    required String teacherUid,
  }) async {
    final batch = _firestore.batch();
    final batchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId);
    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(teacherUid);

    batch.update(batchRef, {
      'assigned_teacher_ids': FieldValue.arrayRemove([teacherUid]),
    });
    batch.update(memberRef, {
      'assignedBatchIds': FieldValue.arrayRemove([batchId]),
    });

    await batch.commit();
  }

  /// Streams pending/all join requests for an organization.
  Stream<List<JoinRequestModel>> streamOrganizationJoinRequests(
    String orgId, {
    String? status,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('joinRequests');
    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => JoinRequestModel.fromJson(doc.data(), docId: doc.id))
          .toList();
    });
  }

  /// Streams students enrolled in a specific batch.
  Stream<List<BatchStudentModel>> streamBatchStudents(
    String orgId,
    String batchId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId)
        .collection('students')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BatchStudentModel.fromJson(doc.data(), docId: doc.id),
              )
              .toList();
        });
  }

  /// Creates a new batch under an institute: `organizations/{orgId}/batches/{batchId}`.
  /// If assignedTeacherIds are provided, atomically adds batchId to their member docs.
  Future<BatchModel> createInstituteBatch({
    required String orgId,
    required String name,
    required String ownerUid,
    String? subject,
    String? description,
    String? schedule,
    String? classLevel,
    String? academicYear,
    double monthlyFee = 0.0,
    bool feeTrackingEnabled = true,
    List<String> assignedTeacherIds = const [],
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Batch name cannot be empty');
    }

    final batchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc();
    final batchId = batchRef.id;

    final batchModel = BatchModel(
      id: batchId,
      name: cleanName,
      subject: subject?.trim(),
      description: description?.trim(),
      schedule: schedule?.trim(),
      classLevel: classLevel?.trim(),
      academicYear: academicYear?.trim(),
      monthlyFee: monthlyFee,
      feeTrackingEnabled: feeTrackingEnabled,
      activeJoinCode: '',
      isArchived: false,
      studentCount: 0,
      pendingRequestCount: 0,
      createdAt: DateTime.now(),
      teacherId: ownerUid,
      assignedTeacherIds: assignedTeacherIds,
    );

    final batch = _firestore.batch();
    batch.set(batchRef, {
      ...batchModel.toJson(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    for (final teacherUid in assignedTeacherIds) {
      final memberRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('members')
          .doc(teacherUid);
      batch.update(memberRef, {
        'assignedBatchIds': FieldValue.arrayUnion([batchId]),
      });
    }

    await batch.commit();
    return batchModel;
  }

  /// Updates an existing institute batch.
  Future<void> updateInstituteBatch({
    required String orgId,
    required String batchId,
    required String name,
    String? subject,
    String? description,
    String? schedule,
    String? classLevel,
    String? academicYear,
    double? monthlyFee,
    bool? feeTrackingEnabled,
    bool? isArchived,
  }) async {
    final batchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId);

    final Map<String, dynamic> updates = {
      'name': name.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (subject != null) updates['subject'] = subject.trim();
    if (description != null) updates['description'] = description.trim();
    if (schedule != null) updates['schedule'] = schedule.trim();
    if (classLevel != null) updates['class_level'] = classLevel.trim();
    if (academicYear != null) updates['academic_year'] = academicYear.trim();
    if (monthlyFee != null) updates['monthly_fee'] = monthlyFee;
    if (feeTrackingEnabled != null) {
      updates['fee_tracking_enabled'] = feeTrackingEnabled;
    }
    if (isArchived != null) updates['is_archived'] = isArchived;

    await batchRef.update(updates);
  }

  /// Toggles the archive / active status of an institute batch.
  Future<void> toggleBatchArchive({
    required String orgId,
    required String batchId,
    required bool isArchived,
  }) async {
    final batchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId);
    await batchRef.update({
      'is_archived': isArchived,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Streams all batches for an institute.
  Stream<List<BatchModel>> streamInstituteBatches(
    String orgId, {
    bool includeArchived = false,
  }) {
    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .snapshots()
        .map((snapshot) {
          final batches = snapshot.docs
              .map((d) => BatchModel.fromJson(d.data(), docId: d.id))
              .toList();
          if (includeArchived) return batches;
          return batches.where((b) => !b.isArchived).toList();
        });
  }

  /// Streams student members of an institute from `organizations/{orgId}/members`.
  Stream<List<OrganizationMemberModel>> streamInstituteStudents(String orgId) {
    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((d) => OrganizationMemberModel.fromMap(d.data(), d.id))
              .toList();
        });
  }

  /// Suspends a member (teacher or student) in an institute.
  Future<void> suspendMember({
    required String orgId,
    required String memberUid,
  }) async {
    final batch = _firestore.batch();
    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(memberUid);
    final userMembershipRef = _firestore
        .collection('users')
        .doc(memberUid)
        .collection('memberships')
        .doc(orgId);

    batch.update(memberRef, {'status': OrganizationStatus.suspended});
    batch.update(userMembershipRef, {'status': OrganizationStatus.suspended});
    await batch.commit();
  }

  /// Reactivates a suspended member in an institute.
  Future<void> reactivateMember({
    required String orgId,
    required String memberUid,
  }) async {
    final batch = _firestore.batch();
    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(memberUid);
    final userMembershipRef = _firestore
        .collection('users')
        .doc(memberUid)
        .collection('memberships')
        .doc(orgId);

    batch.update(memberRef, {'status': OrganizationStatus.active});
    batch.update(userMembershipRef, {'status': OrganizationStatus.active});
    await batch.commit();
  }

  /// Owner provisions a Teacher account directly for the Coaching Institute.
  /// 1. Concurrency-safe atomic generation of sequential Teacher ID `TN-TEA-XXXX`
  /// 2. Creates Teacher in Firebase Authentication using secondary FirebaseApp
  ///    without signing out or altering the active Owner session.
  /// 3. Writes `organizations/{orgId}/members/{teacherUid}` with teacher details.
  /// 4. Writes `users/{teacherUid}/memberships/{orgId}` indexing membership.
  /// 5. Writes `user/{teacherUid}` basic profile.
  /// 6. If monthlySalary > 0, primes salary snapshot via TeacherSalaryService.
  /// 7. Cleans up secondary FirebaseApp.
  /// 8. Returns creation payload for one-time display to Owner.
  Future<Map<String, dynamic>> createTeacherAccount({
    required String orgId,
    required String orgName,
    required String name,
    required String email,
    required String initialPassword,
    required String subject,
    String? mobile,
    String? gender,
    String? qualification,
    String? experience,
    double? monthlySalary,
    DateTime? joiningDate,
    List<String> assignedBatchIds = const [],
    // Optional hook for unit tests where Firebase App/Auth is mocked
    String? mockTeacherUid,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = initialPassword.trim();
    final cleanSubject = subject.trim();

    if (cleanName.isEmpty) throw ArgumentError('Teacher name cannot be empty');
    if (cleanEmail.isEmpty) throw ArgumentError('Teacher email cannot be empty');
    if (cleanPassword.length < 6) {
      throw ArgumentError('Teacher password must be at least 6 characters');
    }
    if (cleanSubject.isEmpty) {
      throw ArgumentError('Subject/Specialization cannot be empty');
    }

    // 1. Concurrency-safe sequential Teacher ID generation
    final orgRef = _firestore.collection('organizations').doc(orgId);
    final teacherId = await _firestore.runTransaction<String>((txn) async {
      final snap = await txn.get(orgRef);
      final currentNum =
          (snap.data()?['last_teacher_number'] as num?)?.toInt() ?? 0;
      final nextNum = currentNum + 1;
      txn.set(orgRef, {'last_teacher_number': nextNum}, SetOptions(merge: true));
      return 'TN-TEA-${nextNum.toString().padLeft(4, '0')}';
    });

    // 2. Secondary FirebaseApp Auth provisioning without session loss
    String teacherUid = mockTeacherUid ?? '';
    if (teacherUid.isEmpty) {
      if (Firebase.apps.isEmpty) {
        teacherUid = 'teacher_${DateTime.now().microsecondsSinceEpoch}';
      } else {
        final appName =
            'TeacherProvision_${DateTime.now().microsecondsSinceEpoch}';
        FirebaseApp? secondaryApp;
        try {
          secondaryApp = await Firebase.initializeApp(
            name: appName,
            options: Firebase.app().options,
          );
          final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
          final cred = await secondaryAuth.createUserWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPassword,
          );
          teacherUid = cred.user!.uid;
          try {
            await cred.user?.updateDisplayName(cleanName);
          } catch (_) {}
          await secondaryAuth.signOut();
        } finally {
          if (secondaryApp != null) {
            try {
              await secondaryApp.delete();
            } catch (_) {}
          }
        }
      }
    }

    // 3. Atomically write member doc, indexing membership, and user profile
    final now = joiningDate ?? DateTime.now();
    final batch = _firestore.batch();

    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(teacherUid);

    final memberModel = OrganizationMemberModel(
      uid: teacherUid,
      email: cleanEmail,
      name: cleanName,
      role: OrganizationRole.teacher,
      status: OrganizationStatus.active,
      joinedAt: now,
      assignedBatchIds: assignedBatchIds,
      teacherId: teacherId,
      subject: cleanSubject,
      phone: mobile?.trim(),
      gender: gender?.trim(),
      qualification: qualification?.trim(),
      experience: experience?.trim(),
      monthlySalary: monthlySalary,
    );
    batch.set(memberRef, memberModel.toMap(), SetOptions(merge: true));

    final userMembershipRef = _firestore
        .collection('users')
        .doc(teacherUid)
        .collection('memberships')
        .doc(orgId);

    final membershipModel = UserMembershipModel(
      organizationId: orgId,
      organizationName: orgName.trim(),
      organizationType: OrganizationType.institute,
      role: OrganizationRole.teacher,
      status: OrganizationStatus.active,
      joinedAt: now,
    );
    batch.set(
      userMembershipRef,
      membershipModel.toMap(),
      SetOptions(merge: true),
    );

    final userProfileRef = _firestore.collection('user').doc(teacherUid);
    batch.set(userProfileRef, {
      'id': teacherUid,
      'teacher_id': teacherUid,
      'teacherId': teacherId,
      'name': cleanName,
      'email': cleanEmail,
      'mobile': mobile?.trim() ?? '',
      'subject': cleanSubject,
      'role': 'teacher',
      'status': 'active',
      'orgId': orgId,
      'last_std_id': '0',
      'last_exam_id': '0',
      'batch': assignedBatchIds,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    for (final bId in assignedBatchIds) {
      final bRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('batches')
          .doc(bId);
      batch.update(bRef, {
        'assigned_teacher_ids': FieldValue.arrayUnion([teacherUid]),
      });
    }

    await batch.commit();

    // 4. Prime monthly salary ledger if specified
    if (monthlySalary != null && monthlySalary > 0) {
      try {
        await TeacherSalaryService.setTeacherDefaultSalary(
          orgId: orgId,
          teacherUid: teacherUid,
          baseSalary: monthlySalary,
        );
      } catch (_) {}
    }

    return {
      'teacherUid': teacherUid,
      'teacherId': teacherId,
      'name': cleanName,
      'email': cleanEmail,
      'initialPassword': cleanPassword,
      'subject': cleanSubject,
      'monthlySalary': monthlySalary ?? 0.0,
      'status': 'active',
    };
  }
}
