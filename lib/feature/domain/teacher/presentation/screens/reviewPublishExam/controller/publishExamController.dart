import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/model/exam_details_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/dashboard/teacher_dashboard_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/fileUpload/controller/file_upload_controller.dart';

class Publishexamcontroller extends ChangeNotifier {
  bool isLoad = false;
  final firestore = FirebaseFirestore.instance;
  void publishExam(BuildContext context) {
    isLoad = true;
    try {
      List<Map<String, dynamic>> QAlist = context
          .read<FileUploadController>()
          .questions
          .map((e) => e.toJson())
          .toList();
      isLoad = true;
      // -- create unique id
      final uniqueId = generateExamId(
        teacherData.name,
        int.parse(teacherData.lastExamId),
      ).toString();
      // ------- publish feature
      final collection = firestore
          .collection("user")
          .doc(teacherData.id)
          .collection('exams');

      collection.doc(uniqueId).set({
        "exam_details": examDetails.toJson(),
        "questions": QAlist,
        "exam_id": uniqueId,
      });
      // -----------update data in firestore
      firestore.collection('user').doc(teacherData.id).set({
        "last_exam_id": (int.parse(teacherData.lastExamId) + 1).toString(),
      });
      // ------ for current use data
      teacherData.lastExamId = (int.parse(teacherData.lastExamId) + 1)
          .toString();
      // -------- for update data locally
      TeacherData.updateTeacherLocalData();
      customSnackbar(
        context: context,
        message: "Exam created Sucessfully",
        color: Colors.green,
        ico: Icons.done,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TeacherDashboardScreen()),
      );
    } catch (e) {
      customSnackbar(
        context: context,
        message: "Error while publishing exam",
        color: Colors.red,
        ico: Icons.error,
      );
      log(e.toString());
    }
    isLoad = false;
    notifyListeners();
  }

  // ------------- unique id create
  static String generateExamId(String teacherName, int sequence) {
    final prefix = '${teacherName.trim().substring(0, 2).toUpperCase()}EX';
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final number = sequence.toString().padLeft(3, '0');
    return '$prefix$year$month$number';
  }
}
