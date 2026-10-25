import 'dart:convert';

import 'package:test_nest/main.dart';

class TeacherData {
  String name;
  String email;
  String id;
  String teacherId;
  String lastStdId;
  String lastExamId;
  List<String> batch;
  bool feeTrackingEnabled;

  TeacherData({
    required this.name,
    required this.email,
    required this.id,
    required this.teacherId,
    required this.lastStdId,
    required this.lastExamId,
    required this.batch,
    this.feeTrackingEnabled = true,
  });

  factory TeacherData.fromJson(Map<String, dynamic> json, {String? docId}) {
    final String resolvedId = (docId != null && docId.trim().isNotEmpty)
        ? docId.trim()
        : (json["id"] ?? "").toString().trim();
    final String resolvedTeacherId =
        (json['teacher_id'] != null &&
            json['teacher_id'].toString().trim().isNotEmpty)
        ? json['teacher_id'].toString().trim()
        : (json['id'] ?? resolvedId).toString().trim();

    return TeacherData(
      id: resolvedId,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      teacherId: resolvedTeacherId,
      lastStdId: (json['last_std_id'] ?? '0').toString(),
      lastExamId: (json['last_exam_id'] ?? '0').toString(),
      batch: List<String>.from(json['batch'] ?? []),
      feeTrackingEnabled: json['fee_tracking_enabled'] != false,
    );
  }

  static Map<String, dynamic> toJson(TeacherData data) {
    return {
      "id": data.id,
      "name": data.name,
      "email": data.email,
      "teacher_id": data.teacherId,
      "last_std_id": data.lastStdId,
      "last_exam_id": data.lastExamId,
      "batch": data.batch,
      "fee_tracking_enabled": data.feeTrackingEnabled,
      // NOTE: password is intentionally NOT stored here
    };
  }

  static Future<void> updateTeacherLocalData() async {
    if (teacherData != null) {
      String teacher = jsonEncode(TeacherData.toJson(teacherData!));
      await pref.setString("teacherData", teacher);
      await pref.setBool("isLogined", true);
      await pref.setString("role", "teacher");
      await pref.setString("id", teacherData!.id);
      // NOTE: password is NOT stored in SharedPreferences
    }
  }
}

TeacherData? teacherData;
