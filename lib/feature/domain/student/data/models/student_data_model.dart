import 'dart:convert';

import 'package:test_nest/main.dart';

class StudentData {
  String name;
  String password;
  String id;
  String teacherId;
  String batch;
  String teacherName;
  StudentData({
    required this.name,
    required this.password,
    required this.id,
    required this.teacherId,
    required this.batch,
    required this.teacherName,
  });
  factory StudentData.fromJson(Map<String, dynamic> json) {
    return StudentData(
      id: json["id"].toString().trim(),
      name: json['name'].toString(),
      password: json['password'].toString(),
      teacherId: json['teacher_id'].toString(),
      batch: json['batch'].toString(),
      teacherName: json['teacher_name'].toString(),
      // batch: List<String>.from(json['batch'] ?? []),
    );
  }
  static Map<String, dynamic> toJson(StudentData data) {
    return {
      "id": data.id,
      "name": data.name,
      "password": data.password,
      "teacher_id": data.teacherId,
      "batch": data.batch,
      "teacher_name": data.teacherName,
    };
  }

  static void updateStudentLocalData() {
    String student = jsonEncode(StudentData.toJson(studentData));
    pref.setString("studentData", student);
  }
}

late StudentData studentData;
