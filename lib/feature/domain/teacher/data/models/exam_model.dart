import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExamModel {
  final String examName;
  final String fullMarks;
  final String examKey;
  final String instruction;
  final String batch;

  final DateTime examDate;
  final int startTime;
  final int endTime;

  ExamModel({
    required this.examName,
    required this.fullMarks,
    required this.examKey,
    required this.instruction,
    required this.batch,
    required this.examDate,
    required this.startTime,
    required this.endTime,
  });

  // TimeOfDay → minutes
  static int timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  // Minutes → TimeOfDay
  static TimeOfDay minutesToTime(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    final dateValue = json['exam_date'];

    DateTime examDate;

    if (dateValue is Timestamp) {
      examDate = dateValue.toDate();
    } else {
      examDate = DateTime.parse(dateValue.toString());
    }

    return ExamModel(
      examName: json['exam_name']?.toString() ?? '',
      fullMarks: json['full_marks']?.toString() ?? '',
      examKey: json['exam_key']?.toString() ?? '',
      instruction: json['instruction']?.toString() ?? '',
      batch: json['batch']?.toString() ?? '',

      examDate: examDate,

      startTime: int.tryParse(json['start_time'].toString()) ?? 0,

      endTime: int.tryParse(json['end_time'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exam_name': examName,
      'full_marks': fullMarks,
      'exam_key': examKey,
      'instruction': instruction,
      'batch': batch,

      // Firestore Timestamp
      'exam_date': Timestamp.fromDate(examDate),

      // Minutes from midnight
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  // Full start DateTime
  DateTime get examStartDateTime {
    return DateTime(
      examDate.year,
      examDate.month,
      examDate.day,
      startTime ~/ 60,
      startTime % 60,
    );
  }

  // Full end DateTime
  DateTime get examEndDateTime {
    return DateTime(
      examDate.year,
      examDate.month,
      examDate.day,
      endTime ~/ 60,
      endTime % 60,
    );
  }

  String get status {
    final now = DateTime.now();

    if (now.isBefore(examStartDateTime)) {
      return 'Upcoming';
    }

    if (now.isAfter(examEndDateTime)) {
      return 'Completed';
    }

    return 'Active';
  }
}
