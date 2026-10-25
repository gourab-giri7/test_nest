import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';

class ExamFirestoreService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static String? get teacherDocId => teacherData?.id.trim();
  static String? get studentTeacherDocId => studentData?.teacherId.trim();

  static CollectionReference<Map<String, dynamic>> exams(String teacherId) =>
      db.collection('user').doc(teacherId.trim()).collection('exams');

  static DocumentReference<Map<String, dynamic>> exam(
    String teacherId,
    String examId,
  ) => exams(teacherId).doc(examId);

  static CollectionReference<Map<String, dynamic>> submissions(
    String teacherId,
    String examId,
  ) => exam(teacherId, examId).collection('submissions');

  static DocumentReference<Map<String, dynamic>> submission(
    String teacherId,
    String examId,
    String studentId,
  ) => submissions(teacherId, examId).doc(studentId.trim());

  static CollectionReference<Map<String, dynamic>> students(String teacherId) =>
      db.collection('user').doc(teacherId.trim()).collection('students');

  /// Builds a Firestore Query for exams belonging to [teacherId].
  ///
  /// Safety rules:
  /// 1. Never passes an empty list to `whereIn` or `arrayContainsAny`, which causes
  ///    an unhandled Firestore assertion crash.
  /// 2. Omits server-side `.orderBy(...)` when filtering with `.where(...)` on
  ///    different fields to avoid requiring composite indexes that fail silently.
  ///    Sorting is performed client-side in Dart.
  static Query<Map<String, dynamic>> getExamsQuery({
    required String teacherId,
    List<String>? batchIds,
    List<String>? assignedStudentIds,
  }) {
    Query<Map<String, dynamic>> query = exams(teacherId);

    // Guard against passing an empty list to whereIn
    if (batchIds != null && batchIds.isNotEmpty) {
      query = query.where('batch', whereIn: batchIds);
    }

    // Guard against passing an empty list to arrayContainsAny
    if (assignedStudentIds != null && assignedStudentIds.isNotEmpty) {
      query = query.where(
        'assigned_student_ids',
        arrayContainsAny: assignedStudentIds,
      );
    }

    // Server-side orderBy across different fields is intentionally omitted.
    // Client-side sorting is handled in Dart.
    return query;
  }

  /// Returns a stream of exam snapshots.
  ///
  /// If [teacherId] is empty or if filter lists like [batchIds] or [assignedStudentIds]
  /// are explicitly provided as empty lists, returns a safe stream instead of
  /// executing an invalid query that would throw an assertion error.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getStudentExamsStream({
    required String teacherId,
    List<String>? batchIds,
    List<String>? assignedStudentIds,
  }) {
    final cleanTeacherId = teacherId.trim();
    if (cleanTeacherId.isEmpty) {
      return const Stream.empty();
    }

    // If an empty list was passed for whereIn or arrayContainsAny,
    // do not construct an invalid query; return an empty stream directly.
    if ((batchIds != null && batchIds.isEmpty) ||
        (assignedStudentIds != null && assignedStudentIds.isEmpty)) {
      return const Stream.empty();
    }

    return getExamsQuery(
      teacherId: cleanTeacherId,
      batchIds: batchIds,
      assignedStudentIds: assignedStudentIds,
    ).snapshots();
  }
}
