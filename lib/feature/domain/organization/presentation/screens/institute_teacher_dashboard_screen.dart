import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/batch_assignment_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class InstituteTeacherDashboardScreen extends StatelessWidget {
  const InstituteTeacherDashboardScreen({super.key});

  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _surface = Colors.white;

  @override
  Widget build(BuildContext context) {
    final tenantCtx = context.watch<ActiveTenantContext>();
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? tenantCtx.currentUid ?? '';
    final orgId = tenantCtx.activeOrgId;

    final batchService = BatchAssignmentService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _buildTopHeader(context, tenantCtx),
            const SizedBox(height: 16),
            StreamBuilder<List<BatchModel>>(
              stream: batchService.streamTeacherBatches(orgId, currentUid),
              builder: (context, snapshot) {
                final batches = snapshot.data ?? [];
                int totalStudents = 0;
                for (final b in batches) {
                  totalStudents += b.studentCount;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(
                      batches.length,
                      totalStudents,
                      currentUid,
                      orgId,
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Teacher Quick Actions'),
                    const SizedBox(height: 12),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildAssignedBatchesSection(context, batches, orgId),
                    const SizedBox(height: 24),
                    _buildMyExamsSection(context, currentUid, orgId),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildTopHeader(BuildContext context, ActiveTenantContext tenantCtx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Text(
                        'FACULTY WORKSPACE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.teal.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Get.toNamed(AppRoutes.organizationSwitcher),
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        children: [
                          Text(
                            'Switch',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(
                            Icons.swap_horiz,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  tenantCtx.activeOrgName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Create Exam',
            onPressed: () => Get.toNamed(AppRoutes.teacherCreateExam),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.add_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Cards ──────────────────────────────────────────────────────────

  Widget _buildStatsGrid(
    int batchCount,
    int studentCount,
    String uid,
    String orgId,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('exams')
          .where('teacher_id', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final examCount = snapshot.data?.docs.length ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Assigned Batches',
                value: '$batchCount',
                icon: Icons.layers_outlined,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Batch Students',
                value: '$studentCount',
                icon: Icons.school_outlined,
                color: const Color(0xFF0D9488),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'My Exams',
                value: '$examCount',
                icon: Icons.assignment_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: _buildActionBtn(
              label: 'Create Exam',
              icon: Icons.add_circle_outline,
              color: AppColors.primary,
              onTap: () => Get.toNamed(AppRoutes.teacherCreateExam),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: _buildActionBtn(
              label: 'Attendance',
              icon: Icons.how_to_reg_outlined,
              color: const Color(0xFF0284C7),
              onTap: () => Get.toNamed(AppRoutes.batchAttendance),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: _buildActionBtn(
              label: 'Notices',
              icon: Icons.campaign_outlined,
              color: const Color(0xFFE11D48),
              onTap: () => Get.toNamed(AppRoutes.noticeList),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: _buildActionBtn(
              label: 'Performance',
              icon: Icons.insights_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () => Get.toNamed(AppRoutes.performanceAnalytics),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: _buildActionBtn(
              label: 'My Exams',
              icon: Icons.assignment_outlined,
              color: const Color(0xFF0D9488),
              onTap: () => Get.toNamed(AppRoutes.teacherExams),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: _buildActionBtn(
              label: 'Directory',
              icon: Icons.people_outline,
              color: const Color(0xFF7C3AED),
              onTap: () => Get.toNamed(AppRoutes.teacherAllStudents),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: _buildActionBtn(
              label: 'Workspace',
              icon: Icons.swap_horiz,
              color: const Color(0xFF475569),
              onTap: () => Get.toNamed(AppRoutes.organizationSwitcher),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Assigned Batches Section ─────────────────────────────────────────────

  Widget _buildAssignedBatchesSection(
    BuildContext context,
    List<BatchModel> batches,
    String orgId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('My Assigned Batches (${batches.length})'),
        const SizedBox(height: 10),
        if (batches.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line),
            ),
            child: const Center(
              child: Text(
                'You have not been assigned to any batches yet.\nContact your institute admin to be assigned.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: batches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final batch = batches[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        batch.name.isNotEmpty
                            ? batch.name[0].toUpperCase()
                            : 'B',
                        style: const TextStyle(
                          color: Color(0xFF0D9488),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Code: ${batch.activeJoinCode} • ${batch.studentCount} students',
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Get.toNamed(
                        AppRoutes.batchAttendance,
                        arguments: {'batchId': batch.id},
                      ),
                      child: const Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Get.toNamed(AppRoutes.teacherCreateExam),
                      child: const Text(
                        'Create Exam',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ── My Exams Section ─────────────────────────────────────────────────────

  Widget _buildMyExamsSection(
    BuildContext context,
    String currentUid,
    String orgId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('My Published Exams'),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.teacherExams),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('organizations')
              .doc(orgId)
              .collection('exams')
              .where('teacher_id', isEqualTo: currentUid)
              .limit(4)
              .snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _line),
                ),
                child: const Center(
                  child: Text(
                    'No exams created yet. Tap "Create Exam" to publish an exam for your assigned batches.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final exam = ExamModel.fromJson(docs[index].data());
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        color: Color(0xFF7C3AED),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.examName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Batch: ${exam.batch} • Marks: ${exam.fullMarks}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _ink,
        letterSpacing: -0.2,
      ),
    );
  }
}
