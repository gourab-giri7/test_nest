import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';

class StudentController extends ChangeNotifier {
  String dropDownvalue = "all";
  List<QueryDocumentSnapshot<Map<String, dynamic>>> studentsData = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> mainData = [];
  String searchValue = "";

  void search(String value) {
    searchValue = value;
    if (value.isEmpty) {
      studentsData = mainData;
    } else {
      studentsData = studentsData.where((data) {
        return data.data()["name"].contains(value);
      }).toList();
    }

    notifyListeners();
  }

  void filter(String value) {
    dropDownvalue = value;
    if (value == "all") {
      studentsData = List.from(mainData);
    } else {
      studentsData = mainData.where((data) {
        return data.data()["batch"] == value;
      }).toList();
    }
    log(studentsData.toString());
    notifyListeners();
  }
}
