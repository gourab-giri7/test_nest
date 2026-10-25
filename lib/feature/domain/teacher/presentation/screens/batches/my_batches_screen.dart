import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class MyBatchesScreen extends StatefulWidget {
  const MyBatchesScreen({super.key});

  @override
  State<MyBatchesScreen> createState() => _MyBatchesScreenState();
}

class _MyBatchesScreenState extends State<MyBatchesScreen> {
  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    customSnackbar(
      context: context,
      message: 'Code $code copied to clipboard!',
      color: Colors.green,
      ico: Icons.copy_rounded,
    );
  }

  void _showJoiningCodeDialog(BatchModel batch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          batch.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Reusable Joining Code',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Text(
                batch.activeJoinCode.isNotEmpty
                    ? batch.activeJoinCode
                    : 'No Active Code',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Share this code with your students. Anyone with this code can request to join this batch.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          if (batch.activeJoinCode.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Code'),
              onPressed: () {
                Get.back();
                _copyCode(batch.activeJoinCode);
              },
            ),
          TextButton(child: const Text('Close'), onPressed: () => Get.back()),
        ],
      ),
    );
  }

  Future<void> _archiveBatch(BatchModel batch) async {
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
      if (!mounted) return;
      customSnackbar(
        context: context,
        message: 'Batch archived successfully.',
        color: Colors.green,
        ico: Icons.archive_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      customSnackbar(
        context: context,
        message: 'Failed to archive batch: $e',
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Batches'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Join Requests',
            onPressed: () {
              Get.toNamed(AppRoutes.teacherJoinRequests);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final activeBatches = docs
              .map((d) => BatchModel.fromJson(d.data(), docId: d.id))
              .where((b) => !b.isArchived)
              .toList();

          if (activeBatches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        size: 40,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Batches Created Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first batch to generate a reusable joining code for your students.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: activeBatches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final batch = activeBatches[index];
              return _buildBatchCard(batch);
            },
          );
        },
      ),
    );
  }

  Widget _buildBatchCard(BatchModel batch) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch Name & Overflow Menu
            Row(
              children: [
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
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  onSelected: (val) {
                    if (val == 'view_code') {
                      _showJoiningCodeDialog(batch);
                    } else if (val == 'view_students') {
                      Get.toNamed(AppRoutes.teacherAllStudents);
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
                      _archiveBatch(batch);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'view_code',
                      child: Row(
                        children: [
                          Icon(
                            Icons.vpn_key_rounded,
                            size: 18,
                            color: Color(0xFF4F46E5),
                          ),
                          SizedBox(width: 10),
                          Text('View Joining Code'),
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
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Archive Batch',
                            style: TextStyle(color: Color(0xFFEF4444)),
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
                    onTap: () => _copyCode(batch.activeJoinCode),
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
