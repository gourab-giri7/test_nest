import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// PaymentEntry — a single payment recorded against a fee record.
// Document path: .../feeRecords/{YYYY-MM}/payments/{paymentId}
//
// Payment history is append-only: never delete a PaymentEntry to "undo" a
// payment. Instead, record a correcting negative-amount entry (reversal) or
// adjustment and update the parent FeeRecord's amountPaid accordingly.
// =============================================================================
class PaymentEntry {
  final String paymentId;
  final double amount;
  final DateTime paidAt;

  /// Payment method: 'cash', 'upi', 'bank_transfer', 'cheque', 'other'
  final String method;

  final String? note;

  /// Name of the teacher who recorded this payment.
  final String recordedBy;

  final String? receiptRef;

  /// A negative amount signals a correcting reversal/adjustment.
  bool get isReversal => amount < 0;

  const PaymentEntry({
    required this.paymentId,
    required this.amount,
    required this.paidAt,
    required this.method,
    required this.recordedBy,
    this.note,
    this.receiptRef,
  });

  factory PaymentEntry.fromJson(Map<String, dynamic> json, {String? docId}) {
    return PaymentEntry(
      paymentId: (json['payment_id'] ?? docId ?? '').toString(),
      amount: _toDouble(json['amount']),
      paidAt: _toDateTime(json['paid_at']) ?? DateTime.now(),
      method: (json['method'] ?? 'cash').toString(),
      recordedBy: (json['recorded_by'] ?? '').toString(),
      note: json['note']?.toString(),
      receiptRef: json['receipt_ref']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_id': paymentId,
    'amount': amount,
    'paid_at': Timestamp.fromDate(paidAt),
    'method': method,
    'recorded_by': recordedBy,
    if (note != null && note!.isNotEmpty) 'note': note,
    if (receiptRef != null && receiptRef!.isNotEmpty) 'receipt_ref': receiptRef,
    'created_at': FieldValue.serverTimestamp(),
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
    switch (method) {
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
