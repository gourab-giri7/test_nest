import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/core/services/fee_service.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/join_code_model.dart';
import 'package:test_nest/model/join_request_model.dart';

class BatchAndJoinCodeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Characters used for joining codes (avoiding ambiguous 0, O, 1, I)
  static const String _codeAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  /// Generates an unpredictable, human-friendly joining code: e.g. "TN-7K9P2".
  static String generateJoiningCode() {
    final random = Random.secure();
    final buffer = StringBuffer('TN-');
    for (int i = 0; i < 5; i++) {
      buffer.write(_codeAlphabet[random.nextInt(_codeAlphabet.length)]);
    }
    return buffer.toString();
  }

  /// Normalizes joining code input (trims whitespace, converts to uppercase).
  static String normalizeCode(String input) {
    return input.trim().toUpperCase().replaceAll(' ', '');
  }

  // ---------------------------------------------------------------------------
  // Batch Operations
  // ---------------------------------------------------------------------------

  /// Creates a new batch with an associated unique reusable joining code.
  static Future<BatchModel> createBatch({
    required String teacherId,
    required String teacherName,
    required String name,
    String? session,
    String? classLevel,
    String? academicYear,
    String? subject,
    String? description,
    double monthlyFee = 0.0,
    bool feeTrackingEnabled = true,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Batch name cannot be empty');
    }

    final effectiveSession =
        (session != null && session.trim().isNotEmpty)
            ? session.trim()
            : academicYear?.trim();

    final batchRef = _db
        .collection('user')
        .doc(teacherId)
        .collection('batches')
        .doc();
    final batchId = batchRef.id;

    // Generate unique joining code
    String joinCode = generateJoiningCode();
    for (int attempt = 0; attempt < 5; attempt++) {
      final codeSnap = await _db.collection('joinCodes').doc(joinCode).get();
      if (!codeSnap.exists) break;
      joinCode = generateJoiningCode();
    }

    final batchData = {
      'id': batchId,
      'name': cleanName,
      'session': effectiveSession,
      'class_level': classLevel?.trim(),
      'academic_year': effectiveSession,
      'subject': subject?.trim(),
      'description': description?.trim(),
      'monthly_fee': monthlyFee,
      'fee_tracking_enabled': feeTrackingEnabled,
      'active_join_code': joinCode,
      'is_archived': false,
      'student_count': 0,
      'pending_request_count': 0,
      'teacher_id': teacherId.trim(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.set(batchRef, batchData);

    // Save joining code index for fast, secure resolution
    batch.set(_db.collection('joinCodes').doc(joinCode), {
      'code': joinCode,
      'teacher_id': teacherId.trim(),
      'teacher_name': teacherName.trim(),
      'batch_id': batchId,
      'batch_name': cleanName,
      'is_active': true,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Ensure backwards compatibility with legacy teacherData.batch string array
    batch.set(_db.collection('user').doc(teacherId), {
      'batch': FieldValue.arrayUnion([cleanName]),
    }, SetOptions(merge: true));

    await batch.commit();

    // Update teacherData in memory if active
    if (teacherData != null && teacherData!.id == teacherId) {
      if (!teacherData!.batch.contains(cleanName)) {
        teacherData!.batch.add(cleanName);
        await TeacherData.updateTeacherLocalData();
      }
    }

    return BatchModel(
      id: batchId,
      name: cleanName,
      classLevel: classLevel,
      academicYear: academicYear,
      subject: subject,
      description: description,
      monthlyFee: monthlyFee,
      feeTrackingEnabled: feeTrackingEnabled,
      activeJoinCode: joinCode,
      teacherId: teacherId,
      createdAt: DateTime.now(),
    );
  }

  /// Rotates the joining code for a batch. The old code is revoked.
  static Future<String> rotateJoiningCode({
    required String teacherId,
    required String teacherName,
    required String batchId,
    required String batchName,
    required String oldCode,
  }) async {
    String newCode = generateJoiningCode();
    for (int attempt = 0; attempt < 5; attempt++) {
      final snap = await _db.collection('joinCodes').doc(newCode).get();
      if (!snap.exists) break;
      newCode = generateJoiningCode();
    }

    final batch = _db.batch();

    // Revoke old code if exists
    if (oldCode.isNotEmpty) {
      batch.update(_db.collection('joinCodes').doc(oldCode), {
        'is_active': false,
        'revoked_at': FieldValue.serverTimestamp(),
      });
    }

    // Set new code
    batch.set(_db.collection('joinCodes').doc(newCode), {
      'code': newCode,
      'teacher_id': teacherId.trim(),
      'teacher_name': teacherName.trim(),
      'batch_id': batchId.trim(),
      'batch_name': batchName.trim(),
      'is_active': true,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Update batch document
    batch.update(
      _db.collection('user').doc(teacherId).collection('batches').doc(batchId),
      {'active_join_code': newCode, 'updated_at': FieldValue.serverTimestamp()},
    );

    await batch.commit();
    return newCode;
  }

  /// Revokes an active joining code.
  static Future<void> revokeJoiningCode({
    required String teacherId,
    required String batchId,
    required String code,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('joinCodes').doc(code), {
      'is_active': false,
      'revoked_at': FieldValue.serverTimestamp(),
    });
    batch.update(
      _db.collection('user').doc(teacherId).collection('batches').doc(batchId),
      {'active_join_code': '', 'updated_at': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  /// Archives a batch without deleting historical data.
  static Future<void> archiveBatch({
    required String teacherId,
    required String batchId,
    required String activeCode,
  }) async {
    final batch = _db.batch();
    batch.update(
      _db.collection('user').doc(teacherId).collection('batches').doc(batchId),
      {'is_archived': true, 'updated_at': FieldValue.serverTimestamp()},
    );
    if (activeCode.isNotEmpty) {
      batch.update(_db.collection('joinCodes').doc(activeCode), {
        'is_active': false,
        'revoked_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Deletes a single batch or multiple batches permanently for a teacher.
  /// - Revokes associated join codes
  /// - Marks enrolled student records in users/{studentUid}/enrollments as removed
  /// - Marks teacher students collection records for that batch as removed
  /// - Removes the batch document from user/{teacherId}/batches/{batchId}
  /// - Cleans up the teacherData.batch array
  /// - Preserves historical exam submissions and fee payment records.
  static Future<void> deleteBatches({
    required String teacherId,
    required List<BatchModel> batchesToDelete,
  }) async {
    if (batchesToDelete.isEmpty) return;

    final teacherRef = _db.collection('user').doc(teacherId.trim());

    for (final batchModel in batchesToDelete) {
      final batchId = batchModel.id.trim();
      final batchName = batchModel.name.trim();

      // 1. Revoke active join code if present
      if (batchModel.activeJoinCode.isNotEmpty) {
        try {
          await _db
              .collection('joinCodes')
              .doc(batchModel.activeJoinCode.trim())
              .delete();
        } catch (_) {}
      }

      // Also query any joinCodes pointing to this batchId
      try {
        final codesSnap = await _db
            .collection('joinCodes')
            .where('teacher_id', isEqualTo: teacherId)
            .where('batch_id', isEqualTo: batchId)
            .get();
        for (final doc in codesSnap.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}

      // 2. Find enrolled students in this teacher's student collection with this batch/batchId
      try {
        final studentsSnap = await teacherRef.collection('students').get();
        final writeBatch = _db.batch();
        int opCount = 0;

        for (final doc in studentsSnap.docs) {
          final data = doc.data();
          final bId = (data['batch_id'] ?? '').toString().trim();
          final bName = (data['batch'] ?? '').toString().trim();
          final authUid = (data['auth_uid'] ?? '').toString().trim();

          if (bId == batchId ||
              bName.toLowerCase() == batchName.toLowerCase()) {
            writeBatch.update(doc.reference, {
              'status': 'removed',
              'removed_at': FieldValue.serverTimestamp(),
              'batch_deleted': true,
            });
            opCount++;

            // Also update student root enrollment in users/{authUid}/enrollments/{teacherId_batchId}
            if (authUid.isNotEmpty) {
              final studentEnrollmentRef = _db
                  .collection('users')
                  .doc(authUid)
                  .collection('enrollments')
                  .doc('${teacherId}_$batchId');
              writeBatch.set(studentEnrollmentRef, {
                'status': 'removed',
                'removed_at': FieldValue.serverTimestamp(),
                'batch_deleted': true,
              }, SetOptions(merge: true));
              opCount++;
            }

            if (opCount >= 400) {
              await writeBatch.commit();
              opCount = 0;
            }
          }
        }
        if (opCount > 0) {
          await writeBatch.commit();
        }
      } catch (_) {}

      // 3. Update pending join requests for this batch
      try {
        final reqSnap = await _db
            .collection('joinRequests')
            .where('teacher_id', isEqualTo: teacherId)
            .where('batch_id', isEqualTo: batchId)
            .get();
        final reqBatch = _db.batch();
        for (final doc in reqSnap.docs) {
          reqBatch.update(doc.reference, {
            'status': 'removed_by_teacher',
            'removed_at': FieldValue.serverTimestamp(),
          });
        }
        await reqBatch.commit();
      } catch (_) {}

      // 4. Delete the batch doc itself
      await teacherRef.collection('batches').doc(batchId).delete();

      // 5. Remove batchName from teacher's root 'batch' array
      await teacherRef.update({
        'batch': FieldValue.arrayRemove([batchName]),
      });

      // Update in-memory teacherData if active
      if (teacherData != null && teacherData!.id == teacherId) {
        teacherData!.batch.removeWhere(
          (b) => b.trim().toLowerCase() == batchName.toLowerCase(),
        );
        await TeacherData.updateTeacherLocalData();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Joining Code Validation & Request Submission
  // ---------------------------------------------------------------------------

  /// Validates a joining code. Returns the code metadata if valid and active.
  static Future<JoinCodeModel?> validateJoiningCode(String inputCode) async {
    final clean = inputCode.trim();
    if (clean.isEmpty) return null;
    final normalized = normalizeCode(clean);

    // 1. Try direct lookup in `joinCodes` by normalized code, clean code, uppercase clean
    for (final key in [normalized, clean, clean.toUpperCase()]) {
      if (key.isEmpty) continue;
      try {
        final doc = await _db.collection('joinCodes').doc(key).get();
        if (doc.exists && doc.data() != null) {
          final model = JoinCodeModel.fromJson(doc.data()!, codeId: doc.id);
          if (model.isActive) return model;
        }
      } catch (_) {}
    }

    // 2. Try query in `joinCodes` where batch_id == clean or batch_id == inputCode
    try {
      final queryByBatch = await _db
          .collection('joinCodes')
          .where('batch_id', isEqualTo: clean)
          .limit(1)
          .get();
      if (queryByBatch.docs.isNotEmpty) {
        final model = JoinCodeModel.fromJson(
          queryByBatch.docs.first.data(),
          codeId: queryByBatch.docs.first.id,
        );
        if (model.isActive) return model;
      }
    } catch (_) {}

    // 3. Try query in `joinCodes` where code == normalized or code == clean
    try {
      final queryByCode = await _db
          .collection('joinCodes')
          .where('code', isEqualTo: normalized)
          .limit(1)
          .get();
      if (queryByCode.docs.isNotEmpty) {
        final model = JoinCodeModel.fromJson(
          queryByCode.docs.first.data(),
          codeId: queryByCode.docs.first.id,
        );
        if (model.isActive) return model;
      }
    } catch (_) {}

    // 4. Try collectionGroup('batches') query safely by 'id' and 'active_join_code'
    try {
      // 4a. Check by active_join_code
      final groupSnapByCode = await _db
          .collectionGroup('batches')
          .where('active_join_code', isEqualTo: normalized)
          .limit(1)
          .get();
      if (groupSnapByCode.docs.isNotEmpty) {
        final batchDoc = groupSnapByCode.docs.first;
        final data = batchDoc.data();
        final parentOrgId = batchDoc.reference.parent.parent?.id ?? '';
        final model = JoinCodeModel(
          code: normalized,
          teacherId: (data['teacher_id'] ?? '').toString(),
          teacherName: (data['teacher_name'] ?? 'Institute').toString(),
          batchId: batchDoc.id,
          batchName: (data['name'] ?? 'Batch').toString(),
          orgId: parentOrgId,
          isActive: data['is_archived'] != true,
        );
        return model;
      }

      // 4b. Check by 'id' field (standard field on BatchModel)
      final groupSnapById = await _db
          .collectionGroup('batches')
          .where('id', isEqualTo: clean)
          .limit(1)
          .get();
      if (groupSnapById.docs.isNotEmpty) {
        final batchDoc = groupSnapById.docs.first;
        final data = batchDoc.data();
        final parentOrgId = batchDoc.reference.parent.parent?.id ?? '';
        final activeCode = (data['active_join_code'] ?? '').toString().trim();
        final resolvedCode = activeCode.isNotEmpty ? activeCode : clean;
        final model = JoinCodeModel(
          code: resolvedCode,
          teacherId: (data['teacher_id'] ?? '').toString(),
          teacherName: (data['teacher_name'] ?? 'Institute').toString(),
          batchId: batchDoc.id,
          batchName: (data['name'] ?? 'Batch').toString(),
          orgId: parentOrgId,
          isActive: data['is_archived'] != true,
        );
        return model;
      }
    } catch (_) {}

    // 5. Fallback: Search organizations collection directly
    try {
      final orgsSnap = await _db.collection('organizations').limit(50).get();
      for (final orgDoc in orgsSnap.docs) {
        final orgData = orgDoc.data();
        final ownerName = (orgData['ownerName'] ?? orgData['name'] ?? 'Institute').toString();

        // 5a. Direct document check by batchId (clean)
        try {
          final batchSnap = await orgDoc.reference
              .collection('batches')
              .doc(clean)
              .get();
          if (batchSnap.exists && batchSnap.data() != null) {
            final data = batchSnap.data()!;
            final activeCode = (data['active_join_code'] ?? '').toString().trim();
            final resolvedCode = activeCode.isNotEmpty ? activeCode : clean;
            return JoinCodeModel(
              code: resolvedCode,
              teacherId: (data['teacher_id'] ?? orgDoc.id).toString(),
              teacherName: ownerName,
              batchId: batchSnap.id,
              batchName: (data['name'] ?? 'Batch').toString(),
              orgId: orgDoc.id,
              isActive: data['is_archived'] != true,
            );
          }
        } catch (_) {}

        // 5b. Query by active_join_code inside org batches
        try {
          final bCodeSnap = await orgDoc.reference
              .collection('batches')
              .where('active_join_code', isEqualTo: normalized)
              .limit(1)
              .get();
          if (bCodeSnap.docs.isNotEmpty) {
            final bDoc = bCodeSnap.docs.first;
            final data = bDoc.data();
            return JoinCodeModel(
              code: normalized,
              teacherId: (data['teacher_id'] ?? orgDoc.id).toString(),
              teacherName: ownerName,
              batchId: bDoc.id,
              batchName: (data['name'] ?? 'Batch').toString(),
              orgId: orgDoc.id,
              isActive: data['is_archived'] != true,
            );
          }
        } catch (_) {}

        // 5c. Scan org batches for ID or code match (supports prefixes or case-insensitive ID)
        try {
          final allBatchesSnap = await orgDoc.reference
              .collection('batches')
              .limit(50)
              .get();
          for (final bDoc in allBatchesSnap.docs) {
            final data = bDoc.data();
            final bId = bDoc.id;
            final activeCode = (data['active_join_code'] ?? '').toString().trim();

            final idMatches = bId == clean ||
                bId.toLowerCase() == clean.toLowerCase() ||
                (clean.length >= 6 && bId.toUpperCase().startsWith(clean.toUpperCase()));
            final codeMatches = activeCode.isNotEmpty &&
                (normalizeCode(activeCode) == normalized ||
                    activeCode.toLowerCase() == clean.toLowerCase());

            if (idMatches || codeMatches) {
              final resolvedCode = activeCode.isNotEmpty ? activeCode : clean;
              return JoinCodeModel(
                code: resolvedCode,
                teacherId: (data['teacher_id'] ?? orgDoc.id).toString(),
                teacherName: ownerName,
                batchId: bDoc.id,
                batchName: (data['name'] ?? 'Batch').toString(),
                orgId: orgDoc.id,
                isActive: data['is_archived'] != true,
              );
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    return null;
  }

  /// Submits a request for a student to join a teacher's or institute's batch.
  static Future<JoinRequestModel> submitJoinRequest({
    required String studentUid,
    required String studentName,
    required String studentEmail,
    String? studentPhone,
    required JoinCodeModel codeModel,
  }) async {
    final orgId = codeModel.orgId?.trim() ?? '';
    final isInstitute = orgId.isNotEmpty;

    // Check duplicate in institute if applicable
    if (isInstitute) {
      // 1. Check if already enrolled in member doc
      try {
        final memberSnap = await _db
            .collection('organizations')
            .doc(orgId)
            .collection('members')
            .doc(studentUid)
            .get();
        if (memberSnap.exists) {
          final assigned = List<String>.from(memberSnap.data()?['assignedBatchIds'] ?? []);
          if (assigned.contains(codeModel.batchId)) {
            throw StateError('You are already enrolled in "${codeModel.batchName}".');
          }
        }
      } catch (e) {
        if (e is StateError) rethrow;
      }

      // 2. Check pending join request in org
      try {
        final orgReqSnap = await _db
            .collection('organizations')
            .doc(orgId)
            .collection('joinRequests')
            .where('student_uid', isEqualTo: studentUid)
            .where('batch_id', isEqualTo: codeModel.batchId)
            .get();
        for (final doc in orgReqSnap.docs) {
          final st = (doc.data()['status'] ?? '').toString().toLowerCase();
          if (st == 'pending') {
            throw StateError('You already have a pending request for this batch.');
          } else if (st == 'approved') {
            throw StateError('You are already an approved member of this batch.');
          }
        }
      } catch (e) {
        if (e is StateError) rethrow;
      }
    } else {
      // Legacy teacher check
      final existingSnap = await _db
          .collection('joinRequests')
          .where('student_uid', isEqualTo: studentUid)
          .where('teacher_id', isEqualTo: codeModel.teacherId)
          .where('batch_id', isEqualTo: codeModel.batchId)
          .get();

      for (final doc in existingSnap.docs) {
        final status = (doc.data()['status'] ?? '').toString().toLowerCase();
        if (status == 'pending') {
          throw StateError('You already have a pending request for this batch.');
        } else if (status == 'approved') {
          throw StateError('You are already an approved member of this batch.');
        }
      }

      final existingStudentSnap = await _db
          .collection('user')
          .doc(codeModel.teacherId)
          .collection('students')
          .where('auth_uid', isEqualTo: studentUid)
          .get();
      for (final doc in existingStudentSnap.docs) {
        final bId = (doc.data()['batch_id'] ?? '').toString();
        final bName = (doc.data()['batch'] ?? '').toString();
        if (bId == codeModel.batchId ||
            (bName.isNotEmpty &&
                bName.toLowerCase() == codeModel.batchName.toLowerCase())) {
          throw StateError(
            'You are already enrolled in "${codeModel.batchName}" with ${codeModel.teacherName}.',
          );
        }
      }
    }

    final reqRef = _db.collection('joinRequests').doc();
    final reqId = reqRef.id;

    final requestData = {
      'id': reqId,
      'student_uid': studentUid.trim(),
      'student_name': studentName.trim(),
      'student_email': studentEmail.trim().toLowerCase(),
      'student_phone': studentPhone?.trim(),
      'teacher_id': codeModel.teacherId.trim(),
      'teacher_name': codeModel.teacherName.trim(),
      'batch_id': codeModel.batchId.trim(),
      'batch_name': codeModel.batchName.trim(),
      if (isInstitute) 'orgId': orgId,
      if (isInstitute) 'org_id': orgId,
      'status': 'pending',
      'requested_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.set(reqRef, requestData);

    if (isInstitute) {
      // Also write directly to organization's joinRequests collection
      final orgReqRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('joinRequests')
          .doc(reqId);
      batch.set(orgReqRef, requestData);
    } else {
      // Increment pending count on teacher batch doc
      batch.update(
        _db
            .collection('user')
            .doc(codeModel.teacherId)
            .collection('batches')
            .doc(codeModel.batchId),
        {'pending_request_count': FieldValue.increment(1)},
      );
    }

    await batch.commit();

    return JoinRequestModel(
      id: reqId,
      studentUid: studentUid,
      studentName: studentName,
      studentEmail: studentEmail,
      studentPhone: studentPhone,
      teacherId: codeModel.teacherId,
      teacherName: codeModel.teacherName,
      batchId: codeModel.batchId,
      batchName: codeModel.batchName,
      status: 'pending',
      requestedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Teacher Approval & Rejection
  // ---------------------------------------------------------------------------

  /// Approves a student's join request.
  /// Atomically updates request, creates student record, and updates batch counts.
  static Future<void> approveJoinRequest({
    required JoinRequestModel request,
  }) async {
    final teacherRef = _db.collection('user').doc(request.teacherId);
    final batchRef = teacherRef.collection('batches').doc(request.batchId);
    final reqRef = _db.collection('joinRequests').doc(request.id);

    // Get batch metadata to check monthly fee
    final batchDoc = await batchRef.get();
    final double batchMonthlyFee = batchDoc.exists
        ? BatchModel.fromJson(batchDoc.data()!).monthlyFee
        : 0.0;
    final bool feeTracking = batchDoc.exists
        ? BatchModel.fromJson(batchDoc.data()!).feeTrackingEnabled
        : true;

    await _db.runTransaction((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) {
        throw StateError('Join request does not exist');
      }
      final currentStatus = (reqSnap.data()?['status'] ?? '').toString();
      if (currentStatus == 'approved') {
        return; // Already approved
      }

      // Check teacher's last_std_id to assign sequential student ID
      final teacherSnap = await tx.get(teacherRef);
      final currentSeq =
          int.tryParse(
            (teacherSnap.data()?['last_std_id'] ?? '0').toString(),
          ) ??
          0;
      final nextSeq = currentSeq + 1;
      final studentId = _generateStudentId(request.teacherName, nextSeq);

      final studentRef = teacherRef.collection('students').doc(studentId);

      // Create student document under user/{teacherId}/students/{studentId}
      tx.set(studentRef, {
        'id': studentId,
        'auth_uid': request.studentUid,
        'name': request.studentName,
        'email': request.studentEmail,
        'phone': request.studentPhone ?? '',
        'batch': request.batchName,
        'batch_id': request.batchId,
        'monthly_fee': batchMonthlyFee,
        'teacher_id': request.teacherId,
        'teacher_name': request.teacherName,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Update teacher sequence
      tx.set(teacherRef, {
        'last_std_id': nextSeq.toString(),
      }, SetOptions(merge: true));

      // Update request status
      tx.update(reqRef, {
        'status': 'approved',
        'resolved_at': FieldValue.serverTimestamp(),
        'assigned_student_id': studentId,
      });

      // Update batch counts
      tx.update(batchRef, {
        'student_count': FieldValue.increment(1),
        'pending_request_count': FieldValue.increment(-1),
      });

      // Maintain multi-teacher enrollments on the student's root account in users/{studentUid}
      final studentUserRef = _db.collection('users').doc(request.studentUid);
      final enrollmentDocRef = studentUserRef
          .collection('enrollments')
          .doc('${request.teacherId}_${request.batchId}');

      tx.set(enrollmentDocRef, {
        'id': '${request.teacherId}_${request.batchId}',
        'teacher_id': request.teacherId,
        'teacher_name': request.teacherName,
        'batch_id': request.batchId,
        'batch_name': request.batchName,
        'student_id': studentId,
        'status': 'active',
        'enrolled_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(studentUserRef, {
        'teacher_ids': FieldValue.arrayUnion([request.teacherId]),
        'batch_ids': FieldValue.arrayUnion([request.batchId]),
        'enrollments': FieldValue.arrayUnion([
          {
            'teacher_id': request.teacherId,
            'teacher_name': request.teacherName,
            'batch_id': request.batchId,
            'batch_name': request.batchName,
            'student_id': studentId,
            'status': 'active',
          },
        ]),
        // Backward-compatible fallback fields for legacy readers
        'teacher_id': request.teacherId,
        'teacher_name': request.teacherName,
        'batch': request.batchName,
        'batch_id': request.batchId,
      }, SetOptions(merge: true));
    });

    // If batch has monthly fee configured and fee tracking is enabled, initialize first month fee record
    if (batchMonthlyFee > 0 && feeTracking) {
      try {
        await FeeService.ensureFeeRecord(
          teacherId: request.teacherId,
          studentId: request.studentUid,
          studentName: request.studentName,
          billingMonth: FeeService.currentMonthKey,
          amountDue: batchMonthlyFee,
        );
      } catch (feeError) {
        // Log silently
      }
    }
  }

  /// Rejects a student's join request.
  static Future<void> rejectJoinRequest({
    required String teacherId,
    required String batchId,
    required String requestId,
  }) async {
    final reqRef = _db.collection('joinRequests').doc(requestId);
    final batchRef = _db
        .collection('user')
        .doc(teacherId)
        .collection('batches')
        .doc(batchId);

    final batch = _db.batch();
    batch.update(reqRef, {
      'status': 'rejected',
      'resolved_at': FieldValue.serverTimestamp(),
    });
    batch.update(batchRef, {'pending_request_count': FieldValue.increment(-1)});
    await batch.commit();
  }

  /// Removes a student from a teacher's batch.
  /// - Marks student record in user/{teacherId}/students/{studentDocId} as removed
  /// - Marks enrollment record in users/{studentAuthUid}/enrollments as removed
  /// - Updates or inserts joinRequests record with status 'removed_by_teacher'
  /// - Decrements batch student_count
  /// - Revokes access immediately without deleting student's account or affecting other teachers
  static Future<void> removeStudentFromBatch({
    required String teacherId,
    required String studentDocId,
    String? studentAuthUid,
    String? batchId,
  }) async {
    final firestore = _db;
    final teacherRef = firestore.collection('user').doc(teacherId);
    final studentRef = teacherRef.collection('students').doc(studentDocId);

    // 1. Fetch student doc to retrieve auth_uid, batch_id, batch name if not passed
    final studentSnap = await studentRef.get();
    final studentData = studentSnap.data() ?? {};
    final resolvedAuthUid =
        (studentAuthUid != null && studentAuthUid.isNotEmpty
                ? studentAuthUid
                : (studentData['auth_uid'] ?? studentData['authUid']))
            ?.toString()
            .trim();
    final resolvedBatchId =
        (batchId != null && batchId.isNotEmpty
                ? batchId
                : (studentData['batch_id'] ?? studentData['batchId']))
            ?.toString()
            .trim();
    final batchName = (studentData['batch'] ?? studentData['batch_name'] ?? '')
        .toString()
        .trim();
    final studentName = (studentData['name'] ?? 'Student').toString().trim();

    final batch = firestore.batch();

    // 2. Mark student record as removed in teacher's subcollection
    batch.update(studentRef, {
      'status': 'removed',
      'removed_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // 3. Decrement batch student_count if batchId is valid
    if (resolvedBatchId != null && resolvedBatchId.isNotEmpty) {
      final batchRef = teacherRef.collection('batches').doc(resolvedBatchId);
      batch.update(batchRef, {'student_count': FieldValue.increment(-1)});
    }

    // 4. Update the student's root account enrollments if auth_uid is known
    if (resolvedAuthUid != null && resolvedAuthUid.isNotEmpty) {
      final studentUserRef = firestore.collection('users').doc(resolvedAuthUid);

      if (resolvedBatchId != null && resolvedBatchId.isNotEmpty) {
        final enrollmentRef = studentUserRef
            .collection('enrollments')
            .doc('${teacherId}_$resolvedBatchId');
        batch.set(enrollmentRef, {
          'status': 'removed',
          'removed_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 5. Update matching joinRequest to 'removed_by_teacher'
      final reqQuery = await firestore
          .collection('joinRequests')
          .where('student_uid', isEqualTo: resolvedAuthUid)
          .where('teacher_id', isEqualTo: teacherId)
          .get();

      if (reqQuery.docs.isNotEmpty) {
        for (final doc in reqQuery.docs) {
          batch.update(doc.reference, {
            'status': 'removed_by_teacher',
            'removed_at': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Create an explicit joinRequest entry so recent requests screen reflects removal
        final newReqRef = firestore.collection('joinRequests').doc();
        batch.set(newReqRef, {
          'id': newReqRef.id,
          'student_uid': resolvedAuthUid,
          'student_name': studentName,
          'teacher_id': teacherId,
          'teacher_name': (studentData['teacher_name'] ?? 'Teacher').toString(),
          'batch_id': resolvedBatchId ?? '',
          'batch_name': batchName,
          'status': 'removed_by_teacher',
          'requested_at':
              studentData['created_at'] ?? FieldValue.serverTimestamp(),
          'removed_at': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Promotion Workflow
  // ---------------------------------------------------------------------------

  /// Promotes selected students to a new batch while preserving historical records.
  static Future<void> promoteStudents({
    required String teacherId,
    required String sourceBatchId,
    required String targetBatchId,
    required String targetBatchName,
    required List<String> studentDocIds,
  }) async {
    if (studentDocIds.isEmpty) return;

    final batch = _db.batch();
    final teacherStudentsRef = _db
        .collection('user')
        .doc(teacherId)
        .collection('students');

    for (final sid in studentDocIds) {
      batch.update(teacherStudentsRef.doc(sid), {
        'batch': targetBatchName.trim(),
        'batch_id': targetBatchId.trim(),
        'previous_batch_id': sourceBatchId.trim(),
        'promoted_at': FieldValue.serverTimestamp(),
      });
    }

    // Update batch student counts
    final batchesRef = _db
        .collection('user')
        .doc(teacherId)
        .collection('batches');
    batch.update(batchesRef.doc(sourceBatchId), {
      'student_count': FieldValue.increment(-studentDocIds.length),
    });
    batch.update(batchesRef.doc(targetBatchId), {
      'student_count': FieldValue.increment(studentDocIds.length),
    });

    await batch.commit();
  }

  static String _generateStudentId(String teacherName, int sequence) {
    final cleanName = teacherName.trim();
    final prefix =
        (cleanName.length >= 2
                ? cleanName.substring(0, 2)
                : cleanName.padRight(2, 'T'))
            .toUpperCase();
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final number = sequence.toString().padLeft(3, '0');
    return '$prefix$year$month$number';
  }
}
