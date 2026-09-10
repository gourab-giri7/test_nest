import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/main.dart';

class AddStudentController extends ChangeNotifier {
  final firestore = FirebaseFirestore.instance;
  // - create new id
  void getNewId() {
    studentIdController.text = generateStudentId(
      teacherData.name,
      int.tryParse(teacherData.lastStdId)! + 1,
    );
  }

  final studentkey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController batchController = TextEditingController();
  // ---------------- validators
  String? passwordValidator(String? value) {
    if (value!.isEmpty) {
      return "Fil this fields before submit";
    } else if (value.length < 5) {
      return "Minimum 5 characters required";
    }
    return null;
  }

  String? validator(String? value) {
    if (value!.isEmpty) {
      return "Fil this fields before submit";
    }
    return null;
  }

  // ------------- unique id create
  static String generateStudentId(String teacherName, int sequence) {
    final prefix = teacherName.trim().substring(0, 2).toUpperCase();
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final number = sequence.toString().padLeft(3, '0');
    return '$prefix$year$month$number';
  }

  void addStudent(BuildContext context) {
    // update teacherdata.lastStdID and in firestore also
    if (studentkey.currentState!.validate()) {
      try {
        firestore
            .collection('user')
            .doc(teacherData.id)
            .collection("students")
            .doc(studentIdController.text.trim())
            .set({
              'batch': batchController.text.trim(),
              'id': studentIdController.text.trim(),
              'name': fullNameController.text.trim(),
              'password': passwordController.text.trim(),
              'teacher_id': teacherData.id.trim(),
              'teacher_name': teacherData.name.trim(),
            });
        String lastStdId = (int.tryParse(teacherData.lastStdId)! + 1)
            .toString();
        firestore.collection('user').doc(teacherData.id).update({
          "last_std_id": lastStdId,
        });
        teacherData.lastStdId = lastStdId;
        log(lastStdId);
        TeacherData.updateTeacherLocalData();
        customSnackbar(
          context: context,
          message: "Student added",
          color: Colors.green,
          ico: Icons.done,
        );

        Navigator.pop(context);
      } catch (e) {
        log(e.toString());
        customSnackbar(
          context: context,
          message: "Somthing went wrong please try again later",
          color: Colors.red,
          ico: Icons.info,
        );
      }
    }
  }

  // ---------------------- dialog feature
  String selectedBatche = "select_batch";
  List<String> allBatches = teacherData.batch;
  void selectBatch(int index) {
    selectedBatche = allBatches[index];
    notifyListeners();
  }

  void addbatch(String batchName, BuildContext context) {
    allBatches.add(batchName);
    teacherData.batch = allBatches;
    TeacherData.updateTeacherLocalData();
    try {
      firestore.collection("user").doc(teacherData.id).update({
        "batch": teacherData.batch,
      });
    } catch (e) {
      log(e.toString());
      customSnackbar(
        context: context,
        message: "Somthing went wrong please try again later",
        color: Colors.orange,
        ico: Icons.info,
      );
    }

    notifyListeners();
  }

  void allClear() {
    log("clear");
    fullNameController.clear();
    passwordController.clear();
    batchController.clear();
    selectedBatche = "select_batch";
    allBatches = teacherData.batch;
    notifyListeners();
  }
}
