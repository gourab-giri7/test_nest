import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/core/services/fee_service.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/payment_model.dart';

// =============================================================================
// StudentFeeStatus — combines a StudentModel with their fee record for a month.
// =============================================================================
class StudentFeeStatus {
  final StudentModel student;
  final FeeRecord? feeRecord;
  final double defaultMonthlyFee;

  const StudentFeeStatus({
    required this.student,
    required this.feeRecord,
    required this.defaultMonthlyFee,
  });

  double get amountDue => feeRecord?.amountDue ?? defaultMonthlyFee;
  double get amountPaid => feeRecord?.amountPaid ?? 0.0;
  double get balance => (amountDue - amountPaid).clamp(0, double.infinity);
  String get status => FeeRecord.computeStatus(amountDue, amountPaid, feeRecord?.dueDate);
}

// =============================================================================
// FeeManagementController
// =============================================================================
class FeeManagementController extends ChangeNotifier {
  final String teacherId;
  final String teacherName;

  String _selectedMonth;
  String? _selectedBatch;
  String _searchQuery = '';

  List<StudentFeeStatus> _allStatuses = [];
  bool _isLoading = false;
  String? _error;

  // Monthly summary totals
  double _totalCollected = 0;
  double _totalDue = 0;
  int _paidCount = 0;
  int _unpaidCount = 0;
  int _partialCount = 0;
  int _overdueCount = 0;

  // Available batches for filter
  List<String> _availableBatches = [];

  FeeManagementController({
    required this.teacherId,
    required this.teacherName,
    String? initialMonth,
  }) : _selectedMonth = initialMonth ?? FeeService.currentMonthKey;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  String get selectedMonth => _selectedMonth;
  String get selectedMonthLabel => FeeService.monthLabel(_selectedMonth);
  String? get selectedBatch => _selectedBatch;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get availableBatches => List.unmodifiable(_availableBatches);

  double get totalCollected => _totalCollected;
  double get totalDue => _totalDue;
  int get paidCount => _paidCount;
  int get unpaidCount => _unpaidCount;
  int get partialCount => _partialCount;
  int get overdueCount => _overdueCount;

  /// Filtered list of student fee statuses.
  List<StudentFeeStatus> get filteredStatuses {
    var list = List<StudentFeeStatus>.from(_allStatuses);

    // Filter by batch
    if (_selectedBatch != null && _selectedBatch!.isNotEmpty) {
      list = list
          .where(
            (s) => StudentModel.isSameBatch(s.student.batch, _selectedBatch!),
          )
          .toList();
    }

    // Filter by search query
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.student.name.toLowerCase().contains(q) ||
                s.student.id.toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  // ---------------------------------------------------------------------------
  // Load fee data for selected month
  // ---------------------------------------------------------------------------
  Future<void> loadFeeData() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Load all students
      final studentsSnap = await FirebaseFirestore.instance
          .collection('user')
          .doc(teacherId)
          .collection('students')
          .get();

      final students =
          studentsSnap.docs
              .map((d) => StudentModel.fromJson(d.data(), docId: d.id))
              .where((s) => s.id.isNotEmpty)
              .toList();

      // Collect available batches
      final batches = <String>{};
      for (final s in students) {
        if (s.batch.trim().isNotEmpty) {
          batches.add(s.batch.trim());
        }
      }
      _availableBatches = batches.toList()..sort();

      // 2. Load fee records for this month
      final studentIds = students.map((s) => s.id).toList();
      final feeRecords = await FeeService.getFeeRecordsForMonth(
        teacherId: teacherId,
        studentIds: studentIds,
        billingMonth: _selectedMonth,
      );

      // 3. Build combined status list
      _allStatuses = students.map((student) {
        // Use student's individual monthly fee if set, otherwise 0
        final defaultFee =
            student.monthlyFee > 0 ? student.monthlyFee : 0.0;
        return StudentFeeStatus(
          student: student,
          feeRecord: feeRecords[student.id],
          defaultMonthlyFee: defaultFee,
        );
      }).toList();

      // Sort by status priority (overdue > unpaid > partial > paid) then name
      _allStatuses.sort((a, b) {
        final ap = _statusPriority(a.status);
        final bp = _statusPriority(b.status);
        if (ap != bp) return ap.compareTo(bp);
        return a.student.name.compareTo(b.student.name);
      });

      // 4. Compute totals
      _computeTotals();

      _isLoading = false;
      notifyListeners();
    } catch (e, st) {
      log('FeeManagementController.loadFeeData error: $e\n$st');
      _isLoading = false;
      _error = 'Failed to load fee data. Please try again.';
      notifyListeners();
    }
  }

  void _computeTotals() {
    _totalCollected = 0;
    _totalDue = 0;
    _paidCount = 0;
    _unpaidCount = 0;
    _partialCount = 0;
    _overdueCount = 0;

    for (final s in _allStatuses) {
      _totalDue += s.amountDue;
      _totalCollected += s.amountPaid;
      switch (s.status) {
        case 'paid':
          _paidCount++;
          break;
        case 'partial':
          _partialCount++;
          break;
        case 'overdue':
          _overdueCount++;
          break;
        default:
          _unpaidCount++;
      }
    }
  }

  int _statusPriority(String status) {
    switch (status) {
      case 'overdue':
        return 0;
      case 'unpaid':
        return 1;
      case 'partial':
        return 2;
      default:
        return 3;
    }
  }

  // ---------------------------------------------------------------------------
  // Month navigation
  // ---------------------------------------------------------------------------
  void goToPreviousMonth() {
    _selectedMonth = FeeService.prevMonth(_selectedMonth);
    loadFeeData();
  }

  void goToNextMonth() {
    _selectedMonth = FeeService.nextMonth(_selectedMonth);
    loadFeeData();
  }

  void setMonth(String month) {
    if (_selectedMonth == month) return;
    _selectedMonth = month;
    loadFeeData();
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------
  void setBatch(String? batch) {
    _selectedBatch = (batch != null && batch.isNotEmpty) ? batch : null;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Record a payment
  // ---------------------------------------------------------------------------
  Future<bool> recordPayment({
    required String studentId,
    required String studentName,
    required double amount,
    required DateTime paidAt,
    required String method,
    String? note,
    String? receiptRef,
    double? amountDue,
  }) async {
    try {
      await FeeService.recordPayment(
        teacherId: teacherId,
        studentId: studentId,
        studentName: studentName,
        billingMonth: _selectedMonth,
        amount: amount,
        paidAt: paidAt,
        method: method,
        recordedBy: teacherName,
        note: note,
        receiptRef: receiptRef,
        amountDue: amountDue,
      );
      await loadFeeData();
      return true;
    } catch (e) {
      log('FeeManagementController.recordPayment error: $e');
      return false;
    }
  }

  /// Update the amount due for a student in the selected month.
  Future<bool> updateAmountDue({
    required String studentId,
    required double amountDue,
  }) async {
    try {
      await FeeService.updateAmountDue(
        teacherId: teacherId,
        studentId: studentId,
        billingMonth: _selectedMonth,
        amountDue: amountDue,
      );
      await loadFeeData();
      return true;
    } catch (e) {
      log('FeeManagementController.updateAmountDue error: $e');
      return false;
    }
  }

  /// Load payment history for a specific student in the selected month.
  Future<List<PaymentEntry>> loadPaymentsForStudent(String studentId) async {
    return FeeService.getPayments(
      teacherId: teacherId,
      studentId: studentId,
      billingMonth: _selectedMonth,
    );
  }
}
