import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? orgId;
  final String? orgName;
  final String? assignedBatchId;
  final String? assignedBatchName;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String status; // "pending" | "approved" | "rejected"
  final DateTime? requestedAt;
  final DateTime? resolvedAt;

  JoinRequestModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.studentEmail,
    String? studentPhone,
    String? phone,
    this.teacherId = '',
    this.teacherName = '',
    this.batchId = '',
    this.batchName = '',
    this.orgId,
    this.orgName,
    this.assignedBatchId,
    this.assignedBatchName,
    this.reviewedBy,
    this.reviewedAt,
    this.status = 'pending',
    DateTime? requestedAt,
    DateTime? timestamp,
    this.resolvedAt,
  }) : studentPhone = studentPhone ?? phone,
       requestedAt = requestedAt ?? timestamp;

  bool get isApproved => status.trim().toLowerCase() == 'approved';
  bool get isPending => status.trim().toLowerCase() == 'pending';
  bool get isRejected => status.trim().toLowerCase() == 'rejected';

  factory JoinRequestModel.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String && val.isNotEmpty) return DateTime.tryParse(val);
      return null;
    }

    return JoinRequestModel(
      id: docId ?? (json['id'] ?? json['request_id'] ?? '').toString(),
      studentUid: (json['student_uid'] ?? json['studentUid'] ?? '')
          .toString()
          .trim(),
      studentName: (json['student_name'] ?? json['studentName'] ?? '')
          .toString()
          .trim(),
      studentEmail: (json['student_email'] ?? json['studentEmail'] ?? '')
          .toString()
          .trim(),
      studentPhone:
          json['student_phone']?.toString().trim() ??
          json['studentPhone']?.toString().trim(),
      teacherId: (json['teacher_id'] ?? json['teacherId'] ?? '')
          .toString()
          .trim(),
      teacherName: (json['teacher_name'] ?? json['teacherName'] ?? '')
          .toString()
          .trim(),
      batchId: (json['batch_id'] ?? json['batchId'] ?? '').toString().trim(),
      batchName: (json['batch_name'] ?? json['batchName'] ?? '')
          .toString()
          .trim(),
      orgId:
          json['org_id']?.toString().trim() ?? json['orgId']?.toString().trim(),
      orgName:
          json['org_name']?.toString().trim() ??
          json['orgName']?.toString().trim(),
      assignedBatchId:
          json['assigned_batch_id']?.toString().trim() ??
          json['assignedBatchId']?.toString().trim(),
      assignedBatchName:
          json['assigned_batch_name']?.toString().trim() ??
          json['assignedBatchName']?.toString().trim(),
      reviewedBy:
          json['reviewed_by']?.toString().trim() ??
          json['reviewedBy']?.toString().trim(),
      reviewedAt: parseDate(json['reviewed_at'] ?? json['reviewedAt']),
      status: (json['status'] ?? 'pending').toString().trim().toLowerCase(),
      requestedAt: parseDate(json['requested_at'] ?? json['requestedAt']),
      resolvedAt: parseDate(json['resolved_at'] ?? json['resolvedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_uid': studentUid.trim(),
      'studentUid': studentUid.trim(),
      'student_name': studentName.trim(),
      'studentName': studentName.trim(),
      'student_email': studentEmail.trim().toLowerCase(),
      'studentEmail': studentEmail.trim().toLowerCase(),
      if (studentPhone != null) 'student_phone': studentPhone!.trim(),
      if (studentPhone != null) 'studentPhone': studentPhone!.trim(),
      'teacher_id': teacherId.trim(),
      'teacherId': teacherId.trim(),
      'teacher_name': teacherName.trim(),
      'teacherName': teacherName.trim(),
      'batch_id': batchId.trim(),
      'batchId': batchId.trim(),
      'batch_name': batchName.trim(),
      'batchName': batchName.trim(),
      if (orgId != null) 'org_id': orgId!.trim(),
      if (orgId != null) 'orgId': orgId!.trim(),
      if (orgName != null) 'org_name': orgName!.trim(),
      if (orgName != null) 'orgName': orgName!.trim(),
      if (assignedBatchId != null) 'assigned_batch_id': assignedBatchId!.trim(),
      if (assignedBatchId != null) 'assignedBatchId': assignedBatchId!.trim(),
      if (assignedBatchName != null)
        'assigned_batch_name': assignedBatchName!.trim(),
      if (assignedBatchName != null)
        'assignedBatchName': assignedBatchName!.trim(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy!.trim(),
      if (reviewedBy != null) 'reviewedBy': reviewedBy!.trim(),
      if (reviewedAt != null) 'reviewed_at': Timestamp.fromDate(reviewedAt!),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      'status': status.trim().toLowerCase(),
      if (requestedAt != null) 'requested_at': Timestamp.fromDate(requestedAt!),
      if (requestedAt != null) 'requestedAt': Timestamp.fromDate(requestedAt!),
      if (resolvedAt != null) 'resolved_at': Timestamp.fromDate(resolvedAt!),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
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
    String? orgId,
    String? orgName,
    String? assignedBatchId,
    String? assignedBatchName,
    String? reviewedBy,
    DateTime? reviewedAt,
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
      orgId: orgId ?? this.orgId,
      orgName: orgName ?? this.orgName,
      assignedBatchId: assignedBatchId ?? this.assignedBatchId,
      assignedBatchName: assignedBatchName ?? this.assignedBatchName,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
