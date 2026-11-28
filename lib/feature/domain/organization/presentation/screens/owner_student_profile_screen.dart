import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/services/fee_service.dart';
import 'package:test_nest/core/services/organization_service.dart';
import 'package:test_nest/core/utils/custom_snackbar.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/studentDetails/model/student_exam_submission_summary.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/organization_model.dart';

// =============================================================================
// OwnerStudentProfileScreen
// Full-screen dedicated student profile for Institute Owners.
// Replaces the old bottom sheet with a 2-tab layout:
// Tab 1: Fees History (Previous months & current month with Paid/Pending status & Collect action)
// Tab 2: Exam History (Recent given exams, tap to inspect all questions, right/wrong answers & marks)
// =============================================================================

class _OwnerStudentProfileData extends ChangeNotifier {
  OrganizationMemberModel currentStudent;
  List<BatchModel> orgBatches = [];

  bool isLoadingFees = false;
  List<FeeRecord> monthlyFeeCards = [];
  double expectedMonthlyFee = 0.0;
  double totalFeesCollected = 0.0;
  double totalFeesDue = 0.0;

  bool isLoadingExams = false;
  String? examError;
  List<StudentExamSubmissionSummary> examHistory = [];

  _OwnerStudentProfileData({required this.currentStudent});

  void computeExpectedMonthlyFee() {
    double total = 0.0;
    final assigned = Set<String>.from(
      currentStudent.assignedBatchIds.map((b) => b.trim().toLowerCase()),
    );
    for (final b in orgBatches) {
      final matchesId = assigned.contains(b.id.trim().toLowerCase());
      final matchesName = assigned.contains(b.name.trim().toLowerCase());
      if (matchesId || matchesName) {
        if (b.monthlyFee > 0) {
          total += b.monthlyFee;
        }
      }
    }
    expectedMonthlyFee = total > 0 ? total : 0.0;
  }

  void setBatches(List<BatchModel> batches) {
    orgBatches = batches;
    computeExpectedMonthlyFee();
    notifyListeners();
  }

  void setLoadingFees(bool val) {
    isLoadingFees = val;
    notifyListeners();
  }

  void setFeeData({
    required List<FeeRecord> cards,
    required double totalCollected,
    required double totalDue,
  }) {
    monthlyFeeCards = cards;
    totalFeesCollected = totalCollected;
    totalFeesDue = totalDue;
    isLoadingFees = false;
    notifyListeners();
  }

  void setLoadingExams(bool val) {
    isLoadingExams = val;
    if (val) examError = null;
    notifyListeners();
  }

  void setExamData(List<StudentExamSubmissionSummary> summaries) {
    examHistory = summaries;
    isLoadingExams = false;
    notifyListeners();
  }

  void setExamError(String err) {
    examError = err;
    isLoadingExams = false;
    notifyListeners();
  }

  void notifyBatchesChanged() {
    computeExpectedMonthlyFee();
    notifyListeners();
  }
}

class OwnerStudentProfileScreen extends StatefulWidget {
  final OrganizationMemberModel student;
  final String orgId;
  final FirebaseFirestore? firestore;
  final bool autoLoad;

  const OwnerStudentProfileScreen({
    super.key,
    required this.student,
    required this.orgId,
    this.firestore,
    this.autoLoad = true,
  });

  @override
  State<OwnerStudentProfileScreen> createState() =>
      _OwnerStudentProfileScreenState();
}

class _OwnerStudentProfileScreenState extends State<OwnerStudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrganizationService _orgService = OrganizationService();

  FirebaseFirestore get _firestore {
    if (widget.firestore != null) return widget.firestore!;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null as dynamic;
    }
  }

  late final _OwnerStudentProfileData _data;

  OrganizationMemberModel get _currentStudent => _data.currentStudent;
  List<BatchModel> get _orgBatches => _data.orgBatches;
  bool get _isLoadingFees => _data.isLoadingFees;
  List<FeeRecord> get _monthlyFeeCards => _data.monthlyFeeCards;
  double get _expectedMonthlyFee => _data.expectedMonthlyFee;
  double get _totalFeesCollected => _data.totalFeesCollected;
  double get _totalFeesDue => _data.totalFeesDue;
  bool get _isLoadingExams => _data.isLoadingExams;
  String? get _examError => _data.examError;
  List<StudentExamSubmissionSummary> get _examHistory => _data.examHistory;

  @override
  void initState() {
    super.initState();
    _data = _OwnerStudentProfileData(currentStudent: widget.student);
    _tabController = TabController(length: 2, vsync: this);

    if (widget.autoLoad) {
      _loadBatchesAndData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _data.dispose();
    super.dispose();
  }

  Future<void> _loadBatchesAndData() async {
    await _loadBatches();
    await Future.wait([_loadFeeHistory(), _loadExamHistory()]);
  }

  Future<void> _loadBatches() async {
    try {
      final snap = await _firestore
          .collection('organizations')
          .doc(widget.orgId)
          .collection('batches')
          .get();
      final batches = snap.docs
          .map((d) => BatchModel.fromJson(d.data(), docId: d.id))
          .toList();

      if (mounted) {
        _data.setBatches(batches);
      }
    } catch (e) {
      log('Error loading institute batches: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Fees Loading & Month Generation
  // ---------------------------------------------------------------------------

  Future<void> _loadFeeHistory() async {
    if (!mounted) return;
    _data.setLoadingFees(true);

    try {
      final recordedList = await FeeService.getStudentFeeHistory(
        orgId: widget.orgId,
        studentId: _currentStudent.uid,
      );

      final recordMap = <String, FeeRecord>{};
      for (final r in recordedList) {
        recordMap[r.billingMonth] = r;
      }

      // Fee ledger starts from the month the student was added to the batch
      final now = DateTime.now();
      final currentMonthDate = DateTime(now.year, now.month, 1);
      final joinDate = _currentStudent.joinedAt;
      final startMonthDate = DateTime(joinDate.year, joinDate.month, 1);

      // Months from startMonthDate up to current month (inclusive)
      int monthCount = (currentMonthDate.year - startMonthDate.year) * 12 +
          (currentMonthDate.month - startMonthDate.month) + 1;
      if (monthCount < 1) monthCount = 1;
      if (monthCount > 36) monthCount = 36;

      final generatedMonths = <FeeRecord>[];
      double totalCollected = 0.0;
      double totalDue = 0.0;

      for (int i = 0; i < monthCount; i++) {
        final date = DateTime(currentMonthDate.year, currentMonthDate.month - i, 1);
        final monthKey = FeeService.monthKey(date);

        if (recordMap.containsKey(monthKey)) {
          final r = recordMap[monthKey]!;
          generatedMonths.add(r);
          totalCollected += r.amountPaid;
          totalDue += r.balance;
        } else {
          // Synthetic entry for unrecorded months
          final syntheticDue = _expectedMonthlyFee;
          final syntheticRecord = FeeRecord(
            billingMonth: monthKey,
            studentId: _currentStudent.uid,
            studentName: _currentStudent.name,
            amountDue: syntheticDue,
            amountPaid: 0.0,
            dueDate: DateTime(date.year, date.month, 10),
          );
          generatedMonths.add(syntheticRecord);
          totalDue += syntheticDue;
        }
      }

      // Also include any older recorded months not in the last 6 months
      for (final r in recordedList) {
        if (!generatedMonths.any((g) => g.billingMonth == r.billingMonth)) {
          generatedMonths.add(r);
          totalCollected += r.amountPaid;
          totalDue += r.balance;
        }
      }

      generatedMonths.sort((a, b) => b.billingMonth.compareTo(a.billingMonth));

      if (mounted) {
        _data.setFeeData(
          cards: generatedMonths,
          totalCollected: totalCollected,
          totalDue: totalDue,
        );
      }
    } catch (e) {
      log('Error loading student fee history: $e');
      if (mounted) _data.setLoadingFees(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Exam History Loading
  // ---------------------------------------------------------------------------

  Future<void> _loadExamHistory() async {
    if (!mounted) return;
    _data.setLoadingExams(true);

    try {
      final List<StudentExamSubmissionSummary> summaries = [];
      final studentUid = _currentStudent.uid.trim();
      final inviteCode = _currentStudent.inviteCode?.trim() ?? '';

      // 1. Fetch organization exams
      final orgExamsSnap = await _firestore
          .collection('organizations')
          .doc(widget.orgId)
          .collection('exams')
          .get();

      for (final examDoc in orgExamsSnap.docs) {
        try {
          DocumentSnapshot<Map<String, dynamic>>? subDoc;

          // A. Check by studentUid
          if (studentUid.isNotEmpty) {
            final doc = await examDoc.reference
                .collection('submissions')
                .doc(studentUid)
                .get();
            if (doc.exists && doc.data() != null) {
              subDoc = doc;
            }
          }

          // B. Check by inviteCode / student roll
          if (subDoc == null && inviteCode.isNotEmpty) {
            final doc = await examDoc.reference
                .collection('submissions')
                .doc(inviteCode)
                .get();
            if (doc.exists && doc.data() != null) {
              subDoc = doc;
            }
          }

          // C. Query by student_id or auth_uid in organization exam submissions
          if (subDoc == null && studentUid.isNotEmpty) {
            final q = await examDoc.reference
                .collection('submissions')
                .where('student_id', isEqualTo: studentUid)
                .limit(1)
                .get();
            if (q.docs.isNotEmpty) {
              subDoc = q.docs.first;
            }
          }
          if (subDoc == null && inviteCode.isNotEmpty) {
            final q = await examDoc.reference
                .collection('submissions')
                .where('student_id', isEqualTo: inviteCode)
                .limit(1)
                .get();
            if (q.docs.isNotEmpty) {
              subDoc = q.docs.first;
            }
          }

          // D. Fallback: Check teacher's user collection if not yet in organization
          if (subDoc == null) {
            final examData = examDoc.data();
            final teacherId = (examData['teacher_id'] ??
                    examData['teacherId'] ??
                    '')
                .toString()
                .trim();
            if (teacherId.isNotEmpty) {
              final candIds = [
                if (studentUid.isNotEmpty) studentUid,
                if (inviteCode.isNotEmpty) inviteCode,
              ];
              for (final cId in candIds) {
                final tDoc = await _firestore
                    .collection('user')
                    .doc(teacherId)
                    .collection('exams')
                    .doc(examDoc.id)
                    .collection('submissions')
                    .doc(cId)
                    .get();
                if (tDoc.exists && tDoc.data() != null) {
                  subDoc = tDoc;
                  // Replicate to organization for future instant lookups
                  try {
                    await examDoc.reference
                        .collection('submissions')
                        .doc(studentUid.isNotEmpty ? studentUid : cId)
                        .set(tDoc.data()!);
                  } catch (_) {}
                  break;
                }
              }

              if (subDoc == null && studentUid.isNotEmpty) {
                final q = await _firestore
                    .collection('user')
                    .doc(teacherId)
                    .collection('exams')
                    .doc(examDoc.id)
                    .collection('submissions')
                    .where('student_id', isEqualTo: studentUid)
                    .limit(1)
                    .get();
                if (q.docs.isNotEmpty) {
                  subDoc = q.docs.first;
                  try {
                    await examDoc.reference
                        .collection('submissions')
                        .doc(studentUid)
                        .set(subDoc.data()!);
                  } catch (_) {}
                }
              }
            }
          }

          if (subDoc != null && subDoc.exists && subDoc.data() != null) {
            final subData = subDoc.data()!;
            final examData = examDoc.data();
            final examModel = ExamModel.fromJson(examData);

            summaries.add(
              StudentExamSubmissionSummary(
                examId: examDoc.id,
                examName: (examData['name'] ??
                        examData['exam_name'] ??
                        examModel.examName)
                    .toString(),
                examDate: examModel.examDate,
                startTime: examModel.examStart != null
                    ? DateFormat('hh:mm a').format(examModel.examStart!)
                    : '',
                endTime: examModel.examEnd != null
                    ? DateFormat('hh:mm a').format(examModel.examEnd!)
                    : '',
                batch: (examData['batch'] ??
                        examData['batch_name'] ??
                        examModel.batch)
                    .toString(),
                score: (subData['score'] ?? '0').toString(),
                fullMarks: (examData['full_marks'] ??
                        (examModel.fullMarks.isNotEmpty
                            ? examModel.fullMarks
                            : '100'))
                    .toString(),
                status: (subData['status'] ?? 'Completed').toString(),
                submittedAt: (subData['submitted_at'] is Timestamp)
                    ? (subData['submitted_at'] as Timestamp).toDate()
                    : null,
                submissionData: subData,
                examModel: examModel,
              ),
            );
          }
        } catch (_) {}
      }

      // Sort recent exams first
      summaries.sort((a, b) {
        final aTime = a.submittedAt ?? DateTime(2000);
        final bTime = b.submittedAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        _data.setExamData(summaries);
      }
    } catch (e) {
      log('Error loading student exams: $e');
      if (mounted) {
        _data.setExamError('Failed to load exam history: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  Future<void> _showCollectFeeDialog(FeeRecord record) async {
    final amountCtrl = TextEditingController(
      text: record.balance > 0
          ? record.balance.toStringAsFixed(0)
          : record.amountDue.toStringAsFixed(0),
    );
    final noteCtrl = TextEditingController();
    String selectedMethod = 'Cash';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Collect Fee: ${record.billingMonth}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student: ${_currentStudent.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Amount to Collect (₹):',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment Method:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Online']
                      .map((method) {
                    final isSel = selectedMethod == method;
                    return ChoiceChip(
                      label: Text(method),
                      selected: isSel,
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : const Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (sel) {
                        if (sel) setDialogState(() => selectedMethod = method);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Note / Receipt Ref (Optional):',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Receipt #1045 or UPI Ref',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final parsedAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
    if (parsedAmount <= 0) {
      if (!mounted) return;
      CustomSnackbar.showError(
        context: context,
        title: 'Invalid Amount',
        message: 'Please enter a valid amount greater than ₹0.',
      );
      return;
    }

    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'owner';
      await FeeService.recordPayment(
        orgId: widget.orgId,
        studentId: _currentStudent.uid,
        studentName: _currentStudent.name,
        billingMonth: record.billingMonth,
        amount: parsedAmount,
        paidAt: DateTime.now(),
        method: selectedMethod,
        recordedBy: currentUid,
        note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
        amountDue: record.amountDue > 0 ? record.amountDue : parsedAmount,
      );

      if (!mounted) return;
      CustomSnackbar.showSuccess(
        context: context,
        title: 'Fee Collected',
        message:
            '₹${parsedAmount.toStringAsFixed(0)} collected for ${record.billingMonth}.',
      );
      await _loadFeeHistory();
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.showError(
        context: context,
        title: 'Payment Failed',
        message: 'Error recording payment: $e',
      );
    }
  }

  void _showPaymentDetailsDialog(FeeRecord record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text('Paid: ${record.billingMonth}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dialogRow('Student', _currentStudent.name),
            _dialogRow('Amount Paid', '₹${record.amountPaid.toStringAsFixed(0)}'),
            _dialogRow('Amount Due', '₹${record.amountDue.toStringAsFixed(0)}'),
            _dialogRow('Status', record.status.toUpperCase()),
            if (record.updatedAt != null)
              _dialogRow(
                'Recorded On',
                DateFormat('dd MMM yyyy, hh:mm a').format(record.updatedAt!),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build Method & UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_OwnerStudentProfileData>.value(
      value: _data,
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Student Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Profile',
            onPressed: _loadBatchesAndData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              if (action == 'enroll') {
                _showEnrollDialog();
              } else if (action == 'transfer') {
                _showTransferDialog();
              } else if (action == 'remove') {
                _showRemoveDialog();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'enroll',
                child: Row(
                  children: [
                    Icon(Icons.add_task_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Enroll in Batch'),
                  ],
                ),
              ),
              if (_currentStudent.assignedBatchIds.isNotEmpty) ...[
                const PopupMenuItem(
                  value: 'transfer',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Transfer Batch'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle_outline_rounded,
                          size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove from Batch',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Consumer<_OwnerStudentProfileData>(
                builder: (_, d, __) {
                  final assignedBatchObjects = d.orgBatches
                      .where(
                        (b) => d.currentStudent.assignedBatchIds.contains(b.id),
                      )
                      .toList();
                  return _buildStudentHeader(assignedBatchObjects);
                },
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1D4ED8),
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicatorColor: const Color(0xFF1D4ED8),
                  indicatorWeight: 3,
                  labelStyle:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: [
                    Selector<_OwnerStudentProfileData, int>(
                      selector: (_, d) => d.monthlyFeeCards.length,
                      builder: (_, count, __) => Tab(
                        icon: const Icon(Icons.receipt_long_rounded, size: 20),
                        text: 'Fees History ($count)',
                      ),
                    ),
                    Selector<_OwnerStudentProfileData, int>(
                      selector: (_, d) => d.examHistory.length,
                      builder: (_, count, __) => Tab(
                        icon: const Icon(Icons.analytics_outlined, size: 20),
                        text: 'Exam History ($count)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            Consumer<_OwnerStudentProfileData>(
              builder: (_, __, ___) => _buildFeesTab(),
            ),
            Consumer<_OwnerStudentProfileData>(
              builder: (_, __, ___) => _buildExamsTab(),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Student Identity Header
  // ---------------------------------------------------------------------------

  Widget _buildStudentHeader(List<BatchModel> assignedBatches) {
    final joinDateStr = DateFormat('dd MMM yyyy').format(_currentStudent.joinedAt);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 31,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    _currentStudent.name.isNotEmpty
                        ? _currentStudent.name[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _currentStudent.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _currentStudent.isActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _currentStudent.status.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentStudent.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    if (_currentStudent.phone != null &&
                        _currentStudent.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded,
                              size: 13, color: Colors.white.withOpacity(0.85)),
                          const SizedBox(width: 4),
                          Text(
                            _currentStudent.phone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Enrolled: $joinDateStr • ID: ${_currentStudent.uid.length > 8 ? _currentStudent.uid.substring(0, 8) : _currentStudent.uid}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Assigned Batches Pill Row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enrolled Batches (${assignedBatches.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    InkWell(
                      onTap: _showEnrollDialog,
                      child: const Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Add Batch',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (assignedBatches.isEmpty)
                  const Text(
                    'No batches assigned. Tap "Add Batch" to enroll.',
                    style: TextStyle(fontSize: 11.5, color: Colors.white70),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: assignedBatches.map((b) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${b.name}${b.effectiveSession.isNotEmpty ? " (${b.effectiveSession})" : ""}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: FEES HISTORY VIEW
  // ---------------------------------------------------------------------------

  Widget _buildFeesTab() {
    if (_isLoadingFees) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeeHistory,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Financial Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFinancialMetric(
                    'Monthly Fee',
                    '₹${_expectedMonthlyFee.toStringAsFixed(0)}',
                    const Color(0xFF2563EB),
                    Icons.calendar_month_rounded,
                  ),
                ),
                Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: _buildFinancialMetric(
                    'Total Paid',
                    '₹${_totalFeesCollected.toStringAsFixed(0)}',
                    const Color(0xFF10B981),
                    Icons.check_circle_rounded,
                  ),
                ),
                Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: _buildFinancialMetric(
                    'Total Due',
                    '₹${_totalFeesDue.toStringAsFixed(0)}',
                    const Color(0xFFEF4444),
                    Icons.error_outline_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Monthly Fees Ledger',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Previous months and current month fee records & dues.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Monthly Cards
          if (_monthlyFeeCards.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No fee records available for this student.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ..._monthlyFeeCards.map(_buildFeeCard),
        ],
      ),
    );
  }

  Widget _buildFinancialMetric(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildFeeCard(FeeRecord record) {
    final isPaid = record.status == 'paid';
    final isPartial = record.status == 'partial';
    final isOverdue = record.status == 'overdue';
    final currentKey = FeeService.currentMonthKey;
    final isCurrentMonth = record.billingMonth == currentKey;

    // Parse month name (e.g. "2026-11" -> "November 2026")
    String displayMonth = record.billingMonth;
    try {
      final parts = record.billingMonth.split('-');
      if (parts.length == 2) {
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        displayMonth = DateFormat('MMMM yyyy').format(d);
      }
    } catch (_) {}

    final Color statusColor = isPaid
        ? const Color(0xFF10B981)
        : (isPartial
            ? const Color(0xFFF59E0B)
            : (isOverdue ? const Color(0xFFEF4444) : const Color(0xFFEAB308)));

    final String statusLabel = isPaid
        ? 'PAID'
        : (isPartial
            ? 'PARTIAL'
            : (isOverdue ? 'OVERDUE' : 'PENDING'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid
              ? const Color(0xFFE2E8F0)
              : statusColor.withOpacity(0.4),
          width: isPaid ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Name & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    displayMonth,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (isCurrentMonth) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid
                          ? Icons.check_circle_rounded
                          : Icons.access_time_filled_rounded,
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Amounts breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Amount Due',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    '₹${record.amountDue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Amount Paid',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    '₹${record.amountPaid.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balance Due',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  Text(
                    '₹${record.balance.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: record.balance > 0
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action button
          if (!isPaid)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.payment_rounded, size: 16),
                label: Text(
                  isPartial
                      ? 'Collect Remaining (₹${record.balance.toStringAsFixed(0)})'
                      : 'Collect Fee (₹${record.amountDue.toStringAsFixed(0)})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _showCollectFeeDialog(record),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.receipt_rounded, size: 16),
                label: const Text(
                  'View Payment Receipt',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => _showPaymentDetailsDialog(record),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: EXAM HISTORY VIEW
  // ---------------------------------------------------------------------------

  Widget _buildExamsTab() {
    if (_isLoadingExams) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
      );
    }

    if (_examError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text(_examError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadExamHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_examHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 42,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Exams Attempted',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'This student has not submitted any institute exams yet.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Compute stats
    int totalExams = _examHistory.length;
    double totalScorePct = 0.0;
    double maxPct = 0.0;

    for (final e in _examHistory) {
      final sc = double.tryParse(e.score) ?? 0.0;
      final fm = double.tryParse(e.fullMarks) ?? 100.0;
      final pct = fm > 0 ? (sc / fm) * 100 : 0.0;
      totalScorePct += pct;
      if (pct > maxPct) maxPct = pct;
    }
    final avgPct = totalExams > 0 ? (totalScorePct / totalExams) : 0.0;

    return RefreshIndicator(
      onRefresh: _loadExamHistory,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Exam Stats Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFinancialMetric(
                    'Exams Given',
                    '$totalExams',
                    const Color(0xFF2563EB),
                    Icons.assignment_turned_in_rounded,
                  ),
                ),
                Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: _buildFinancialMetric(
                    'Average Score',
                    '${avgPct.toStringAsFixed(1)}%',
                    const Color(0xFF10B981),
                    Icons.trending_up_rounded,
                  ),
                ),
                Container(width: 1, height: 42, color: const Color(0xFFE2E8F0)),
                Expanded(
                  child: _buildFinancialMetric(
                    'Highest Score',
                    '${maxPct.toStringAsFixed(1)}%',
                    const Color(0xFF8B5CF6),
                    Icons.emoji_events_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Recent Exam Attempts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap on any exam card to view full question marks, chosen answers, and correct answers.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          ..._examHistory.map(_buildExamCard),
        ],
      ),
    );
  }

  Widget _buildExamCard(StudentExamSubmissionSummary summary) {
    final sc = double.tryParse(summary.score) ?? 0.0;
    final fm = double.tryParse(summary.fullMarks) ?? 100.0;
    final pct = fm > 0 ? ((sc / fm) * 100).round() : 0;

    final dateStr = summary.submittedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(summary.submittedAt!)
        : summary.examDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Open full exam review screen with questions & answers breakdown
            Get.to(
              () => OwnerExamResultDetailScreen(
                student: _currentStudent,
                summary: summary,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.quiz_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.examName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pct >= 60
                            ? const Color(0xFFECFDF5)
                            : (pct >= 40
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFFEF2F2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: pct >= 60
                              ? const Color(0xFF15803D)
                              : (pct >= 40
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFFB91C1C)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score: ${summary.score} / ${summary.fullMarks} Marks',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'View Breakdown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Correct / Incorrect / Unattempted badges
                Row(
                  children: [
                    _countBadge(
                      '${summary.correctCount} Correct',
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    _countBadge(
                      '${summary.incorrectCount} Wrong',
                      const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    _countBadge(
                      '${summary.unattemptedCount} Skipped',
                      const Color(0xFF64748B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _countBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Batch Management Dialogs
  // ---------------------------------------------------------------------------

  void _showEnrollDialog() {
    final availableBatches = _orgBatches
        .where((b) => !_currentStudent.assignedBatchIds.contains(b.id) && !b.isArchived)
        .toList();

    if (availableBatches.isEmpty) {
      CustomSnackbar.showInfo(
        context: context,
        title: 'No Batches',
        message: 'No other active batches available to enroll.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Enroll ${_currentStudent.name} in Batch'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: availableBatches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, index) {
              final b = availableBatches[index];
              return ListTile(
                title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Fee: ₹${b.monthlyFee.toStringAsFixed(0)}'),
                trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
                onTap: () async {
                  Navigator.pop(dialogCtx);
                  try {
                    await _orgService.enrollStudentInBatch(
                      orgId: widget.orgId,
                      batchId: b.id,
                      batchName: b.name,
                      studentUid: _currentStudent.uid,
                      studentName: _currentStudent.name,
                      studentEmail: _currentStudent.email,
                    );
                    _currentStudent.assignedBatchIds.add(b.id);
                    _data.notifyBatchesChanged();
                    CustomSnackbar.showSuccess(
                      context: context,
                      title: 'Enrolled',
                      message: '${_currentStudent.name} enrolled in ${b.name}.',
                    );
                    await _loadBatchesAndData();
                  } catch (e) {
                    CustomSnackbar.showError(
                      context: context,
                      title: 'Error',
                      message: 'Enrollment failed: $e',
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTransferDialog() {
    final currentBatches = _orgBatches
        .where((b) => _currentStudent.assignedBatchIds.contains(b.id))
        .toList();
    final otherBatches = _orgBatches
        .where((b) => !_currentStudent.assignedBatchIds.contains(b.id) && !b.isArchived)
        .toList();

    if (currentBatches.isEmpty || otherBatches.isEmpty) {
      CustomSnackbar.showInfo(
        context: context,
        title: 'Transfer Not Possible',
        message: 'No alternative batches available to transfer to.',
      );
      return;
    }

    String fromBatchId = currentBatches.first.id;
    String toBatchId = otherBatches.first.id;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Transfer ${_currentStudent.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('From Batch:'),
              DropdownButton<String>(
                isExpanded: true,
                value: fromBatchId,
                items: currentBatches
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => fromBatchId = v);
                },
              ),
              const SizedBox(height: 12),
              const Text('To Batch:'),
              DropdownButton<String>(
                isExpanded: true,
                value: toBatchId,
                items: otherBatches
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => toBatchId = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final targetBatch = otherBatches.firstWhere((b) => b.id == toBatchId);
                try {
                  await _orgService.transferStudentBatch(
                    orgId: widget.orgId,
                    fromBatchId: fromBatchId,
                    toBatchId: toBatchId,
                    toBatchName: targetBatch.name,
                    studentUid: _currentStudent.uid,
                    studentName: _currentStudent.name,
                    studentEmail: _currentStudent.email,
                  );
                  _currentStudent.assignedBatchIds.remove(fromBatchId);
                  _currentStudent.assignedBatchIds.add(toBatchId);
                  _data.notifyBatchesChanged();
                  CustomSnackbar.showSuccess(
                    context: context,
                    title: 'Transferred',
                    message: '${_currentStudent.name} transferred to ${targetBatch.name}.',
                  );
                  await _loadBatchesAndData();
                } catch (e) {
                  CustomSnackbar.showError(
                    context: context,
                    title: 'Error',
                    message: 'Transfer failed: $e',
                  );
                }
              },
              child: const Text('Transfer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog() {
    final currentBatches = _orgBatches
        .where((b) => _currentStudent.assignedBatchIds.contains(b.id))
        .toList();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Remove ${_currentStudent.name} from Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currentBatches.map((b) {
            return ListTile(
              title: Text(b.name),
              trailing: const Icon(Icons.remove_circle, color: Colors.red),
              onTap: () async {
                Navigator.pop(dialogCtx);
                try {
                  await _orgService.removeStudentFromBatch(
                    orgId: widget.orgId,
                    batchId: b.id,
                    studentUid: _currentStudent.uid,
                  );
                  _currentStudent.assignedBatchIds.remove(b.id);
                  _data.notifyBatchesChanged();
                  CustomSnackbar.showSuccess(
                    context: context,
                    title: 'Removed',
                    message: '${_currentStudent.name} removed from ${b.name}.',
                  );
                  await _loadBatchesAndData();
                } catch (e) {
                  CustomSnackbar.showError(
                    context: context,
                    title: 'Error',
                    message: 'Failed to remove: $e',
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// OwnerExamResultDetailScreen
// Full Question-by-Question breakdown of an exam attempt:
// - Score obtained / Full marks
// - Every question text & options
// - Student's chosen answer
// - Right answer vs Wrong answer highlighted in color
// - Marks scored per question
// =============================================================================

class OwnerExamResultDetailScreen extends StatelessWidget {
  final OrganizationMemberModel student;
  final StudentExamSubmissionSummary summary;

  const OwnerExamResultDetailScreen({
    super.key,
    required this.student,
    required this.summary,
  });

  static String? _getStudentAnswer(Map answersMap, QAModel q, int index) {
    if (answersMap.containsKey(q.id)) {
      return answersMap[q.id]?.toString();
    }
    if (answersMap.containsKey(index.toString())) {
      return answersMap[index.toString()]?.toString();
    }
    if (answersMap.containsKey(index)) {
      return answersMap[index]?.toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final exam = summary.examModel;
    final questions = exam?.questions ?? [];
    final subData = summary.submissionData;

    final Map answersMap = (subData['answers'] is Map)
        ? (subData['answers'] as Map)
        : (subData['answers_by_index'] is Map
            ? (subData['answers_by_index'] as Map)
            : {});

    int correctCount = 0;
    int incorrectCount = 0;
    int unattemptedCount = 0;

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final studentAns = _getStudentAnswer(answersMap, q, i);
      if (studentAns == null || studentAns.trim().isEmpty) {
        unattemptedCount++;
      } else if (studentAns.trim().toUpperCase() == q.ans.trim().toUpperCase()) {
        correctCount++;
      } else {
        incorrectCount++;
      }
    }

    final totalMarks = summary.fullMarks;
    final score = summary.score;
    final dateStr = summary.submittedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(summary.submittedAt!)
        : summary.examDate;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Exam Breakdown',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Score Overview Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        summary.examName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$score / $totalMarks Marks',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Student: ${student.name} • Submitted: $dateStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statBadge('${questions.length}', 'Questions', Colors.white),
                    _statBadge('$correctCount', 'Correct', const Color(0xFF86EFAC)),
                    _statBadge('$incorrectCount', 'Wrong', const Color(0xFFFCA5A5)),
                    _statBadge('$unattemptedCount', 'Skipped', Colors.white70),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Question-by-Question Review',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Detailed answer comparison showing student answers and correct answers.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          if (questions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('No question data available for this exam.'),
              ),
            )
          else
            ...List.generate(questions.length, (index) {
              final q = questions[index];
              final studentAns = _getStudentAnswer(answersMap, q, index);
              return _buildQuestionCard(index + 1, q, studentAns);
            }),
        ],
      ),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int number, QAModel q, String? studentAns) {
    final cleanStudentAns = studentAns?.trim().toUpperCase();
    final cleanCorrectAns = q.ans.trim().toUpperCase();

    final isAttempted = cleanStudentAns != null && cleanStudentAns.isNotEmpty;
    final isCorrect = isAttempted && cleanStudentAns == cleanCorrectAns;

    final Color statusColor = !isAttempted
        ? const Color(0xFF64748B)
        : (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444));

    final String statusLabel = !isAttempted
        ? 'Skipped / Unattempted'
        : (isCorrect ? '✓ Correct Answer' : '✗ Incorrect Answer');

    final options = [
      {'key': 'A', 'text': q.a},
      {'key': 'B', 'text': q.b},
      {'key': 'C', 'text': q.c},
      {'key': 'D', 'text': q.d},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFFBBF7D0)
              : (isAttempted ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Q# & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Question $number',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Question Text
          Text(
            q.q,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          // Options List
          ...options.map((opt) {
            final optKey = opt['key']!;
            final optText = opt['text']!;
            final isChosenByStudent = cleanStudentAns == optKey;
            final isThisCorrectAns = cleanCorrectAns == optKey;

            Color tileBg = const Color(0xFFF8FAFC);
            Color tileBorder = const Color(0xFFE2E8F0);
            Color textColor = const Color(0xFF334155);
            Widget? trailingBadge;

            if (isThisCorrectAns) {
              tileBg = const Color(0xFFF0FDF4);
              tileBorder = const Color(0xFF86EFAC);
              textColor = const Color(0xFF15803D);
              trailingBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Correct Answer',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }

            if (isChosenByStudent && !isCorrect) {
              tileBg = const Color(0xFFFEF2F2);
              tileBorder = const Color(0xFFFCA5A5);
              textColor = const Color(0xFFB91C1C);
              trailingBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Student Choice (Wrong)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            } else if (isChosenByStudent && isCorrect) {
              trailingBadge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Student Choice (Correct)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tileBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: isThisCorrectAns
                        ? const Color(0xFF10B981)
                        : (isChosenByStudent && !isCorrect
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFE2E8F0)),
                    foregroundColor:
                        (isThisCorrectAns || (isChosenByStudent && !isCorrect))
                            ? Colors.white
                            : const Color(0xFF475569),
                    child: Text(
                      optKey,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      optText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (trailingBadge != null) trailingBadge,
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// Sliver TabBar Delegate helper
// =============================================================================
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
