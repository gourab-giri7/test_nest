import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:test_nest/core/services/exam_firestore_service.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/model/exam_model.dart';

class StudentDashboardController extends ChangeNotifier {
  Stream<List<ExamModel>>? _examStream;
  Stream<List<ExamModel>>? get examStream => _examStream;

  StudentDashboardController() {
    loadStudentData();
    openExamStream();
  }

  void loadStudentData() {
    if (studentData == null) {
      final data = pref.getString('studentData');
      if (data != null && data.isNotEmpty) {
        try {
          studentData = StudentData.fromJson(jsonDecode(data));
          notifyListeners();
        } catch (e) {
          log('Error parsing studentData: $e');
        }
      }
    }
  }

  void openExamStream() {
    try {
      if (studentData != null) {
        final active = studentData!.activeEnrollments;
        if (active.isNotEmpty) {
          _examStream = ExamFirestoreService.getMultiTeacherExamsStream(
            enrollments: active,
          );
        } else {
          _examStream = Stream.value(const <ExamModel>[]);
        }
      } else {
        _examStream = Stream.value(const <ExamModel>[]);
      }
    } catch (e) {
      log('Could not open exam stream: $e');
      _examStream = Stream.value(const <ExamModel>[]);
    }
    notifyListeners();
  }

  void retryExamStream() {
    openExamStream();
  }
}
