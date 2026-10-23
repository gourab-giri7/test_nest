import 'dart:convert';

import 'package:test_nest/main.dart';

class StudentData {
  String name;
  String id;
  String teacherId;
  String batch;
  String teacherName;
  StudentData({
    required this.name,
    required this.id,
    required this.teacherId,
    required this.batch,
    required this.teacherName,
  });
  factory StudentData.fromJson(Map<String, dynamic> json, {String? docId}) {
    final resolvedId = (json["id"] ?? json["student_id"] ?? docId ?? "")
        .toString()
        .trim();
    return StudentData(
      id: resolvedId,
      name: (json['name'] ?? "").toString(),
      teacherId: (json['teacher_id'] ?? "").toString().trim(),
      batch: (json['batch'] ?? "").toString(),
      teacherName: (json['teacher_name'] ?? "").toString(),
    );
  }

  static Map<String, dynamic> toJson(StudentData data) {
    return {
      "id": data.id,
      "name": data.name,
      "teacher_id": data.teacherId,
      "batch": data.batch,
      "teacher_name": data.teacherName,
      // NOTE: password is intentionally NOT stored here
    };
  }

  static Future<void> updateStudentLocalData() async {
    if (studentData != null) {
      String student = jsonEncode(StudentData.toJson(studentData!));
      await pref.setString("studentData", student);
      await pref.setBool("isLogined", true);
      await pref.setString("role", "student");
      await pref.setString("id", studentData!.id);
      await pref.setString("teacherId", studentData!.teacherId);
      // NOTE: password is NOT stored in SharedPreferences
    }
  }
}

StudentData? studentData;
