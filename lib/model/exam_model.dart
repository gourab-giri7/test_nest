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

  factory ExamModel.fromJson(Map<String, dynamic> json) {
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
      examId: (json['exam_id'] ?? details['exam_id'] ?? '').toString().trim(),
      examName: (details['exam_name'] ?? '').toString(),
      fullMarks: (details['full_marks'] ?? '').toString(),
      examKey: (details['exam_key'] ?? '').toString(),
      instruction: (details['instruction'] ?? '').toString(),
      batch: (details['batch'] ?? '').toString(),
      examStart: _toDateTime(details['exam_start']),
      examEnd: _toDateTime(details['exam_end']),
      resultPublished: _toBool(
        json['result_published'] ?? details['result_published'],
      ),
      assignedStudentIds:
          (json['assigned_student_ids'] as List<dynamic>? ?? const [])
              .map((id) => id.toString().trim())
              .where((id) => id.isNotEmpty)
              .toList(growable: false),
      questions: () {
        final list = <QAModel>[];
        var i = 1;
        for (final item in questionData) {
          if (item is Map) {
            final qa = QAModel.fromJson(Map<String, dynamic>.from(item));
            if (qa.id.trim().isEmpty) {
              qa.id = 'q_$i';
            }
            list.add(qa);
            i++;
          }
        }
        return list;
      }(),
    );
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
}
