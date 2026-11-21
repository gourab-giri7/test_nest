import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/attendance_service.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/model/attendance_model.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class AttendanceOverviewScreen extends StatefulWidget {
  final String? fallbackTeacherId;

  const AttendanceOverviewScreen({super.key, this.fallbackTeacherId});

  @override
  State<AttendanceOverviewScreen> createState() =>
      _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState extends State<AttendanceOverviewScreen> {
  final AttendanceService _service = AttendanceService();
  bool _isLoading = true;
  String? _errorMessage;

  List<BatchModel> _batches = [];
  Map<String, List<AttendanceRecordModel>> _todayRecordsByBatch = {};

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  TenantPathResolver _getResolver() {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.read<ActiveTenantContext>();
    } catch (_) {}
    return TenantPathResolver(tenantContext: tenantCtx);
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resolver = _getResolver();
      final user = FirebaseAuth.instance.currentUser;
      final teacherUid = user?.uid ?? widget.fallbackTeacherId ?? '';

      ActiveTenantContext? tenantCtx;
      try {
        tenantCtx = context.read<ActiveTenantContext>();
      } catch (_) {}

      final isTeacherInInstitute =
          tenantCtx != null && tenantCtx.isInstitute && tenantCtx.isTeacher;

      final batches = await _service.fetchBatches(
        resolver: resolver,
        filterTeacherUid: isTeacherInInstitute ? teacherUid : null,
        fallbackTeacherId: widget.fallbackTeacherId ?? teacherUid,
      );

      final todayKey = AttendanceRecordModel.formatDateKey(DateTime.now());
      final Map<String, List<AttendanceRecordModel>> todayRecords = {};

      for (final b in batches) {
        try {
          final records = await _service.fetchBatchAttendanceForDate(
            resolver: resolver,
            batchId: b.id,
            dateKey: todayKey,
            fallbackTeacherId: widget.fallbackTeacherId ?? teacherUid,
          );
          todayRecords[b.id] = records;
        } catch (_) {
          todayRecords[b.id] = [];
        }
      }

      if (mounted) {
        setState(() {
          _batches = batches;
          _todayRecordsByBatch = todayRecords;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load attendance overview: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Attendance Overview',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
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
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadOverview,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOverview,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Batches (${_batches.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add_task, size: 16),
                          label: const Text('Mark Any Batch'),
                          onPressed: () {
                            Get.toNamed(
                              AppRoutes.batchAttendance,
                            )?.then((_) => _loadOverview());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildBatchCardsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    final todayKey = AttendanceRecordModel.formatDateKey(DateTime.now());
    int markedTodayCount = 0;
    for (final records in _todayRecordsByBatch.values) {
      if (records.isNotEmpty) markedTodayCount++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Attendance Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  todayKey,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _batches.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Total Batches',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$markedTodayCount / ${_batches.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Marked Today',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBatchCardsList() {
    if (_batches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.class_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No Batches Available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'No active batches found to track attendance.',
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
      itemCount: _batches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final batch = _batches[index];
        final records = _todayRecordsByBatch[batch.id] ?? [];
        final isMarkedToday = records.isNotEmpty;

        final present = records.where((r) => r.isPresent).length;
        final absent = records.where((r) => r.isAbsent).length;
        final lateCount = records.where((r) => r.isLate).length;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
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
                          batch.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.text,
                          ),
                        ),
                        if (batch.subject != null && batch.subject!.isNotEmpty)
                          Text(
                            batch.subject!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isMarkedToday
                          ? AppColors.successSoft
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isMarkedToday
                            ? AppColors.success
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      isMarkedToday ? 'Marked Today' : 'Not Marked',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isMarkedToday
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isMarkedToday) ...[
                Row(
                  children: [
                    _buildMiniBadge('Present', present, AppColors.success),
                    const SizedBox(width: 8),
                    _buildMiniBadge('Absent', absent, AppColors.danger),
                    const SizedBox(width: 8),
                    _buildMiniBadge('Late', lateCount, AppColors.warning),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(
                      isMarkedToday ? Icons.edit : Icons.check,
                      size: 16,
                    ),
                    label: Text(
                      isMarkedToday ? 'Edit Attendance' : 'Mark Attendance',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMarkedToday
                          ? AppColors.primarySoft
                          : AppColors.primary,
                      foregroundColor: isMarkedToday
                          ? AppColors.primary
                          : Colors.white,
                      elevation: isMarkedToday ? 0 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      Get.toNamed(
                        AppRoutes.batchAttendance,
                        arguments: {'batchId': batch.id},
                      )?.then((_) => _loadOverview());
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
