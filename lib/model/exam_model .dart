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
  final DateTime examStart;
  final DateTime examEnd;

  final List<QAModel> questions;

  ExamModel({
    required this.examId,
    required this.examName,
    required this.fullMarks,
    required this.examKey,
    required this.instruction,
    required this.batch,
    required this.examStart,
    required this.examEnd,
    required this.questions,
  });

  // =========================
  // FROM FIRESTORE
  // =========================

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    final details = json['exam_details'] as Map<String, dynamic>? ?? {};

    final questionData = json['questions'] as List<dynamic>? ?? [];

    return ExamModel(
      examId: json['exam_id']?.toString() ?? '',

      examName: details['exam_name']?.toString() ?? '',
      fullMarks: details['full_marks']?.toString() ?? '',
      examKey: details['exam_key']?.toString() ?? '',
      instruction: details['instruction']?.toString() ?? '',
      batch: details['batch']?.toString() ?? '',

      examStart: _toDateTime(details['exam_start']),
      examEnd: _toDateTime(details['exam_end']),

      questions: questionData
          .map((e) => QAModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  // =========================
  // TIMESTAMP CONVERSION
  // =========================

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    throw FormatException('Invalid date value: $value');
  }

  // =========================
  // TO FIRESTORE
  // =========================

  Map<String, dynamic> toJson() {
    return {
      'exam_id': examId,

      'exam_details': {
        'exam_name': examName,
        'full_marks': fullMarks,
        'exam_key': examKey,
        'instruction': instruction,
        'batch': batch,

        'exam_start': Timestamp.fromDate(examStart),
        'exam_end': Timestamp.fromDate(examEnd),
      },

      'questions': questions.map((question) => question.toJson()).toList(),
    };
  }

  // =========================
  // FORMATTED DATE
  // =========================

  String get examDate {
    return DateFormat('dd MMMM yyyy').format(examStart);
  }

  String get startTime {
    return DateFormat('hh:mm a').format(examStart);
  }

  String get endTime {
    return DateFormat('hh:mm a').format(examEnd);
  }

  String get startDateTime {
    return DateFormat('dd MMM yyyy, hh:mm a').format(examStart);
  }

  String get endDateTime {
    return DateFormat('dd MMM yyyy, hh:mm a').format(examEnd);
  }

  // =========================
  // EXAM STATUS
  // =========================

  String get status {
    final now = DateTime.now();

    if (now.isBefore(examStart)) {
      return 'Upcoming';
    }

    if (now.isAfter(examEnd)) {
      return 'Completed';
    }

    return 'Active';
  }

  // =========================
  // QUESTION COUNT
  // =========================

  int get questionCount {
    return questions.length;
  }
}
