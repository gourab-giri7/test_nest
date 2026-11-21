import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String revoked = 'revoked';
  static const String expired = 'expired';
}

/// Represents an invitation stored in:
/// 1. `invitations/{code}` (global lookup for redeeming)
/// 2. `organizations/{orgId}/invitations/{code}` (org scoped history for admins)
class TeacherInvitationModel {
  final String code;
  final String orgId;
  final String orgName;
  final String teacherEmail;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final String? usedBy;
  final DateTime? usedAt;
  final String status;

  const TeacherInvitationModel({
    required this.code,
    required this.orgId,
    required this.orgName,
    required this.teacherEmail,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
    this.usedBy,
    this.usedAt,
    this.status = InvitationStatus.pending,
  });

  bool get isExpired =>
      status == InvitationStatus.expired ||
      (!isUsed && DateTime.now().isAfter(expiresAt));

  bool get isPending =>
      !isUsed && status == InvitationStatus.pending && !isExpired;

  bool get isAccepted => isUsed || status == InvitationStatus.accepted;
  bool get isRevoked => status == InvitationStatus.revoked;

  factory TeacherInvitationModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final expiresAt = parseDate(map['expiresAt']);
    final isUsed = map['isUsed'] == true;
    String rawStatus = (map['status'] ?? InvitationStatus.pending).toString();

    // Dynamically mark expired if time passed and not accepted
    if (!isUsed &&
        rawStatus == InvitationStatus.pending &&
        DateTime.now().isAfter(expiresAt)) {
      rawStatus = InvitationStatus.expired;
    }

    return TeacherInvitationModel(
      code: docId.isNotEmpty ? docId : (map['code'] ?? '').toString(),
      orgId: (map['orgId'] ?? '').toString(),
      orgName: (map['orgName'] ?? '').toString(),
      teacherEmail: (map['teacherEmail'] ?? '').toString().toLowerCase().trim(),
      createdBy: (map['createdBy'] ?? '').toString(),
      createdAt: parseDate(map['createdAt']),
      expiresAt: expiresAt,
      isUsed: isUsed,
      usedBy: map['usedBy']?.toString(),
      usedAt: map['usedAt'] != null ? parseDate(map['usedAt']) : null,
      status: rawStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'orgId': orgId,
      'orgName': orgName,
      'teacherEmail': teacherEmail.toLowerCase().trim(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isUsed': isUsed,
      'usedBy': usedBy,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'status': status,
    };
  }

  TeacherInvitationModel copyWith({
    String? code,
    String? orgId,
    String? orgName,
    String? teacherEmail,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isUsed,
    String? usedBy,
    DateTime? usedAt,
    String? status,
  }) {
    return TeacherInvitationModel(
      code: code ?? this.code,
      orgId: orgId ?? this.orgId,
      orgName: orgName ?? this.orgName,
      teacherEmail: teacherEmail ?? this.teacherEmail,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
      usedBy: usedBy ?? this.usedBy,
      usedAt: usedAt ?? this.usedAt,
      status: status ?? this.status,
    );
  }
}
