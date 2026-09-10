import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/model/exam_details_model.dart';

class ExamController extends ChangeNotifier {
  int _selectedTabIndex = 0;
  String examStatus = "All";
  int get selectedTabIndex => _selectedTabIndex;
  // List<ExamModel> exams = [];
  final firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getExam() {
    // log(studentData.id);
    return firestore
        .collection("user")
        .doc(studentData.teacherId)
        .collection("exams")
        .snapshots();
  }

  void filterExam(int index, String status) {
    _selectedTabIndex = index;
    examStatus = status;
    notifyListeners();
  }
}
