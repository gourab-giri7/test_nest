import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';

class ExamController extends ChangeNotifier {
  final firestore = FirebaseFirestore.instance;
  int selectedTab = 0;

  void changeTab(int index) {
    if (selectedTab != index) {
      selectedTab = index;
      notifyListeners();
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _cachedStream;
  String _cachedTeacherId = "";

  Stream<QuerySnapshot<Map<String, dynamic>>> getExam() {
    final sData = studentData;
    if (sData == null || sData.teacherId.isEmpty) {
      _cachedStream = null;
      _cachedTeacherId = "";
      return const Stream.empty();
    }
    if (_cachedStream != null && _cachedTeacherId == sData.teacherId) {
      return _cachedStream!;
    }
    _cachedTeacherId = sData.teacherId;
    _cachedStream = firestore
        .collection("user")
        .doc(sData.teacherId)
        .collection("exams")
        .orderBy("exam_id", descending: true)
        .snapshots();
    return _cachedStream!;
  }

  void reset() {
    selectedTab = 0;
    _cachedStream = null;
    _cachedTeacherId = "";
    notifyListeners();
  }
}
