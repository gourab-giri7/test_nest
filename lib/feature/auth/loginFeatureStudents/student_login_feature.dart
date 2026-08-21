import 'dart:developer';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/teacher/data/datasources/get_student_data.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/main.dart';

class StudentLoginFeature {
  static final firestore = FirebaseFirestore.instance;
  static Future<int> studentlogin(
    String teacherId,
    String id,
    String password,
  ) async {
    try {
      final ids = await firestore
          .collection("user")
          .doc(teacherId)
          .collection("students")
          .get();
      for (final doc in ids.docs) {
        final data = doc.data();
        if (data["id"].toString().trim() == id.trim() &&
            data["password"].toString().trim() == password.trim()) {
          studentData = StudentData.fromJson(data);
          // ----------- store local
          StudentData.updateStudentLocalData();
          // String teacher = jsonEncode(TeacherData.toJson(teacherData));
          // pref.setString("teacherData", teacher);
          return 200;
        }
      }
    } catch (e) {
      log(name: "login error", e.toString());
      return 400;
    }

    return 404;
  }
}
