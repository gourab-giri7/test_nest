import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    return docs.where((doc) {
      final data = doc.data();
      final status = (data["status"] ?? "active").toString().toLowerCase();
      if (status == "removed" || status == "removed_by_teacher") {
        return false;
      }

      final name = (data["name"] ?? "").toString().toLowerCase();
      final id = (data["id"] ?? "").toString().toLowerCase();
      final batch = (data["batch"] ?? "").toString();

      final matchesSearch =
          searchValue.isEmpty ||
          name.contains(searchValue.toLowerCase()) ||
          id.contains(searchValue.toLowerCase());

      final matchesBatch =
          dropDownvalue == "all" ||
          batch.trim().toLowerCase() == dropDownvalue.trim().toLowerCase();

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
        .map((doc) {
          final data = doc.data();
          return (data['batch'] ?? '').toString().trim();
        })
        .where((batch) => batch.isNotEmpty)
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
