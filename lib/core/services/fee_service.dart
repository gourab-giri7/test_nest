import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/payment_model.dart';

// =============================================================================
// FeeService — trusted client-side service for fee management.
//
// Dual-Mode Firestore paths:
// 1. Single Teacher Mode (Legacy):
//    user/{teacherId}/students/{studentId}/feeRecords/{YYYY-MM}
//    user/{teacherId}/students/{studentId}/feeRecords/{YYYY-MM}/payments/{id}
//
// 2. Coaching Institute Mode:
//    organizations/{orgId}/feeRecords/{studentId}/months/{YYYY-MM}
//    organizations/{orgId}/feeRecords/{studentId}/months/{YYYY-MM}/payments/{id}
//    organizations/{orgId}/feeRecords/{studentId} (top-level summary for real-time listeners)
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
  // Single Teacher Mode (Legacy) collection references
  // ---------------------------------------------------------------------------
  static CollectionReference<Map<String, dynamic>> _feeRecordsRef(
    String teacherId,
    String studentId,
  ) => _db
      .collection('user')
      .doc(teacherId)
      .collection('students')
      .doc(studentId)
      .collection('feeRecords');

  static CollectionReference<Map<String, dynamic>> _paymentsRef(
    String teacherId,
    String studentId,
    String billingMonth,
  ) => _feeRecordsRef(
    teacherId,
    studentId,
  ).doc(billingMonth).collection('payments');

  // ---------------------------------------------------------------------------
  // Coaching Institute Mode collection references
  // ---------------------------------------------------------------------------
  static DocumentReference<Map<String, dynamic>> _orgFeeMonthRef(
    String orgId,
    String studentId,
    String billingMonth,
  ) => _db
      .collection('organizations')
      .doc(orgId)
      .collection('feeRecords')
      .doc(studentId)
      .collection('months')
      .doc(billingMonth);

  static CollectionReference<Map<String, dynamic>> _orgPaymentsRef(
    String orgId,
    String studentId,
    String billingMonth,
  ) => _orgFeeMonthRef(orgId, studentId, billingMonth).collection('payments');

  static DocumentReference<Map<String, dynamic>> _orgFeeSummaryRef(
    String orgId,
    String studentId,
  ) => _db
      .collection('organizations')
      .doc(orgId)
      .collection('feeRecords')
      .doc(studentId);

  // ---------------------------------------------------------------------------
  // Fee record operations
  // ---------------------------------------------------------------------------

  /// Idempotently ensure a fee record exists for [studentId] in [billingMonth].
  /// Does NOT overwrite an existing record's amountPaid or payments.
  /// If the record already exists, only updates amountDue if it changed.
  static Future<void> ensureFeeRecord({
    String? teacherId,
    String? orgId,
    required String studentId,
    required String studentName,
    required String billingMonth,
    required double amountDue,
    DateTime? dueDate,
    String? batchId,
  }) async {
    final isOrg = orgId != null && orgId.trim().isNotEmpty;

    if (isOrg) {
      final monthRef = _orgFeeMonthRef(orgId, studentId, billingMonth);
      final summaryRef = _orgFeeSummaryRef(orgId, studentId);

      final snap = await monthRef.get();
      if (!snap.exists) {
        final recordData = {
          'billing_month': billingMonth,
          'student_id': studentId,
          'student_name': studentName,
          'org_id': orgId,
          if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
          'amount_due': amountDue,
          'amount_paid': 0.0,
          'balance': amountDue,
          'status': amountDue <= 0 ? 'paid' : 'pending',
          if (dueDate != null) 'due_date': Timestamp.fromDate(dueDate),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };

        await monthRef.set(recordData);
        // Also update summary for student dashboard
        await summaryRef.set(recordData, SetOptions(merge: true));
      } else {
        final existingDue = FeeRecord.toDouble(snap.data()?['amount_due']);
        final existingPaid = FeeRecord.toDouble(snap.data()?['amount_paid']);
        if (existingDue != amountDue) {
          final newBalance = (amountDue - existingPaid).clamp(
            0,
            double.infinity,
          );
          final newStatus = FeeRecord.computeStatus(
            amountDue,
            existingPaid,
            dueDate,
          );
          final updates = {
            'amount_due': amountDue,
            'balance': newBalance,
            'status': newStatus,
            'updated_at': FieldValue.serverTimestamp(),
          };
          await monthRef.update(updates);
          await summaryRef.set(updates, SetOptions(merge: true));
        }
      }
    } else {
      final tId = teacherId ?? '';
      if (tId.isEmpty) return;
      final ref = _feeRecordsRef(tId, studentId).doc(billingMonth);
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
        final existingDue = FeeRecord.toDouble(snap.data()?['amount_due']);
        if (existingDue != amountDue) {
          await ref.update({
            'amount_due': amountDue,
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  /// Record a payment for a student in a billing month.
  /// Updates amountPaid on the fee record atomically using a transaction.
  /// Guarantees idempotency and append-only ledger entries.
  static Future<PaymentEntry> recordPayment({
    String? teacherId,
    String? orgId,
    required String studentId,
    required String studentName,
    required String billingMonth,
    required double amount,
    required DateTime paidAt,
    required String method,
    required String recordedBy,
    String? note,
    String? receiptRef,
    double? amountDue,
    String? paymentId,
  }) async {
    final isOrg = orgId != null && orgId.trim().isNotEmpty;

    if (isOrg) {
      final monthRef = _orgFeeMonthRef(orgId, studentId, billingMonth);
      final summaryRef = _orgFeeSummaryRef(orgId, studentId);
      final paymentsCol = _orgPaymentsRef(orgId, studentId, billingMonth);
      final effectivePaymentId = paymentId ?? paymentsCol.doc().id;
      final paymentRef = paymentsCol.doc(effectivePaymentId);

      final entry = PaymentEntry(
        paymentId: effectivePaymentId,
        studentUid: studentId,
        orgId: orgId,
        billingMonth: billingMonth,
        amount: amount,
        paidAt: paidAt,
        method: method,
        recordedBy: recordedBy,
        note: note,
        receiptRef: receiptRef,
        createdAt: DateTime.now(),
      );

      await _db.runTransaction((tx) async {
        // Idempotency check: verify payment entry doesn't already exist
        final existingPayment = await tx.get(paymentRef);
        if (existingPayment.exists) {
          throw StateError(
            'Duplicate payment ID: $effectivePaymentId already processed.',
          );
        }

        final feeSnap = await tx.get(monthRef);
        final existingPaid = feeSnap.exists
            ? FeeRecord.toDouble(feeSnap.data()?['amount_paid'])
            : 0.0;
        final existingDue = feeSnap.exists
            ? FeeRecord.toDouble(feeSnap.data()?['amount_due'])
            : (amountDue ?? amount);
        final newPaid = existingPaid + amount;
        final newBalance = (existingDue - newPaid).clamp(0, double.infinity);
        final status = FeeRecord.computeStatus(existingDue, newPaid, null);

        final monthData = {
          'billing_month': billingMonth,
          'student_id': studentId,
          'student_name': studentName,
          'org_id': orgId,
          'amount_due': existingDue,
          'amount_paid': newPaid,
          'balance': newBalance,
          'status': status,
          'updated_at': FieldValue.serverTimestamp(),
          if (!feeSnap.exists) 'created_at': FieldValue.serverTimestamp(),
        };

        tx.set(monthRef, monthData, SetOptions(merge: true));
        tx.set(summaryRef, monthData, SetOptions(merge: true));
        tx.set(paymentRef, entry.toJson());
      });

      return entry;
    } else {
      final tId = teacherId ?? '';
      final feeRef = _feeRecordsRef(tId, studentId).doc(billingMonth);
      final paymentsCol = _paymentsRef(tId, studentId, billingMonth);
      final effectivePaymentId = paymentId ?? paymentsCol.doc().id;
      final paymentRef = paymentsCol.doc(effectivePaymentId);

      final entry = PaymentEntry(
        paymentId: effectivePaymentId,
        studentUid: studentId,
        billingMonth: billingMonth,
        amount: amount,
        paidAt: paidAt,
        method: method,
        recordedBy: recordedBy,
        note: note,
        receiptRef: receiptRef,
        createdAt: DateTime.now(),
      );

      await _db.runTransaction((tx) async {
        final existingPayment = await tx.get(paymentRef);
        if (existingPayment.exists) {
          throw StateError(
            'Duplicate payment ID: $effectivePaymentId already processed.',
          );
        }

        final feeSnap = await tx.get(feeRef);
        final existingPaid = FeeRecord.toDouble(feeSnap.data()?['amount_paid']);
        final newPaid = existingPaid + amount;

        if (!feeSnap.exists) {
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
  }

  /// Get all payment entries for a student in a billing month, sorted by paidAt desc.
  static Future<List<PaymentEntry>> getPayments({
    String? teacherId,
    String? orgId,
    required String studentId,
    required String billingMonth,
  }) async {
    try {
      final isOrg = orgId != null && orgId.trim().isNotEmpty;
      final snap = isOrg
          ? await _orgPaymentsRef(orgId, studentId, billingMonth).get()
          : await _paymentsRef(teacherId ?? '', studentId, billingMonth).get();

      final entries = snap.docs
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
    String? teacherId,
    String? orgId,
    required String studentId,
    required String billingMonth,
  }) async {
    try {
      final isOrg = orgId != null && orgId.trim().isNotEmpty;
      if (isOrg) {
        final snap = await _orgFeeMonthRef(
          orgId,
          studentId,
          billingMonth,
        ).get();
        if (snap.exists && snap.data() != null) {
          return FeeRecord.fromJson(snap.data()!, docId: snap.id);
        }
        // Fallback to top-level summary if matching billingMonth
        final sumSnap = await _orgFeeSummaryRef(orgId, studentId).get();
        if (sumSnap.exists && sumSnap.data() != null) {
          final data = sumSnap.data()!;
          if (data['billing_month'] == billingMonth) {
            return FeeRecord.fromJson(data, docId: sumSnap.id);
          }
        }
        return null;
      } else {
        final snap = await _feeRecordsRef(
          teacherId ?? '',
          studentId,
        ).doc(billingMonth).get();
        if (!snap.exists || snap.data() == null) return null;
        return FeeRecord.fromJson(snap.data()!, docId: snap.id);
      }
    } catch (e) {
      log('FeeService.getFeeRecord error: $e');
      return null;
    }
  }

  /// Get all fee records for a student across all billing months.
  static Future<List<FeeRecord>> getStudentFeeHistory({
    String? teacherId,
    String? orgId,
    required String studentId,
  }) async {
    try {
      final isOrg = orgId != null && orgId.trim().isNotEmpty;
      if (isOrg) {
        final snap = await _db
            .collection('organizations')
            .doc(orgId)
            .collection('feeRecords')
            .doc(studentId)
            .collection('months')
            .orderBy('billing_month', descending: true)
            .get();

        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => FeeRecord.fromJson(d.data(), docId: d.id))
              .toList();
        }
        // Fallback check top-level summary if months collection empty
        final sumSnap = await _orgFeeSummaryRef(orgId, studentId).get();
        if (sumSnap.exists && sumSnap.data() != null) {
          return [FeeRecord.fromJson(sumSnap.data()!, docId: sumSnap.id)];
        }
        return [];
      } else {
        final snap = await _feeRecordsRef(
          teacherId ?? '',
          studentId,
        ).orderBy('billing_month', descending: true).get();
        return snap.docs
            .map((d) => FeeRecord.fromJson(d.data(), docId: d.id))
            .toList();
      }
    } catch (e) {
      log('FeeService.getStudentFeeHistory error: $e');
      return [];
    }
  }

  /// Get fee records for students of an institute or teacher for a specific billing month.
  static Future<Map<String, FeeRecord>> getFeeRecordsForMonth({
    String? teacherId,
    String? orgId,
    required List<String> studentIds,
    required String billingMonth,
  }) async {
    final result = <String, FeeRecord>{};
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
            orgId: orgId,
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
  static Future<void> updateAmountDue({
    String? teacherId,
    String? orgId,
    required String studentId,
    required String billingMonth,
    required double amountDue,
  }) async {
    final isOrg = orgId != null && orgId.trim().isNotEmpty;
    if (isOrg) {
      final monthRef = _orgFeeMonthRef(orgId, studentId, billingMonth);
      final summaryRef = _orgFeeSummaryRef(orgId, studentId);
      final snap = await monthRef.get();
      final existingPaid = snap.exists
          ? FeeRecord.toDouble(snap.data()?['amount_paid'])
          : 0.0;
      final newBalance = (amountDue - existingPaid).clamp(0, double.infinity);
      final status = FeeRecord.computeStatus(amountDue, existingPaid, null);

      final updateData = {
        'amount_due': amountDue,
        'balance': newBalance,
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      };
      await monthRef.set(updateData, SetOptions(merge: true));
      await summaryRef.set(updateData, SetOptions(merge: true));
    } else {
      final ref = _feeRecordsRef(teacherId ?? '', studentId).doc(billingMonth);
      await ref.set({
        'amount_due': amountDue,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Set or update the monthly fee for all students enrolled in a specific batch.
  static Future<int> setBatchFee({
    required String orgId,
    required String batchId,
    required String billingMonth,
    required double amountDue,
    DateTime? dueDate,
  }) async {
    try {
      final studentsSnap = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('batches')
          .doc(batchId)
          .collection('students')
          .get();

      var count = 0;
      for (final doc in studentsSnap.docs) {
        final studentUid =
            (doc.data()['student_uid'] ?? doc.data()['studentUid'] ?? doc.id)
                .toString();
        final studentName =
            (doc.data()['student_name'] ?? doc.data()['name'] ?? 'Student')
                .toString();

        await ensureFeeRecord(
          orgId: orgId,
          studentId: studentUid,
          studentName: studentName,
          billingMonth: billingMonth,
          amountDue: amountDue,
          dueDate: dueDate,
          batchId: batchId,
        );
        count++;
      }
      return count;
    } catch (e) {
      log('FeeService.setBatchFee error: $e');
      rethrow;
    }
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
    return '$year-${month.toString().padLeft(2, '0')}';
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
    return '$year-${month.toString().padLeft(2, '0')}';
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
    if (month < 1 || month > 12) return key;
    return '${months[month]} $year';
  }
}
