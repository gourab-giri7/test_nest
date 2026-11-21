import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/attendance/controller/student_attendance_controller.dart';
import 'package:test_nest/model/attendance_model.dart';

class StudentAttendanceHistoryScreen extends StatefulWidget {
  final String? studentId;
  final String? studentName;
  final String? batchId;
  final String? fallbackTeacherId;

  const StudentAttendanceHistoryScreen({
    super.key,
    this.studentId,
    this.studentName,
    this.batchId,
    this.fallbackTeacherId,
  });

  @override
  State<StudentAttendanceHistoryScreen> createState() =>
      _StudentAttendanceHistoryScreenState();
}

class _StudentAttendanceHistoryScreenState
    extends State<StudentAttendanceHistoryScreen> {
  late final StudentAttendanceController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = StudentAttendanceController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.read<ActiveTenantContext>();
    } catch (_) {}

    final resolver = TenantPathResolver(tenantContext: tenantCtx);
    final user = FirebaseAuth.instance.currentUser;
    final effectiveStudentId = widget.studentId ?? user?.uid ?? '';
    final effectiveStudentName =
        widget.studentName ?? user?.displayName ?? 'Student';

    await _controller.loadAttendance(
      resolver: resolver,
      studentId: effectiveStudentId,
      studentName: effectiveStudentName,
      batchId: widget.batchId,
      fallbackTeacherId: widget.fallbackTeacherId,
    );
  }

  TenantPathResolver _getResolver() {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.read<ActiveTenantContext>();
    } catch (_) {}
    return TenantPathResolver(tenantContext: tenantCtx);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentAttendanceController>.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Attendance History',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.text,
        ),
        body: Consumer<StudentAttendanceController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.danger,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        controller.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(controller),
                    const SizedBox(height: 16),
                    _buildFilterSection(controller),
                    const SizedBox(height: 16),
                    _buildRecordsList(controller),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(StudentAttendanceController controller) {
    final summary = controller.summary;
    final total = summary?.totalClasses ?? 0;
    final present = summary?.presentCount ?? 0;
    final absent = summary?.absentCount ?? 0;
    final lateCount = summary?.lateCount ?? 0;
    final percentage = summary?.attendancePercentage ?? 100.0;

    Color percentageColor;
    if (percentage >= 75) {
      percentageColor = AppColors.success;
    } else if (percentage >= 60) {
      percentageColor = AppColors.warning;
    } else {
      percentageColor = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: percentageColor.withOpacity(0.12),
                  border: Border.all(color: percentageColor, width: 3),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: percentageColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'No attendance records yet'
                          : percentage >= 75
                          ? 'Good Standing (>= 75%)'
                          : percentage >= 60
                          ? 'Attendance Warning (60-74%)'
                          : 'Critically Low (< 60%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: percentageColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Present + Late: ${present + lateCount} / $total classes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                'Total Classes',
                total.toString(),
                AppColors.text,
              ),
              _buildMetricItem(
                'Present',
                present.toString(),
                AppColors.success,
              ),
              _buildMetricItem('Late', lateCount.toString(), AppColors.warning),
              _buildMetricItem('Absent', absent.toString(), AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFilterSection(StudentAttendanceController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All (${controller.allRecords.length})',
            isSelected: controller.statusFilter == null,
            onTap: () => controller.setStatusFilter(null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Present',
            isSelected: controller.statusFilter == AttendanceStatus.present,
            activeColor: AppColors.success,
            onTap: () => controller.setStatusFilter(AttendanceStatus.present),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Late',
            isSelected: controller.statusFilter == AttendanceStatus.late,
            activeColor: AppColors.warning,
            onTap: () => controller.setStatusFilter(AttendanceStatus.late),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Absent',
            isSelected: controller.statusFilter == AttendanceStatus.absent,
            activeColor: AppColors.danger,
            onTap: () => controller.setStatusFilter(AttendanceStatus.absent),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color activeColor = AppColors.primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordsList(StudentAttendanceController controller) {
    final records = controller.filteredRecords;

    if (records.isEmpty) {
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
              Icons.event_busy_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Records Found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              controller.statusFilter != null
                  ? 'No attendance records matching the selected filter.'
                  : 'Your attendance records will appear here once marked by your teacher.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildRecordTile(record);
      },
    );
  }

  Widget _buildRecordTile(AttendanceRecordModel record) {
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusLabel;

    if (record.isPresent) {
      statusColor = AppColors.success;
      statusBgColor = AppColors.successSoft;
      statusIcon = Icons.check_circle;
      statusLabel = 'Present';
    } else if (record.isAbsent) {
      statusColor = AppColors.danger;
      statusBgColor = AppColors.dangerSoft;
      statusIcon = Icons.cancel;
      statusLabel = 'Absent';
    } else {
      statusColor = AppColors.warning;
      statusBgColor = AppColors.warningSoft;
      statusIcon = Icons.access_time_filled;
      statusLabel = 'Late';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.dateKey,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.class_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Batch: ${record.batchName.isNotEmpty ? record.batchName : 'General'}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              if (record.markedByName.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  record.markedByName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (record.remarks != null && record.remarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Note: ${record.remarks}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
