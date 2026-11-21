import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/batch_attendance_controller.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/model/attendance_model.dart';
import 'package:test_nest/model/batch_model.dart';

class BatchAttendanceScreen extends StatefulWidget {
  final String? initialBatchId;
  final String? fallbackTeacherId;

  const BatchAttendanceScreen({
    super.key,
    this.initialBatchId,
    this.fallbackTeacherId,
  });

  @override
  State<BatchAttendanceScreen> createState() => _BatchAttendanceScreenState();
}

class _BatchAttendanceScreenState extends State<BatchAttendanceScreen> {
  late final BatchAttendanceController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = BatchAttendanceController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initController();
    }
  }

  void _initController() {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.read<ActiveTenantContext>();
    } catch (_) {}

    final resolver = TenantPathResolver(tenantContext: tenantCtx);
    final user = FirebaseAuth.instance.currentUser;
    final teacherUid = user?.uid ?? widget.fallbackTeacherId ?? '';

    // If teacher in institute mode, pass teacherUid as filter so only assigned batches show
    final isTeacherInInstitute =
        tenantCtx != null && tenantCtx.isInstitute && tenantCtx.isTeacher;

    _controller.initialize(
      resolver: resolver,
      defaultBatchId: widget.initialBatchId,
      filterTeacherUid: isTeacherInInstitute ? teacherUid : null,
      fallbackTeacherId: widget.fallbackTeacherId ?? teacherUid,
    );
  }

  TenantPathResolver _getResolver() {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.read<ActiveTenantContext>();
    } catch (_) {}
    return TenantPathResolver(tenantContext: tenantCtx);
  }

  Future<bool> _handlePop() async {
    if (!_controller.isDirty) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved attendance changes for this batch. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (discard == true) {
      _controller.discardChanges();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BatchAttendanceController>.value(
      value: _controller,
      child: Consumer<BatchAttendanceController>(
        builder: (context, controller, child) {
          return PopScope(
            canPop: !controller.isDirty,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final shouldPop = await _handlePop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text(
                  'Mark Attendance',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.text,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    final shouldPop = await _handlePop();
                    if (shouldPop && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                actions: [
                  if (controller.isDirty)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 14, color: AppColors.warning),
                          SizedBox(width: 4),
                          Text(
                            'Unsaved',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              body: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(controller),
              bottomNavigationBar: controller.students.isNotEmpty
                  ? _buildBottomBar(controller)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BatchAttendanceController controller) {
    if (controller.batches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group_off_outlined,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Batches Available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Create or assign a batch first before taking attendance.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBatchAndDateSelector(controller),
          const SizedBox(height: 14),
          _buildSummaryStats(controller),
          const SizedBox(height: 14),
          _buildQuickActionButtons(controller),
          const SizedBox(height: 16),
          if (controller.errorMessage != null) ...[
            _buildAlertBanner(controller.errorMessage!, isError: true),
            const SizedBox(height: 12),
          ],
          if (controller.successMessage != null) ...[
            _buildAlertBanner(controller.successMessage!, isError: false),
            const SizedBox(height: 12),
          ],
          _buildStudentList(controller),
        ],
      ),
    );
  }

  Widget _buildBatchAndDateSelector(BatchAttendanceController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Batch & Date Selection',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          // Batch Dropdown
          DropdownButtonFormField<BatchModel>(
            value: controller.selectedBatch,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Select Batch',
              labelStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(
                Icons.school_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: controller.batches.map((batch) {
              return DropdownMenuItem<BatchModel>(
                value: batch,
                child: Text(
                  batch.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (BatchModel? newBatch) {
              if (newBatch != null) {
                controller.selectBatch(newBatch, resolver: _getResolver());
              }
            },
          ),
          const SizedBox(height: 12),
          // Date Selector
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final prevDay = controller.selectedDate.subtract(
                    const Duration(days: 1),
                  );
                  controller.selectDate(prevDay, resolver: _getResolver());
                },
                tooltip: 'Previous Day',
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: controller.selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      controller.selectDate(picked, resolver: _getResolver());
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.dateKey,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final nextDay = controller.selectedDate.add(
                    const Duration(days: 1),
                  );
                  controller.selectDate(nextDay, resolver: _getResolver());
                },
                tooltip: 'Next Day',
              ),
              TextButton(
                onPressed: () {
                  controller.selectDate(
                    DateTime.now(),
                    resolver: _getResolver(),
                  );
                },
                child: const Text(
                  'Today',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(BatchAttendanceController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatPill(
            'Present',
            controller.presentCount,
            AppColors.success,
            AppColors.successSoft,
          ),
          _buildStatPill(
            'Absent',
            controller.absentCount,
            AppColors.danger,
            AppColors.dangerSoft,
          ),
          _buildStatPill(
            'Late',
            controller.lateCount,
            AppColors.warning,
            AppColors.warningSoft,
          ),
          _buildStatPill(
            'Unmarked',
            controller.unmarkedCount,
            AppColors.textMuted,
            AppColors.surfaceAlt,
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, int count, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(BatchAttendanceController controller) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(
              Icons.check_circle_outline,
              size: 16,
              color: AppColors.success,
            ),
            label: const Text(
              'Mark All Present',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.success),
              backgroundColor: AppColors.successSoft,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: controller.students.isEmpty
                ? null
                : controller.markAllPresent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(
              Icons.cancel_outlined,
              size: 16,
              color: AppColors.danger,
            ),
            label: const Text(
              'Mark All Absent',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
              backgroundColor: AppColors.dangerSoft,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: controller.students.isEmpty
                ? null
                : controller.markAllAbsent,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBanner(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? AppColors.dangerSoft : AppColors.successSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? AppColors.danger : AppColors.success,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppColors.danger : AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? AppColors.danger : AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(BatchAttendanceController controller) {
    if (controller.students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Students in this Batch',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Enroll students in this batch to take attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Students (${controller.students.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Status: Present / Absent / Late',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.students.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final student = controller.students[index];
            final sKey = BatchAttendanceController.studentKey(student);
            final currentStatus = controller.attendanceMap[sKey];
            final remarks = controller.remarksMap[sKey] ?? '';

            return _buildStudentCard(
              controller: controller,
              student: student,
              studentKey: sKey,
              currentStatus: currentStatus,
              remarks: remarks,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentCard({
    required BatchAttendanceController controller,
    required StudentModel student,
    required String studentKey,
    required String? currentStatus,
    required String remarks,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentStatus == AttendanceStatus.present
              ? AppColors.success.withOpacity(0.3)
              : currentStatus == AttendanceStatus.absent
              ? AppColors.danger.withOpacity(0.3)
              : currentStatus == AttendanceStatus.late
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.border,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (student.id.isNotEmpty)
                      Text(
                        'ID: ${student.id}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // Segmented Action: Present, Absent, Late
              _buildStatusToggle(
                studentKey: studentKey,
                currentStatus: currentStatus,
                onSelected: (status) =>
                    controller.markStatus(studentKey, status),
              ),
            ],
          ),
          // Remarks field toggle / display
          if (remarks.isNotEmpty || currentStatus == AttendanceStatus.late) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.comment_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    remarks.isNotEmpty
                        ? remarks
                        : 'Add late arrival / reason note...',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: remarks.isNotEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: remarks.isNotEmpty
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showRemarksDialog(
                    controller,
                    studentKey,
                    student.name,
                    remarks,
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    remarks.isNotEmpty ? 'Edit Note' : 'Add Note',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusToggle({
    required String studentKey,
    required String? currentStatus,
    required ValueChanged<String> onSelected,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChoiceChip(
          label: 'P',
          fullName: 'Present',
          isSelected: currentStatus == AttendanceStatus.present,
          activeColor: AppColors.success,
          activeBgColor: AppColors.successSoft,
          onTap: () => onSelected(AttendanceStatus.present),
        ),
        const SizedBox(width: 4),
        _buildChoiceChip(
          label: 'A',
          fullName: 'Absent',
          isSelected: currentStatus == AttendanceStatus.absent,
          activeColor: AppColors.danger,
          activeBgColor: AppColors.dangerSoft,
          onTap: () => onSelected(AttendanceStatus.absent),
        ),
        const SizedBox(width: 4),
        _buildChoiceChip(
          label: 'L',
          fullName: 'Late',
          isSelected: currentStatus == AttendanceStatus.late,
          activeColor: AppColors.warning,
          activeBgColor: AppColors.warningSoft,
          onTap: () => onSelected(AttendanceStatus.late),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String fullName,
    required bool isSelected,
    required Color activeColor,
    required Color activeBgColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: fullName,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRemarksDialog(
    BatchAttendanceController controller,
    String studentKey,
    String studentName,
    String currentRemarks,
  ) async {
    final textController = TextEditingController(text: currentRemarks);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Remarks for $studentName',
          style: const TextStyle(fontSize: 16),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Arrived 15 mins late, informed parent, etc.',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.markRemarks(studentKey, textController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BatchAttendanceController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          onPressed: controller.isSaving
              ? null
              : () async {
                  final user = FirebaseAuth.instance.currentUser;
                  final markedBy = user?.uid ?? widget.fallbackTeacherId ?? '';
                  final markedByName = user?.displayName ?? 'Teacher';

                  final ok = await controller.saveAttendance(
                    resolver: _getResolver(),
                    markedBy: markedBy,
                    markedByName: markedByName,
                    teacherId: widget.fallbackTeacherId ?? markedBy,
                    fallbackTeacherId: widget.fallbackTeacherId,
                  );

                  if (ok && mounted) {
                    Get.snackbar(
                      'Success',
                      'Attendance saved successfully!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
          child: controller.isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Saving Attendance...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      controller.isDirty
                          ? 'Save Attendance *'
                          : 'Save Attendance',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
