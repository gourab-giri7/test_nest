import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/fee_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/dashboard/controller/student_workspace_controller.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/notice_model.dart';
import 'package:test_nest/model/payment_model.dart';
import 'package:test_nest/routes/app_routes.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examResult/exam_result_review_screen.dart';
import 'package:test_nest/main.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Colors.white;

  @override
  Widget build(BuildContext context) {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.watch<ActiveTenantContext>();
    } catch (_) {}

    final sData = studentData;
    final user = FirebaseAuth.instance.currentUser;
    final currentUid = user?.uid ?? sData?.id ?? '';

    return ChangeNotifierProvider<StudentWorkspaceController>(
      create: (_) => StudentWorkspaceController(
        tenantContext: tenantCtx,
        studentUid: currentUid,
      ),
      child: Consumer<StudentWorkspaceController>(
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
                            ? 'My Exams'
                            : controller.currentTabIndex == 2
                                ? 'Exam Results'
                                : controller.currentTabIndex == 3
                                    ? 'Notices & Bulletins'
                                    : 'Student Profile & Fees',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                    ),
              body: SafeArea(
                child: IndexedStack(
                  index: controller.currentTabIndex,
                  children: [
                    _StudentHomeTab(controller: controller),
                    _StudentExamsTab(controller: controller),
                    _StudentResultsTab(controller: controller),
                    _StudentNoticesTab(controller: controller),
                    _StudentProfileTab(controller: controller),
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
// TAB 0: STUDENT HOME
// ============================================================================

class _StudentHomeTab extends StatelessWidget {
  final StudentWorkspaceController controller;

  const _StudentHomeTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = FirebaseAuth.instance.currentUser;
    final studentName = user?.displayName ?? studentData?.name ?? 'Student';

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
          _buildHeader(studentName),
          const SizedBox(height: 16),
          _buildMetricsGrid(),
          const SizedBox(height: 20),
          _buildQuickActions(context),
          const SizedBox(height: 20),
          _buildUpcomingExamsSection(context),
          const SizedBox(height: 20),
          _buildAttendanceSnapshot(context),
          const SizedBox(height: 20),
          _buildRecentResultsSection(context),
          const SizedBox(height: 20),
          _buildRecentNoticesSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(String studentName) {
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
            backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.12),
            child: Text(
              studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $studentName 👋',
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
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        controller.orgName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '• Student Portal',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notices',
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF7C3AED)),
                onPressed: () {
                  controller.markAllNoticesAsRead();
                  controller.switchTab(3);
                },
              ),
              if (controller.hasUnreadNotices)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline, color: Color(0xFF7C3AED)),
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
              title: 'My Batches',
              value: '${controller.activeBatchCount}',
              icon: Icons.class_outlined,
              color: const Color(0xFF3B82F6),
            ),
            _buildMetricCard(
              title: 'Upcoming Exams',
              value: '${controller.upcomingExams.length}',
              icon: Icons.assignment_outlined,
              color: const Color(0xFFF59E0B),
            ),
            _buildMetricCard(
              title: 'Attendance',
              value: controller.attendanceTotalCount > 0
                  ? '${controller.attendancePercentage.toStringAsFixed(0)}%'
                  : 'No records',
              icon: Icons.fact_check_outlined,
              color: const Color(0xFF10B981),
            ),
            _buildMetricCard(
              title: 'Fee Balance',
              value: '₹${controller.outstandingFeeAmount.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF8B5CF6),
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
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionBtn(
            label: 'View Exams',
            icon: Icons.assignment_outlined,
            color: const Color(0xFF2563EB),
            onTap: () => controller.switchTab(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn(
            label: 'View Results',
            icon: Icons.analytics_outlined,
            color: const Color(0xFF10B981),
            onTap: () => controller.switchTab(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn(
            label: 'Attendance',
            icon: Icons.fact_check_outlined,
            color: const Color(0xFF0D9488),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StudentAttendanceDetailScreen(controller: controller),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionBtn(
            label: 'Fee Status',
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFFD97706),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StudentFeeStatusScreen(controller: controller),
                ),
              );
            },
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingExamsSection(BuildContext context) {
    final upcoming = controller.upcomingExams.take(2).toList();
    final active = controller.activeExams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Exams & Tests',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () => controller.switchTab(1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (active.isEmpty && upcoming.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No upcoming or active tests scheduled for your batches.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          )
        else ...[
          ...active.map((e) => _buildLiveExamCard(context, e)),
          ...upcoming.map((e) => _buildUpcomingExamCard(e)),
        ],
      ],
    );
  }

  Widget _buildLiveExamCard(BuildContext context, ExamModel exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
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
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                Text(
                  'Batch: ${exam.batch} • ${exam.fullMarks} Marks',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                if (exam.teacherName.trim().isNotEmpty)
                  Text(
                    'Created by: ${exam.teacherName.trim()}${exam.createdByRole != null ? ' (${exam.createdByRole})' : ''}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.toNamed(AppRoutes.studentTakeExam, arguments: exam);
            },
            style: ElevatedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExamCard(ExamModel exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, color: Color(0xFFF59E0B), size: 20),
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
                  'Scheduled: ${exam.examStart != null ? DateFormat('MMM dd, hh:mm a').format(exam.examStart!) : 'Upcoming'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (exam.teacherName.trim().isNotEmpty)
                  Text(
                    'Created by: ${exam.teacherName.trim()}${exam.createdByRole != null ? ' (${exam.createdByRole})' : ''}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSnapshot(BuildContext context) {
    final total = controller.attendanceTotalCount;
    final present = controller.attendancePresentCount;
    final pct = controller.attendancePercentage;

    return Container(
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
              const Text(
                'Attendance Snapshot',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                total > 0
                    ? '${pct.toStringAsFixed(1)}% Present'
                    : 'No records yet',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: total > 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? (present / total) : 0.0,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF10B981),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Present: $present / $total days',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentAttendanceDetailScreen(controller: controller),
                    ),
                  );
                },
                child: const Text(
                  'Details →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResultsSection(BuildContext context) {
    final results = controller.results.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Test Results',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () => controller.switchTab(2),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (results.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No evaluated exam results recorded yet.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          )
        else
          ...results.map(
            (r) => Container(
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.examName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Score: ${r.obtainedMarks.toStringAsFixed(0)} / ${r.totalMarks.toStringAsFixed(0)} (${r.percentage.toStringAsFixed(1)}%)',
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
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      r.status,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
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
    final notices = controller.notices.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Institute Bulletins',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () => controller.switchTab(3),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 6),
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
                'No bulletins published for your batches yet.',
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
                    size: 18,
                  ),
                  const SizedBox(width: 10),
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
// TAB 1: STUDENT EXAMS
// ============================================================================

class _StudentExamsTab extends StatelessWidget {
  final StudentWorkspaceController controller;

  const _StudentExamsTab({required this.controller});

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
              const Text(
                'My Batch Exams',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: controller.setExamSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search by exam title or batch...',
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
              : RefreshIndicator(
                  onRefresh: () async => controller.refreshWorkspace(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: exams.length,
                    itemBuilder: (context, i) {
                      final exam = exams[i];
                      return _buildExamCard(context, exam);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected =
        controller.examFilter.toLowerCase() == value.toLowerCase();
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
      onSelected: (_) => controller.setExamFilter(value),
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
            'There are no exams matching your selected criteria.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildExamStatusBadge(String status) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;
    String label;
    IconData? dot;

    if (s == 'active') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      label = 'LIVE';
      dot = Icons.fiber_manual_record;
    } else if (s == 'upcoming') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      label = 'UPCOMING';
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
      label = 'COMPLETED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Icon(dot, size: 8, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamCard(BuildContext context, ExamModel exam) {
    final status = exam.status;
    final isLive = status.toLowerCase() == 'active';
    final isUpcoming = status.toLowerCase() == 'upcoming';
    final isCompleted = status.toLowerCase() == 'completed';
    final hasSubmitted = controller.hasSubmittedExam(exam.examId);

    // Subject display
    final subjectText = (exam.subject != null && exam.subject!.trim().isNotEmpty)
        ? exam.subject!.trim()
        : null;

    final batchText = exam.batches.isNotEmpty
        ? exam.batches.join(', ')
        : (exam.batch.isNotEmpty ? exam.batch : 'All Batches');

    final dateStr = exam.examStart != null
        ? DateFormat('dd MMM yyyy').format(exam.examStart!)
        : 'Date Flexible';

    final timeStr = (exam.examStart != null && exam.examEnd != null)
        ? '${DateFormat('hh:mm a').format(exam.examStart!)} - ${DateFormat('hh:mm a').format(exam.examEnd!)}'
        : (exam.examStart != null
            ? DateFormat('hh:mm a').format(exam.examStart!)
            : 'Flexible Time');

    final durationMinutes = (exam.examStart != null && exam.examEnd != null)
        ? exam.examEnd!.difference(exam.examStart!).inMinutes
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? const Color(0xFF3B82F6)
              : (isUpcoming ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Exam Name & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exam.examName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildExamStatusBadge(status),
            ],
          ),
          const SizedBox(height: 8),

          // Subject & Batch Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (subjectText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 4),
                      Text(
                        subjectText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      batchText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Exam Details Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.calendar_today_outlined,
                        'Date',
                        dateStr,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.access_time_rounded,
                        'Time',
                        timeStr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        Icons.emoji_events_outlined,
                        'Full Marks',
                        '${exam.fullMarks} Marks',
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        Icons.quiz_outlined,
                        'Questions',
                        '${exam.questions.length} Qs${durationMinutes != null ? ' • $durationMinutes m' : ''}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (exam.instruction.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      exam.instruction.trim(),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (exam.teacherName.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  'Created by: ${exam.teacherName.trim()}${exam.createdByRole != null ? ' (${exam.createdByRole})' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],

          // Action Section: COMPLETELY HIDDEN for Upcoming Exams!
          if (!isUpcoming) ...[
            const Divider(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isLive) ...[
                  if (hasSubmitted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF16A34A)),
                          SizedBox(width: 6),
                          Text(
                            'Submitted',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(AppRoutes.studentTakeExam, arguments: exam);
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Start Exam'),
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ] else if (isCompleted) ...[
                  if (hasSubmitted || exam.resultPublished)
                    OutlinedButton.icon(
                      onPressed: () {
                        controller.switchTab(2);
                      },
                      icon: const Icon(Icons.assessment_outlined, size: 16),
                      label: Text(exam.resultPublished ? 'View Results' : 'View Submission'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Exam Ended',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 2: STUDENT RESULTS
// ============================================================================

class _StudentResultsTab extends StatelessWidget {
  final StudentWorkspaceController controller;

  const _StudentResultsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final results = controller.filteredResults;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Exam Results',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: controller.setResultSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search results by exam or batch...',
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
          child: results.isEmpty
              ? _buildEmptyResults()
              : RefreshIndicator(
                  onRefresh: () async => controller.refreshWorkspace(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final item = results[i];
                      return _buildResultCard(context, item);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No Results Available',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Results will be posted here once evaluation is complete.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    StudentSubmissionResultItem item,
  ) {
    final isPublished = item.status == 'Published' || (item.exam?.resultPublished ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (isPublished && item.exam != null) {
              Get.to(
                () => ExamResultReviewScreen(
                  exam: item.exam!,
                  submission: item.submissionData,
                ),
              );
            } else {
              customSnackbar(
                context: context,
                message:
                    'Result is currently under review. Full answer analysis will be visible once published.',
                color: Colors.orange,
                ico: Icons.lock_clock,
              );
            }
          },
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
                        item.examName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPublished
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPublished ? 'PUBLISHED' : 'UNDER REVIEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isPublished
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Batch: ${item.batch}${item.subject.isNotEmpty ? ' • ${item.subject}' : ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Score Obtained',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        Text(
                          '${item.obtainedMarks.toStringAsFixed(0)} / ${item.totalMarks.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Percentage',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        Text(
                          '${item.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: item.percentage >= 50
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (item.examDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('MMM dd, yyyy').format(item.examDate!)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
                if (isPublished) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Text(
                        'View Answers & Review',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 3: STUDENT NOTICES
// ============================================================================

class _StudentNoticesTab extends StatelessWidget {
  final StudentWorkspaceController controller;

  const _StudentNoticesTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final notices = controller.filteredNotices;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Institute Bulletins',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: controller.setNoticeSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search bulletins...',
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
          child: notices.isEmpty
              ? _buildEmptyNotices()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notices.length,
                  itemBuilder: (context, i) {
                    final notice = notices[i];
                    return _buildNoticeCard(context, notice);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyNotices() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No Bulletins Found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'There are no active notices for your batches at this time.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context, NoticeModel notice) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: Color(0xFF7C3AED),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notice.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notice.body,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audience: ${notice.audienceSummary}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              if (notice.publishedAt != null)
                Text(
                  DateFormat('MMM dd, yyyy').format(notice.publishedAt!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 4: STUDENT PROFILE & UTILITIES
// ============================================================================

class _StudentProfileTab extends StatelessWidget {
  final StudentWorkspaceController controller;

  const _StudentProfileTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? studentData?.name ?? 'Student';
    final email = user?.email ?? 'student@institute.edu';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Profile identity card
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
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
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
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.orgName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Secondary section tiles
        _buildSectionTile(
          title: 'My Batches',
          subtitle: '${controller.activeBatchCount} Active Enrollments',
          icon: Icons.class_outlined,
          color: const Color(0xFF3B82F6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentBatchesScreen(controller: controller),
              ),
            );
          },
        ),
        _buildSectionTile(
          title: 'Attendance History',
          subtitle: 'Daily present/absent logs and percentage',
          icon: Icons.fact_check_outlined,
          color: const Color(0xFF0D9488),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    StudentAttendanceDetailScreen(controller: controller),
              ),
            );
          },
        ),
        _buildSectionTile(
          title: 'Fee Status & Ledger',
          subtitle: 'Inspect fee dues and payment records',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFFD97706),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentFeeStatusScreen(controller: controller),
              ),
            );
          },
        ),
        const Divider(height: 28),
        _buildSectionTile(
          title: 'Sign Out',
          subtitle: 'Log out of your student account',
          icon: Icons.logout,
          color: Colors.red,
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }

  Widget _buildSectionTile({
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
// COMPANION VIEW: MY BATCHES (ORGANIZATION SCOPED)
// ============================================================================

class StudentBatchesScreen extends StatelessWidget {
  final StudentWorkspaceController controller;

  const StudentBatchesScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final batches = controller.batches;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Batches'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: batches.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.class_outlined,
                      size: 52,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Enrolled Batches',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'You are not enrolled in any batches yet. Please contact your coaching institute administration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: batches.length,
              itemBuilder: (context, i) {
                final b = batches[i];
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
                          Expanded(
                            child: Text(
                              b.name,
                              style: const TextStyle(
                                fontSize: 16,
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
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Enrolled',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (b.subject != null && b.subject!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Subject: ${b.subject}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Schedule: ${b.schedule ?? 'Flexible'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// COMPANION VIEW: STUDENT ATTENDANCE DETAILS
// ============================================================================

class StudentAttendanceDetailScreen extends StatelessWidget {
  final StudentWorkspaceController controller;

  const StudentAttendanceDetailScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final total = controller.attendanceTotalCount;
    final present = controller.attendancePresentCount;
    final absent = controller.attendanceAbsentCount;
    final lateCount = controller.attendanceLateCount;
    final pct = controller.attendancePercentage;
    final records = controller.attendanceRecords;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary KPI Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Text(
                  total > 0 ? '${pct.toStringAsFixed(1)}%' : 'No records yet',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: total > 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Overall Attendance Rate',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(
                      'Present',
                      '$present',
                      const Color(0xFF10B981),
                    ),
                    _buildStatCol('Absent', '$absent', const Color(0xFFEF4444)),
                    _buildStatCol(
                      'Late',
                      '$lateCount',
                      const Color(0xFFF59E0B),
                    ),
                    _buildStatCol('Total', '$total', const Color(0xFF0F172A)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Daily Attendance Logs',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          if (records.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'No attendance logs recorded yet for your account.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...records.map((r) {
              final status = (r['status'] ?? 'present').toString();
              final dateStr = (r['date'] ?? r['created_at'] ?? '').toString();
              final batchName = (r['batch_name'] ?? r['batch_id'] ?? 'Batch')
                  .toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batchName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status.toLowerCase() == 'present'
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: status.toLowerCase() == 'present'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

// ============================================================================
// COMPANION VIEW: STUDENT FEE STATUS & HISTORY
// ============================================================================

class StudentFeeStatusScreen extends StatelessWidget {
  final StudentWorkspaceController controller;

  const StudentFeeStatusScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final fee = controller.feeRecord;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fee Status & Ledger'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Outstanding Balance',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (fee?.balance ?? 0) <= 0
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (fee?.status ?? 'PAID').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: (fee?.balance ?? 0) <= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${(fee?.balance ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Due',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          '₹${(fee?.amountDue ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Paid',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          '₹${(fee?.amountPaid ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Payment History & Ledger',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<PaymentEntry>>(
            future: FeeService.getPayments(
              orgId: controller.orgId,
              studentId: controller.studentUid,
              billingMonth: fee?.billingMonth.isNotEmpty == true
                  ? fee!.billingMonth
                  : FeeService.currentMonthKey,
            ),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final payments = snap.data ?? [];
              if (payments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      'No payment receipts found for this billing cycle.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ),
                );
              }

              final df = DateFormat('dd MMM yyyy, hh:mm a');
              return Column(
                children: payments.map((p) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${p.amount.toStringAsFixed(2)} — ${PaymentEntry.methodLabel(p.method)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${df.format(p.paidAt)}${p.referenceNumber != null ? ' | Ref: ${p.referenceNumber}' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fee dues and payment records are maintained authoritatively by the institute administration.',
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
}
