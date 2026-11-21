import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/model/attendance_model.dart';
import 'package:test_nest/model/batch_model.dart';

class AttendanceService {
  final FirebaseFirestore? _explicitFirestore;

  AttendanceService({FirebaseFirestore? firestore})
    : _explicitFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  /// Saves or updates attendance records for an entire batch on a given date.
  /// Uses a Firestore WriteBatch with deterministic IDs: `${batchId}_${studentId}_${dateKey}`
  /// so calling this multiple times acts as an idempotent upsert.
  Future<void> saveBatchAttendance({
    required TenantPathResolver resolver,
    required String batchId,
    required String batchName,
    required DateTime date,
    required List<AttendanceRecordModel> records,
    String? fallbackTeacherId,
  }) async {
    if (records.isEmpty) return;

    final attendancePath = resolver.attendancePath(fallbackTeacherId);
    final collectionRef = _firestore.collection(attendancePath);

    // Firestore batch limit is 500 operations
    const int chunkSize = 400;
    for (int i = 0; i < records.length; i += chunkSize) {
      final chunk = records.skip(i).take(chunkSize);
      final writeBatch = _firestore.batch();

      for (final record in chunk) {
        final docRef = collectionRef.doc(record.id);
        writeBatch.set(docRef, record.toMap(), SetOptions(merge: true));
      }

      await writeBatch.commit();
    }
  }

  /// Fetches attendance records for a batch on a specific date (dateKey: YYYY-MM-DD).
  Future<List<AttendanceRecordModel>> fetchBatchAttendanceForDate({
    required TenantPathResolver resolver,
    required String batchId,
    required String dateKey,
    String? fallbackTeacherId,
  }) async {
    final attendancePath = resolver.attendancePath(fallbackTeacherId);
    final snap = await _firestore
        .collection(attendancePath)
        .where('batchId', isEqualTo: batchId)
        .where('dateKey', isEqualTo: dateKey)
        .get();

    return snap.docs
        .map((d) => AttendanceRecordModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Streams attendance records for a batch on a specific date (dateKey: YYYY-MM-DD).
  Stream<List<AttendanceRecordModel>> streamBatchAttendanceForDate({
    required TenantPathResolver resolver,
    required String batchId,
    required String dateKey,
    String? fallbackTeacherId,
  }) {
    final attendancePath = resolver.attendancePath(fallbackTeacherId);
    return _firestore
        .collection(attendancePath)
        .where('batchId', isEqualTo: batchId)
        .where('dateKey', isEqualTo: dateKey)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AttendanceRecordModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Fetches all attendance records for a student across all dates (or filtered by batch).
  Future<List<AttendanceRecordModel>> fetchStudentAttendance({
    required TenantPathResolver resolver,
    required String studentId,
    String? batchId,
    String? fallbackTeacherId,
  }) async {
    final attendancePath = resolver.attendancePath(fallbackTeacherId);
    Query<Map<String, dynamic>> query = _firestore
        .collection(attendancePath)
        .where('studentId', isEqualTo: studentId);

    if (batchId != null && batchId.isNotEmpty) {
      query = query.where('batchId', isEqualTo: batchId);
    }

    final snap = await query.get();
    final records = snap.docs
        .map((d) => AttendanceRecordModel.fromMap(d.data(), d.id))
        .toList();

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  /// Streams attendance records for a student.
  Stream<List<AttendanceRecordModel>> streamStudentAttendance({
    required TenantPathResolver resolver,
    required String studentId,
    String? batchId,
    String? fallbackTeacherId,
  }) {
    final attendancePath = resolver.attendancePath(fallbackTeacherId);
    Query<Map<String, dynamic>> query = _firestore
        .collection(attendancePath)
        .where('studentId', isEqualTo: studentId);

    if (batchId != null && batchId.isNotEmpty) {
      query = query.where('batchId', isEqualTo: batchId);
    }

    return query.snapshots().map((snap) {
      final records = snap.docs
          .map((d) => AttendanceRecordModel.fromMap(d.data(), d.id))
          .toList();
      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    });
  }

  /// Calculates summary statistics for a student.
  Future<StudentAttendanceSummary> fetchStudentAttendanceSummary({
    required TenantPathResolver resolver,
    required String studentId,
    required String studentName,
    String? batchId,
    String? fallbackTeacherId,
  }) async {
    final records = await fetchStudentAttendance(
      resolver: resolver,
      studentId: studentId,
      batchId: batchId,
      fallbackTeacherId: fallbackTeacherId,
    );

    return StudentAttendanceSummary.fromRecords(
      studentId: studentId,
      studentName: studentName,
      records: records,
    );
  }

  /// Loads all active students for a given batch from the tenant's students collection.
  Future<List<StudentModel>> fetchStudentsForBatch({
    required TenantPathResolver resolver,
    required String batchId,
    required String batchName,
    String? fallbackTeacherId,
  }) async {
    final studentsPath = resolver.studentsPath(fallbackTeacherId);
    final snap = await _firestore.collection(studentsPath).get();

    final allStudents = snap.docs
        .map((d) => StudentModel.fromJson(d.data(), docId: d.id))
        .where((s) => s.isActive && (s.id.isNotEmpty || s.authUid.isNotEmpty))
        .toList();

    return allStudents.where((s) {
      final matchesId = s.batchId != null && s.batchId == batchId;
      final matchesName = StudentModel.isSameBatch(s.batch, batchName);
      return matchesId || matchesName;
    }).toList();
  }

  /// Loads available batches for current tenant context.
  Future<List<BatchModel>> fetchBatches({
    required TenantPathResolver resolver,
    String? filterTeacherUid,
    String? fallbackTeacherId,
  }) async {
    final batchesPath = resolver.batchesPath(fallbackTeacherId);
    final snap = await _firestore.collection(batchesPath).get();

    var batches = snap.docs
        .map((d) => BatchModel.fromJson(d.data(), docId: d.id))
        .where((b) => !b.isArchived)
        .toList();

    // In coaching institute mode, if a teacher UID filter is specified and the user is a teacher,
    // only show batches where the teacher is assigned or creator
    if (resolver.isInstitute &&
        filterTeacherUid != null &&
        filterTeacherUid.isNotEmpty) {
      batches = batches.where((b) {
        return b.teacherId == filterTeacherUid ||
            b.assignedTeacherIds.contains(filterTeacherUid);
      }).toList();
    }

    batches.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return batches;
  }
}
