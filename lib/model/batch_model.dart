class BatchModel {
  final String id;
  final String name;
  final String? classLevel;
  final String? academicYear;
  final String? subject;
  final String? description;
  final double monthlyFee;
  final bool feeTrackingEnabled;
  final String activeJoinCode;
  final bool isArchived;
  final int studentCount;
  final int pendingRequestCount;
  final DateTime? createdAt;
  final String teacherId;

  BatchModel({
    required this.id,
    required this.name,
    this.classLevel,
    this.academicYear,
    this.subject,
    this.description,
    this.monthlyFee = 0.0,
    this.feeTrackingEnabled = true,
    required this.activeJoinCode,
    this.isArchived = false,
    this.studentCount = 0,
    this.pendingRequestCount = 0,
    this.createdAt,
    required this.teacherId,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return BatchModel(
      id: docId ?? (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString().trim(),
      classLevel: json['class_level']?.toString(),
      academicYear: json['academic_year']?.toString(),
      subject: json['subject']?.toString(),
      description: json['description']?.toString(),
      monthlyFee: _toDouble(json['monthly_fee']),
      feeTrackingEnabled: json['fee_tracking_enabled'] != false,
      activeJoinCode: (json['active_join_code'] ?? '').toString().trim(),
      isArchived: json['is_archived'] == true,
      studentCount: (json['student_count'] is num)
          ? (json['student_count'] as num).toInt()
          : int.tryParse(json['student_count']?.toString() ?? '0') ?? 0,
      pendingRequestCount: (json['pending_request_count'] is num)
          ? (json['pending_request_count'] as num).toInt()
          : int.tryParse(json['pending_request_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? (json['created_at'] is DateTime
                ? json['created_at'] as DateTime
                : DateTime.tryParse(json['created_at'].toString()))
          : null,
      teacherId: (json['teacher_id'] ?? '').toString().trim(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.trim(),
      'class_level': classLevel?.trim(),
      'academic_year': academicYear?.trim(),
      'subject': subject?.trim(),
      'description': description?.trim(),
      'monthly_fee': monthlyFee,
      'fee_tracking_enabled': feeTrackingEnabled,
      'active_join_code': activeJoinCode.trim(),
      'is_archived': isArchived,
      'student_count': studentCount,
      'pending_request_count': pendingRequestCount,
      'teacher_id': teacherId.trim(),
    };
  }

  BatchModel copyWith({
    String? id,
    String? name,
    String? classLevel,
    String? academicYear,
    String? subject,
    String? description,
    double? monthlyFee,
    bool? feeTrackingEnabled,
    String? activeJoinCode,
    bool? isArchived,
    int? studentCount,
    int? pendingRequestCount,
    DateTime? createdAt,
    String? teacherId,
  }) {
    return BatchModel(
      id: id ?? this.id,
      name: name ?? this.name,
      classLevel: classLevel ?? this.classLevel,
      academicYear: academicYear ?? this.academicYear,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      feeTrackingEnabled: feeTrackingEnabled ?? this.feeTrackingEnabled,
      activeJoinCode: activeJoinCode ?? this.activeJoinCode,
      isArchived: isArchived ?? this.isArchived,
      studentCount: studentCount ?? this.studentCount,
      pendingRequestCount: pendingRequestCount ?? this.pendingRequestCount,
      createdAt: createdAt ?? this.createdAt,
      teacherId: teacherId ?? this.teacherId,
    );
  }
}
