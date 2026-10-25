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
      'class_level': classLevel?.trim(),
      'academic_year': academicYear?.trim(),
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

  // ---------------------------------------------------------------------------
  // Joining Code Validation & Request Submission
  // ---------------------------------------------------------------------------

  /// Validates a joining code. Returns the code metadata if valid and active.
  static Future<JoinCodeModel?> validateJoiningCode(String inputCode) async {
    final normalized = normalizeCode(inputCode);
    if (normalized.isEmpty) return null;

    final doc = await _db.collection('joinCodes').doc(normalized).get();
    if (!doc.exists || doc.data() == null) return null;

    final model = JoinCodeModel.fromJson(doc.data()!, codeId: doc.id);
    if (!model.isActive) return null;

    return model;
  }

  /// Submits a request for a student to join a teacher's batch.
  static Future<JoinRequestModel> submitJoinRequest({
    required String studentUid,
    required String studentName,
    required String studentEmail,
    String? studentPhone,
    required JoinCodeModel codeModel,
  }) async {
    // Check if duplicate pending or approved request already exists
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

    // Also verify directly against teacher's student collection to prevent duplicate enrollments
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
      'status': 'pending',
      'requested_at': FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();
    batch.set(reqRef, requestData);

    // Increment pending count on batch doc
    batch.update(
      _db
          .collection('user')
          .doc(codeModel.teacherId)
          .collection('batches')
          .doc(codeModel.batchId),
      {'pending_request_count': FieldValue.increment(1)},
    );

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
