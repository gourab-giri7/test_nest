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
    final resolvedId =
        (json["id"] ?? json["student_id"] ?? json["studentId"] ?? docId ?? "")
            .toString()
            .trim();
    final resolvedTeacherId =
        (json['teacher_id'] ?? json['teacherId'] ?? json['teacherDocId'] ?? "")
            .toString()
            .trim();
    return StudentData(
      id: resolvedId,
      name: (json['name'] ?? json['student_name'] ?? json['studentName'] ?? "")
          .toString()
          .trim(),
      teacherId: resolvedTeacherId,
      batch: (json['batch'] ?? json['batch_name'] ?? json['batchName'] ?? "")
          .toString()
          .trim(),
      teacherName: (json['teacher_name'] ?? json['teacherName'] ?? "")
          .toString()
          .trim(),
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

  static Future<StudentData?> restoreFromPreferences() async {
    if (studentData != null && studentData!.teacherId.trim().isNotEmpty) {
      return studentData;
    }
    final rawString = pref.getString("studentData");
    if (rawString != null && rawString.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawString);
        if (decoded is Map<String, dynamic>) {
          studentData = StudentData.fromJson(decoded);
        }
      } catch (_) {}
    }
    if (studentData == null || studentData!.teacherId.trim().isEmpty) {
      final savedId = pref.getString("id") ?? "";
      final savedTeacherId = pref.getString("teacherId") ?? "";
      if (savedId.isNotEmpty || savedTeacherId.isNotEmpty) {
        studentData = StudentData(
          id: (studentData?.id.isNotEmpty == true)
              ? studentData!.id
              : savedId.trim(),
          name: studentData?.name ?? "",
          teacherId: (studentData?.teacherId.isNotEmpty == true)
              ? studentData!.teacherId
              : savedTeacherId.trim(),
          batch: studentData?.batch ?? "",
          teacherName: studentData?.teacherName ?? "",
        );
      }
    }
    return studentData;
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
