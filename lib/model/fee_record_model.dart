import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// FeeRecord — monthly fee record for a student.
// Document path: user/{teacherId}/students/{studentId}/feeRecords/{YYYY-MM}
// =============================================================================
class FeeRecord {
  /// Billing month key, always in 'YYYY-MM' format (e.g. '2025-10').
  final String billingMonth;

  final String studentId;
  final String studentName;

  /// Amount that is due for this billing month.
  final double amountDue;

  /// Total amount paid so far in this billing month.
  final double amountPaid;

  /// Due date for this billing period.
  final DateTime? dueDate;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FeeRecord({
    required this.billingMonth,
    required this.studentId,
    required this.studentName,
    required this.amountDue,
    required this.amountPaid,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Derive payment status from amounts and due date.
  String get status => computeStatus(amountDue, amountPaid, dueDate);

  /// Outstanding balance.
  double get balance => (amountDue - amountPaid).clamp(0, double.infinity);

  static String computeStatus(double due, double paid, DateTime? dueDate) {
    if (due <= 0) return 'paid'; // No fee set — treat as paid
    if (paid >= due) return 'paid';
    if (paid > 0) return 'partial';
    if (dueDate != null && DateTime.now().isAfter(dueDate)) return 'overdue';
    return 'unpaid';
  }

  factory FeeRecord.fromJson(Map<String, dynamic> json, {String? docId}) {
    return FeeRecord(
      billingMonth: (json['billing_month'] ?? docId ?? '').toString(),
      studentId: (json['student_id'] ?? '').toString(),
      studentName: (json['student_name'] ?? '').toString(),
      amountDue: _toDouble(json['amount_due']),
      amountPaid: _toDouble(json['amount_paid']),
      dueDate: _toDateTime(json['due_date']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'billing_month': billingMonth,
    'student_id': studentId,
    'student_name': studentName,
    'amount_due': amountDue,
    'amount_paid': amountPaid,
    if (dueDate != null) 'due_date': Timestamp.fromDate(dueDate!),
    'updated_at': FieldValue.serverTimestamp(),
  };

  FeeRecord copyWith({
    double? amountDue,
    double? amountPaid,
    DateTime? dueDate,
  }) {
    return FeeRecord(
      billingMonth: billingMonth,
      studentId: studentId,
      studentName: studentName,
      amountDue: amountDue ?? this.amountDue,
      amountPaid: amountPaid ?? this.amountPaid,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static double toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static double _toDouble(dynamic v) => toDouble(v);

  static DateTime? _toDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
