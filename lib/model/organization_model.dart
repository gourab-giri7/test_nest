import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationType {
  static const String independent = 'independent';
  static const String institute = 'institute';

  static bool isValid(String type) => type == independent || type == institute;
}

class OrganizationRole {
  static const String admin = 'admin';
  static const String teacher = 'teacher';
  static const String student = 'student';

  static bool isValid(String role) =>
      role == admin || role == teacher || role == student;
}

class OrganizationStatus {
  static const String active = 'active';
  static const String suspended = 'suspended';
}

/// Represents an Organization / Workspace doc in `organizations/{orgId}`.
class OrganizationModel {
  final String id;
  final String name;
  final String type; // 'independent' or 'institute'
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // 'active' or 'suspended'
  final Map<String, dynamic> metadata;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
    this.updatedAt,
    this.status = OrganizationStatus.active,
    this.metadata = const {},
  });

  bool get isInstitute => type == OrganizationType.institute;
  bool get isIndependent => type == OrganizationType.independent;
  bool get isActive => status == OrganizationStatus.active;

  factory OrganizationModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return OrganizationModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      type: (map['type'] ?? OrganizationType.independent).toString(),
      ownerId: (map['ownerId'] ?? '').toString(),
      ownerName: (map['ownerName'] ?? '').toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
      status: (map['status'] ?? OrganizationStatus.active).toString(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      'status': status,
      'metadata': metadata,
    };
  }

  OrganizationModel copyWith({
    String? id,
    String? name,
    String? type,
    String? ownerId,
    String? ownerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return OrganizationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Represents a member in `organizations/{orgId}/members/{uid}`.
/// Primary authorization doc used by Firestore rules and client checks.
class OrganizationMemberModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin', 'teacher', 'student'
  final String status; // 'active', 'suspended'
  final DateTime joinedAt;
  final List<String> assignedBatchIds;
  final String? inviteCode;
  final String? teacherId; // e.g. 'TN-TEA-0001'
  final String? subject;
  final String? phone;
  final String? gender;
  final String? qualification;
  final String? experience;
  final double? monthlySalary;

  const OrganizationMemberModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.status = OrganizationStatus.active,
    required this.joinedAt,
    this.assignedBatchIds = const [],
    this.inviteCode,
    this.teacherId,
    this.subject,
    this.phone,
    this.gender,
    this.qualification,
    this.experience,
    this.monthlySalary,
  });

  bool get isAdmin => role == OrganizationRole.admin;
  bool get isTeacher => role == OrganizationRole.teacher;
  bool get isStudent => role == OrganizationRole.student;
  bool get isActive => status == OrganizationStatus.active;
  bool get isSuspended => status == OrganizationStatus.suspended;
  List<String> get batchIds => assignedBatchIds;

  factory OrganizationMemberModel.fromMap(
    Map<String, dynamic> map,
    String uid,
  ) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawBatches = map['assignedBatchIds'] ?? map['batchIds'] ?? map['batch_ids'];
    List<String> batches = [];
    if (rawBatches is List) {
      batches = rawBatches.map((e) => e.toString()).toList();
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return OrganizationMemberModel(
      uid: uid,
      email: (map['email'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      role: (map['role'] ?? OrganizationRole.teacher).toString(),
      status: (map['status'] ?? OrganizationStatus.active).toString(),
      joinedAt: parseDate(map['joinedAt']),
      assignedBatchIds: batches,
      inviteCode: map['inviteCode']?.toString(),
      teacherId: map['teacherId']?.toString() ?? map['teacher_id']?.toString(),
      subject: map['subject']?.toString(),
      phone: map['phone']?.toString() ?? map['mobile']?.toString(),
      gender: map['gender']?.toString(),
      qualification: map['qualification']?.toString(),
      experience: map['experience']?.toString(),
      monthlySalary: parseDouble(map['monthlySalary'] ?? map['monthly_salary']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email.toLowerCase().trim(),
      'name': name,
      'role': role,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'assignedBatchIds': assignedBatchIds,
      if (inviteCode != null) 'inviteCode': inviteCode,
      if (teacherId != null) 'teacherId': teacherId,
      if (teacherId != null) 'teacher_id': teacherId,
      if (subject != null) 'subject': subject,
      if (phone != null) 'phone': phone,
      if (gender != null) 'gender': gender,
      if (qualification != null) 'qualification': qualification,
      if (experience != null) 'experience': experience,
      if (monthlySalary != null) 'monthlySalary': monthlySalary,
      if (monthlySalary != null) 'monthly_salary': monthlySalary,
    };
  }
}

/// Represents an indexing membership document in `users/{uid}/memberships/{orgId}`.
/// Allows fast client lookup of all organizations a user belongs to without
/// requiring costly or permission-sensitive collection group queries.
class UserMembershipModel {
  final String organizationId;
  final String organizationName;
  final String organizationType;
  final String role;
  final String status;
  final DateTime joinedAt;

  const UserMembershipModel({
    required this.organizationId,
    required this.organizationName,
    required this.organizationType,
    required this.role,
    this.status = OrganizationStatus.active,
    required this.joinedAt,
  });

  bool get isInstitute => organizationType == OrganizationType.institute;
  bool get isIndependent => organizationType == OrganizationType.independent;
  bool get isAdmin => role == OrganizationRole.admin;
  bool get isTeacher => role == OrganizationRole.teacher;
  bool get isStudent => role == OrganizationRole.student;
  bool get isActive => status == OrganizationStatus.active;

  factory UserMembershipModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserMembershipModel(
      organizationId: docId.isNotEmpty
          ? docId
          : (map['organizationId'] ?? '').toString(),
      organizationName: (map['organizationName'] ?? '').toString(),
      organizationType:
          (map['organizationType'] ?? OrganizationType.independent).toString(),
      role: (map['role'] ?? OrganizationRole.teacher).toString(),
      status: (map['status'] ?? OrganizationStatus.active).toString(),
      joinedAt: parseDate(map['joinedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'organizationName': organizationName,
      'organizationType': organizationType,
      'role': role,
      'status': status,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
