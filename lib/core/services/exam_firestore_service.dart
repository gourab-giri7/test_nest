import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/model/exam_model.dart';

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

  /// Returns a combined, deduplicated stream of [ExamModel]s across multiple teachers'
  /// batches without requiring composite server indexes.
  static Stream<List<ExamModel>> getMultiTeacherExamsStream({
    required List<StudentEnrollment> enrollments,
  }) {
    if (enrollments.isEmpty) {
      return Stream.value(const <ExamModel>[]);
    }

    final uniqueTeacherMap = <String, String>{};
    for (final e in enrollments) {
      if (e.teacherId.trim().isNotEmpty) {
        uniqueTeacherMap[e.teacherId.trim()] = e.teacherName.trim();
      }
    }

    if (uniqueTeacherMap.isEmpty) {
      return Stream.value(const <ExamModel>[]);
    }

    late StreamController<List<ExamModel>> streamController;
    final subscriptions = <StreamSubscription>[];
    final teacherExams = <String, List<ExamModel>>{};

    void emitCombined() {
      if (streamController.isClosed) return;
      final seenKeys = <String>{};
      final combined = <ExamModel>[];

      for (final list in teacherExams.values) {
        for (final exam in list) {
          final uniqueKey = '${exam.teacherId}_${exam.examId}';
          if (!seenKeys.contains(uniqueKey) &&
              !seenKeys.contains(exam.examId)) {
            seenKeys.add(uniqueKey);
            seenKeys.add(exam.examId);
            combined.add(exam);
          }
        }
      }

      combined.sort((a, b) {
        final aStart = a.examStart;
        final bStart = b.examStart;
        if (aStart == null && bStart == null) {
          return b.examId.compareTo(a.examId);
        }
        if (aStart == null) return 1;
        if (bStart == null) return -1;
        return bStart.compareTo(aStart);
      });

      streamController.add(combined);
    }

    streamController = StreamController<List<ExamModel>>(
      onListen: () {
        for (final entry in uniqueTeacherMap.entries) {
          final tId = entry.key;
          final tName = entry.value;

          final sub = exams(tId).snapshots().listen(
            (snap) {
              final list = <ExamModel>[];
              for (final doc in snap.docs) {
                try {
                  final exam = ExamModel.fromJson(
                    doc.data(),
                    teacherId: tId,
                    teacherName: tName,
                  );
                  list.add(exam);
                } catch (e) {
                  log('Error parsing exam document ${doc.id}: $e');
                }
              }
              teacherExams[tId] = list;
              emitCombined();
            },
            onError: (err) {
              log('Error listening to exams for teacher $tId: $err');
            },
          );
          subscriptions.add(sub);
        }
      },
      onCancel: () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
        subscriptions.clear();
      },
    );

    return streamController.stream;
  }

  /// Loads exams asynchronously across multiple teachers.
  static Future<List<ExamModel>> loadMultiTeacherExams({
    required List<StudentEnrollment> enrollments,
  }) async {
    if (enrollments.isEmpty) return const [];

    final uniqueTeacherMap = <String, String>{};
    for (final e in enrollments) {
      if (e.teacherId.trim().isNotEmpty) {
        uniqueTeacherMap[e.teacherId.trim()] = e.teacherName.trim();
      }
    }

    final futures = uniqueTeacherMap.entries.map((entry) async {
      final tId = entry.key;
      final tName = entry.value;
      try {
        final snap = await exams(tId).get();
        final list = <ExamModel>[];
        for (final doc in snap.docs) {
          try {
            list.add(
              ExamModel.fromJson(
                doc.data(),
                teacherId: tId,
                teacherName: tName,
              ),
            );
          } catch (_) {}
        }
        return list;
      } catch (e) {
        log('Error loading exams for teacher $tId: $e');
        return <ExamModel>[];
      }
    });

    final results = await Future.wait(futures);
    final seenKeys = <String>{};
    final combined = <ExamModel>[];

    for (final list in results) {
      for (final exam in list) {
        final uniqueKey = '${exam.teacherId}_${exam.examId}';
        if (!seenKeys.contains(uniqueKey) && !seenKeys.contains(exam.examId)) {
          seenKeys.add(uniqueKey);
          seenKeys.add(exam.examId);
          combined.add(exam);
        }
      }
    }

    combined.sort((a, b) {
      final aStart = a.examStart;
      final bStart = b.examStart;
      if (aStart == null && bStart == null) {
        return b.examId.compareTo(a.examId);
      }
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      return bStart.compareTo(aStart);
    });

    return combined;
  }
}
