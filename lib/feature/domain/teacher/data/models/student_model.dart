class StudentModel {
  final String name;
  final String batch;
  final String? batchId;
  final String id;
  // NOTE: password is kept for backward compatibility with existing student
  // records. New students should not store passwords in Firestore.
  // This field is not displayed in the UI and will be phased out.
  final String password;
  final String? docId;

  /// Standard monthly fee for this student (0 means not set / use teacher default).
  final double monthlyFee;

  /// Student login email / account ID
  final String email;

  /// Firebase Authentication UID linked to this student
  final String authUid;

  /// Account status (e.g. 'Active', 'Enrolled', 'Pending')
  final String status;

  /// Student contact phone number
  final String phone;

  StudentModel({
    required this.name,
    required this.batch,
    this.batchId,
    required this.id,
    required this.password,
    this.docId,
    this.monthlyFee = 0.0,
    this.email = '',
    this.authUid = '',
    this.status = 'Active',
    this.phone = '',
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

    final rawAuthUid =
        (json['auth_uid'] ?? json['authUid'] ?? json['student_uid'] ?? '')
            .toString()
            .trim();
    final rawEmail = (json['email'] ?? json['student_email'] ?? '')
        .toString()
        .trim();
    final rawStatus =
        (json['status'] ?? (rawAuthUid.isNotEmpty ? 'Active' : 'Enrolled'))
            .toString()
            .trim();
    final rawPhone = (json['phone'] ?? json['mobile'] ?? '').toString().trim();
    final rawBatchId =
        (json['batch_id'] ?? json['batchId'] ?? '').toString().trim();

    return StudentModel(
      name: (json['name'] ?? '').toString().trim(),
      batch: (json['batch'] ?? '').toString().trim(),
      batchId: rawBatchId.isNotEmpty ? rawBatchId : null,
      id: resolvedId,
      password: (json['password'] ?? '').toString(),
      docId: docId ?? (json['doc_id']?.toString() ?? resolvedId),
      monthlyFee: _toDouble(json['monthly_fee']),
      email: rawEmail,
      authUid: rawAuthUid,
      status: rawStatus.isEmpty ? 'Active' : rawStatus,
      phone: rawPhone,
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
    String? batchId,
    String? id,
    String? password,
    String? docId,
    double? monthlyFee,
    String? email,
    String? authUid,
    String? status,
    String? phone,
  }) {
    return StudentModel(
      name: name ?? this.name,
      batch: batch ?? this.batch,
      batchId: batchId ?? this.batchId,
      id: id ?? this.id,
      password: password ?? this.password,
      docId: docId ?? this.docId,
      monthlyFee: monthlyFee ?? this.monthlyFee,
      email: email ?? this.email,
      authUid: authUid ?? this.authUid,
      status: status ?? this.status,
      phone: phone ?? this.phone,
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
      'batch_id': data.batchId ?? '',
      'id': data.id.trim(),
      'password': data.password,
      'monthly_fee': data.monthlyFee,
      'email': data.email.trim(),
      'auth_uid': data.authUid.trim(),
      'status': data.status.trim(),
      'phone': data.phone.trim(),
    };
  }
}
