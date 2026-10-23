class StudentModel {
  final String name;
  final String batch;
  final String id;
  // NOTE: password is kept for backward compatibility with existing student
  // records. New students should not store passwords in Firestore.
  // This field is not displayed in the UI and will be phased out.
  final String password;
  final String? docId;

  /// Standard monthly fee for this student (0 means not set / use teacher default).
  final double monthlyFee;

  StudentModel({
    required this.name,
    required this.batch,
    required this.id,
    required this.password,
    this.docId,
    this.monthlyFee = 0.0,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final String resolvedId =
        (json['id'] != null && json['id'].toString().trim().isNotEmpty)
        ? json['id'].toString().trim()
        : (json['student_id'] != null &&
              json['student_id'].toString().trim().isNotEmpty)
        ? json['student_id'].toString().trim()
        : (docId != null && docId.trim().isNotEmpty)
        ? docId.trim()
        : '';

    return StudentModel(
      name: (json['name'] ?? '').toString().trim(),
      batch: (json['batch'] ?? '').toString().trim(),
      id: resolvedId,
      password: (json['password'] ?? '').toString(),
      docId: docId ?? (json['doc_id']?.toString() ?? resolvedId),
      monthlyFee: _toDouble(json['monthly_fee']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  StudentModel copyWith({
    String? name,
    String? batch,
    String? id,
    String? password,
    String? docId,
    double? monthlyFee,
  }) {
    return StudentModel(
      name: name ?? this.name,
      batch: batch ?? this.batch,
      id: id ?? this.id,
      password: password ?? this.password,
      docId: docId ?? this.docId,
      monthlyFee: monthlyFee ?? this.monthlyFee,
    );
  }

  static String normalizeBatch(String batch) {
    return batch
        .replaceAll('\uFEFF', '')
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  static bool isSameBatch(String a, String b) {
    return normalizeBatch(a) == normalizeBatch(b);
  }

  static Map<String, dynamic> tojson(StudentModel data) {
    return {
      'name': data.name.trim(),
      'batch': data.batch.trim(),
      'id': data.id.trim(),
      'password': data.password,
      'monthly_fee': data.monthlyFee,
    };
  }
}
