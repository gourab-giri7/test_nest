import 'package:cloud_firestore/cloud_firestore.dart';

class ExamDetailsModel {
  // final String examId;
  final String examName;
  final String fullMarks;
  final String examKey;
  final String instruction;
  final String batch;

  final DateTime examStart;
  final DateTime examEnd;

  ExamDetailsModel({
    // required this.examId,
    required this.examName,
    required this.fullMarks,
    required this.examKey,
    required this.instruction,
    required this.batch,
    required this.examStart,
    required this.examEnd,
  });

  factory ExamDetailsModel.fromJson(Map<String, dynamic> json) {
    final details = json['exam_details'] as Map<String, dynamic>? ?? {};

    return ExamDetailsModel(
      // examId: json['exam_id']?.toString() ?? '',
      examName: details['exam_name']?.toString() ?? '',
      fullMarks: details['full_marks']?.toString() ?? '',
      examKey: details['exam_key']?.toString() ?? '',
      instruction: details['instruction']?.toString() ?? '',
      batch: details['batch']?.toString() ?? '',
      examStart: _timestampToDateTime(details['exam_start']),
      examEnd: _timestampToDateTime(details['exam_end']),
    );
  }

  static DateTime _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    throw FormatException('Invalid timestamp value: $value');
  }

  Map<String, dynamic> toJson() {
    return {
      // 'exam_id': examId,
      'exam_details': {
        'exam_name': examName,
        'full_marks': fullMarks,
        'exam_key': examKey,
        'instruction': instruction,
        'batch': batch,
        'exam_start': Timestamp.fromDate(examStart),
        'exam_end': Timestamp.fromDate(examEnd),
      },
    };
  }

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
}

late ExamDetailsModel examDetails;
