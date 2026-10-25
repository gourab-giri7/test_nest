import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/main.dart';

class StudentEnrollment {
  final String teacherId;
  final String teacherName;
  final String batchId;
  final String batchName;
  final String studentId;
  final String status;
  final DateTime? enrolledAt;

  StudentEnrollment({
    required this.teacherId,
    required this.teacherName,
    required this.batchId,
    required this.batchName,
    required this.studentId,
    this.status = 'active',
    this.enrolledAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isRemoved =>
      status.toLowerCase() == 'removed' ||
      status.toLowerCase() == 'removed_by_teacher';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPending => status.toLowerCase() == 'pending';

  factory StudentEnrollment.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate =
        json['enrolled_at'] ??
        json['approved_at'] ??
        json['created_at'] ??
        json['enrolledAt'] ??
        json['approvedAt'];

    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    return StudentEnrollment(
      teacherId: (json['teacher_id'] ?? json['teacherId'] ?? '')
          .toString()
          .trim(),
      teacherName: (json['teacher_name'] ?? json['teacherName'] ?? '')
          .toString()
          .trim(),
      batchId: (json['batch_id'] ?? json['batchId'] ?? '').toString().trim(),
      batchName:
          (json['batch_name'] ?? json['batch'] ?? json['batchName'] ?? '')
              .toString()
              .trim(),
      studentId: (json['student_id'] ?? json['id'] ?? '').toString().trim(),
      status: (json['status'] ?? 'active').toString().trim(),
      enrolledAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'batch_id': batchId,
      'batch_name': batchName,
      'student_id': studentId,
      'status': status,
      'enrolled_at': enrolledAt?.toIso8601String(),
    };
  }
}

class StudentData {
  String name;
  String id;
  String teacherId;
  String batch;
  String teacherName;
  List<StudentEnrollment> enrollments;

  StudentData({
    required this.name,
    required this.id,
    required this.teacherId,
    required this.batch,
    required this.teacherName,
    List<StudentEnrollment>? enrollments,
  }) : enrollments = enrollments ?? [];

  /// Returns only active, approved batch enrollments.
  List<StudentEnrollment> get activeEnrollments =>
      enrollments.where((e) => e.isActive).toList(growable: false);

  /// Whether the student currently has at least one approved, active enrollment.
  bool get hasActiveEnrollment => activeEnrollments.isNotEmpty;

  /// Retrieves the enrollment record for a specific teacher.
  StudentEnrollment? getEnrollmentForTeacher(String? targetTeacherId) {
    final clean = targetTeacherId?.trim() ?? '';
    if (clean.isEmpty) {
      return activeEnrollments.isNotEmpty ? activeEnrollments.first : null;
    }
    for (final e in enrollments) {
      if (e.teacherId.trim() == clean) {
        return e;
      }
    }
    return null;
  }

  /// Returns the server-managed enrollment timestamp for a teacher.
  DateTime? getEnrollmentDateForTeacher(String? targetTeacherId) {
    return getEnrollmentForTeacher(targetTeacherId)?.enrolledAt;
  }

  /// Returns the assigned student ID for a given teacher, or defaults to [id].
  String getStudentIdForTeacher(String? targetTeacherId) {
    final clean = targetTeacherId?.trim() ?? '';
    if (clean.isEmpty) return id;
    for (final e in enrollments) {
      if (e.teacherId.trim() == clean && e.studentId.trim().isNotEmpty) {
        return e.studentId.trim();
      }
    }
    return id;
  }

  /// Returns the batch name for a given teacher, or defaults to [batch].
  String getBatchForTeacher(String? targetTeacherId) {
    final clean = targetTeacherId?.trim() ?? '';
    if (clean.isEmpty) return batch;
    for (final e in enrollments) {
      if (e.teacherId.trim() == clean && e.batchName.trim().isNotEmpty) {
        return e.batchName.trim();
      }
    }
    return batch;
  }

  /// Returns all unique teacher IDs with active memberships.
  List<String> get allTeacherIds {
    final set = <String>{};
    for (final e in activeEnrollments) {
      if (e.teacherId.trim().isNotEmpty) set.add(e.teacherId.trim());
    }
    if (set.isEmpty && enrollments.isEmpty && teacherId.trim().isNotEmpty) {
      set.add(teacherId.trim());
    }
    return set.toList(growable: false);
  }

  /// Returns all unique teacher names with active memberships.
  List<String> get allTeacherNames {
    final set = <String>{};
    for (final e in activeEnrollments) {
      if (e.teacherName.trim().isNotEmpty) set.add(e.teacherName.trim());
    }
    if (set.isEmpty && enrollments.isEmpty && teacherName.trim().isNotEmpty) {
      set.add(teacherName.trim());
    }
    return set.toList(growable: false);
  }

  /// Returns all batch names with active memberships.
  List<String> get allBatchNames {
    final set = <String>{};
    for (final e in activeEnrollments) {
      if (e.batchName.trim().isNotEmpty) set.add(e.batchName.trim());
    }
    if (set.isEmpty && enrollments.isEmpty && batch.trim().isNotEmpty) {
      set.add(batch.trim());
    }
    return set.toList(growable: false);
  }

  factory StudentData.fromJson(Map<String, dynamic> json, {String? docId}) {
    final resolvedId =
        (json["id"] ?? json["student_id"] ?? json["studentId"] ?? docId ?? "")
            .toString()
            .trim();
    final resolvedTeacherId =
        (json['teacher_id'] ?? json['teacherId'] ?? json['teacherDocId'] ?? "")
            .toString()
            .trim();
    final resolvedTeacherName =
        (json['teacher_name'] ?? json['teacherName'] ?? "").toString().trim();
    final resolvedBatch =
        (json['batch'] ?? json['batch_name'] ?? json['batchName'] ?? "")
            .toString()
            .trim();

    final parsedEnrollments = <StudentEnrollment>[];
    if (json['enrollments'] is List) {
      for (final item in json['enrollments'] as List) {
        if (item is Map) {
          try {
            parsedEnrollments.add(
              StudentEnrollment.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {}
        }
      }
    }

    // If enrollments was empty but a single teacher/batch is present, seed with single enrollment
    if (parsedEnrollments.isEmpty && resolvedTeacherId.isNotEmpty) {
      parsedEnrollments.add(
        StudentEnrollment(
          teacherId: resolvedTeacherId,
          teacherName: resolvedTeacherName,
          batchId: (json['batch_id'] ?? '').toString().trim(),
          batchName: resolvedBatch,
          studentId: resolvedId,
        ),
      );
    }

    return StudentData(
      id: resolvedId,
      name: (json['name'] ?? json['student_name'] ?? json['studentName'] ?? "")
          .toString()
          .trim(),
      teacherId: resolvedTeacherId,
      batch: resolvedBatch,
      teacherName: resolvedTeacherName,
      enrollments: parsedEnrollments,
    );
  }

  static Map<String, dynamic> toJson(StudentData data) {
    return {
      "id": data.id,
      "name": data.name,
      "teacher_id": data.teacherId,
      "batch": data.batch,
      "teacher_name": data.teacherName,
      "enrollments": data.enrollments.map((e) => e.toJson()).toList(),
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
          enrollments: studentData?.enrollments ?? [],
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
