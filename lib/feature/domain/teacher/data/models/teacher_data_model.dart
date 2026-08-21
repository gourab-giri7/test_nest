import 'dart:convert';

import 'package:test_nest/main.dart';

class TeacherData {
  String name;
  String password;
  String id;
  String teacherId;
  String lastStdId;
  String lastExamId;
  List<String> batch;
  TeacherData({
    required this.name,
    required this.password,
    required this.id,
    required this.teacherId,
    required this.lastStdId,
    required this.lastExamId,
    required this.batch,
  });
  factory TeacherData.fromJson(Map<String, dynamic> json) {
    return TeacherData(
      id: json["id"].toString().trim(),
      name: json['name'].toString(),
      password: json['password'].toString(),
      teacherId: json['teacher_id'].toString(),
      lastStdId: json['last_std_id'].toString(),
      lastExamId: json['last_exam_id'].toString(),
      batch: List<String>.from(json['batch'] ?? []),
    );
  }
  static Map<String, dynamic> toJson(TeacherData data) {
    return {
      "id": data.id,
      "name": data.name,
      "password": data.password,
      "teacher_id": data.teacherId,
      "last_std_id": data.lastStdId,
      "last_exam_id": data.lastExamId,
      "batch": data.batch,
    };
  }

  static void updateTeacherLocalData() {
    String teacher = jsonEncode(TeacherData.toJson(teacherData));
    pref.setString("teacherData", teacher);
  }
}

late TeacherData teacherData;
