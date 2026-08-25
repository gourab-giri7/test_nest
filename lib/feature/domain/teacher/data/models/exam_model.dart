import 'package:cloud_firestore/cloud_firestore.dart';

class ExamModel {
  final String examName;
  final String fullMarks;
  final String examKey;
  final String instruction;
  final String batch;

  final DateTime examStart;
  final DateTime examEnd;

  ExamModel({
    required this.examName,
    required this.fullMarks,
    required this.examKey,
    required this.instruction,
    required this.batch,
    required this.examStart,
    required this.examEnd,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      examName: json['exam_name']?.toString() ?? '',
      fullMarks: json['full_marks']?.toString() ?? '',
      examKey: json['exam_key']?.toString() ?? '',
      instruction: json['instruction']?.toString() ?? '',
      batch: json['batch']?.toString() ?? '',

      examStart: _timestampToDateTime(json['exam_start']),
      examEnd: _timestampToDateTime(json['exam_end']),
    );
  }

  static DateTime _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.parse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'exam_name': examName,
      'full_marks': fullMarks,
      'exam_key': examKey,
      'instruction': instruction,
      'batch': batch,

      'exam_start': Timestamp.fromDate(examStart),
      'exam_end': Timestamp.fromDate(examEnd),
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
late ExamModel examDetails;