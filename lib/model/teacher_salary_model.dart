import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an append-only salary payment entry under a teacher's monthly salary record.
class SalaryPaymentEntry {
  final String paymentId;
  final String salaryRecordId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? referenceNumber;
  final String? note;
  final String recordedBy;
  final DateTime? createdAt;

  const SalaryPaymentEntry({
    required this.paymentId,
    this.salaryRecordId = '',
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.referenceNumber,
    this.note,
    required this.recordedBy,
    this.createdAt,
  });

  factory SalaryPaymentEntry.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return SalaryPaymentEntry(
      paymentId: (json['payment_id'] ?? json['paymentId'] ?? docId ?? '')
          .toString(),
      salaryRecordId: (json['salary_record_id'] ?? json['salaryRecordId'] ?? '')
          .toString(),
      amount: parseDouble(json['amount']),
      paymentDate:
          parseDate(
            json['payment_date'] ?? json['paymentDate'] ?? json['paid_at'],
          ) ??
          DateTime.now(),
      paymentMethod:
          (json['payment_method'] ??
                  json['paymentMethod'] ??
                  json['payment_mode'] ??
                  'bank_transfer')
              .toString(),
      referenceNumber:
          json['reference_number']?.toString() ??
          json['referenceNumber']?.toString(),
      note: json['note']?.toString() ?? json['notes']?.toString(),
      recordedBy: (json['recorded_by'] ?? json['recordedBy'] ?? 'Administrator')
          .toString(),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_id': paymentId,
      'salary_record_id': salaryRecordId,
      'amount': amount,
      'payment_date': Timestamp.fromDate(paymentDate),
      'payment_method': paymentMethod,
      if (referenceNumber != null && referenceNumber!.isNotEmpty)
        'reference_number': referenceNumber,
      if (note != null && note!.isNotEmpty) 'note': note,
      'recorded_by': recordedBy,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Represents a teacher's monthly salary snapshot and payment status.
class TeacherSalaryModel {
  final String id;
  final String orgId;
  final String teacherUid;
  final String teacherName;
  final double amount; // base monthly salary
  final double amountPaid;
  final double remainingAmount;
  final String month;
  final String status;
  final DateTime? paidAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? paymentMode;
  final String? referenceNumber;
  final String? notes;

  const TeacherSalaryModel({
    required this.id,
    required this.orgId,
    required this.teacherUid,
    required this.teacherName,
    required this.amount,
    this.amountPaid = 0.0,
    double? remainingAmount,
    required this.month,
    String? status,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
    this.paymentMode,
    this.referenceNumber,
    this.notes,
  }) : status =
           status ??
           ((amount <= 0 || (amountPaid >= amount && amount > 0))
               ? 'paid'
               : (amountPaid > 0 ? 'partial' : 'pending')),
       remainingAmount =
           remainingAmount ??
           ((amount - amountPaid) > 0 ? (amount - amountPaid) : 0.0);

  double get baseSalary => amount;
  double get balance => remainingAmount;

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isPartial => status.toLowerCase() == 'partial';
  bool get isPending => status.toLowerCase() == 'pending';

  factory TeacherSalaryModel.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final parsedAmount = parseDouble(json['amount'] ?? json['base_salary']);
    final parsedPaid = parseDouble(json['amount_paid'] ?? json['amountPaid']);
    final parsedRemaining =
        json['remaining_amount'] != null || json['remainingAmount'] != null
        ? parseDouble(json['remaining_amount'] ?? json['remainingAmount'])
        : (parsedAmount - parsedPaid).clamp(0, double.infinity).toDouble();

    // Compute status if not explicitly given
    String derivedStatus = (json['status'] ?? '').toString();
    if (derivedStatus.isEmpty) {
      if (parsedAmount <= 0 || parsedPaid >= parsedAmount) {
        derivedStatus = 'paid';
      } else if (parsedPaid > 0) {
        derivedStatus = 'partial';
      } else {
        derivedStatus = 'pending';
      }
    }

    return TeacherSalaryModel(
      id: docId ?? (json['id'] ?? '').toString(),
      orgId: (json['org_id'] ?? json['orgId'] ?? '').toString(),
      teacherUid: (json['teacher_uid'] ?? json['teacherId'] ?? '').toString(),
      teacherName: (json['teacher_name'] ?? json['teacherName'] ?? '')
          .toString(),
      amount: parsedAmount,
      amountPaid: parsedPaid,
      remainingAmount: parsedRemaining,
      month: (json['month'] ?? json['billing_month'] ?? '').toString(),
      status: derivedStatus,
      paidAt: parseDate(json['paid_at'] ?? json['paidAt']),
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
      paymentMode:
          json['payment_mode']?.toString() ?? json['paymentMode']?.toString(),
      referenceNumber:
          json['reference_number']?.toString() ??
          json['referenceNumber']?.toString(),
      notes: json['notes']?.toString() ?? json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'org_id': orgId,
      'teacher_uid': teacherUid,
      'teacher_name': teacherName,
      'amount': amount,
      'base_salary': amount,
      'amount_paid': amountPaid,
      'remaining_amount': remainingAmount,
      'month': month,
      'billing_month': month,
      'status': status,
      if (paidAt != null) 'paid_at': Timestamp.fromDate(paidAt!),
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (notes != null) 'notes': notes,
    };
  }

  TeacherSalaryModel copyWith({
    String? id,
    String? orgId,
    String? teacherUid,
    String? teacherName,
    double? amount,
    double? amountPaid,
    double? remainingAmount,
    String? month,
    String? status,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentMode,
    String? referenceNumber,
    String? notes,
  }) {
    final effAmount = amount ?? this.amount;
    final effPaid = amountPaid ?? this.amountPaid;
    return TeacherSalaryModel(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      teacherUid: teacherUid ?? this.teacherUid,
      teacherName: teacherName ?? this.teacherName,
      amount: effAmount,
      amountPaid: effPaid,
      remainingAmount:
          remainingAmount ??
          (effAmount - effPaid).clamp(0, double.infinity).toDouble(),
      month: month ?? this.month,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMode: paymentMode ?? this.paymentMode,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
    );
  }
}
