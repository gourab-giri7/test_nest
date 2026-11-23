import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/utils/custom_snackbar.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/institute_teacher_dashboard_controller.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/batch_student_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/teacher_salary_model.dart';
import 'package:test_nest/routes/app_routes.dart';
import 'package:test_nest/main.dart';

class InstituteTeacherDashboardScreen extends StatelessWidget {
  const InstituteTeacherDashboardScreen({super.key});

  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Colors.white;

  @override
  Widget build(BuildContext context) {
    final tenantCtx = context.watch<ActiveTenantContext>();
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? tenantCtx.currentUid ?? '';

    return ChangeNotifierProvider<InstituteTeacherDashboardController>(
      create: (_) => InstituteTeacherDashboardController(
        tenantContext: tenantCtx,
        teacherUid: currentUid,
      ),
      child: Consumer<InstituteTeacherDashboardController>(
        builder: (context, controller, _) {
          return PopScope(
            canPop: controller.currentTabIndex == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && controller.currentTabIndex != 0) {
                controller.switchTab(0);
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: controller.currentTabIndex == 0
                  ? null
                  : AppBar(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        onPressed: () => controller.switchTab(0),
                      ),
                      title: Text(
                        controller.currentTabIndex == 1
                            ? 'My Assigned Batches'
                            : controller.currentTabIndex == 2
                                ? 'Exams Management'
                                : controller.currentTabIndex == 3
                                    ? 'My Students'
                                    : 'Teacher Settings & Profile',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                    ),
              body: SafeArea(
                child: IndexedStack(
                  index: controller.currentTabIndex,
                  children: [
                    _TeacherHomeTab(controller: controller, tenantCtx: tenantCtx),
                    _TeacherBatchesTab(
                      controller: controller,
                      tenantCtx: tenantCtx,
                    ),
                    _TeacherExamsTab(
                      controller: controller,
                      tenantCtx: tenantCtx,
                    ),
                    _TeacherStudentsTab(
                      controller: controller,
                      tenantCtx: tenantCtx,
                    ),
                    _TeacherMoreTab(controller: controller, tenantCtx: tenantCtx),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// TAB 0: TEACHER HOME
// ============================================================================

class _TeacherHomeTab extends StatelessWidget {
  final InstituteTeacherDashboardController controller;
  final ActiveTenantContext tenantCtx;

  const _TeacherHomeTab({required this.controller, required this.tenantCtx});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = FirebaseAuth.instance.currentUser;
    final teacherName = user?.displayName ?? 'Teacher';

    return RefreshIndicator(
      onRefresh: () async {
        controller.initListeners();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildHeader(teacherName),
          const SizedBox(height: 16),
          _buildMetricsGrid(),
          const SizedBox(height: 20),
          _buildSectionHeader('Quick Actions'),
          const SizedBox(height: 10),
          _buildQuickActions(context),
          const SizedBox(height: 20),
          _buildTodayScheduleSection(context),
          const SizedBox(height: 20),
          _buildActiveExamsSection(context),
          const SizedBox(height: 20),
          _buildRecentNoticesSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(String teacherName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
            child: Text(
              teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D9488),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $teacherName 👋',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tenantCtx.activeOrgName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '• Teacher Portal',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notices',
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0D9488)),
            onPressed: () => Get.toNamed(AppRoutes.noticeList),
          ),
          IconButton(
            tooltip: 'Profile & Salary',
            icon: const Icon(Icons.person_outline, color: Color(0xFF0D9488)),
            onPressed: () => controller.switchTab(4),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = constraints.maxWidth < 360 ? 1.35 : 1.55;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            _buildMetricCard(
              title: 'Assigned Batches',
              count: '${controller.assignedBatchesCount}',
              icon: Icons.class_outlined,
              color: const Color(0xFF0D9488),
              onTap: () => controller.switchTab(1),
            ),
            _buildMetricCard(
              title: 'My Students',
              count: '${controller.assignedStudentsCount}',
              icon: Icons.people_outline_rounded,
              color: const Color(0xFF0284C7),
              onTap: () => controller.switchTab(3),
            ),
            _buildMetricCard(
              title: 'Active Exams',
              count: '${controller.activeExamsCount}',
              icon: Icons.assignment_outlined,
              color: const Color(0xFFF59E0B),
              onTap: () => controller.switchTab(2),
            ),
            _buildMetricCard(
              title: 'Salary Records',
              count: 'View',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF10B981),
              onTap: () => controller.switchTab(4),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: count.length > 3 ? 18 : 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, [Widget? trailing]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            label: 'My Batches',
            icon: Icons.class_outlined,
            color: const Color(0xFF0D9488),
            onTap: () => controller.switchTab(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn(
            label: 'Create Exam',
            icon: Icons.add_circle_outline,
            color: const Color(0xFF0D9488),
            onTap: () => _openCreateExamModal(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn(
            label: 'My Students',
            icon: Icons.people_outline,
            color: const Color(0xFF0D9488),
            onTap: () => controller.switchTab(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn(
            label: 'Attendance',
            icon: Icons.fact_check_outlined,
            color: const Color(0xFF0D9488),
            onTap: () => _showBatchPickerForAttendance(context),
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchPickerForAttendance(BuildContext context) {
    final batches = controller.batches;
    if (batches.isEmpty) {
      CustomSnackbar.showInfo(
        context: context,
        title: 'No Batches',
        message: 'You have not been assigned to any batches yet.',
      );
      return;
    }

    if (batches.length == 1) {
      Get.toNamed(
        AppRoutes.batchAttendance,
        arguments: {'batchId': batches.first.id},
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Batch for Attendance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: batches.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final b = batches[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.class_outlined,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          b.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${b.studentCount} students enrolled'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.pop(ctx);
                          Get.toNamed(
                            AppRoutes.batchAttendance,
                            arguments: {'batchId': b.id},
                          );
                        },
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
  }

  void _openCreateExamModal(BuildContext context) {
    final batches = controller.batches;
    if (batches.isEmpty) {
      CustomSnackbar.showInfo(
        context: context,
        title: 'No Assigned Batches',
        message:
            'You must be assigned to at least one batch to create an exam.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _CreateTeacherExamModal(
          orgId: controller.orgId,
          teacherUid: controller.effectiveTeacherUid,
          assignedBatches: batches,
          onExamCreated: () {
            controller.initListeners();
          },
        );
      },
    );
  }

  Widget _buildTodayScheduleSection(BuildContext context) {
    final scheduledBatches = controller.todayScheduledBatches;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 8),
              const Text(
                'Class Schedule',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                '${scheduledBatches.length} Batches',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (scheduledBatches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No class schedule recorded for your assigned batches.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            )
          else
            ...scheduledBatches.map(
              (b) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            b.schedule ?? 'Schedule not set',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fact_check_outlined, size: 18),
                      tooltip: 'Mark Attendance',
                      onPressed: () {
                        Get.toNamed(
                          AppRoutes.batchAttendance,
                          arguments: {'batchId': b.id},
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveExamsSection(BuildContext context) {
    final activeExams = controller.exams
        .where((e) => e.status.toLowerCase() == 'active')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Active Exams',
          TextButton(
            onPressed: () => controller.switchTab(2),
            child: const Text('View All'),
          ),
        ),
        const SizedBox(height: 8),
        if (activeExams.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No active exams in your assigned batches right now.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          )
        else
          ...activeExams
              .take(3)
              .map(
                (exam) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.examName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Batch: ${exam.batch} • ${exam.fullMarks} Marks',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildRecentNoticesSection(BuildContext context) {
    final notices = controller.notices.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Institute Bulletins',
          TextButton(
            onPressed: () => Get.toNamed(AppRoutes.noticeList),
            child: const Text('All Notices'),
          ),
        ),
        const SizedBox(height: 8),
        if (notices.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No bulletins published for your institute yet.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          )
        else
          ...notices.map(
            (n) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          n.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// TAB 1: TEACHER BATCHES
// ============================================================================

class _TeacherBatchesTab extends StatelessWidget {
  final InstituteTeacherDashboardController controller;
  final ActiveTenantContext tenantCtx;

  const _TeacherBatchesTab({required this.controller, required this.tenantCtx});

  @override
  Widget build(BuildContext context) {
    final batches = controller.filteredBatches;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Assigned Batches',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${controller.assignedBatchesCount} Total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: controller.setBatchSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search batch by name or subject...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: batches.isEmpty
              ? _buildEmptyBatches()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: batches.length,
                  itemBuilder: (context, i) {
                    final batch = batches[i];
                    return _buildBatchCard(context, batch);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyBatches() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.class_outlined, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No Assigned Batches Found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'The institute owner has not assigned you to any batches yet.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchCard(BuildContext context, BatchModel batch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    batch.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (batch.subject != null && batch.subject!.isNotEmpty)
              Text(
                'Subject: ${batch.subject}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    batch.schedule ?? 'Flexible Schedule',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${batch.studentCount} students',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Get.toNamed(
                      AppRoutes.batchAttendance,
                      arguments: {'batchId': batch.id},
                    );
                  },
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: const Text('Attendance'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF0D9488),
                    side: const BorderSide(color: Color(0xFF0D9488)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherBatchDetailScreen(
                          orgId: controller.orgId,
                          batch: batch,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View Batch'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 2: TEACHER EXAMS
// ============================================================================

class _TeacherExamsTab extends StatelessWidget {
  final InstituteTeacherDashboardController controller;
  final ActiveTenantContext tenantCtx;

  const _TeacherExamsTab({required this.controller, required this.tenantCtx});

  @override
  Widget build(BuildContext context) {
    final exams = controller.filteredExams;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assigned Batch Exams',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateExamModal(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Create'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: controller.setExamSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search exams by title...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Active', 'active'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Upcoming', 'upcoming'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Completed', 'completed'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: exams.isEmpty
              ? _buildEmptyExams()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exams.length,
                  itemBuilder: (context, i) {
                    final exam = exams[i];
                    return _buildExamCard(context, exam);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected =
        controller.examStatusFilter.toLowerCase() == value.toLowerCase();
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF1F5F9),
      showCheckmark: false,
      onSelected: (_) => controller.setExamStatusFilter(value),
    );
  }

  Widget _buildEmptyExams() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No Exams Found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Create an exam for one of your assigned batches.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, ExamModel exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _buildStatusPill(exam.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Batch: ${exam.batch}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${exam.fullMarks} Marks',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Schedule: ${exam.examStart != null ? DateFormat('yyyy-MM-dd HH:mm').format(exam.examStart!) : 'Not scheduled'}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    final s = status.toLowerCase();
    if (s == 'active') {
      bg = const Color(0xFF10B981).withValues(alpha: 0.1);
      fg = const Color(0xFF10B981);
    } else if (s == 'upcoming') {
      bg = const Color(0xFF3B82F6).withValues(alpha: 0.1);
      fg = const Color(0xFF3B82F6);
    } else {
      bg = const Color(0xFF64748B).withValues(alpha: 0.1);
      fg = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  void _openCreateExamModal(BuildContext context) {
    final batches = controller.batches;
    if (batches.isEmpty) {
      CustomSnackbar.showInfo(
        context: context,
        title: 'No Batches',
        message: 'You have no assigned batches to create exams for.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _CreateTeacherExamModal(
          orgId: controller.orgId,
          teacherUid: controller.effectiveTeacherUid,
          assignedBatches: batches,
          onExamCreated: () {
            controller.initListeners();
          },
        );
      },
    );
  }
}

// ============================================================================
// TAB 3: TEACHER STUDENTS (Deduplicated Across Assigned Batches)
// ============================================================================

class _TeacherStudentsTab extends StatelessWidget {
  final InstituteTeacherDashboardController controller;
  final ActiveTenantContext tenantCtx;

  const _TeacherStudentsTab({
    required this.controller,
    required this.tenantCtx,
  });

  @override
  Widget build(BuildContext context) {
    final students = controller.filteredStudents;
    final batches = controller.batches;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Institute Students',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${controller.assignedStudentsCount} Enrolled',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: controller.setStudentSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, or phone...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildBatchChip('All Batches', 'all'),
                    ...batches.map((b) => _buildBatchChip(b.name, b.id)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? _buildEmptyStudents()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, i) {
                    final student = students[i];
                    return _buildStudentCard(context, student);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBatchChip(String label, String batchId) {
    final isSelected = controller.studentBatchFilter == batchId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
        selectedColor: AppColors.primary,
        backgroundColor: const Color(0xFFF1F5F9),
        showCheckmark: false,
        onSelected: (_) => controller.setStudentBatchFilter(batchId),
      ),
    );
  }

  Widget _buildEmptyStudents() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No Students Found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'No students found in this institute matching your search.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    TeacherAssignedStudent student,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            student.studentName.isNotEmpty
                ? student.studentName[0].toUpperCase()
                : 'S',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        title: Text(
          student.studentName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.studentEmail,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: student.batchNames
                  .map(
                    (bName) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        bName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        onTap: () {
          _openStudentDetailsModal(context, student);
        },
      ),
    );
  }

  void _openStudentDetailsModal(
    BuildContext context,
    TeacherAssignedStudent student,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Text(
                        student.studentName.isNotEmpty
                            ? student.studentName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.studentName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            student.studentEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (student.studentPhone.isNotEmpty)
                            Text(
                              student.studentPhone,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                const Text(
                  'Enrolled Batches Under You',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: student.batchNames
                      .map(
                        (name) => Chip(
                          label: Text(name),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Batch enrollments and student transfers are managed by institute administration.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// TAB 4: TEACHER MORE
// ============================================================================

class _TeacherMoreTab extends StatelessWidget {
  final InstituteTeacherDashboardController controller;
  final ActiveTenantContext tenantCtx;

  const _TeacherMoreTab({required this.controller, required this.tenantCtx});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Teacher Utilities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildFeatureTile(
          title: 'Attendance System',
          subtitle: 'Mark daily attendance and inspect batch logs',
          icon: Icons.fact_check_outlined,
          color: const Color(0xFF0D9488),
          onTap: () => Get.toNamed(AppRoutes.attendanceOverview),
        ),
        _buildFeatureTile(
          title: 'Notices & Bulletins',
          subtitle: 'Read institute notices or create batch notices',
          icon: Icons.campaign_outlined,
          color: const Color(0xFF7C3AED),
          onTap: () => Get.toNamed(AppRoutes.noticeList),
        ),
        _buildFeatureTile(
          title: 'Performance Intelligence',
          subtitle: 'Review student evaluation benchmarks for your batches',
          icon: Icons.insights_outlined,
          color: const Color(0xFF0284C7),
          onTap: () => Get.toNamed(AppRoutes.performanceAnalytics),
        ),
        _buildFeatureTile(
          title: 'My Salary History',
          subtitle: 'Inspect compensation records and payment history',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF10B981),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherSalaryScreen(
                  orgId: controller.orgId,
                  teacherUid: controller.effectiveTeacherUid,
                ),
              ),
            );
          },
        ),
        _buildFeatureTile(
          title: 'Teacher Profile',
          subtitle: 'View your profile and institute assignments',
          icon: Icons.person_outline_rounded,
          color: const Color(0xFF4F46E5),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InstituteTeacherProfileScreen(
                  tenantCtx: tenantCtx,
                  assignedBatchCount: controller.assignedBatchesCount,
                ),
              ),
            );
          },
        ),
        const Divider(height: 32),
        _buildFeatureTile(
          title: 'Sign Out',
          subtitle: 'Log out of your account',
          icon: Icons.logout,
          color: Colors.red,
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }

  Widget _buildFeatureTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
        onTap: onTap,
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              LoginController? loginCtrl;
              try {
                loginCtrl = context.read<LoginController>();
              } catch (_) {}
              if (loginCtrl == null && Get.isRegistered<LoginController>()) {
                loginCtrl = Get.find<LoginController>();
              }
              if (loginCtrl != null) {
                await loginCtrl.logout(context);
              } else {
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (_) {}
                try {
                  if (context.mounted) {
                    context.read<ActiveTenantContext>().clear();
                  }
                } catch (_) {}
                await pref.clear();
                Get.offAllNamed(AppRoutes.login);
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPANION VIEW: TEACHER BATCH DETAILS (READ-ONLY FOR TEACHER)
// ============================================================================

class TeacherBatchDetailScreen extends StatelessWidget {
  final String orgId;
  final BatchModel batch;

  const TeacherBatchDetailScreen({
    super.key,
    required this.orgId,
    required this.batch,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(batch.name),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            tooltip: 'Take Attendance',
            icon: const Icon(
              Icons.fact_check_outlined,
              color: Color(0xFF0D9488),
            ),
            onPressed: () {
              Get.toNamed(
                AppRoutes.batchAttendance,
                arguments: {'batchId': batch.id},
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Batch info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      batch.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                if (batch.subject != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Subject: ${batch.subject}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Schedule: ${batch.schedule ?? 'Flexible'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (batch.activeJoinCode.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Join Code: ${batch.activeJoinCode}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Enrolled Students',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('organizations')
                .doc(orgId)
                .collection('batches')
                .doc(batch.id)
                .collection('students')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'No students enrolled in this batch yet.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ),
                );
              }

              final students = docs
                  .map((d) => BatchStudentModel.fromJson(d.data(), docId: d.id))
                  .toList();

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, i) {
                  final s = students[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          s.studentName.isNotEmpty
                              ? s.studentName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        s.studentName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(s.studentEmail),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPANION VIEW: TEACHER SALARY HISTORY (READ-ONLY)
// ============================================================================

class TeacherSalaryScreen extends StatelessWidget {
  final String orgId;
  final String teacherUid;

  const TeacherSalaryScreen({
    super.key,
    required this.orgId,
    required this.teacherUid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Salary History'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('salaries')
            .where('teacher_uid', isEqualTo: teacherUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Salary history will appear here',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Compensation disbursements and salary slips will be displayed here once processed by institute administration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            );
          }

          final records = docs
              .map((d) => TeacherSalaryModel.fromJson(d.data(), docId: d.id))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, i) {
              final rec = records[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rec.month.isNotEmpty ? rec.month : 'Disbursement',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: rec.isPaid
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rec.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: rec.isPaid
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${rec.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (rec.amountPaid > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Disbursed: ₹${rec.amountPaid.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Remaining: ₹${rec.remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: rec.remainingAmount > 0
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (rec.paymentMode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Payment Mode: ${rec.paymentMode}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (rec.referenceNumber != null &&
                        rec.referenceNumber!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ref: ${rec.referenceNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if (rec.notes != null && rec.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Notes: ${rec.notes}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// COMPANION VIEW: INSTITUTE TEACHER PROFILE
// ============================================================================

class InstituteTeacherProfileScreen extends StatelessWidget {
  final ActiveTenantContext tenantCtx;
  final int assignedBatchCount;

  const InstituteTeacherProfileScreen({
    super.key,
    required this.tenantCtx,
    required this.assignedBatchCount,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Teacher';
    final email = user?.email ?? 'teacher@institute.edu';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildProfileItem(
                  icon: Icons.business_rounded,
                  label: 'Institute',
                  value: tenantCtx.activeOrgName,
                ),
                const Divider(height: 1),
                _buildProfileItem(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: 'Teacher (Organization Member)',
                ),
                const Divider(height: 1),
                _buildProfileItem(
                  icon: Icons.check_circle_outline,
                  label: 'Status',
                  value: 'Active',
                ),
                const Divider(height: 1),
                _buildProfileItem(
                  icon: Icons.class_outlined,
                  label: 'Assigned Batches',
                  value: '$assignedBatchCount Batches',
                ),
                const Divider(height: 1),
                _buildProfileItem(
                  icon: Icons.fingerprint,
                  label: 'User ID',
                  value: user?.uid ?? 'Not available',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Institute role, status, and batch assignments are managed authoritatively by the institute owner.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF64748B), size: 20),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}

// ============================================================================
// MODAL: CREATE TEACHER EXAM (Restricted strictly to assigned batches)
// ============================================================================

class _CreateTeacherExamModal extends StatefulWidget {
  final String orgId;
  final String teacherUid;
  final List<BatchModel> assignedBatches;
  final VoidCallback onExamCreated;

  const _CreateTeacherExamModal({
    required this.orgId,
    required this.teacherUid,
    required this.assignedBatches,
    required this.onExamCreated,
  });

  @override
  State<_CreateTeacherExamModal> createState() =>
      _CreateTeacherExamModalState();
}

class _CreateTeacherExamModalState extends State<_CreateTeacherExamModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _marksController = TextEditingController(text: '100');
  late String _selectedBatchId;
  late String _selectedBatchName;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedBatchId = widget.assignedBatches.first.id;
    _selectedBatchName = widget.assignedBatches.first.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  Future<void> _submitExam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final examId = 'exam_${DateTime.now().millisecondsSinceEpoch}';
      final totalMarks = int.tryParse(_marksController.text.trim()) ?? 100;

      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.orgId)
          .collection('exams')
          .doc(examId)
          .set({
            'exam_id': examId,
            'exam_name': _nameController.text.trim(),
            'teacher_id': widget.teacherUid,
            'batch': _selectedBatchName,
            'assignedBatchIds': [_selectedBatchId],
            'total_marks': totalMarks,
            'status': 'active',
            'is_active': true,
            'is_published': true,
            'created_at': FieldValue.serverTimestamp(),
            'exam_start': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
            'exam_end': DateFormat(
              'yyyy-MM-dd HH:mm',
            ).format(DateTime.now().add(const Duration(hours: 2))),
            'questions': [],
          });

      if (mounted) {
        Navigator.pop(context);
        CustomSnackbar.showSuccess(
          context: context,
          title: 'Exam Created',
          message:
              'Exam "${_nameController.text.trim()}" created for $_selectedBatchName.',
        );
        widget.onExamCreated();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        CustomSnackbar.showError(
          context: context,
          title: 'Error',
          message: 'Failed to create exam: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Exam for Assigned Batch',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Exam Title *',
                  hintText: 'e.g. Unit 3 Calculus Assessment',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter exam title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedBatchId,
                decoration: const InputDecoration(
                  labelText: 'Target Batch *',
                  border: OutlineInputBorder(),
                ),
                items: widget.assignedBatches
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedBatchId = val;
                      _selectedBatchName = widget.assignedBatches
                          .firstWhere((b) => b.id == val)
                          .name;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _marksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Marks *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || int.tryParse(val.trim()) == null) {
                    return 'Please enter valid marks';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Exam',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
