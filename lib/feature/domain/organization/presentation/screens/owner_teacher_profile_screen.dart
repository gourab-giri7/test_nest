import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/services/organization_service.dart';
import 'package:test_nest/core/services/teacher_salary_service.dart';
import 'package:test_nest/core/utils/custom_snackbar.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/organization_model.dart';
import 'package:test_nest/model/teacher_salary_model.dart';

class _OwnerTeacherProfileData extends ChangeNotifier {
  OrganizationMemberModel currentTeacher;
  List<BatchModel> orgBatches = [];

  bool isLoadingSalaries = false;
  List<TeacherSalaryModel> monthlySalaryCards = [];
  double configuredBaseSalary;
  double totalSalaryPaid = 0.0;
  double totalSalaryPending = 0.0;

  bool isLoadingExams = false;
  String? examError;
  List<ExamModel> teacherExams = [];

  _OwnerTeacherProfileData({
    required this.currentTeacher,
    required this.configuredBaseSalary,
  });

  void setOrgBatches(List<BatchModel> batches) {
    orgBatches = batches;
    notifyListeners();
  }

  void setLoadingSalaries(bool val) {
    isLoadingSalaries = val;
    notifyListeners();
  }

  void setSalaryData({
    required List<TeacherSalaryModel> cards,
    required double totalPaid,
    required double totalPending,
  }) {
    monthlySalaryCards = cards;
    totalSalaryPaid = totalPaid;
    totalSalaryPending = totalPending;
    isLoadingSalaries = false;
    notifyListeners();
  }

  void setLoadingExams(bool val) {
    isLoadingExams = val;
    if (val) examError = null;
    notifyListeners();
  }

  void setExamData(List<ExamModel> exams) {
    teacherExams = exams;
    isLoadingExams = false;
    notifyListeners();
  }

  void setExamError(String err) {
    examError = err;
    isLoadingExams = false;
    notifyListeners();
  }

  void updateBaseSalary(double newBase) {
    configuredBaseSalary = newBase;
    currentTeacher = currentTeacher.copyWith(monthlySalary: newBase);
    notifyListeners();
  }

  void updateTeacher(OrganizationMemberModel updated) {
    currentTeacher = updated;
    notifyListeners();
  }
}

class OwnerTeacherProfileScreen extends StatefulWidget {
  final OrganizationMemberModel teacher;
  final String orgId;
  final FirebaseFirestore? firestore;
  final bool autoLoad;

  const OwnerTeacherProfileScreen({
    super.key,
    required this.teacher,
    required this.orgId,
    this.firestore,
    this.autoLoad = true,
  });

  @override
  State<OwnerTeacherProfileScreen> createState() =>
      _OwnerTeacherProfileScreenState();
}

class _OwnerTeacherProfileScreenState extends State<OwnerTeacherProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrganizationService _orgService = OrganizationService();
  final TeacherSalaryService _salaryService = TeacherSalaryService();

  FirebaseFirestore get _firestore {
    if (widget.firestore != null) return widget.firestore!;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null as dynamic;
    }
  }

  late final _OwnerTeacherProfileData _data;

  OrganizationMemberModel get _currentTeacher => _data.currentTeacher;
  List<BatchModel> get _orgBatches => _data.orgBatches;
  bool get _isLoadingSalaries => _data.isLoadingSalaries;
  List<TeacherSalaryModel> get _monthlySalaryCards => _data.monthlySalaryCards;
  double get _configuredBaseSalary => _data.configuredBaseSalary;
  double get _totalSalaryPaid => _data.totalSalaryPaid;
  double get _totalSalaryPending => _data.totalSalaryPending;
  bool get _isLoadingExams => _data.isLoadingExams;
  String? get _examError => _data.examError;
  List<ExamModel> get _teacherExams => _data.teacherExams;

  @override
  void initState() {
    super.initState();
    _data = _OwnerTeacherProfileData(
      currentTeacher: widget.teacher,
      configuredBaseSalary: widget.teacher.monthlySalary ?? 0.0,
    );
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
    await Future.wait([_loadSalaryHistory(), _loadExamHistory()]);
  }

  Future<void> _loadBatches() async {
    try {
      final snap = await _firestore
          .collection('organizations')
          .doc(widget.orgId)
          .collection('batches')
          .get();
      if (mounted) {
        _data.setOrgBatches(
          snap.docs
              .map((d) => BatchModel.fromJson(d.data(), docId: d.id))
              .toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> _loadSalaryHistory() async {
    _data.setLoadingSalaries(true);
    try {
      final records = await _salaryService.fetchSalaryHistory(
        orgId: widget.orgId,
        teacherUid: _currentTeacher.uid,
      );

      final Map<String, TeacherSalaryModel> recordMap = {
        for (final r in records) r.month: r,
      };

      // Salary history starts from the month the teacher joined the institute
      final List<TeacherSalaryModel> cards = [];
      final now = DateTime.now();
      final currentMonthDate = DateTime(now.year, now.month, 1);
      final joinDate = _currentTeacher.joinedAt;
      final startMonthDate = DateTime(joinDate.year, joinDate.month, 1);

      int monthCount = (currentMonthDate.year - startMonthDate.year) * 12 +
          (currentMonthDate.month - startMonthDate.month) + 1;
      if (monthCount < 1) monthCount = 1;
      if (monthCount > 36) monthCount = 36;

      double totalPaid = 0.0;
      double totalDue = 0.0;

      for (int i = 0; i < monthCount; i++) {
        final d = DateTime(currentMonthDate.year, currentMonthDate.month - i, 1);
        final monthKey = DateFormat('yyyy-MM').format(d);

        if (recordMap.containsKey(monthKey)) {
          final rec = recordMap[monthKey]!;
          cards.add(rec);
          totalPaid += rec.amountPaid;
          totalDue += rec.balanceDue;
        } else {
          // Synthetic pending month
          final synth = TeacherSalaryModel(
            id: '${_currentTeacher.uid}_$monthKey',
            orgId: widget.orgId,
            teacherUid: _currentTeacher.uid,
            teacherName: _currentTeacher.name,
            month: monthKey,
            amount: _configuredBaseSalary,
            baseSalary: _configuredBaseSalary,
            amountPaid: 0.0,
            status: _configuredBaseSalary > 0
                ? 'pending'
                : 'paid',
          );
          cards.add(synth);
          if (_configuredBaseSalary > 0) {
            totalDue += _configuredBaseSalary;
          }
        }
      }

      if (mounted) {
        _data.setSalaryData(
          cards: cards,
          totalPaid: totalPaid,
          totalPending: totalDue,
        );
      }
    } catch (e) {
      if (mounted) {
        _data.setLoadingSalaries(false);
      }
    }
  }

  Future<void> _loadExamHistory() async {
    _data.setLoadingExams(true);

    try {
      final List<ExamModel> exams = [];
      final tUid = _currentTeacher.uid.trim();

      // Query from organizations/{orgId}/exams
      try {
        final snap = await _firestore
            .collection('organizations')
            .doc(widget.orgId)
            .collection('exams')
            .where('teacher_id', isEqualTo: tUid)
            .get();

        for (final doc in snap.docs) {
          exams.add(ExamModel.fromJson(doc.data(), teacherId: tUid));
        }
      } catch (_) {}

      // Query from user/{teacherUid}/exams
      try {
        final snapTeacher = await _firestore
            .collection('user')
            .doc(tUid)
            .collection('exams')
            .get();

        for (final doc in snapTeacher.docs) {
          if (!exams.any((e) => e.examId == doc.id)) {
            exams.add(ExamModel.fromJson(doc.data(), teacherId: tUid));
          }
        }
      } catch (_) {}

      exams.sort((a, b) {
        final dateA = a.examStart ?? a.createdAt ?? DateTime(2000);
        final dateB = b.examStart ?? b.createdAt ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        _data.setExamData(exams);
      }
    } catch (e) {
      if (mounted) {
        _data.setExamError('Failed to load exam history: $e');
      }
    }
  }

  void _recordSalaryDisbursement(TeacherSalaryModel monthModel) {
    final amountController = TextEditingController(
      text: monthModel.balanceDue > 0
          ? monthModel.balanceDue.toStringAsFixed(0)
          : (monthModel.baseSalary > 0
              ? monthModel.baseSalary.toStringAsFixed(0)
              : _configuredBaseSalary.toStringAsFixed(0)),
    );
    final refController = TextEditingController();
    final remarksController = TextEditingController();
    String selectedMethod = 'UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Disburse Salary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Month: ${monthModel.displayMonth} • ${_currentTeacher.name}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Disbursement Amount (₹)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Payment Mode',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    items: const [
                      DropdownMenuItem(value: 'UPI', child: Text('UPI / GPay / PhonePe')),
                      DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer (NEFT/IMPS)')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedMethod = v);
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Transaction Ref / Cheque No. (Optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: refController,
                    decoration: InputDecoration(
                      hintText: 'e.g. UPI-92817291 or CHQ-00192',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Remarks / Notes (Optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      hintText: 'Monthly salary disbursement',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (amt <= 0) {
                          CustomSnackbar.showError(
                            context: context,
                            message: 'Please enter a valid amount',
                          );
                          return;
                        }

                        Navigator.pop(sheetCtx);
                        final currentAuth = FirebaseAuth.instance.currentUser;
                        final processedBy = currentAuth?.uid ?? 'owner';

                        try {
                          await _salaryService.recordPayment(
                            orgId: widget.orgId,
                            teacherUid: _currentTeacher.uid,
                            teacherName: _currentTeacher.name,
                            billingMonth: monthModel.month,
                            amount: amt,
                            paymentDate: DateTime.now(),
                            paymentMethod: selectedMethod,
                            referenceNumber: refController.text.trim().isNotEmpty
                                ? refController.text.trim()
                                : null,
                            note: remarksController.text.trim().isNotEmpty
                                ? remarksController.text.trim()
                                : null,
                            recordedBy: processedBy,
                            baseSalary: monthModel.baseSalary > 0
                                ? monthModel.baseSalary
                                : (_configuredBaseSalary > 0
                                    ? _configuredBaseSalary
                                    : null),
                          );

                          CustomSnackbar.showSuccess(
                            context: context,
                            title: 'Salary Recorded',
                            message: '₹${amt.toStringAsFixed(0)} disbursed to ${_currentTeacher.name} for ${monthModel.displayMonth}.',
                          );

                          _loadSalaryHistory();
                        } catch (e) {
                          CustomSnackbar.showError(
                            context: context,
                            title: 'Error',
                            message: 'Failed to disburse salary: $e',
                          );
                        }
                      },
                      child: const Text(
                        'Confirm Disbursement',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConfigureBaseSalaryDialog() {
    final ctrl = TextEditingController(
      text: _configuredBaseSalary > 0
          ? _configuredBaseSalary.toStringAsFixed(0)
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Configure Base Salary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set the ongoing monthly compensation for ${_currentTeacher.name}. Past historical salary disbursements are permanently protected.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Salary (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newBase = double.tryParse(ctrl.text.trim()) ?? 0.0;
                Navigator.pop(ctx);
                try {
                  await _salaryService.setTeacherBaseSalary(
                    orgId: widget.orgId,
                    teacherUid: _currentTeacher.uid,
                    baseSalary: newBase,
                  );

                  _data.updateBaseSalary(newBase);
                  _loadSalaryHistory();

                  CustomSnackbar.showSuccess(
                    context: context,
                    title: 'Salary Configured',
                    message: 'Monthly salary updated to ₹${newBase.toStringAsFixed(0)}.',
                  );

                  _loadSalaryHistory();
                } catch (e) {
                  CustomSnackbar.showError(
                    context: context,
                    message: 'Failed to update base salary: $e',
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showManageBatchesDialog() {
    final selectedBatchIds = Set<String>.from(_currentTeacher.assignedBatchIds);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Manage Assigned Batches'),
              content: SizedBox(
                width: double.maxFinite,
                child: _orgBatches.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No batches available in this institute.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _orgBatches.length,
                        itemBuilder: (context, index) {
                          final b = _orgBatches[index];
                          final isAssigned = selectedBatchIds.contains(b.id);
                          return CheckboxListTile(
                            title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('ID: ${b.id} • ${b.studentCount} students'),
                            value: isAssigned,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedBatchIds.add(b.id);
                                } else {
                                  selectedBatchIds.remove(b.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    try {
                      await _firestore
                          .collection('organizations')
                          .doc(widget.orgId)
                          .collection('members')
                          .doc(_currentTeacher.uid)
                          .update({
                        'assignedBatchIds': selectedBatchIds.toList(),
                      });

                      _data.updateTeacher(
                        _currentTeacher.copyWith(
                          assignedBatchIds: selectedBatchIds.toList(),
                        ),
                      );

                      CustomSnackbar.showSuccess(
                        context: context,
                        title: 'Batches Updated',
                        message: 'Assigned batches updated for ${_currentTeacher.name}.',
                      );
                    } catch (e) {
                      CustomSnackbar.showError(
                        context: context,
                        message: 'Failed to update batches: $e',
                      );
                    }
                  },
                  child: const Text('Save Assignments'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExamDetailsModal(ExamModel exam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          height: MediaQuery.of(sheetCtx).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.examName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Batch: ${exam.batch} • Full Marks: ${exam.fullMarks}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoBadge('${exam.questions.length}', 'Questions', const Color(0xFF2563EB)),
                  _infoBadge(exam.fullMarks, 'Full Marks', const Color(0xFF059669)),
                  _infoBadge(exam.status, 'Status', const Color(0xFF7C3AED)),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Assigned Schedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Date: ${exam.examDate} (${exam.startTime} - ${exam.endTime})',
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              if (exam.instruction.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Instructions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  exam.instruction,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Assigned Students (${exam.assignedStudentIds.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: exam.assignedStudentIds.isEmpty
                    ? const Center(
                        child: Text(
                          'Open to all batch members.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: exam.assignedStudentIds.length,
                        itemBuilder: (ctx, i) {
                          return ListTile(
                            dense: true,
                            leading: const CircleAvatar(
                              radius: 14,
                              child: Icon(Icons.person, size: 16),
                            ),
                            title: Text('Student ID: ${exam.assignedStudentIds[i]}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoBadge(String val, String label, Color col) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: col,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_OwnerTeacherProfileData>.value(
      value: _data,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                title: Selector<_OwnerTeacherProfileData, String>(
                  selector: (_, d) => d.currentTeacher.name,
                  builder: (_, name, __) => Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Consumer<_OwnerTeacherProfileData>(
                    builder: (_, d, __) {
                      final assignedBatches = _orgBatches
                          .where(
                            (b) => _currentTeacher.assignedBatchIds.contains(
                              b.id,
                            ),
                          )
                          .toList();
                      return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  _currentTeacher.name.isNotEmpty
                                      ? _currentTeacher.name[0].toUpperCase()
                                      : 'T',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentTeacher.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentTeacher.email,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                    if (_currentTeacher.phone != null &&
                                        _currentTeacher.phone!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _currentTeacher.phone!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _currentTeacher.status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (_currentTeacher.subject != null &&
                                  _currentTeacher.subject!.isNotEmpty)
                                _tagChip(Icons.book_outlined, _currentTeacher.subject!),
                              _tagChip(
                                Icons.calendar_today_outlined,
                                'Joined ${DateFormat('MMM yyyy').format(_currentTeacher.joinedAt)}',
                              ),
                              if (_configuredBaseSalary > 0)
                                _tagChip(
                                  Icons.currency_rupee,
                                  '₹${_configuredBaseSalary.toStringAsFixed(0)}/mo',
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1D4ED8),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.class_outlined, size: 14),
                                label: const Text('Manage Batches', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: _showManageBatchesDialog,
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.currency_rupee, size: 14),
                                label: const Text('Set Salary', style: TextStyle(fontSize: 12)),
                                onPressed: _showConfigureBaseSalaryDialog,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                    },
                  ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TeacherSliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF1D4ED8),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF1D4ED8),
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.currency_rupee, size: 18),
                      text: 'Salary History',
                    ),
                    Tab(
                      icon: Icon(Icons.assignment_outlined, size: 18),
                      text: 'Exam History',
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
            Consumer<_OwnerTeacherProfileData>(
              builder: (_, __, ___) => _buildSalaryTab(),
            ),
            Consumer<_OwnerTeacherProfileData>(
              builder: (_, __, ___) => _buildExamsTab(),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _tagChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryTab() {
    if (_isLoadingSalaries) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Salary Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Salary Ledger Summary',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    onPressed: _loadSalaryHistory,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metricBox(
                      'Base Monthly',
                      '₹${_configuredBaseSalary.toStringAsFixed(0)}',
                      const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricBox(
                      'Total Paid',
                      '₹${_totalSalaryPaid.toStringAsFixed(0)}',
                      const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricBox(
                      'Total Pending',
                      '₹${_totalSalaryPending.toStringAsFixed(0)}',
                      _totalSalaryPending > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Monthly Compensation History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '${_monthlySalaryCards.length} months',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_monthlySalaryCards.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No salary records available for this faculty member.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          ..._monthlySalaryCards.map((monthCard) => _buildSalaryMonthCard(monthCard)),
      ],
    );
  }

  Widget _metricBox(String title, String val, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: col.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, color: col, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: col,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryMonthCard(TeacherSalaryModel card) {
    final isPaid = card.isPaid;
    final isPartial = card.isPartial;

    final Color statusColor = isPaid
        ? const Color(0xFF16A34A)
        : (isPartial ? const Color(0xFFD97706) : const Color(0xFFDC2626));
    final String statusLabel = isPaid
        ? 'PAID'
        : (isPartial ? 'PARTIAL' : 'PENDING');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.displayMonth,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Base Salary',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '₹${card.baseSalary.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paid',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '₹${card.amountPaid.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: card.amountPaid > 0 ? const Color(0xFF16A34A) : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Due / Balance',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '₹${card.balanceDue.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: card.balanceDue > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (card.payments.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Disbursements (${card.payments.length})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            ...card.payments.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${p.amount.toStringAsFixed(0)} via ${p.method}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(p.paymentDate),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )),
          ],
          if (!isPaid) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.payment, size: 14),
                label: const Text('Disburse Payment', style: TextStyle(fontSize: 12)),
                onPressed: () => _recordSalaryDisbursement(card),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExamsTab() {
    if (_isLoadingExams) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_examError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
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

    final totalQuestions = _teacherExams.fold<int>(
      0,
      (sum, e) => sum + e.questions.length,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Exam Performance Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Faculty Exam Portfolio',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    onPressed: _loadExamHistory,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metricBox(
                      'Published Exams',
                      '${_teacherExams.length}',
                      const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricBox(
                      'Total Questions',
                      '$totalQuestions',
                      const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metricBox(
                      'Assigned Batches',
                      '${_currentTeacher.assignedBatchIds.length}',
                      const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Published Exam History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '${_teacherExams.length} exams',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_teacherExams.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No exams published by this teacher yet.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          ..._teacherExams.map((exam) => _buildTeacherExamCard(exam)),
      ],
    );
  }

  Widget _buildTeacherExamCard(ExamModel exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showExamDetailsModal(exam),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exam.examName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      exam.status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.class_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      exam.batch.isNotEmpty ? exam.batch : 'All batches',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    exam.examDate,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statPill(Icons.quiz_outlined, '${exam.questions.length} Questions'),
                  const SizedBox(width: 8),
                  _statPill(Icons.stars_outlined, '${exam.fullMarks} Marks'),
                  const SizedBox(width: 8),
                  _statPill(Icons.people_outline, '${exam.assignedStudentIds.length} Students'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF475569)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherSliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TeacherSliverTabBarDelegate(this.tabBar);

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
  bool shouldRebuild(_TeacherSliverTabBarDelegate oldDelegate) {
    return false;
  }
}
