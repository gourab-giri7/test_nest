import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';

class StudentController extends ChangeNotifier {
  String dropDownvalue = "all";
  String searchValue = "";
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allDocs = [];

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get studentsData =>
      filteredStudents;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get filteredStudents =>
      filterDocs(_allDocs);

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final search = searchValue.trim().toLowerCase();
    final batchFilter = dropDownvalue.trim().toLowerCase();
    final availableBatches = getBatchItems(
      docs,
    ).map((b) => b.trim().toLowerCase()).toSet();
    final effectiveBatchFilter =
        (batchFilter == "all" || availableBatches.contains(batchFilter))
        ? batchFilter
        : "all";

    return docs.where((doc) {
      final student = StudentModel.fromJson(doc.data(), docId: doc.id);
      if (!student.isActive) {
        return false;
      }

      final matchesSearch =
          search.isEmpty ||
          student.name.toLowerCase().contains(search) ||
          student.id.toLowerCase().contains(search) ||
          student.email.toLowerCase().contains(search) ||
          student.batch.toLowerCase().contains(search);

      final matchesBatch =
          effectiveBatchFilter == "all" ||
          student.batch.trim().toLowerCase() == effectiveBatchFilter ||
          (student.batchId != null &&
              student.batchId!.trim().toLowerCase() == effectiveBatchFilter);

      return matchesSearch && matchesBatch;
    }).toList();
  }

  void search(String value) {
    final clean = value.trim();
    if (searchValue != clean) {
      searchValue = clean;
      notifyListeners();
    }
  }

  void filter(String value) {
    if (dropDownvalue != value) {
      dropDownvalue = value;
      notifyListeners();
    }
  }

  List<String> get batchItems => getBatchItems(_allDocs);

  List<String> getBatchItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final batches = docs
        .map((doc) => StudentModel.fromJson(doc.data(), docId: doc.id))
        .where((s) => s.isActive && s.batch.isNotEmpty)
        .map((s) => s.batch)
        .toSet()
        .toList();

    batches.sort();
    return batches;
  }

  void setDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    _allDocs = docs;
  }

  void reset() {
    dropDownvalue = "all";
    searchValue = "";
    _allDocs = [];
    notifyListeners();
  }
}
