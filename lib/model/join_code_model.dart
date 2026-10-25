class JoinCodeModel {
  final String code;
  final String teacherId;
  final String teacherName;
  final String batchId;
  final String batchName;
  final bool isActive;
  final DateTime? createdAt;

  JoinCodeModel({
    required this.code,
    required this.teacherId,
    required this.teacherName,
    required this.batchId,
    required this.batchName,
    this.isActive = true,
    this.createdAt,
  });

  factory JoinCodeModel.fromJson(Map<String, dynamic> json, {String? codeId}) {
    return JoinCodeModel(
      code: (codeId ?? json['code'] ?? '').toString().trim().toUpperCase(),
      teacherId: (json['teacher_id'] ?? '').toString().trim(),
      teacherName: (json['teacher_name'] ?? '').toString().trim(),
      batchId: (json['batch_id'] ?? '').toString().trim(),
      batchName: (json['batch_name'] ?? '').toString().trim(),
      isActive: json['is_active'] != false,
      createdAt: json['created_at'] != null
          ? (json['created_at'] is DateTime
                ? json['created_at'] as DateTime
                : DateTime.tryParse(json['created_at'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code.trim().toUpperCase(),
      'teacher_id': teacherId.trim(),
      'teacher_name': teacherName.trim(),
      'batch_id': batchId.trim(),
      'batch_name': batchName.trim(),
      'is_active': isActive,
    };
  }
}
