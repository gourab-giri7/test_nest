import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/payment_model.dart';

// =============================================================================
// FeeService — trusted client-side service for fee management.
//
// Firestore paths:
//   user/{teacherId}/students/{studentId}/feeRecords/{YYYY-MM}
//   user/{teacherId}/students/{studentId}/feeRecords/{YYYY-MM}/payments/{id}
//
// BILLING MONTH KEY: always 'YYYY-MM' (e.g. '2025-10').
// =============================================================================
class FeeService {
  static final _db = FirebaseFirestore.instance;

  /// Formats a DateTime as 'YYYY-MM'.
  static String monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Current billing month key.
  static String get currentMonthKey => monthKey(DateTime.now());

  // ---------------------------------------------------------------------------
  // Collection references
  // ---------------------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> _feeRecordsRef(
    String teacherId,
    String studentId,
  ) =>
      _db
          .collection('user')
          .doc(teacherId)
          .collection('students')
          .doc(studentId)
          .collection('feeRecords');

  static CollectionReference<Map<String, dynamic>> _paymentsRef(
    String teacherId,
    String studentId,
    String billingMonth,
  ) =>
      _feeRecordsRef(teacherId, studentId).doc(billingMonth).collection(
        'payments',
      );

  // ---------------------------------------------------------------------------
  // Fee record operations
  // ---------------------------------------------------------------------------

  /// Idempotently ensure a fee record exists for [studentId] in [billingMonth].
  /// Does NOT overwrite an existing record's amountPaid or payments.
  /// If the record already exists, only updates amountDue if it changed.
  static Future<void> ensureFeeRecord({
    required String teacherId,
    required String studentId,
    required String studentName,
    required String billingMonth,
    required double amountDue,
    DateTime? dueDate,
  }) async {
    final ref = _feeRecordsRef(teacherId, studentId).doc(billingMonth);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'billing_month': billingMonth,
        'student_id': studentId,
        'student_name': studentName,
        'amount_due': amountDue,
        'amount_paid': 0.0,
        if (dueDate != null) 'due_date': Timestamp.fromDate(dueDate),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      // Update amount due only if it changed
      final existingDue = FeeRecord._toDouble(snap.data()?['amount_due']);
      if (existingDue != amountDue) {
        await ref.update({
          'amount_due': amountDue,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// Record a payment for a student in a billing month.
  /// Updates amountPaid on the fee record atomically.
  static Future<PaymentEntry> recordPayment({
    required String teacherId,
    required String studentId,
    required String studentName,
    required String billingMonth,
    required double amount,
    required DateTime paidAt,
    required String method,
    required String recordedBy,
    String? note,
    String? receiptRef,
    double? amountDue, // required to create the record if missing
  }) async {
    final feeRef = _feeRecordsRef(teacherId, studentId).doc(billingMonth);
    final paymentRef = _paymentsRef(teacherId, studentId, billingMonth).doc();
    final paymentId = paymentRef.id;

    final entry = PaymentEntry(
      paymentId: paymentId,
      amount: amount,
      paidAt: paidAt,
      method: method,
      recordedBy: recordedBy,
      note: note,
      receiptRef: receiptRef,
    );

    await _db.runTransaction((tx) async {
      final feeSnap = await tx.get(feeRef);
      final existingPaid = FeeRecord._toDouble(feeSnap.data()?['amount_paid']);
      final newPaid = existingPaid + amount;

      if (!feeSnap.exists) {
        // Create fee record if it doesn't exist
        tx.set(feeRef, {
          'billing_month': billingMonth,
          'student_id': studentId,
          'student_name': studentName,
          'amount_due': amountDue ?? 0.0,
          'amount_paid': newPaid,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(feeRef, {
          'amount_paid': newPaid,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      tx.set(paymentRef, entry.toJson());
    });

    return entry;
  }

  /// Get all payment entries for a student in a billing month, sorted by paidAt desc.
  static Future<List<PaymentEntry>> getPayments({
    required String teacherId,
    required String studentId,
    required String billingMonth,
  }) async {
    try {
      final snap =
          await _paymentsRef(teacherId, studentId, billingMonth).get();
      final entries =
          snap.docs
              .map((d) => PaymentEntry.fromJson(d.data(), docId: d.id))
              .toList();
      entries.sort((a, b) => b.paidAt.compareTo(a.paidAt));
      return entries;
    } catch (e) {
      log('FeeService.getPayments error: $e');
      return [];
    }
  }

  /// Get the fee record for a student in a billing month. Returns null if none.
  static Future<FeeRecord?> getFeeRecord({
    required String teacherId,
    required String studentId,
    required String billingMonth,
  }) async {
    try {
      final snap =
          await _feeRecordsRef(teacherId, studentId).doc(billingMonth).get();
      if (!snap.exists || snap.data() == null) return null;
      return FeeRecord.fromJson(snap.data()!, docId: snap.id);
    } catch (e) {
      log('FeeService.getFeeRecord error: $e');
      return null;
    }
  }

  /// Get all fee records for a student across all billing months.
  static Future<List<FeeRecord>> getStudentFeeHistory({
    required String teacherId,
    required String studentId,
  }) async {
    try {
      final snap =
          await _feeRecordsRef(teacherId, studentId)
              .orderBy('billing_month', descending: true)
              .get();
      return snap.docs
          .map((d) => FeeRecord.fromJson(d.data(), docId: d.id))
          .toList();
    } catch (e) {
      log('FeeService.getStudentFeeHistory error: $e');
      return [];
    }
  }

  /// Get fee records for ALL students of a teacher for a specific billing month.
  /// This does N Firestore reads (one per student). For large rosters, consider
  /// a denormalized collection-group query instead.
  static Future<Map<String, FeeRecord>> getFeeRecordsForMonth({
    required String teacherId,
    required List<String> studentIds,
    required String billingMonth,
  }) async {
    final result = <String, FeeRecord>{};
    // Batch into groups of 10 for parallel reads
    final batches = <List<String>>[];
    for (var i = 0; i < studentIds.length; i += 10) {
      batches.add(
        studentIds.sublist(
          i,
          i + 10 > studentIds.length ? studentIds.length : i + 10,
        ),
      );
    }

    for (final batch in batches) {
      await Future.wait(
        batch.map((studentId) async {
          final record = await getFeeRecord(
            teacherId: teacherId,
            studentId: studentId,
            billingMonth: billingMonth,
          );
          if (record != null) {
            result[studentId] = record;
          }
        }),
      );
    }
    return result;
  }

  /// Update the amountDue for a specific fee record.
  /// Useful when a teacher wants to override the default monthly fee.
  static Future<void> updateAmountDue({
    required String teacherId,
    required String studentId,
    required String billingMonth,
    required double amountDue,
  }) async {
    final ref = _feeRecordsRef(teacherId, studentId).doc(billingMonth);
    await ref.set(
      {'amount_due': amountDue, 'updated_at': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // Utility: billing month navigation
  // ---------------------------------------------------------------------------

  /// Returns a list of billing month keys for the past N months including current.
  static List<String> recentMonths({int count = 12}) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return monthKey(d);
    });
  }

  /// Returns the next billing month from a given month key.
  static String nextMonth(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    var year = int.tryParse(parts[0]) ?? DateTime.now().year;
    var month = int.tryParse(parts[1]) ?? DateTime.now().month;
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
    return '${year}-${month.toString().padLeft(2, '0')}';
  }

  /// Returns the previous billing month from a given month key.
  static String prevMonth(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    var year = int.tryParse(parts[0]) ?? DateTime.now().year;
    var month = int.tryParse(parts[1]) ?? DateTime.now().month;
    month--;
    if (month < 1) {
      month = 12;
      year--;
    }
    return '${year}-${month.toString().padLeft(2, '0')}';
  }

  /// Human-readable label for a billing month key ('YYYY-MM' → 'October 2025').
  static String monthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return key;
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[month]} $year';
  }
}
