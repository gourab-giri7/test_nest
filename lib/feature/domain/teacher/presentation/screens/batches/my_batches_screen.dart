import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/core/services/batch_qr_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/organization/presentation/screens/batch_teacher_assignment_screen.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/controller/batch_management_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/widgets/batch_qr_code_dialog.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class MyBatchesScreen extends StatelessWidget {
  const MyBatchesScreen({super.key});

  void _copyCode(BuildContext context, String code) {
    BatchQrService.copyJoiningCode(context, code);
  }

  void _showJoiningCodeDialog(BuildContext context, BatchModel batch) {
    BatchQrCodeDialog.show(context, batch);
  }

  Future<void> _archiveBatch(BuildContext context, BatchModel batch) async {
    final tData = teacherData;
    if (tData == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Archive Batch'),
        content: Text(
          'Are you sure you want to archive "${batch.name}"? Historical exams, scores, and fee records will be safely preserved.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Get.back(result: false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Archive'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BatchAndJoinCodeService.archiveBatch(
        teacherId: tData.id,
        batchId: batch.id,
        activeCode: batch.activeJoinCode,
      );
      if (!context.mounted) return;
      customSnackbar(
        context: context,
        message: 'Batch archived successfully.',
        color: Colors.green,
        ico: Icons.archive_rounded,
      );
    } catch (e) {
      if (!context.mounted) return;
      customSnackbar(
        context: context,
        message: 'Failed to archive batch: $e',
        color: Colors.red,
        ico: Icons.error,
      );
    }
  }

  Future<void> _deleteBatches(
    BuildContext context,
    BatchManagementController controller,
    List<BatchModel> batches,
  ) async {
    final tData = teacherData;
    if (tData == null || batches.isEmpty || controller.isDeleting) return;

    final isSingle = batches.length == 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          isSingle ? 'Delete Batch' : 'Delete ${batches.length} Batches',
        ),
        content: Text(
          isSingle
              ? 'Are you sure you want to delete "${batches.first.name}"?\n\nWarning: Students enrolled in this batch will lose access to it. Historical exams and completed submissions will be preserved.'
              : 'Are you sure you want to delete these ${batches.length} batches?\n\nWarning: Students enrolled in these batches will lose access. Historical exams and completed submissions will be preserved.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Get.back(result: false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    controller.setDeleting(true);

    try {
      await BatchAndJoinCodeService.deleteBatches(
        teacherId: tData.id,
        batchesToDelete: batches,
      );
      if (!context.mounted) return;
      controller.setDeleting(false);
      controller.clearSelection();

      customSnackbar(
        context: context,
        message: isSingle
            ? 'Batch deleted successfully.'
            : '${batches.length} batches deleted successfully.',
        color: Colors.green,
        ico: Icons.delete_outline_rounded,
      );
    } catch (e) {
      if (!context.mounted) return;
      controller.setDeleting(false);
      customSnackbar(
        context: context,
        message: 'Failed to delete: $e',
        color: Colors.red,
        ico: Icons.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tData = teacherData;
    if (tData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Batches')),
        body: const Center(child: Text('Session expired. Please log in.')),
      );
    }

    return ChangeNotifierProvider<BatchManagementController>(
      create: (_) => BatchManagementController(),
      child: Consumer<BatchManagementController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                controller.isSelectionMode
                    ? '${controller.selectedBatchIds.length} Selected'
                    : 'My Batches',
              ),
              leading: IconButton(
                icon: Icon(
                  controller.isSelectionMode
                      ? Icons.close_rounded
                      : Icons.arrow_back_ios_rounded,
                ),
                onPressed: () {
                  if (controller.isSelectionMode) {
                    controller.clearSelection();
                  } else {
                    Get.back();
                  }
                },
              ),
              actions: [
                if (!controller.isSelectionMode) ...[
                  IconButton(
                    icon: const Icon(Icons.group_add_rounded),
                    tooltip: 'Join Requests',
                    onPressed: () {
                      Get.toNamed(AppRoutes.teacherJoinRequests);
                    },
                  ),
                ],
              ],
            ),
            floatingActionButton: controller.isSelectionMode
                ? (controller.selectedBatchIds.isNotEmpty
                      ? FloatingActionButton.extended(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          icon: controller.isDeleting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete_forever_rounded),
                          label: Text(
                            controller.isDeleting
                                ? 'Deleting...'
                                : 'Delete (${controller.selectedBatchIds.length})',
                          ),
                          onPressed: controller.isDeleting
                              ? null
                              : () {
                                  // Handled via selection toolbar delete button
                                },
                        )
                      : null)
                : FloatingActionButton.extended(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Batch'),
                    onPressed: () {
                      Get.toNamed(AppRoutes.teacherCreateBatch);
                    },
                  ),
            body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('user')
                  .doc(tData.id)
                  .collection('batches')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final batches = docs.map((d) {
                  final data = d.data();
                  data['id'] = d.id;
                  return BatchModel.fromJson(data);
                }).toList();

                final activeBatches = batches
                    .where((b) => !b.isArchived)
                    .toList();

                if (activeBatches.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              size: 42,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Batches Yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your first batch to start organizing students and assigning exams.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Batch'),
                            onPressed: () {
                              Get.toNamed(AppRoutes.teacherCreateBatch);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allSelected =
                    activeBatches.isNotEmpty &&
                    activeBatches.every(
                      (b) => controller.selectedBatchIds.contains(b.id),
                    );

                return Column(
                  children: [
                    // Action / Selection toolbar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          if (controller.isSelectionMode) ...[
                            Checkbox(
                              value: allSelected,
                              activeColor: const Color(0xFF4F46E5),
                              onChanged: (v) {
                                if (v == true) {
                                  controller.selectAll(
                                    activeBatches.map((b) => b.id).toList(),
                                  );
                                } else {
                                  controller.clearSelection();
                                  controller.toggleSelectionMode();
                                }
                              },
                            ),
                            const Text(
                              'Select All',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            if (controller.selectedBatchIds.isNotEmpty)
                              TextButton.icon(
                                onPressed: controller.isDeleting
                                    ? null
                                    : () {
                                        final batchesToDelete = activeBatches
                                            .where(
                                              (b) => controller.selectedBatchIds
                                                  .contains(b.id),
                                            )
                                            .toList();
                                        _deleteBatches(
                                          context,
                                          controller,
                                          batchesToDelete,
                                        );
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  'Delete (${controller.selectedBatchIds.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ] else ...[
                            Text(
                              '${activeBatches.length} Active Batches',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                controller.toggleSelectionMode();
                              },
                              icon: const Icon(
                                Icons.checklist_rounded,
                                size: 18,
                              ),
                              label: const Text('Select'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: activeBatches.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final batch = activeBatches[index];
                          return _buildBatchCard(context, controller, batch);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBatchCard(
    BuildContext context,
    BatchManagementController controller,
    BatchModel batch,
  ) {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.watch<ActiveTenantContext>();
    } catch (_) {
      tenantCtx = null;
    }

    final isSelected = controller.selectedBatchIds.contains(batch.id);

    return InkWell(
      onLongPress: () {
        if (!controller.isSelectionMode) {
          controller.toggleSelectionMode();
        }
        controller.toggleBatchSelection(batch.id);
      },
      onTap: () {
        if (controller.isSelectionMode) {
          controller.toggleBatchSelection(batch.id);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFF4F46E5),
                    onChanged: (v) {
                      controller.toggleBatchSelection(batch.id);
                    },
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF4F46E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (batch.classLevel != null ||
                          batch.academicYear != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (batch.classLevel != null) batch.classLevel,
                            if (batch.academicYear != null) batch.academicYear,
                            if (batch.subject != null) batch.subject,
                          ].join(' • '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!controller.isSelectionMode)
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                    onSelected: (val) {
                      if (val == 'view_code') {
                        _showJoiningCodeDialog(context, batch);
                      } else if (val == 'assign_teachers') {
                        final orgId = tenantCtx?.activeOrgId ?? '';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BatchTeacherAssignmentScreen(
                              orgId: orgId,
                              batch: batch,
                            ),
                          ),
                        );
                      } else if (val == 'view_students') {
                        Get.toNamed(AppRoutes.teacherAllStudents);
                      } else if (val == 'attendance') {
                        Get.toNamed(
                          AppRoutes.batchAttendance,
                          arguments: {
                            'batchId': batch.id,
                            'teacherId': batch.teacherId,
                          },
                        );
                      } else if (val == 'promote') {
                        Get.toNamed(
                          AppRoutes.teacherPromoteStudents,
                          arguments: batch,
                        );
                      } else if (val == 'requests') {
                        Get.toNamed(AppRoutes.teacherJoinRequests);
                      } else if (val == 'fees') {
                        Get.toNamed(AppRoutes.teacherFeeManagement);
                      } else if (val == 'archive') {
                        _archiveBatch(context, batch);
                      } else if (val == 'delete') {
                        _deleteBatches(context, controller, [batch]);
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (tenantCtx != null &&
                          tenantCtx.isInstitute &&
                          tenantCtx.isAdmin)
                        const PopupMenuItem(
                          value: 'assign_teachers',
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                              SizedBox(width: 10),
                              Text('Assign Teachers'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'view_code',
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 18,
                              color: Color(0xFF4F46E5),
                            ),
                            SizedBox(width: 10),
                            Text('View Code & QR Pass'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'view_students',
                        child: Row(
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 10),
                            Text('View Students'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'attendance',
                        child: Row(
                          children: [
                            Icon(
                              Icons.how_to_reg_rounded,
                              size: 18,
                              color: Color(0xFF0284C7),
                            ),
                            SizedBox(width: 10),
                            Text('Mark Attendance'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'requests',
                        child: Row(
                          children: [
                            Icon(
                              Icons.group_add_rounded,
                              size: 18,
                              color: Color(0xFFD97706),
                            ),
                            SizedBox(width: 10),
                            Text('Join Requests'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'promote',
                        child: Row(
                          children: [
                            Icon(
                              Icons.upgrade_rounded,
                              size: 18,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 10),
                            Text('Promote Students'),
                          ],
                        ),
                      ),
                      if (batch.feeTrackingEnabled)
                        const PopupMenuItem(
                          value: 'fees',
                          child: Row(
                            children: [
                              Icon(
                                Icons.currency_rupee_rounded,
                                size: 18,
                                color: Color(0xFF0D9488),
                              ),
                              SizedBox(width: 10),
                              Text('Manage Fees'),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              Icons.archive_outlined,
                              size: 18,
                              color: Color(0xFFF59E0B),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Archive Batch',
                              style: TextStyle(color: Color(0xFFF59E0B)),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Delete Batch',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Metrics row: Approved Students, Pending Requests, Joining Code
            Row(
              children: [
                _metricPill(
                  Icons.people_outline_rounded,
                  '${batch.studentCount} Students',
                  const Color(0xFFEEF2FF),
                  const Color(0xFF4F46E5),
                ),
                const SizedBox(width: 8),
                if (batch.pendingRequestCount > 0) ...[
                  _metricPill(
                    Icons.hourglass_top_rounded,
                    '${batch.pendingRequestCount} Pending',
                    const Color(0xFFFEF3C7),
                    const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: InkWell(
                    onTap: () => _copyCode(context, batch.activeJoinCode),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.vpn_key_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            batch.activeJoinCode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showJoiningCodeDialog(context, batch),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_rounded,
                          size: 16,
                          color: Color(0xFF4F46E5),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'QR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricPill(IconData icon, String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textCol),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }
}
