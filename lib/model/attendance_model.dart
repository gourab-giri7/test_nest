import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceStatus {
  static const String present = 'present';
  static const String absent = 'absent';
  static const String late = 'late';

  static bool isValid(String s) => s == present || s == absent || s == late;
}

class AttendanceRecordModel {
  final String id;
  final String organizationId;
  final String teacherId;
  final String batchId;
  final String batchName;
  final String studentId;
  final String studentName;
  final DateTime date;
  final String dateKey; // Format: YYYY-MM-DD
  final String status; // 'present', 'absent', 'late'
  final String? remarks;
  final String markedBy;
  final String markedByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceRecordModel({
    required this.id,
    this.organizationId = '',
    required this.teacherId,
    required this.batchId,
    required this.batchName,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.dateKey,
    required this.status,
    this.remarks,
    required this.markedBy,
    required this.markedByName,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isLate => status == AttendanceStatus.late;
  bool get isAttended => isPresent || isLate;

  /// Deterministic ID generator preventing duplicates for student + batch + date
  static String generateId({
    required String batchId,
    required String studentId,
    required String dateKey,
  }) {
    final b = batchId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final s = studentId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final d = dateKey.trim();
    return '${b}_${s}_$d';
  }

  /// Consistent local date key representation (YYYY-MM-DD) avoiding UTC shifts
  static String formatDateKey(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  factory AttendanceRecordModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final d = parseDate(map['date']);
    final dKey = (map['dateKey'] ?? map['date_key'] ?? formatDateKey(d))
        .toString();

    return AttendanceRecordModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? '').toString(),
      organizationId: (map['organizationId'] ?? map['orgId'] ?? '').toString(),
      teacherId: (map['teacherId'] ?? map['teacher_id'] ?? '').toString(),
      batchId: (map['batchId'] ?? map['batch_id'] ?? '').toString(),
      batchName: (map['batchName'] ?? map['batch_name'] ?? '').toString(),
      studentId: (map['studentId'] ?? map['student_id'] ?? '').toString(),
      studentName: (map['studentName'] ?? map['student_name'] ?? '').toString(),
      date: d,
      dateKey: dKey,
      status: (map['status'] ?? AttendanceStatus.present)
          .toString()
          .toLowerCase()
          .trim(),
      remarks: map['remarks']?.toString(),
      markedBy: (map['markedBy'] ?? map['marked_by'] ?? '').toString(),
      markedByName: (map['markedByName'] ?? map['marked_by_name'] ?? '')
          .toString(),
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'teacherId': teacherId,
      'batchId': batchId,
      'batchName': batchName,
      'studentId': studentId,
      'studentName': studentName,
      'date': Timestamp.fromDate(date),
      'dateKey': dateKey,
      'status': status,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      'markedBy': markedBy,
      'markedByName': markedByName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AttendanceRecordModel copyWith({
    String? id,
    String? organizationId,
    String? teacherId,
    String? batchId,
    String? batchName,
    String? studentId,
    String? studentName,
    DateTime? date,
    String? dateKey,
    String? status,
    String? remarks,
    String? markedBy,
    String? markedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecordModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      teacherId: teacherId ?? this.teacherId,
      batchId: batchId ?? this.batchId,
      batchName: batchName ?? this.batchName,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      date: date ?? this.date,
      dateKey: dateKey ?? this.dateKey,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      markedBy: markedBy ?? this.markedBy,
      markedByName: markedByName ?? this.markedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StudentAttendanceSummary {
  final String studentId;
  final String studentName;
  final int totalClasses;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final List<AttendanceRecordModel> records;

  const StudentAttendanceSummary({
    required this.studentId,
    required this.studentName,
    required this.totalClasses,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    this.records = const [],
  });

  int get attendedCount => presentCount + lateCount;

  double get attendancePercentage {
    if (totalClasses == 0) return 100.0;
    return ((attendedCount / totalClasses) * 100.0).clamp(0.0, 100.0);
  }

  factory StudentAttendanceSummary.fromRecords({
    required String studentId,
    required String studentName,
    required List<AttendanceRecordModel> records,
  }) {
    int p = 0;
    int a = 0;
    int l = 0;

    for (final r in records) {
      if (r.isPresent) {
        p++;
      } else if (r.isAbsent) {
        a++;
      } else if (r.isLate) {
        l++;
      }
    }

    return StudentAttendanceSummary(
      studentId: studentId,
      studentName: studentName,
      totalClasses: records.length,
      presentCount: p,
      absentCount: a,
      lateCount: l,
      records: records,
    );
  }
}
