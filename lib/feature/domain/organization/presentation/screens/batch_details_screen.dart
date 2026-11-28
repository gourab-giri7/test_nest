import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/services/batch_assignment_service.dart';
import 'package:test_nest/core/services/organization_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/core/utils/custom_snackbar.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/widgets/batch_qr_code_dialog.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/batch_student_model.dart';
import 'package:test_nest/model/organization_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class BatchDetailsScreen extends StatefulWidget {
  final String orgId;
  final BatchModel batch;

  const BatchDetailsScreen({
    super.key,
    required this.orgId,
    required this.batch,
  });

  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsData extends ChangeNotifier {
  BatchModel currentBatch;

  _BatchDetailsData(this.currentBatch);

  void updateBatch(BatchModel batch) {
    currentBatch = batch;
    notifyListeners();
  }
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen>
    with SingleTickerProviderStateMixin {
  final OrganizationService _orgService = OrganizationService();
  final BatchAssignmentService _assignmentService = BatchAssignmentService();

  late TabController _tabController;
  late final _BatchDetailsData _data;

  BatchModel get _currentBatch => _data.currentBatch;

  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _surface = Colors.white;

  @override
  void initState() {
    super.initState();
    _data = _BatchDetailsData(widget.batch);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_BatchDetailsData>.value(
      value: _data,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Selector<_BatchDetailsData, String>(
            selector: (_, d) => d.currentBatch.name,
            builder: (_, name, __) => Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          backgroundColor: _surface,
          foregroundColor: _ink,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Edit Batch',
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: _showEditBatchDialog,
            ),
            IconButton(
              tooltip: 'Delete Batch',
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _confirmDeleteBatch,
            ),
          ],
        ),
        body: Column(
          children: [
            Consumer<_BatchDetailsData>(
              builder: (_, __, ___) => _buildBatchInfoCard(),
            ),
          Container(
            color: _surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: _muted,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.assignment_ind_outlined, size: 20),
                  text: 'Assigned Teachers',
                ),
                Tab(
                  icon: Icon(Icons.school_outlined, size: 20),
                  text: 'Enrolled Students',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Consumer<_BatchDetailsData>(
                  builder: (_, __, ___) => _buildAssignedTeachersTab(),
                ),
                Consumer<_BatchDetailsData>(
                  builder: (_, __, ___) => _buildEnrolledStudentsTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  // ── Batch Overview Card ───────────────────────────────────────────────────

  Widget _buildBatchInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentBatch.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    if (_currentBatch.subject != null &&
                        _currentBatch.subject!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Subject: ${_currentBatch.subject}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _muted,
                          ),
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
                  color: _currentBatch.isArchived
                      ? Colors.grey.shade100
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentBatch.isArchived ? 'Archived' : 'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _currentBatch.isArchived
                        ? Colors.grey.shade600
                        : const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          if (_currentBatch.schedule != null &&
              _currentBatch.schedule!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: _muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _currentBatch.schedule!,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ),
              ],
            ),
          ],
          if (_currentBatch.description != null &&
              _currentBatch.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _currentBatch.description!,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatChip(
                Icons.people_alt_outlined,
                '${_currentBatch.studentCount} Students',
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                Icons.person_pin_outlined,
                '${_currentBatch.assignedTeacherIds.length} Teachers',
              ),
              if (_currentBatch.monthlyFee > 0) ...[
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.currency_rupee,
                  '₹${_currentBatch.monthlyFee.toInt()}/mo',
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.vpn_key_rounded, size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  'Join Code: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  _currentBatch.activeJoinCode.isNotEmpty
                      ? _currentBatch.activeJoinCode
                      : _currentBatch.id,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    final code = _currentBatch.activeJoinCode.isNotEmpty
                        ? _currentBatch.activeJoinCode
                        : _currentBatch.id;
                    Clipboard.setData(ClipboardData(text: code));
                    CustomSnackbar.showSuccess(
                      context: context,
                      title: 'Copied',
                      message: 'Batch join code $code copied',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text('Show QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => BatchQrCodeDialog.show(context, _currentBatch),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Assign Teacher'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: _showAssignTeacherSheet,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.group_add_outlined, size: 16),
                label: const Text('Enroll Student'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: _showEnrollStudentSheet,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.fact_check_outlined, size: 16),
                label: const Text('Attendance'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D9488),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => Get.toNamed(
                  AppRoutes.batchAttendance,
                  arguments: {
                    'batchId': _currentBatch.id,
                    'batchName': _currentBatch.name,
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Assigned Teachers ──────────────────────────────────────────────

  Widget _buildAssignedTeachersTab() {
    return StreamBuilder<List<OrganizationMemberModel>>(
      stream: _orgService.streamOrganizationMembers(widget.orgId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allMembers = snapshot.data ?? [];
        final assignedTeachers = allMembers
            .where(
              (m) =>
                  (m.isTeacher || m.isAdmin) &&
                  _currentBatch.assignedTeacherIds.contains(m.uid),
            )
            .toList();

        if (assignedTeachers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 44,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No teachers assigned to this batch yet.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Assign Teacher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _showAssignTeacherSheet,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: assignedTeachers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final teacher = assignedTeachers[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _line),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEFF6FF),
                    foregroundColor: AppColors.primary,
                    child: Text(
                      teacher.name.isNotEmpty
                          ? teacher.name[0].toUpperCase()
                          : 'T',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        Text(
                          teacher.email,
                          style: const TextStyle(fontSize: 12, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove from batch',
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () => _confirmRemoveTeacher(teacher),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Tab 2: Enrolled Students ──────────────────────────────────────────────

  Widget _buildEnrolledStudentsTab() {
    return StreamBuilder<List<BatchStudentModel>>(
      stream: _orgService.streamBatchStudents(widget.orgId, _currentBatch.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final students = snapshot.data ?? [];
        if (students.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 44,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No students enrolled in this batch.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.group_add_outlined, size: 16),
                    label: const Text('Enroll Student'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _showEnrollStudentSheet,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final student = students[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _line),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF0FDF4),
                    foregroundColor: const Color(0xFF16A34A),
                    child: Text(
                      student.studentName.isNotEmpty
                          ? student.studentName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.studentName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        Text(
                          student.studentEmail,
                          style: const TextStyle(fontSize: 12, color: _muted),
                        ),
                        if (student.studentPhone != null &&
                            student.studentPhone!.isNotEmpty)
                          Text(
                            student.studentPhone!,
                            style: const TextStyle(fontSize: 11, color: _muted),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: _muted),
                    onSelected: (action) {
                      if (action == 'transfer') {
                        _showTransferStudentDialog(student);
                      } else if (action == 'remove') {
                        _confirmRemoveStudent(student);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'transfer',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz, size: 18),
                            SizedBox(width: 8),
                            Text('Transfer Batch'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_remove_outlined,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Remove from Batch',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Actions & Dialogs ─────────────────────────────────────────────────────

  void _showAssignTeacherSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StreamBuilder<List<OrganizationMemberModel>>(
          stream: _orgService.streamOrganizationMembers(widget.orgId),
          builder: (context, snapshot) {
            final teachers = (snapshot.data ?? [])
                .where((m) => m.isTeacher || m.isAdmin)
                .toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign Teacher to Batch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (teachers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No teachers found in institute.'),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: teachers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final t = teachers[index];
                            final isAssigned = _currentBatch.assignedTeacherIds
                                .contains(t.uid);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(
                                  t.name.isNotEmpty
                                      ? t.name[0].toUpperCase()
                                      : 'T',
                                ),
                              ),
                              title: Text(t.name),
                              subtitle: Text(t.email),
                              trailing: isAssigned
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _assignTeacher(t);
                                      },
                                      child: const Text('Assign'),
                                    ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _assignTeacher(OrganizationMemberModel teacher) async {
    try {
      await _assignmentService.assignTeacherToBatch(
        orgId: widget.orgId,
        batchId: _currentBatch.id,
        teacherUid: teacher.uid,
      );
      final currentList = List<String>.from(_currentBatch.assignedTeacherIds);
      if (!currentList.contains(teacher.uid)) {
        currentList.add(teacher.uid);
      }
      _data.updateBatch(
        _currentBatch.copyWith(assignedTeacherIds: currentList),
      );
      CustomSnackbar.showSuccess(
        context: context,
        title: 'Teacher Assigned',
        message: '${teacher.name} has been assigned to ${_currentBatch.name}.',
      );
    } catch (e) {
      CustomSnackbar.showError(
        context: context,
        title: 'Error',
        message: 'Failed to assign teacher: $e',
      );
    }
  }

  void _confirmRemoveTeacher(OrganizationMemberModel teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Teacher from Batch?'),
        content: Text(
          'Are you sure you want to remove ${teacher.name} from ${_currentBatch.name}? '
          'Their organization membership and other batch assignments will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _assignmentService.removeTeacherFromBatch(
                  orgId: widget.orgId,
                  batchId: _currentBatch.id,
                  teacherUid: teacher.uid,
                );
                final currentList = List<String>.from(
                  _currentBatch.assignedTeacherIds,
                );
                currentList.remove(teacher.uid);
                _data.updateBatch(
                  _currentBatch.copyWith(assignedTeacherIds: currentList),
                );
                CustomSnackbar.showSuccess(
                  context: context,
                  title: 'Removed',
                  message: '${teacher.name} removed from batch.',
                );
              } catch (e) {
                CustomSnackbar.showError(
                  context: context,
                  title: 'Error',
                  message: 'Failed to remove teacher: $e',
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEnrollStudentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StreamBuilder<List<OrganizationMemberModel>>(
          stream: _orgService.streamInstituteStudents(widget.orgId),
          builder: (context, snapshot) {
            final students = snapshot.data ?? [];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enroll Institute Student',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (students.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No students in the institute directory yet. '
                          'Approve student join requests to add students.',
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: students.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final s = students[index];
                            final isEnrolled = s.assignedBatchIds.contains(
                              _currentBatch.id,
                            );

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFF0FDF4),
                                child: Text(
                                  s.name.isNotEmpty
                                      ? s.name[0].toUpperCase()
                                      : 'S',
                                ),
                              ),
                              title: Text(s.name),
                              subtitle: Text(s.email),
                              trailing: isEnrolled
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _enrollStudent(s);
                                      },
                                      child: const Text('Enroll'),
                                    ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _enrollStudent(OrganizationMemberModel student) async {
    try {
      await _orgService.enrollStudentInBatch(
        orgId: widget.orgId,
        batchId: _currentBatch.id,
        batchName: _currentBatch.name,
        studentUid: student.uid,
        studentName: student.name,
        studentEmail: student.email,
      );
      _data.updateBatch(
        _currentBatch.copyWith(studentCount: _currentBatch.studentCount + 1),
      );
      CustomSnackbar.showSuccess(
        context: context,
        title: 'Student Enrolled',
        message: '${student.name} enrolled in ${_currentBatch.name}.',
      );
    } catch (e) {
      CustomSnackbar.showError(
        context: context,
        title: 'Error',
        message: 'Failed to enroll student: $e',
      );
    }
  }

  void _confirmRemoveStudent(BatchStudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student from Batch?'),
        content: Text(
          'Remove ${student.studentName} from ${_currentBatch.name}? '
          'The student will remain an organization member.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _orgService.removeStudentFromBatch(
                  orgId: widget.orgId,
                  batchId: _currentBatch.id,
                  studentUid: student.studentUid,
                );
                _data.updateBatch(
                  _currentBatch.copyWith(
                    studentCount: (_currentBatch.studentCount - 1).clamp(
                      0,
                      9999,
                    ),
                  ),
                );
                CustomSnackbar.showSuccess(
                  context: context,
                  title: 'Student Removed',
                  message: '${student.studentName} removed from batch.',
                );
              } catch (e) {
                CustomSnackbar.showError(
                  context: context,
                  title: 'Error',
                  message: 'Failed to remove student: $e',
                );
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTransferStudentDialog(BatchStudentModel student) {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<List<BatchModel>>(
          stream: _orgService.streamInstituteBatches(widget.orgId),
          builder: (context, snapshot) {
            final otherBatches = (snapshot.data ?? [])
                .where((b) => b.id != _currentBatch.id && !b.isArchived)
                .toList();

            return AlertDialog(
              title: const Text('Transfer Student'),
              content: otherBatches.isEmpty
                  ? const Text(
                      'No other active batches available to transfer to.',
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transfer ${student.studentName} to another batch:',
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: otherBatches.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final b = otherBatches[index];
                                return ListTile(
                                  title: Text(b.name),
                                  subtitle: Text(b.subject ?? ''),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await _transferStudent(student, b);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _transferStudent(
    BatchStudentModel student,
    BatchModel targetBatch,
  ) async {
    try {
      await _orgService.transferStudentBatch(
        orgId: widget.orgId,
        fromBatchId: _currentBatch.id,
        toBatchId: targetBatch.id,
        toBatchName: targetBatch.name,
        studentUid: student.studentUid,
        studentName: student.studentName,
        studentEmail: student.studentEmail,
        studentPhone: student.studentPhone ?? '',
      );
      _data.updateBatch(
        _currentBatch.copyWith(
          studentCount: (_currentBatch.studentCount - 1).clamp(0, 9999),
        ),
      );
      CustomSnackbar.showSuccess(
        context: context,
        title: 'Transferred',
        message:
            '${student.studentName} successfully transferred to ${targetBatch.name}.',
      );
    } catch (e) {
      CustomSnackbar.showError(
        context: context,
        title: 'Error',
        message: 'Failed to transfer student: $e',
      );
    }
  }

  void _showEditBatchDialog() {
    final nameCtrl = TextEditingController(text: _currentBatch.name);
    final subjectCtrl = TextEditingController(
      text: _currentBatch.subject ?? '',
    );
    final scheduleCtrl = TextEditingController(
      text: _currentBatch.schedule ?? '',
    );
    final descCtrl = TextEditingController(
      text: _currentBatch.description ?? '',
    );
    final feeCtrl = TextEditingController(
      text: _currentBatch.monthlyFee > 0
          ? _currentBatch.monthlyFee.toStringAsFixed(0)
          : '',
    );
    bool feeEnabled = _currentBatch.feeTrackingEnabled;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Batch Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Batch Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: scheduleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Schedule (e.g. Mon, Wed 4 PM)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Fee (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                if (newName.isEmpty) return;
                Navigator.pop(context);
                final newFee = double.tryParse(feeCtrl.text.trim()) ?? 0.0;
                try {
                  await _orgService.updateInstituteBatch(
                    orgId: widget.orgId,
                    batchId: _currentBatch.id,
                    name: newName,
                    subject: subjectCtrl.text.trim(),
                    schedule: scheduleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    monthlyFee: newFee,
                    feeTrackingEnabled: feeEnabled,
                  );
                  _data.updateBatch(
                    _currentBatch.copyWith(
                      name: newName,
                      subject: subjectCtrl.text.trim(),
                      schedule: scheduleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      monthlyFee: newFee,
                    ),
                  );
                  CustomSnackbar.showSuccess(
                    context: context,
                    title: 'Batch Updated',
                    message: 'Batch details have been updated.',
                  );
                } catch (e) {
                  CustomSnackbar.showError(
                    context: context,
                    title: 'Error',
                    message: 'Failed to update batch: $e',
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteBatch() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Batch?'),
        content: Text(
          'Are you sure you want to delete "${_currentBatch.name}"?\n\n'
          'This will permanently remove the batch and unenroll all students. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _orgService.deleteInstituteBatch(
                  orgId: widget.orgId,
                  batchId: _currentBatch.id,
                );
                if (mounted) {
                  CustomSnackbar.showSuccess(
                    context: context,
                    title: 'Batch Deleted',
                    message: 'Batch "${_currentBatch.name}" was successfully deleted.',
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  CustomSnackbar.showError(
                    context: context,
                    title: 'Delete Failed',
                    message: 'Could not delete batch: $e',
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
