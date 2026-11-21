import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// PaymentEntry — a single payment recorded against a fee record.
// Document path: .../feeRecords/{YYYY-MM}/payments/{paymentId}
// or organizations/{orgId}/feeRecords/{studentUid}/months/{YYYY-MM}/payments/{paymentId}
//
// Payment history is append-only: never delete a PaymentEntry to "undo" a
// payment. Instead, record a correcting negative-amount entry (reversal) or
// adjustment and update the parent FeeRecord's amountPaid accordingly.
// =============================================================================
class PaymentEntry {
  final String paymentId;
  final String? studentUid;
  final String? orgId;
  final String? billingMonth;
  final double amount;
  final DateTime paidAt;

  /// Payment method: 'cash', 'upi', 'bank_transfer', 'cheque', 'other'
  final String method;

  final String? note;

  /// Name of the teacher / owner who recorded this payment.
  final String recordedBy;

  final String? receiptRef;
  final DateTime? createdAt;

  /// Alias for receiptRef
  String? get referenceNumber => receiptRef;

  /// A negative amount signals a correcting reversal/adjustment.
  bool get isReversal => amount < 0;

  const PaymentEntry({
    required this.paymentId,
    this.studentUid,
    this.orgId,
    this.billingMonth,
    required this.amount,
    required this.paidAt,
    required this.method,
    required this.recordedBy,
    this.note,
    this.receiptRef,
    this.createdAt,
  });

  factory PaymentEntry.fromJson(Map<String, dynamic> json, {String? docId}) {
    return PaymentEntry(
      paymentId: (json['payment_id'] ?? json['paymentId'] ?? docId ?? '')
          .toString(),
      studentUid:
          json['student_uid']?.toString() ?? json['studentId']?.toString(),
      orgId: json['org_id']?.toString() ?? json['orgId']?.toString(),
      billingMonth:
          json['billing_month']?.toString() ?? json['billingMonth']?.toString(),
      amount: _toDouble(json['amount']),
      paidAt:
          _toDateTime(
            json['paid_at'] ?? json['payment_date'] ?? json['paidAt'],
          ) ??
          DateTime.now(),
      method: (json['method'] ?? json['payment_method'] ?? 'cash').toString(),
      recordedBy: (json['recorded_by'] ?? json['recordedBy'] ?? '').toString(),
      note: json['note']?.toString(),
      receiptRef:
          json['receipt_ref']?.toString() ??
          json['reference_number']?.toString(),
      createdAt: _toDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_id': paymentId,
    if (studentUid != null && studentUid!.isNotEmpty) 'student_uid': studentUid,
    if (orgId != null && orgId!.isNotEmpty) 'org_id': orgId,
    if (billingMonth != null && billingMonth!.isNotEmpty)
      'billing_month': billingMonth,
    'amount': amount,
    'paid_at': Timestamp.fromDate(paidAt),
    'payment_date': Timestamp.fromDate(paidAt),
    'method': method,
    'payment_method': method,
    'recorded_by': recordedBy,
    if (note != null && note!.isNotEmpty) 'note': note,
    if (receiptRef != null && receiptRef!.isNotEmpty) ...{
      'receipt_ref': receiptRef,
      'reference_number': receiptRef,
    },
    'created_at': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static const List<String> methodOptions = [
    'cash',
    'upi',
    'bank_transfer',
    'cheque',
    'other',
  ];

  static String methodLabel(String method) {
    switch (method.toLowerCase().trim()) {
      case 'cash':
        return 'Cash';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cheque':
        return 'Cheque';
      default:
        return 'Other';
    }
  }
}
