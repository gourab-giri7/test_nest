import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/model/teacher_salary_model.dart';

// =============================================================================
// TeacherSalaryService — trusted client-side service for teacher salary management.
//
// Organization-Scoped Firestore paths:
// 1. Monthly Records:
//    organizations/{orgId}/teacherSalaryRecords/{teacherUid}/months/{YYYY-MM}
// 2. Append-Only Salary Payment Entries:
//    organizations/{orgId}/teacherSalaryRecords/{teacherUid}/months/{YYYY-MM}/payments/{id}
// 3. Top-Level Index (for backward compatibility with Step 4 Teacher Dashboard query):
//    organizations/{orgId}/salaries/{teacherUid}_{YYYY-MM}
//
// HISTORICAL SALARY PROTECTION:
// Changing a teacher's ongoing base salary snapshot NEVER alters past monthly records.
// =============================================================================
class TeacherSalaryService {
  static final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Firestore references
  // ---------------------------------------------------------------------------
  /// Backward compatibility aliases
  Future<List<TeacherSalaryModel>> fetchSalaryHistory({
    required String orgId,
    required String teacherUid,
  }) =>
      getTeacherSalaryHistory(orgId: orgId, teacherUid: teacherUid);

  Future<void> setTeacherBaseSalary({
    required String orgId,
    required String teacherUid,
    required double baseSalary,
  }) =>
      setTeacherDefaultSalary(
        orgId: orgId,
        teacherUid: teacherUid,
        baseSalary: baseSalary,
      );

  Future<SalaryPaymentEntry> recordPayment({
    required String orgId,
    required String teacherUid,
    required String teacherName,
    required String billingMonth,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? referenceNumber,
    String? note,
    required String recordedBy,
    double? baseSalary,
  }) =>
      recordSalaryPayment(
        orgId: orgId,
        teacherUid: teacherUid,
        teacherName: teacherName,
        billingMonth: billingMonth,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        note: note,
        recordedBy: recordedBy,
        baseSalary: baseSalary,
      );

  static DocumentReference<Map<String, dynamic>> _teacherDocRef(
    String orgId,
    String teacherUid,
  ) => _db
      .collection('organizations')
      .doc(orgId)
      .collection('members')
      .doc(teacherUid);

  static DocumentReference<Map<String, dynamic>> _monthDocRef(
    String orgId,
    String teacherUid,
    String billingMonth,
  ) => _db
      .collection('organizations')
      .doc(orgId)
      .collection('teacherSalaryRecords')
      .doc(teacherUid)
      .collection('months')
      .doc(billingMonth);

  static CollectionReference<Map<String, dynamic>> _paymentsRef(
    String orgId,
    String teacherUid,
    String billingMonth,
  ) => _monthDocRef(orgId, teacherUid, billingMonth).collection('payments');

  static DocumentReference<Map<String, dynamic>> _legacySalaryDocRef(
    String orgId,
    String teacherUid,
    String billingMonth,
  ) => _db
      .collection('organizations')
      .doc(orgId)
      .collection('salaries')
      .doc('${teacherUid}_$billingMonth');

  // ---------------------------------------------------------------------------
  // Teacher default salary configuration (stored in member doc)
  // ---------------------------------------------------------------------------

  /// Fetches the configured default monthly base salary for a teacher.
  static Future<double> getTeacherDefaultSalary({
    required String orgId,
    required String teacherUid,
  }) async {
    try {
      final snap = await _teacherDocRef(orgId, teacherUid).get();
      if (!snap.exists) return 0.0;
      final data = snap.data() ?? {};
      final raw =
          data['monthly_salary'] ?? data['base_salary'] ?? data['salary'];
      if (raw == null) return 0.0;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 0.0;
    } catch (e) {
      log('TeacherSalaryService.getTeacherDefaultSalary error: $e');
      return 0.0;
    }
  }

  /// Sets the teacher's ongoing default monthly salary.
  /// HISTORICAL PROTECTION: This only updates the teacher's profile setting and does
  /// NOT rewrite or mutate previously generated monthly salary records.
  static Future<void> setTeacherDefaultSalary({
    required String orgId,
    required String teacherUid,
    required double baseSalary,
  }) async {
    try {
      await _teacherDocRef(orgId, teacherUid).set({
        'monthly_salary': baseSalary,
        'salary_updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      log('TeacherSalaryService.setTeacherDefaultSalary error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Monthly salary snapshot & record management
  // ---------------------------------------------------------------------------

  /// Ensures a monthly salary record exists for a teacher.
  /// If the record already exists, its base salary is preserved to protect history.
  static Future<TeacherSalaryModel> ensureSalaryRecord({
    required String orgId,
    required String teacherUid,
    required String teacherName,
    required String billingMonth,
    double? baseSalary,
  }) async {
    final monthRef = _monthDocRef(orgId, teacherUid, billingMonth);
    final legacyRef = _legacySalaryDocRef(orgId, teacherUid, billingMonth);

    final snap = await monthRef.get();
    if (snap.exists && snap.data() != null) {
      return TeacherSalaryModel.fromJson(snap.data()!, docId: snap.id);
    }

    // Determine the base salary snapshot
    double effectiveSalary = baseSalary ?? 0.0;
    if (effectiveSalary <= 0.0) {
      effectiveSalary = await getTeacherDefaultSalary(
        orgId: orgId,
        teacherUid: teacherUid,
      );
    }

    final record = TeacherSalaryModel(
      id: '${teacherUid}_$billingMonth',
      orgId: orgId,
      teacherUid: teacherUid,
      teacherName: teacherName,
      amount: effectiveSalary,
      amountPaid: 0.0,
      remainingAmount: effectiveSalary,
      month: billingMonth,
      status: effectiveSalary <= 0 ? 'paid' : 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final data = record.toJson();
    await monthRef.set(data);
    await legacyRef.set(data, SetOptions(merge: true));

    return record;
  }

  /// Override the base salary for a specific month only (if no payments have been recorded yet).
  static Future<void> updateMonthlyBaseSalary({
    required String orgId,
    required String teacherUid,
    required String billingMonth,
    required double newBaseSalary,
  }) async {
    final monthRef = _monthDocRef(orgId, teacherUid, billingMonth);
    final legacyRef = _legacySalaryDocRef(orgId, teacherUid, billingMonth);

    final snap = await monthRef.get();
    if (snap.exists) {
      final existingPaid = TeacherSalaryModel.fromJson(snap.data()!).amountPaid;
      if (existingPaid > 0 && newBaseSalary < existingPaid) {
        throw StateError(
          'Cannot reduce base salary below already paid amount (₹${existingPaid.toStringAsFixed(2)}).',
        );
      }
      final newRemaining = (newBaseSalary - existingPaid)
          .clamp(0, double.infinity)
          .toDouble();
      String status = 'pending';
      if (newBaseSalary <= 0 || existingPaid >= newBaseSalary) {
        status = 'paid';
      } else if (existingPaid > 0) {
        status = 'partial';
      }

      final updates = {
        'amount': newBaseSalary,
        'base_salary': newBaseSalary,
        'remaining_amount': newRemaining,
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await monthRef.update(updates);
      await legacyRef.set(updates, SetOptions(merge: true));
    }
  }

  // ---------------------------------------------------------------------------
  // Salary Payment Recording (Transaction & Append-Only)
  // ---------------------------------------------------------------------------

  /// Records a salary disbursement to a teacher for a specific billing month.
  /// Uses a Firestore transaction for atomic remaining balance & status calculation.
  /// Appends an immutable SalaryPaymentEntry to payments/{paymentId}.
  static Future<SalaryPaymentEntry> recordSalaryPayment({
    required String orgId,
    required String teacherUid,
    required String teacherName,
    required String billingMonth,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? referenceNumber,
    String? note,
    required String recordedBy,
    double? baseSalary,
    String? paymentId,
  }) async {
    final monthRef = _monthDocRef(orgId, teacherUid, billingMonth);
    final paymentsCol = _paymentsRef(orgId, teacherUid, billingMonth);
    final legacyRef = _legacySalaryDocRef(orgId, teacherUid, billingMonth);

    final effectivePaymentId = paymentId ?? paymentsCol.doc().id;
    final paymentDocRef = paymentsCol.doc(effectivePaymentId);

    final entry = SalaryPaymentEntry(
      paymentId: effectivePaymentId,
      salaryRecordId: '${teacherUid}_$billingMonth',
      amount: amount,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      note: note,
      recordedBy: recordedBy,
      createdAt: DateTime.now(),
    );

    await _db.runTransaction((tx) async {
      // Idempotency check: verify payment entry doesn't already exist
      final existingPayment = await tx.get(paymentDocRef);
      if (existingPayment.exists) {
        throw StateError(
          'Duplicate salary payment ID: $effectivePaymentId already processed.',
        );
      }

      final monthSnap = await tx.get(monthRef);
      double existingSalary = baseSalary ?? 0.0;
      double existingPaid = 0.0;

      if (monthSnap.exists && monthSnap.data() != null) {
        final existingRecord = TeacherSalaryModel.fromJson(monthSnap.data()!);
        existingSalary = existingRecord.amount;
        existingPaid = existingRecord.amountPaid;
      } else if (existingSalary <= 0.0) {
        existingSalary = amount; // Fallback to current disbursement if unset
      }

      final newPaid = existingPaid + amount;
      final newRemaining = (existingSalary - newPaid)
          .clamp(0, double.infinity)
          .toDouble();

      String derivedStatus = 'pending';
      if (existingSalary <= 0 || newPaid >= existingSalary) {
        derivedStatus = 'paid';
      } else if (newPaid > 0) {
        derivedStatus = 'partial';
      }

      final recordUpdates = {
        'id': '${teacherUid}_$billingMonth',
        'org_id': orgId,
        'teacher_uid': teacherUid,
        'teacher_name': teacherName,
        'amount': existingSalary,
        'base_salary': existingSalary,
        'amount_paid': newPaid,
        'remaining_amount': newRemaining,
        'month': billingMonth,
        'billing_month': billingMonth,
        'status': derivedStatus,
        'paid_at': Timestamp.fromDate(paymentDate),
        'payment_mode': paymentMethod,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'reference_number': referenceNumber,
        if (note != null && note.isNotEmpty) 'notes': note,
        'updated_at': FieldValue.serverTimestamp(),
        if (!monthSnap.exists) 'created_at': FieldValue.serverTimestamp(),
      };

      tx.set(monthRef, recordUpdates, SetOptions(merge: true));
      tx.set(legacyRef, recordUpdates, SetOptions(merge: true));
      tx.set(paymentDocRef, entry.toJson());
    });

    return entry;
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Fetches the monthly salary record for a teacher.
  static Future<TeacherSalaryModel?> getSalaryRecord({
    required String orgId,
    required String teacherUid,
    required String billingMonth,
  }) async {
    try {
      final snap = await _monthDocRef(orgId, teacherUid, billingMonth).get();
      if (snap.exists && snap.data() != null) {
        return TeacherSalaryModel.fromJson(snap.data()!, docId: snap.id);
      }
      // Check legacy path fallback
      final legSnap = await _legacySalaryDocRef(
        orgId,
        teacherUid,
        billingMonth,
      ).get();
      if (legSnap.exists && legSnap.data() != null) {
        return TeacherSalaryModel.fromJson(legSnap.data()!, docId: legSnap.id);
      }
      return null;
    } catch (e) {
      log('TeacherSalaryService.getSalaryRecord error: $e');
      return null;
    }
  }

  /// Fetches the append-only payment entries for a teacher in a billing month.
  static Future<List<SalaryPaymentEntry>> getSalaryPayments({
    required String orgId,
    required String teacherUid,
    required String billingMonth,
  }) async {
    try {
      final snap = await _paymentsRef(orgId, teacherUid, billingMonth).get();
      final entries = snap.docs
          .map((d) => SalaryPaymentEntry.fromJson(d.data(), docId: d.id))
          .toList();
      entries.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return entries;
    } catch (e) {
      log('TeacherSalaryService.getSalaryPayments error: $e');
      return [];
    }
  }

  /// Fetches the complete monthly salary history for a teacher across all months.
  static Future<List<TeacherSalaryModel>> getTeacherSalaryHistory({
    required String orgId,
    required String teacherUid,
  }) async {
    try {
      final snap = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('teacherSalaryRecords')
          .doc(teacherUid)
          .collection('months')
          .orderBy('billing_month', descending: true)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((d) => TeacherSalaryModel.fromJson(d.data(), docId: d.id))
            .toList();
      }

      // Fallback check legacy salaries collection
      final legSnap = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('salaries')
          .where('teacher_uid', isEqualTo: teacherUid)
          .get();

      final list = legSnap.docs
          .map((d) => TeacherSalaryModel.fromJson(d.data(), docId: d.id))
          .toList();
      list.sort((a, b) => b.month.compareTo(a.month));
      return list;
    } catch (e) {
      log('TeacherSalaryService.getTeacherSalaryHistory error: $e');
      return [];
    }
  }

  /// Fetches salary status for a roster of teachers in a specific billing month.
  static Future<Map<String, TeacherSalaryModel>> getSalariesForMonth({
    required String orgId,
    required List<String> teacherUids,
    required String billingMonth,
  }) async {
    final result = <String, TeacherSalaryModel>{};
    for (final uid in teacherUids) {
      final rec = await getSalaryRecord(
        orgId: orgId,
        teacherUid: uid,
        billingMonth: billingMonth,
      );
      if (rec != null) {
        result[uid] = rec;
      }
    }
    return result;
  }
}
