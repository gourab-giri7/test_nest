import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:test_nest/model/Q&A_model.dart';

class ExamModel {
  final String examId;
  final String examName;
  final String fullMarks;
  final String examKey;
  final String instruction;
  final String batch;
  final DateTime? examStart;
  final DateTime? examEnd;
  final List<QAModel> questions;
  final bool resultPublished;
  final List<String> assignedStudentIds;

  const ExamModel({
    required this.examId,
    required this.examName,
    required this.fullMarks,
    required this.examKey,
    required this.instruction,
    required this.batch,
    required this.examStart,
    required this.examEnd,
    required this.questions,
    this.resultPublished = false,
    this.assignedStudentIds = const [],
  });

  factory ExamModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ExamModel(
        examId: '',
        examName: '',
        fullMarks: '',
        examKey: '',
        instruction: '',
        batch: '',
        examStart: null,
        examEnd: null,
        questions: [],
        resultPublished: false,
        assignedStudentIds: [],
      );
    }

    final rawDetails = json['exam_details'];
    var details = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : Map<String, dynamic>.from(json);
    if (details['exam_details'] is Map) {
      details = Map<String, dynamic>.from(details['exam_details'] as Map);
    }
    final rawQuestions = json['questions'];
    final questionData = rawQuestions is List ? rawQuestions : const [];

    return ExamModel(
      examId:
          (json['exam_id'] ??
                  json['id'] ??
                  details['exam_id'] ??
                  details['id'] ??
                  '')
              .toString()
              .trim(),
      examName:
          (details['exam_name'] ?? json['exam_name'] ?? details['name'] ?? '')
              .toString(),
      fullMarks: (details['full_marks'] ?? json['full_marks'] ?? '').toString(),
      examKey: (details['exam_key'] ?? json['exam_key'] ?? '').toString(),
      instruction: (details['instruction'] ?? json['instruction'] ?? '')
          .toString(),
      batch: (details['batch'] ?? json['batch'] ?? '').toString(),
      examStart: _toDateTime(details['exam_start'] ?? json['exam_start']),
      examEnd: _toDateTime(details['exam_end'] ?? json['exam_end']),
      resultPublished: _toBool(
        json['result_published'] ?? details['result_published'],
      ),
      assignedStudentIds: () {
        final rawIds =
            json['assigned_student_ids'] ?? details['assigned_student_ids'];
        if (rawIds is List) {
          return rawIds
              .map((id) => id?.toString().trim() ?? '')
              .where((id) => id.isNotEmpty)
              .toList(growable: false);
        }
        return const <String>[];
      }(),
      questions: () {
        final list = <QAModel>[];
        var i = 1;
        for (final item in questionData) {
          if (item is Map) {
            try {
              final qa = QAModel.fromJson(Map<String, dynamic>.from(item));
              if (qa.id.trim().isEmpty) {
                qa.id = 'q_$i';
              }
              list.add(qa);
              i++;
            } catch (_) {}
          }
        }
        return list;
      }(),
    );
  }

  /// Alias factory for [fromJson] to support [fromMap] call convention.
  factory ExamModel.fromMap(Map<String, dynamic>? map) =>
      ExamModel.fromJson(map);

  /// Deserializes an [ExamModel] from a Firestore [DocumentSnapshot].
  factory ExamModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final mapWithId = Map<String, dynamic>.from(data);
    if (!mapWithId.containsKey('exam_id') ||
        (mapWithId['exam_id']?.toString().trim().isEmpty ?? true)) {
      mapWithId['exam_id'] = doc.id;
    }
    return ExamModel.fromJson(mapWithId);
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'exam_id': examId,
    'exam_details': {
      'exam_name': examName,
      'full_marks': fullMarks,
      'exam_key': examKey,
      'instruction': instruction,
      'batch': batch,
      'exam_start': examStart == null ? null : Timestamp.fromDate(examStart!),
      'exam_end': examEnd == null ? null : Timestamp.fromDate(examEnd!),
    },
    'questions': questions.map((q) => q.toJson()).toList(),
    'result_published': resultPublished,
    'assigned_student_ids': assignedStudentIds,
  };

  String get examDate => examStart == null
      ? 'Date not available'
      : DateFormat('dd MMMM yyyy').format(examStart!);
  String get startTime =>
      examStart == null ? '--:--' : DateFormat('hh:mm a').format(examStart!);
  String get endTime =>
      examEnd == null ? '--:--' : DateFormat('hh:mm a').format(examEnd!);
  String get startDateTime => examStart == null
      ? 'Date not available'
      : DateFormat('dd MMM yyyy, hh:mm a').format(examStart!);
  String get endDateTime => examEnd == null
      ? 'Date not available'
      : DateFormat('dd MMM yyyy, hh:mm a').format(examEnd!);

  /// Calculates the current exam status from the actual start/end time.
  ///
  /// This is intentionally calculated at read time instead of relying on a
  /// stored status value, so the UI cannot become stale when the date changes.
  String get status {
    final start = examStart;
    final end = examEnd;

    if (start == null || end == null || !end.isAfter(start)) {
      return 'Invalid';
    }

    final now = DateTime.now();

    if (now.isBefore(start)) {
      return 'Upcoming';
    }

    // At the exact end time the exam is already completed.
    if (!now.isBefore(end)) {
      return 'Completed';
    }

    return 'Active';
  }

  int get questionCount => questions.length;

  bool isStudentAssigned(
    String studentId, {
    String? authUid,
    String? studentBatch,
  }) {
    final cleanId = studentId.trim().toLowerCase();
    final cleanAuthUid = (authUid ?? '').trim().toLowerCase();

    // If specific students are assigned, check against studentId and authUid
    if (assignedStudentIds.isNotEmpty) {
      return assignedStudentIds.any((id) {
        final cleanAssigned = id.trim().toLowerCase();
        return cleanAssigned == cleanId ||
            (cleanAuthUid.isNotEmpty && cleanAssigned == cleanAuthUid);
      });
    }

    // If assignedStudentIds is empty (batch-wide or legacy exam), check batch
    if (studentBatch != null &&
        studentBatch.trim().isNotEmpty &&
        batch.trim().isNotEmpty) {
      return studentBatch.trim().toLowerCase() ==
          batch.trim().toLowerCase();
    }

    // Default to true if the exam is not restricted to specific IDs
    return cleanId.isNotEmpty;
  }

  ExamModel copyWith({
    String? examId,
    String? examName,
    String? fullMarks,
    String? examKey,
    String? instruction,
    String? batch,
    DateTime? examStart,
    DateTime? examEnd,
    List<QAModel>? questions,
    bool? resultPublished,
    List<String>? assignedStudentIds,
  }) {
    return ExamModel(
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      fullMarks: fullMarks ?? this.fullMarks,
      examKey: examKey ?? this.examKey,
      instruction: instruction ?? this.instruction,
      batch: batch ?? this.batch,
      examStart: examStart ?? this.examStart,
      examEnd: examEnd ?? this.examEnd,
      questions: questions ?? this.questions,
      resultPublished: resultPublished ?? this.resultPublished,
      assignedStudentIds: assignedStudentIds ?? this.assignedStudentIds,
    );
  }
}
