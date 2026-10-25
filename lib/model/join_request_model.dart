class JoinRequestModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String studentEmail;
  final String? studentPhone;
  final String teacherId;
  final String teacherName;
  final String batchId;
  final String batchName;
  final String status; // "pending" | "approved" | "rejected"
  final DateTime? requestedAt;
  final DateTime? resolvedAt;

  JoinRequestModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.studentEmail,
    this.studentPhone,
    required this.teacherId,
    required this.teacherName,
    required this.batchId,
    required this.batchName,
    this.status = 'pending',
    this.requestedAt,
    this.resolvedAt,
  });

  factory JoinRequestModel.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    return JoinRequestModel(
      id: docId ?? (json['id'] ?? json['request_id'] ?? '').toString(),
      studentUid: (json['student_uid'] ?? '').toString().trim(),
      studentName: (json['student_name'] ?? '').toString().trim(),
      studentEmail: (json['student_email'] ?? '').toString().trim(),
      studentPhone: json['student_phone']?.toString().trim(),
      teacherId: (json['teacher_id'] ?? '').toString().trim(),
      teacherName: (json['teacher_name'] ?? '').toString().trim(),
      batchId: (json['batch_id'] ?? '').toString().trim(),
      batchName: (json['batch_name'] ?? '').toString().trim(),
      status: (json['status'] ?? 'pending').toString().trim().toLowerCase(),
      requestedAt: json['requested_at'] != null
          ? (json['requested_at'] is DateTime
                ? json['requested_at'] as DateTime
                : DateTime.tryParse(json['requested_at'].toString()))
          : null,
      resolvedAt: json['resolved_at'] != null
          ? (json['resolved_at'] is DateTime
                ? json['resolved_at'] as DateTime
                : DateTime.tryParse(json['resolved_at'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_uid': studentUid.trim(),
      'student_name': studentName.trim(),
      'student_email': studentEmail.trim(),
      'student_phone': studentPhone?.trim(),
      'teacher_id': teacherId.trim(),
      'teacher_name': teacherName.trim(),
      'batch_id': batchId.trim(),
      'batch_name': batchName.trim(),
      'status': status.trim().toLowerCase(),
    };
  }

  JoinRequestModel copyWith({
    String? id,
    String? studentUid,
    String? studentName,
    String? studentEmail,
    String? studentPhone,
    String? teacherId,
    String? teacherName,
    String? batchId,
    String? batchName,
    String? status,
    DateTime? requestedAt,
    DateTime? resolvedAt,
  }) {
    return JoinRequestModel(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      studentPhone: studentPhone ?? this.studentPhone,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      batchId: batchId ?? this.batchId,
      batchName: batchName ?? this.batchName,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
