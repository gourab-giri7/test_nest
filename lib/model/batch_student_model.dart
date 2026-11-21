import 'package:cloud_firestore/cloud_firestore.dart';

/// Canonical student enrollment document under:
/// `organizations/{orgId}/batches/{batchId}/students/{studentUid}`
class BatchStudentModel {
  final String studentUid;
  final String? docId;
  final String orgId;
  final String batchId;
  final String batchName;
  final String studentName;
  final String studentEmail;
  final String? studentPhone;
  final String status; // 'active', 'transferred', 'removed'
  final DateTime enrolledAt;
  final DateTime? updatedAt;

  const BatchStudentModel({
    required this.studentUid,
    this.docId,
    required this.orgId,
    required this.batchId,
    required this.batchName,
    required this.studentName,
    required this.studentEmail,
    this.studentPhone,
    this.status = 'active',
    required this.enrolledAt,
    this.updatedAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isRemoved =>
      status.toLowerCase() == 'removed' ||
      status.toLowerCase() == 'transferred';

  factory BatchStudentModel.fromJson(
    Map<String, dynamic> map, {
    String? docId,
  }) => BatchStudentModel.fromMap(map, docId ?? '');

  factory BatchStudentModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return BatchStudentModel(
      studentUid:
          (map['studentUid'] ??
                  map['student_uid'] ??
                  (docId.isNotEmpty ? docId : ''))
              .toString()
              .trim(),
      docId: docId.isNotEmpty ? docId : null,
      orgId: (map['orgId'] ?? map['org_id'] ?? '').toString().trim(),
      batchId: (map['batchId'] ?? map['batch_id'] ?? '').toString().trim(),
      batchName: (map['batchName'] ?? map['batch_name'] ?? '')
          .toString()
          .trim(),
      studentName: (map['studentName'] ?? map['student_name'] ?? '')
          .toString()
          .trim(),
      studentEmail: (map['studentEmail'] ?? map['student_email'] ?? '')
          .toString()
          .trim(),
      studentPhone:
          map['studentPhone']?.toString().trim() ??
          map['student_phone']?.toString().trim(),
      status: (map['status'] ?? 'active').toString().trim().toLowerCase(),
      enrolledAt: parseDate(map['enrolledAt'] ?? map['enrolled_at']),
      updatedAt: (map['updatedAt'] != null || map['updated_at'] != null)
          ? parseDate(map['updatedAt'] ?? map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'student_uid': studentUid,
      'orgId': orgId,
      'org_id': orgId,
      'batchId': batchId,
      'batch_id': batchId,
      'batchName': batchName,
      'batch_name': batchName,
      'studentName': studentName,
      'student_name': studentName,
      'studentEmail': studentEmail.toLowerCase().trim(),
      'student_email': studentEmail.toLowerCase().trim(),
      if (studentPhone != null) 'studentPhone': studentPhone,
      if (studentPhone != null) 'student_phone': studentPhone,
      'status': status,
      'enrolledAt': Timestamp.fromDate(enrolledAt),
      'enrolled_at': Timestamp.fromDate(enrolledAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
