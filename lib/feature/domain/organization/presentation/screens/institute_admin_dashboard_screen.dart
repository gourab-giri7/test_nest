import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/institute_admin_dashboard_controller.dart';
import 'package:test_nest/feature/domain/organization/presentation/screens/batch_teacher_assignment_screen.dart';
import 'package:test_nest/feature/domain/organization/presentation/screens/institute_teachers_screen.dart';
import 'package:test_nest/routes/app_routes.dart';

class InstituteAdminDashboardScreen extends StatelessWidget {
  const InstituteAdminDashboardScreen({super.key});

  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _surface = Colors.white;

  @override
  Widget build(BuildContext context) {
    final tenantCtx = context.watch<ActiveTenantContext>();

    return ChangeNotifierProvider<InstituteAdminDashboardController>(
      create: (_) =>
          InstituteAdminDashboardController(tenantContext: tenantCtx),
      child: Consumer<InstituteAdminDashboardController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async => controller.refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    _buildTopHeader(context, tenantCtx),
                    const SizedBox(height: 16),
                    _buildSummaryGrid(controller),
                    const SizedBox(height: 20),
                    _sectionTitle('Admin Command Center'),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(context, tenantCtx),
                    const SizedBox(height: 24),
                    _buildBatchesManagementSection(context, controller),
                    const SizedBox(height: 24),
                    _buildRecentExamsSection(context, controller),
                  ],
                ),
              ),
            ),
          );
        },
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
                colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
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
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.indigo.shade200),
                      ),
                      child: Text(
                        'INSTITUTE ADMIN',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.indigo.shade800,
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
            tooltip: 'Invite Teachers',
            onPressed: () => Get.toNamed(AppRoutes.manageInvitations),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.mail_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Cards Grid ───────────────────────────────────────────────────

  Widget _buildSummaryGrid(InstituteAdminDashboardController controller) {
    if (controller.isLoading) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 20) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              title: 'Total Students',
              value: '${controller.totalStudents}',
              icon: Icons.school_outlined,
              color: const Color(0xFF2563EB),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Total Teachers',
              value: '${controller.totalTeachers}',
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF0D9488),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Total Batches',
              value: '${controller.totalBatches}',
              icon: Icons.layers_outlined,
              color: const Color(0xFF7C3AED),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Active Exams',
              value: '${controller.activeExams}',
              icon: Icons.assignment_outlined,
              color: const Color(0xFFEA580C),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Pending Requests',
              value: '${controller.pendingJoinRequests}',
              icon: Icons.how_to_reg_outlined,
              color: const Color(0xFFD97706),
              width: cardWidth,
            ),
            _buildStatCard(
              title: 'Estimated Fee Due',
              value: '₹${controller.totalFeeDue.toStringAsFixed(0)}',
              icon: Icons.currency_rupee_rounded,
              color: const Color(0xFF059669),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.02),
            blurRadius: 6,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions Grid ───────────────────────────────────────────────────

  Widget _buildQuickActionsGrid(
    BuildContext context,
    ActiveTenantContext tenantCtx,
  ) {
    final actions = [
      _QuickActionItem(
        label: 'Manage Teachers',
        icon: Icons.people_alt_outlined,
        color: const Color(0xFF2563EB),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                InstituteTeachersScreen(orgId: tenantCtx.activeOrgId),
          ),
        ),
      ),
      _QuickActionItem(
        label: 'Invite Teacher',
        icon: Icons.mail_outline_rounded,
        color: const Color(0xFF7C3AED),
        onTap: () => Get.toNamed(AppRoutes.manageInvitations),
      ),
      _QuickActionItem(
        label: 'Manage Students',
        icon: Icons.school_outlined,
        color: const Color(0xFF0D9488),
        onTap: () => Get.toNamed(AppRoutes.teacherAllStudents),
      ),
      _QuickActionItem(
        label: 'Manage Batches',
        icon: Icons.view_module_outlined,
        color: const Color(0xFFEA580C),
        onTap: () => Get.toNamed(AppRoutes.teacherBatches),
      ),
      _QuickActionItem(
        label: 'Manage Exams',
        icon: Icons.assignment_outlined,
        color: const Color(0xFF059669),
        onTap: () => Get.toNamed(AppRoutes.teacherExams),
      ),
      _QuickActionItem(
        label: 'Fee Management',
        icon: Icons.payments_outlined,
        color: const Color(0xFF4F46E5),
        onTap: () => Get.toNamed(AppRoutes.teacherFeeManagement),
      ),
      _QuickActionItem(
        label: 'Attendance',
        icon: Icons.how_to_reg_outlined,
        color: const Color(0xFF0284C7),
        onTap: () => Get.toNamed(AppRoutes.attendanceOverview),
      ),
      _QuickActionItem(
        label: 'Notice Board',
        icon: Icons.campaign_outlined,
        color: const Color(0xFFE11D48),
        onTap: () => Get.toNamed(AppRoutes.noticeList),
      ),
      _QuickActionItem(
        label: 'Performance',
        icon: Icons.insights_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () => Get.toNamed(AppRoutes.performanceAnalytics),
      ),
      _QuickActionItem(
        label: 'Join Requests',
        icon: Icons.person_add_alt,
        color: const Color(0xFFB45309),
        onTap: () => Get.toNamed(AppRoutes.teacherJoinRequests),
      ),
      _QuickActionItem(
        label: 'Switch Workspace',
        icon: Icons.business_outlined,
        color: const Color(0xFF475569),
        onTap: () => Get.toNamed(AppRoutes.organizationSwitcher),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final a = actions[index];
        return InkWell(
          onTap: a.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: a.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a.icon, size: 20, color: a.color),
                ),
                const SizedBox(height: 8),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Batches Section ──────────────────────────────────────────────────────

  Widget _buildBatchesManagementSection(
    BuildContext context,
    InstituteAdminDashboardController controller,
  ) {
    final batches = controller.batches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Institute Batches & Teacher Assignments'),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.teacherBatches),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
                'No batches created yet. Create a batch from Manage Batches.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: batches.take(4).length,
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
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        batch.name.isNotEmpty
                            ? batch.name[0].toUpperCase()
                            : 'B',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
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
                            '${batch.studentCount} students • ${batch.assignedTeacherIds.length} teachers assigned',
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
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BatchTeacherAssignmentScreen(
                              orgId: controller.orgId,
                              batch: batch,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Assign Teachers',
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

  // ── Recent Exams Section ─────────────────────────────────────────────────

  Widget _buildRecentExamsSection(
    BuildContext context,
    InstituteAdminDashboardController controller,
  ) {
    final exams = controller.recentExams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Recent Institute Exams'),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.teacherExams),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (exams.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _line),
            ),
            child: const Center(
              child: Text(
                'No exams published in this institute yet.',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final exam = exams[index];
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
                      Icons.description_outlined,
                      color: AppColors.primary,
                      size: 24,
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
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
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

class _QuickActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
