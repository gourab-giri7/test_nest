import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/fee_service.dart';
import 'package:test_nest/core/services/teacher_salary_service.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/teacher_salary_model.dart';

// =============================================================================
// StudentFeeItem — Represents a student alongside their fee record for a month
// =============================================================================
class StudentFeeItem {
  final String studentUid;
  final String studentName;
  final String studentEmail;
  final String? studentPhone;
  final List<String> batchNames;
  final FeeRecord? feeRecord;
  final double defaultMonthlyFee;

  const StudentFeeItem({
    required this.studentUid,
    required this.studentName,
    required this.studentEmail,
    this.studentPhone,
    this.batchNames = const [],
    this.feeRecord,
    this.defaultMonthlyFee = 0.0,
  });

  double get amountDue => feeRecord?.amountDue ?? defaultMonthlyFee;
  double get amountPaid => feeRecord?.amountPaid ?? 0.0;
  double get balance => (amountDue - amountPaid).clamp(0, double.infinity);
  String get status =>
      FeeRecord.computeStatus(amountDue, amountPaid, feeRecord?.dueDate);

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return studentName.toLowerCase().contains(q) ||
        studentEmail.toLowerCase().contains(q) ||
        (studentPhone?.toLowerCase().contains(q) ?? false) ||
        batchNames.any((b) => b.toLowerCase().contains(q));
  }
}

// =============================================================================
// OwnerStudentFeesController — Manages organization student fees
// =============================================================================
class OwnerStudentFeesController extends ChangeNotifier {
  final ActiveTenantContext tenantContext;
  final FirebaseFirestore? _explicitFirestore;
  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  String _selectedMonth;
  String _selectedBatchId = 'all';
  String _statusFilter = 'all'; // all, paid, partial, pending, overdue
  String _searchQuery = '';

  List<StudentFeeItem> _items = [];
  List<BatchModel> _batches = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Monthly statistics
  double _totalExpectedFees = 0.0;
  double _totalCollected = 0.0;
  double _outstandingBalance = 0.0;
  int _paidCount = 0;
  int _partialCount = 0;
  int _pendingCount = 0;
  int _overdueCount = 0;

  OwnerStudentFeesController({
    ActiveTenantContext? tenantContext,
    FirebaseFirestore? firestore,
    String? initialMonth,
    bool autoLoad = true,
  }) : tenantContext = tenantContext ?? ActiveTenantContext(),
       _explicitFirestore = firestore,
       _selectedMonth = initialMonth ?? FeeService.currentMonthKey {
    if (autoLoad) {
      loadData();
    }
  }

  String get orgId => tenantContext.activeOrgId;
  String get selectedMonth => _selectedMonth;
  String get selectedMonthLabel => FeeService.monthLabel(_selectedMonth);
  String get selectedBatchId => _selectedBatchId;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BatchModel> get batches => List.unmodifiable(_batches);
  List<StudentFeeItem> get allItems => List.unmodifiable(_items);

  double get totalExpectedFees => _totalExpectedFees;
  double get totalCollected => _totalCollected;
  double get outstandingBalance => _outstandingBalance;
  int get paidCount => _paidCount;
  int get partialCount => _partialCount;
  int get pendingCount => _pendingCount;
  int get overdueCount => _overdueCount;

  List<StudentFeeItem> get filteredItems {
    var list = List<StudentFeeItem>.from(_items);

    // Batch filter
    if (_selectedBatchId != 'all') {
      final selectedBatchName = _batches
          .where((b) => b.id == _selectedBatchId)
          .map((b) => b.batchName)
          .firstOrNull;
      if (selectedBatchName != null) {
        list = list
            .where(
              (item) => item.batchNames.any(
                (b) =>
                    b.trim().toLowerCase() ==
                    selectedBatchName.trim().toLowerCase(),
              ),
            )
            .toList();
      }
    }

    // Status filter
    if (_statusFilter != 'all') {
      list = list.where((item) {
        final st = item.status.toLowerCase();
        if (_statusFilter == 'pending') {
          return st == 'pending' || st == 'unpaid';
        }
        return st == _statusFilter.toLowerCase();
      }).toList();
    }

    // Search query
    if (_searchQuery.trim().isNotEmpty) {
      list = list.where((item) => item.matchesSearch(_searchQuery)).toList();
    }

    return list;
  }

  // ---------------------------------------------------------------------------
  // Mutators & Filters
  // ---------------------------------------------------------------------------
  void setMonth(String month) {
    if (_selectedMonth != month) {
      _selectedMonth = month;
      loadData();
    }
  }

  void goToPreviousMonth() {
    _selectedMonth = FeeService.prevMonth(_selectedMonth);
    loadData();
  }

  void goToNextMonth() {
    _selectedMonth = FeeService.nextMonth(_selectedMonth);
    loadData();
  }

  void setBatchId(String batchId) {
    _selectedBatchId = batchId;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Load data
  // ---------------------------------------------------------------------------
  Future<void> loadData() async {
    final currentOrgId = orgId;
    if (currentOrgId.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch batches
      final batchSnap = await _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('batches')
          .get();

      _batches = batchSnap.docs
          .map((d) => BatchModel.fromJson(d.data(), docId: d.id))
          .toList();

      // 2. Fetch student members of the institute
      final membersSnap = await _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('members')
          .where('role', isEqualTo: 'student')
          .get();

      final studentUids = membersSnap.docs.map((d) => d.id).toList();

      // 3. Batch lookup mapping per student
      final studentBatchMap = <String, List<String>>{};
      for (final doc in membersSnap.docs) {
        final data = doc.data();
        final rawBatches = data['assignedBatchIds'] ?? data['batch_ids'];
        final bList = <String>[];
        if (rawBatches is List) {
          for (final b in rawBatches) {
            final match = _batches
                .where((bm) => bm.id == b.toString())
                .firstOrNull;
            bList.add(match?.batchName ?? b.toString());
          }
        }
        studentBatchMap[doc.id] = bList;
      }

      // 4. Fetch fee records for this month
      final feeRecords = await FeeService.getFeeRecordsForMonth(
        orgId: currentOrgId,
        studentIds: studentUids,
        billingMonth: _selectedMonth,
      );

      // 5. Build StudentFeeItem list
      final items = <StudentFeeItem>[];
      for (final doc in membersSnap.docs) {
        final data = doc.data();
        final uid = doc.id;
        final name = (data['displayName'] ?? data['name'] ?? 'Student')
            .toString();
        final email = (data['email'] ?? '').toString();
        final phone = data['phone']?.toString();
        final defaultFee = (data['monthly_fee'] is num)
            ? (data['monthly_fee'] as num).toDouble()
            : 0.0;

        items.add(
          StudentFeeItem(
            studentUid: uid,
            studentName: name,
            studentEmail: email,
            studentPhone: phone,
            batchNames: studentBatchMap[uid] ?? const [],
            feeRecord: feeRecords[uid],
            defaultMonthlyFee: defaultFee,
          ),
        );
      }

      // Sort by priority (overdue > unpaid > partial > paid) then name
      items.sort((a, b) {
        final ap = _statusPriority(a.status);
        final bp = _statusPriority(b.status);
        if (ap != bp) return ap.compareTo(bp);
        return a.studentName.compareTo(b.studentName);
      });

      _items = items;
      _computeTotals();

      _isLoading = false;
      notifyListeners();
    } catch (e, st) {
      log('OwnerStudentFeesController.loadData error: $e\n$st');
      _errorMessage = 'Failed to load fee records. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _computeTotals() {
    _totalExpectedFees = 0.0;
    _totalCollected = 0.0;
    _outstandingBalance = 0.0;
    _paidCount = 0;
    _partialCount = 0;
    _pendingCount = 0;
    _overdueCount = 0;

    for (final s in _items) {
      _totalExpectedFees += s.amountDue;
      _totalCollected += s.amountPaid;
      _outstandingBalance += s.balance;
      final st = s.status.toLowerCase();
      switch (st) {
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
          _pendingCount++;
      }
    }
  }

  int _statusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'overdue':
        return 0;
      case 'pending':
      case 'unpaid':
        return 1;
      case 'partial':
        return 2;
      default:
        return 3;
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Records a fee payment for a student with transaction & idempotency.
  Future<bool> recordStudentPayment({
    required String studentUid,
    required String studentName,
    required double amount,
    required DateTime paidAt,
    required String method,
    required String recordedBy,
    String? note,
    String? receiptRef,
    double? amountDue,
  }) async {
    try {
      await FeeService.recordPayment(
        orgId: orgId,
        studentId: studentUid,
        studentName: studentName,
        billingMonth: _selectedMonth,
        amount: amount,
        paidAt: paidAt,
        method: method,
        recordedBy: recordedBy,
        note: note,
        receiptRef: receiptRef,
        amountDue: amountDue,
      );
      await loadData();
      return true;
    } catch (e) {
      log('OwnerStudentFeesController.recordStudentPayment error: $e');
      return false;
    }
  }

  /// Updates or overrides the amount due for a single student in this month.
  Future<bool> updateStudentFeeDue({
    required String studentUid,
    required double amountDue,
  }) async {
    try {
      await FeeService.updateAmountDue(
        orgId: orgId,
        studentId: studentUid,
        billingMonth: _selectedMonth,
        amountDue: amountDue,
      );
      await loadData();
      return true;
    } catch (e) {
      log('OwnerStudentFeesController.updateStudentFeeDue error: $e');
      return false;
    }
  }

  /// Bulk configures or updates the monthly fee for all students in a batch.
  Future<int> setBatchFee({
    required String batchId,
    required double amountDue,
    DateTime? dueDate,
  }) async {
    try {
      final count = await FeeService.setBatchFee(
        orgId: orgId,
        batchId: batchId,
        billingMonth: _selectedMonth,
        amountDue: amountDue,
        dueDate: dueDate,
      );
      await loadData();
      return count;
    } catch (e) {
      log('OwnerStudentFeesController.setBatchFee error: $e');
      rethrow;
    }
  }

  @visibleForTesting
  void setTestData({List<StudentFeeItem>? items, List<BatchModel>? batches}) {
    if (items != null) _items = items;
    if (batches != null) _batches = batches;
    _computeTotals();
    _isLoading = false;
    notifyListeners();
  }
}

// =============================================================================
// TeacherSalaryItem — Combines teacher identity with their monthly salary snapshot
// =============================================================================
class TeacherSalaryItem {
  final String teacherUid;
  final String teacherName;
  final String teacherEmail;
  final String? teacherPhone;
  final TeacherSalaryModel? salaryRecord;
  final double configuredBaseSalary;

  const TeacherSalaryItem({
    required this.teacherUid,
    required this.teacherName,
    required this.teacherEmail,
    this.teacherPhone,
    this.salaryRecord,
    this.configuredBaseSalary = 0.0,
  });

  double get baseSalary => salaryRecord?.baseSalary ?? configuredBaseSalary;
  double get amountPaid => salaryRecord?.amountPaid ?? 0.0;
  double get remainingAmount =>
      (baseSalary - amountPaid).clamp(0, double.infinity);
  String get status =>
      salaryRecord?.status ?? (baseSalary <= 0 ? 'paid' : 'pending');

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return teacherName.toLowerCase().contains(q) ||
        teacherEmail.toLowerCase().contains(q) ||
        (teacherPhone?.toLowerCase().contains(q) ?? false);
  }
}

// =============================================================================
// OwnerTeacherSalariesController — Manages teacher salaries and disbursements
// =============================================================================
class OwnerTeacherSalariesController extends ChangeNotifier {
  final ActiveTenantContext tenantContext;
  final FirebaseFirestore? _explicitFirestore;
  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  String _selectedMonth;
  String _statusFilter = 'all'; // all, paid, partial, pending
  String _searchQuery = '';

  List<TeacherSalaryItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Monthly summary statistics
  double _totalObligation = 0.0;
  double _totalPaid = 0.0;
  double _totalPending = 0.0;
  int _paidCount = 0;
  int _partialCount = 0;
  int _pendingCount = 0;

  OwnerTeacherSalariesController({
    ActiveTenantContext? tenantContext,
    FirebaseFirestore? firestore,
    String? initialMonth,
    bool autoLoad = true,
  }) : tenantContext = tenantContext ?? ActiveTenantContext(),
       _explicitFirestore = firestore,
       _selectedMonth = initialMonth ?? FeeService.currentMonthKey {
    if (autoLoad) {
      loadData();
    }
  }

  String get orgId => tenantContext.activeOrgId;
  String get selectedMonth => _selectedMonth;
  String get selectedMonthLabel => FeeService.monthLabel(_selectedMonth);
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TeacherSalaryItem> get allItems => List.unmodifiable(_items);

  double get totalObligation => _totalObligation;
  double get totalPaid => _totalPaid;
  double get totalPending => _totalPending;
  int get paidCount => _paidCount;
  int get partialCount => _partialCount;
  int get pendingCount => _pendingCount;

  List<TeacherSalaryItem> get filteredItems {
    var list = List<TeacherSalaryItem>.from(_items);

    // Status filter
    if (_statusFilter != 'all') {
      list = list
          .where(
            (item) => item.status.toLowerCase() == _statusFilter.toLowerCase(),
          )
          .toList();
    }

    // Search query
    if (_searchQuery.trim().isNotEmpty) {
      list = list.where((item) => item.matchesSearch(_searchQuery)).toList();
    }

    return list;
  }

  // ---------------------------------------------------------------------------
  // Mutators & Filters
  // ---------------------------------------------------------------------------
  void setMonth(String month) {
    if (_selectedMonth != month) {
      _selectedMonth = month;
      loadData();
    }
  }

  void goToPreviousMonth() {
    _selectedMonth = FeeService.prevMonth(_selectedMonth);
    loadData();
  }

  void goToNextMonth() {
    _selectedMonth = FeeService.nextMonth(_selectedMonth);
    loadData();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Load data
  // ---------------------------------------------------------------------------
  Future<void> loadData() async {
    final currentOrgId = orgId;
    if (currentOrgId.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch teacher members of the institute
      final teachersSnap = await _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('members')
          .where('role', isEqualTo: 'teacher')
          .get();

      final teacherUids = teachersSnap.docs.map((d) => d.id).toList();

      // 2. Fetch salary records for this month
      final salaryRecords = await TeacherSalaryService.getSalariesForMonth(
        orgId: currentOrgId,
        teacherUids: teacherUids,
        billingMonth: _selectedMonth,
      );

      // 3. Build TeacherSalaryItem list
      final items = <TeacherSalaryItem>[];
      for (final doc in teachersSnap.docs) {
        final data = doc.data();
        final uid = doc.id;
        final name = (data['displayName'] ?? data['name'] ?? 'Teacher')
            .toString();
        final email = (data['email'] ?? '').toString();
        final phone = data['phone']?.toString();
        final rawSalary =
            data['monthly_salary'] ?? data['base_salary'] ?? data['salary'];
        final configuredSalary = (rawSalary is num)
            ? rawSalary.toDouble()
            : (double.tryParse(rawSalary?.toString() ?? '') ?? 0.0);

        items.add(
          TeacherSalaryItem(
            teacherUid: uid,
            teacherName: name,
            teacherEmail: email,
            teacherPhone: phone,
            salaryRecord: salaryRecords[uid],
            configuredBaseSalary: configuredSalary,
          ),
        );
      }

      // Sort by priority (pending > partial > paid) then name
      items.sort((a, b) {
        final ap = _statusPriority(a.status);
        final bp = _statusPriority(b.status);
        if (ap != bp) return ap.compareTo(bp);
        return a.teacherName.compareTo(b.teacherName);
      });

      _items = items;
      _computeTotals();

      _isLoading = false;
      notifyListeners();
    } catch (e, st) {
      log('OwnerTeacherSalariesController.loadData error: $e\n$st');
      _errorMessage = 'Failed to load teacher salaries. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _computeTotals() {
    _totalObligation = 0.0;
    _totalPaid = 0.0;
    _totalPending = 0.0;
    _paidCount = 0;
    _partialCount = 0;
    _pendingCount = 0;

    for (final t in _items) {
      _totalObligation += t.baseSalary;
      _totalPaid += t.amountPaid;
      _totalPending += t.remainingAmount;
      switch (t.status.toLowerCase()) {
        case 'paid':
          _paidCount++;
          break;
        case 'partial':
          _partialCount++;
          break;
        default:
          _pendingCount++;
      }
    }
  }

  int _statusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'partial':
        return 1;
      default:
        return 2;
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Records a salary disbursement to a teacher with transaction & idempotency.
  Future<bool> recordSalaryPayment({
    required String teacherUid,
    required String teacherName,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    required String recordedBy,
    String? referenceNumber,
    String? note,
    double? baseSalary,
  }) async {
    try {
      await TeacherSalaryService.recordSalaryPayment(
        orgId: orgId,
        teacherUid: teacherUid,
        teacherName: teacherName,
        billingMonth: _selectedMonth,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        recordedBy: recordedBy,
        referenceNumber: referenceNumber,
        note: note,
        baseSalary: baseSalary,
      );
      await loadData();
      return true;
    } catch (e) {
      log('OwnerTeacherSalariesController.recordSalaryPayment error: $e');
      return false;
    }
  }

  /// Sets or updates the teacher's ongoing default monthly salary.
  /// HISTORICAL PROTECTION: Does not rewrite past monthly salary records.
  Future<bool> configureTeacherDefaultSalary({
    required String teacherUid,
    required double baseSalary,
  }) async {
    try {
      await TeacherSalaryService.setTeacherDefaultSalary(
        orgId: orgId,
        teacherUid: teacherUid,
        baseSalary: baseSalary,
      );
      // Also ensure this month's snapshot reflects it if unpaid
      final currentMonthRecord = await TeacherSalaryService.getSalaryRecord(
        orgId: orgId,
        teacherUid: teacherUid,
        billingMonth: _selectedMonth,
      );
      if (currentMonthRecord == null || currentMonthRecord.amountPaid <= 0.0) {
        await TeacherSalaryService.ensureSalaryRecord(
          orgId: orgId,
          teacherUid: teacherUid,
          teacherName:
              _items
                  .where((i) => i.teacherUid == teacherUid)
                  .firstOrNull
                  ?.teacherName ??
              'Teacher',
          billingMonth: _selectedMonth,
          baseSalary: baseSalary,
        );
      }
      await loadData();
      return true;
    } catch (e) {
      log(
        'OwnerTeacherSalariesController.configureTeacherDefaultSalary error: $e',
      );
      return false;
    }
  }

  @visibleForTesting
  void setTestData({List<TeacherSalaryItem>? items}) {
    if (items != null) _items = items;
    _computeTotals();
    _isLoading = false;
    notifyListeners();
  }
}
