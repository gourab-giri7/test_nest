import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/main.dart';

class TeacherLoginFeature {
  
  static final firestore = FirebaseFirestore.instance;
  static Future<int> teacherlogin(String id, String password) async {
    try {
      final emails = await firestore.collection("user").get();
      for (final doc in emails.docs) {
        final data = doc.data();
        if (data["id"].toString().trim() == id.trim() &&
            data["password"].toString().trim() == password.trim()) {
          teacherData = TeacherData.fromJson(data);
          // ----------- store local
          TeacherData.updateTeacherLocalData();
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
