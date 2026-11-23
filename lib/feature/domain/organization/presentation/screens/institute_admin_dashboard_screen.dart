import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/batch_assignment_service.dart';
import 'package:test_nest/core/services/organization_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/core/utils/custom_snackbar.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/institute_admin_dashboard_controller.dart';
import 'package:test_nest/feature/domain/organization/presentation/screens/batch_details_screen.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/join_request_model.dart';
import 'package:test_nest/model/organization_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/widgets/batch_qr_code_dialog.dart';
import 'package:test_nest/routes/app_routes.dart';
import 'package:test_nest/main.dart';

class InstituteAdminDashboardScreen extends StatelessWidget {
  const InstituteAdminDashboardScreen({super.key});

  static const Color _muted = Color(0xFF64748B);
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
              child: IndexedStack(
                index: controller.currentTabIndex,
                children: [
                  _OwnerHomeTab(controller: controller, tenantCtx: tenantCtx),
                  _OwnerTeachersTab(
                    controller: controller,
                    tenantCtx: tenantCtx,
                  ),
                  _OwnerStudentsTab(
                    controller: controller,
                    tenantCtx: tenantCtx,
                  ),
                  _OwnerBatchesTab(
                    controller: controller,
                    tenantCtx: tenantCtx,
                  ),
                  _OwnerMoreTab(controller: controller, tenantCtx: tenantCtx),
                ],
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: controller.currentTabIndex,
              onTap: controller.switchTab,
              type: BottomNavigationBarType.fixed,
              backgroundColor: _surface,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: _muted,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'Teachers',
                ),
                BottomNavigationBarItem(
                  icon: controller.pendingJoinRequests > 0
                      ? Badge(
                          label: Text('${controller.pendingJoinRequests}'),
                          child: const Icon(Icons.school_outlined),
                        )
                      : const Icon(Icons.school_outlined),
                  activeIcon: controller.pendingJoinRequests > 0
                      ? Badge(
                          label: Text('${controller.pendingJoinRequests}'),
                          child: const Icon(Icons.school),
                        )
                      : const Icon(Icons.school),
                  label: 'Students',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.class_outlined),
                  activeIcon: Icon(Icons.class_),
                  label: 'Batches',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// TAB 1: OWNER HOME (DASHBOARD)
// =============================================================================

class _OwnerHomeTab extends StatelessWidget {
  final InstituteAdminDashboardController controller;
  final ActiveTenantContext tenantCtx;

  const _OwnerHomeTab({required this.controller, required this.tenantCtx});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => controller.refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _buildTopHeader(context),
          if (controller.pendingJoinRequests > 0) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => controller.switchTab(2),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'New Joining Requests',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${controller.pendingJoinRequests}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Students are waiting for your approval to join batches',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildSummaryStatsGrid(),
          const SizedBox(height: 20),
          _buildManagementShortcutsGrid(context),
          const SizedBox(height: 20),
          _buildRecentJoinRequestsSection(context),
          const SizedBox(height: 20),
          _buildRecentActivitySection(context),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final ownerName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (tenantCtx.activeOrg?.ownerName.isNotEmpty == true
            ? tenantCtx.activeOrg!.ownerName
            : 'Institute Owner');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
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
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenantCtx.activeOrgName.isNotEmpty
                      ? tenantCtx.activeOrgName
                      : 'Coaching Institute',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ownerName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'OWNER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Institute Notices',
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF2563EB)),
            onPressed: () => Get.toNamed(AppRoutes.noticeList),
          ),
          IconButton(
            tooltip: 'Owner Profile',
            icon: const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
            onPressed: () => _OwnerMoreTab.showOwnerProfileModal(
              context,
              tenantCtx,
              () => _confirmSignOutFromHome(context),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOutFromHome(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
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

  Widget _buildSummaryStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 4 : 2;
        final aspectRatio = constraints.maxWidth < 360 ? 1.35 : 1.5;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: aspectRatio,
          children: [
            _buildStatCard(
              title: 'Total Students',
              value: '${controller.totalStudents}',
              icon: Icons.school_outlined,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
            ),
            _buildStatCard(
              title: 'Total Teachers',
              value: '${controller.totalTeachers}',
              icon: Icons.people_outline,
              iconColor: const Color(0xFF1D4ED8),
              bgColor: const Color(0xFFEFF6FF),
            ),
            _buildStatCard(
              title: 'Total Batches',
              value: '${controller.totalBatches}',
              icon: Icons.class_outlined,
              iconColor: const Color(0xFF3B82F6),
              bgColor: const Color(0xFFEFF6FF),
            ),
            _buildStatCard(
              title: 'Total Exams',
              value: '${controller.totalExams}',
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFF1E40AF),
              bgColor: const Color(0xFFEFF6FF),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementShortcutsGrid(BuildContext context) {
    final shortcuts = [
      _ShortcutItem(
        title: 'Teachers',
        subtitle: 'Faculty & accounts',
        icon: Icons.people_rounded,
        color: const Color(0xFF2563EB),
        onTap: () => controller.switchTab(1),
      ),
      _ShortcutItem(
        title: 'Teacher Salaries',
        subtitle: 'Disbursements',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF059669),
        onTap: () => Get.toNamed(AppRoutes.ownerTeacherSalaries),
      ),
      _ShortcutItem(
        title: 'Students',
        subtitle: 'Directory & requests',
        icon: Icons.school_rounded,
        color: const Color(0xFF2563EB),
        onTap: () => controller.switchTab(2),
      ),
      _ShortcutItem(
        title: 'Batches',
        subtitle: 'Class groupings',
        icon: Icons.class_rounded,
        color: const Color(0xFF1E40AF),
        onTap: () => controller.switchTab(3),
      ),
      _ShortcutItem(
        title: 'Student Fees',
        subtitle: 'Dues & collections',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFD97706),
        onTap: () => Get.toNamed(AppRoutes.ownerStudentFees),
      ),
      _ShortcutItem(
        title: 'Exams',
        subtitle: 'Institute assessments',
        icon: Icons.assignment_rounded,
        color: const Color(0xFF1D4ED8),
        onTap: () => Get.toNamed(AppRoutes.teacherExams),
      ),
      _ShortcutItem(
        title: 'Attendance',
        subtitle: 'Daily mark sheets',
        icon: Icons.fact_check_rounded,
        color: const Color(0xFF0D9488),
        onTap: () => Get.toNamed(AppRoutes.attendanceOverview),
      ),
      _ShortcutItem(
        title: 'Notices',
        subtitle: 'Institute broadcasts',
        icon: Icons.campaign_rounded,
        color: const Color(0xFF7C3AED),
        onTap: () => Get.toNamed(AppRoutes.noticeList),
      ),
    ];

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
          const Text(
            'Management Shortcuts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shortcuts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, i) {
              final item = shortcuts[i];
              return InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.color.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, size: 18, color: item.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentJoinRequestsSection(BuildContext context) {
    final requests = controller.recentJoinRequests;
    final orgService = OrganizationService();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Pending Join Requests',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (requests.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${requests.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton(
                onPressed: () =>
                    controller.switchTab(2), // Switch to Students tab
                child: const Text('Review All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (requests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'No pending join requests. All caught up!',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.take(3).length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        req.studentName.isNotEmpty
                            ? req.studentName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.studentName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  req.studentEmail,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                      tooltip: 'Approve',
                      onPressed: () async {
                        final reviewer = FirebaseAuth.instance.currentUser?.uid ?? '';
                        try {
                          await orgService.approveStudentJoinRequest(
                            orgId: controller.orgId,
                            orgName: controller.orgName,
                            requestId: req.id,
                            studentUid: req.studentUid,
                            reviewerUid: reviewer,
                            studentName: req.studentName,
                            studentEmail: req.studentEmail,
                            assignedBatchId: req.assignedBatchId ?? (req.batchId.isNotEmpty ? req.batchId : null),
                            assignedBatchName: req.assignedBatchName ?? (req.batchName.isNotEmpty ? req.batchName : null),
                          );
                          CustomSnackbar.showSuccess(
                            context: context,
                            title: 'Approved',
                            message: '${req.studentName} has been approved.',
                          );
                        } catch (e) {
                          CustomSnackbar.showError(
                            context: context,
                            title: 'Error',
                            message: 'Could not approve: $e',
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        color: Color(0xFFEF4444),
                        size: 24,
                      ),
                      tooltip: 'Reject',
                      onPressed: () async {
                        final reviewer = FirebaseAuth.instance.currentUser?.uid ?? '';
                        try {
                          await orgService.rejectStudentJoinRequest(
                            orgId: controller.orgId,
                            requestId: req.id,
                            reviewerUid: reviewer,
                          );
                          CustomSnackbar.showSuccess(
                            context: context,
                            title: 'Rejected',
                            message: '${req.studentName} request was rejected.',
                          );
                        } catch (e) {
                          CustomSnackbar.showError(
                            context: context,
                            title: 'Error',
                            message: 'Could not reject: $e',
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    final exams = controller.recentExams;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Institute Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.teacherExams),
                child: const Text('All Exams'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (exams.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No recent exam activity recorded.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exams.take(3).length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final e = exams[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.examName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Status: ${e.status} • Batch: ${e.batch}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      e.examDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ShortcutItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// =============================================================================
// TAB 2: OWNER TEACHERS MANAGEMENT
// =============================================================================

class _OwnerTeachersTab extends StatefulWidget {
  final InstituteAdminDashboardController controller;
  final ActiveTenantContext tenantCtx;

  const _OwnerTeachersTab({required this.controller, required this.tenantCtx});

  @override
  State<_OwnerTeachersTab> createState() => _OwnerTeachersTabState();
}

class _OwnerTeachersTabState extends State<_OwnerTeachersTab> {
  final OrganizationService _orgService = OrganizationService();
  final BatchAssignmentService _assignmentService = BatchAssignmentService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTeachersHeader(),
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<List<OrganizationMemberModel>>(
            stream: _orgService.streamOrganizationMembers(
              widget.controller.orgId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final allMembers = snapshot.data ?? [];
              final teachers = allMembers
                  .where((m) => m.isTeacher || m.isAdmin)
                  .where((m) {
                    if (_searchQuery.isEmpty) return true;
                    final q = _searchQuery.toLowerCase();
                    return m.name.toLowerCase().contains(q) ||
                        m.email.toLowerCase().contains(q);
                  })
                  .toList();

              if (teachers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No teachers added yet.'
                              : 'No teachers match "$_searchQuery".',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add_alt_1, size: 16),
                          label: const Text('Add Teacher'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showCreateTeacherDialog(context),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: teachers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final teacher = teachers[index];
                  return _buildTeacherCard(teacher);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeachersHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Faculty Directory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.mark_email_read_outlined, size: 14),
                label: const Text('Invitations'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => Get.toNamed(AppRoutes.manageInvitations),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1, size: 14),
                label: const Text('Add Teacher'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _showCreateTeacherDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        decoration: InputDecoration(
          hintText: 'Search faculty by name or email...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherCard(OrganizationMemberModel teacher) {
    final isSuspended = teacher.status.toLowerCase() == 'suspended';
    final batches = widget.controller.batches;
    final assignedBatchObjects = batches
        .where((b) => teacher.assignedBatchIds.contains(b.id))
        .toList();
    int studentCountAcrossBatches = 0;
    for (final b in assignedBatchObjects) {
      studentCountAcrossBatches += b.studentCount;
    }

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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: teacher.isAdmin
                    ? const Color(0xFFF5F3FF)
                    : const Color(0xFFEFF6FF),
                foregroundColor: teacher.isAdmin
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF2563EB),
                child: Text(
                  teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : 'T',
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      teacher.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSuspended
                      ? Colors.red.shade100
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSuspended ? 'Suspended' : teacher.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSuspended
                        ? Colors.red.shade800
                        : const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          if ((teacher.teacherId != null && teacher.teacherId!.isNotEmpty) ||
              (teacher.subject != null && teacher.subject!.isNotEmpty) ||
              (teacher.monthlySalary != null && teacher.monthlySalary! > 0)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (teacher.teacherId != null && teacher.teacherId!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 12,
                          color: Color(0xFF1D4ED8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          teacher.teacherId!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (teacher.subject != null && teacher.subject!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      teacher.subject!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                if (teacher.monthlySalary != null &&
                    teacher.monthlySalary! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Text(
                      '₹${teacher.monthlySalary!.toStringAsFixed(0)}/mo',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7E22CE),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 13,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                'Joined ${DateFormat('dd MMM yyyy').format(teacher.joinedAt)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.people_outline,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                '$studentCountAcrossBatches Students',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (assignedBatchObjects.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: assignedBatchObjects.map((b) {
                return Chip(
                  label: Text(b.name, style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(0),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                label: const Text('Manage Batches'),
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _showManageTeacherBatches(teacher),
              ),
              if (!teacher.isAdmin) ...[
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: isSuspended
                        ? Colors.green
                        : Colors.orange.shade800,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _toggleTeacherStatus(teacher),
                  child: Text(isSuspended ? 'Reactivate' : 'Suspend'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showManageTeacherBatches(OrganizationMemberModel teacher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allBatches = widget.controller.batches;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Batches: ${teacher.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Assign or unassign teacher to institute batches',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    if (allBatches.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No batches available.'),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: allBatches.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final b = allBatches[index];
                            final isAssigned = teacher.assignedBatchIds
                                .contains(b.id);

                            return CheckboxListTile(
                              title: Text(b.name),
                              subtitle: Text(
                                '${b.studentCount} students • ${b.subject ?? ""}',
                              ),
                              value: isAssigned,
                              onChanged: (val) async {
                                if (val == true) {
                                  await _assignmentService.assignTeacherToBatch(
                                    orgId: widget.controller.orgId,
                                    batchId: b.id,
                                    teacherUid: teacher.uid,
                                  );
                                  teacher.assignedBatchIds.add(b.id);
                                } else {
                                  await _assignmentService
                                      .removeTeacherFromBatch(
                                        orgId: widget.controller.orgId,
                                        batchId: b.id,
                                        teacherUid: teacher.uid,
                                      );
                                  teacher.assignedBatchIds.remove(b.id);
                                }
                                setSheetState(() {});
                                setState(() {});
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
      },
    );
  }

  void _toggleTeacherStatus(OrganizationMemberModel teacher) {
    final isSuspended = teacher.status.toLowerCase() == 'suspended';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSuspended ? 'Reactivate Teacher?' : 'Suspend Teacher?'),
        content: Text(
          isSuspended
              ? 'Reactivate ${teacher.name}\'s faculty account?'
              : 'Suspend ${teacher.name}\'s access to the institute? '
                    'Student records, exams, and attendance history will remain untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuspended ? Colors.green : Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (isSuspended) {
                  await _orgService.reactivateMember(
                    orgId: widget.controller.orgId,
                    memberUid: teacher.uid,
                  );
                } else {
                  await _orgService.suspendMember(
                    orgId: widget.controller.orgId,
                    memberUid: teacher.uid,
                  );
                }
                CustomSnackbar.showSuccess(
                  context: context,
                  title: isSuspended ? 'Reactivated' : 'Suspended',
                  message: '${teacher.name} status updated.',
                );
              } catch (e) {
                CustomSnackbar.showError(
                  context: context,
                  title: 'Error',
                  message: 'Action failed: $e',
                );
              }
            },
            child: Text(
              isSuspended ? 'Reactivate' : 'Suspend',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTeacherDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final qualCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

    String selectedGender = 'Male';
    final List<String> selectedBatchIds = [];
    bool obscurePassword = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final batches = widget.controller.batches;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Faculty Member',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Create and provision teacher credentials',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Full Name
                        const Text(
                          'Full Name *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Dr. Ramesh Kumar',
                            prefixIcon: const Icon(Icons.person_outline, size: 18),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Full Name is required'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Email
                        const Text(
                          'Email Address *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'e.g. teacher@institute.com',
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                              size: 18,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Initial Password
                        const Text(
                          'Initial Password *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: passwordCtrl,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'At least 6 characters',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Password is required';
                            }
                            if (v.trim().length < 6) {
                              return 'Minimum 6 characters required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Subject / Specialization
                        const Text(
                          'Subject / Specialization *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: subjectCtrl,
                          decoration: InputDecoration(
                            hintText: 'e.g. Physics, Mathematics',
                            prefixIcon: const Icon(
                              Icons.auto_stories_outlined,
                              size: 18,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Subject is required'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Row: Mobile & Gender
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mobile (Optional)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: '+91 98765 43210',
                                      prefixIcon: const Icon(
                                        Icons.phone_outlined,
                                        size: 18,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gender',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    value: selectedGender,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Male',
                                        child: Text('Male', style: TextStyle(fontSize: 13)),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Female',
                                        child: Text('Female', style: TextStyle(fontSize: 13)),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Other',
                                        child: Text('Other', style: TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setDialogState(() => selectedGender = v);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Row: Qualification & Experience
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Qualification',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: qualCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. M.Sc, B.Ed',
                                      prefixIcon: const Icon(
                                        Icons.school_outlined,
                                        size: 18,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Experience',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: expCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 5 Years',
                                      prefixIcon: const Icon(
                                        Icons.work_history_outlined,
                                        size: 18,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Monthly Salary
                        const Text(
                          'Monthly Salary (₹)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: salaryCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'e.g. 25000',
                            prefixIcon: const Icon(
                              Icons.currency_rupee_rounded,
                              size: 18,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Assign Batches (Optional)
                        if (batches.isNotEmpty) ...[
                          const Text(
                            'Assign Initial Batches (Optional)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: batches.map((b) {
                              final isSelected = selectedBatchIds.contains(b.id);
                              return FilterChip(
                                label: Text(b.name, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (sel) {
                                  setDialogState(() {
                                    if (sel) {
                                      selectedBatchIds.add(b.id);
                                    } else {
                                      selectedBatchIds.remove(b.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);

                          try {
                            final double? salary =
                                double.tryParse(salaryCtrl.text.trim());

                            final result =
                                await _orgService.createTeacherAccount(
                              orgId: widget.controller.orgId,
                              orgName: widget.tenantCtx.activeOrgName,
                              name: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim().toLowerCase(),
                              initialPassword: passwordCtrl.text,
                              subject: subjectCtrl.text.trim(),
                              mobile: phoneCtrl.text.trim().isNotEmpty
                                  ? phoneCtrl.text.trim()
                                  : null,
                              gender: selectedGender,
                              qualification: qualCtrl.text.trim().isNotEmpty
                                  ? qualCtrl.text.trim()
                                  : null,
                              experience: expCtrl.text.trim().isNotEmpty
                                  ? expCtrl.text.trim()
                                  : null,
                              monthlySalary: salary,
                              joiningDate: DateTime.now(),
                              assignedBatchIds: selectedBatchIds,
                            );

                            if (context.mounted) {
                              Navigator.pop(dialogCtx);
                              _showTeacherCreatedSuccessDialog(context, result);
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (context.mounted) {
                              CustomSnackbar.showError(
                                context: context,
                                title: 'Account Creation Failed',
                                message: '$e',
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTeacherCreatedSuccessDialog(
    BuildContext context,
    Map<String, dynamic> result,
  ) {
    final name = result['name'] ?? '';
    final email = result['email'] ?? '';
    final initialPassword = result['initialPassword'] ?? '';
    final teacherId = result['teacherId'] ?? '';
    final subject = result['subject'] ?? '';
    final salary = result['monthlySalary'] as num? ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF166534),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher Account Created',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Credentials generated successfully',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildCredentialRow('Teacher Name', name),
                    const Divider(height: 16),
                    _buildCredentialRow('Teacher ID', teacherId),
                    const Divider(height: 16),
                    _buildCredentialRow('Subject', subject),
                    const Divider(height: 16),
                    _buildCredentialRow('Login Email', email),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Initial Password',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              initialPassword,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Copy Password',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: initialPassword),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (salary > 0) ...[
                      const Divider(height: 16),
                      _buildCredentialRow(
                        'Monthly Salary',
                        '₹${salary.toStringAsFixed(0)}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Share these credentials with the teacher. They can log in immediately from the Teacher Portal.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_all_rounded, size: 16),
            label: const Text('Copy All Details'),
            onPressed: () {
              final text =
                  'Institute: ${widget.tenantCtx.activeOrgName}\n'
                  'Teacher Name: $name\n'
                  'Teacher ID: $teacherId\n'
                  'Login Email: $email\n'
                  'Password: $initialPassword\n'
                  'Subject: $subject\n';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All credentials copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 3: OWNER STUDENTS DIRECTORY & JOIN REQUESTS
// =============================================================================

class _OwnerStudentsTab extends StatefulWidget {
  final InstituteAdminDashboardController controller;
  final ActiveTenantContext tenantCtx;

  const _OwnerStudentsTab({required this.controller, required this.tenantCtx});

  @override
  State<_OwnerStudentsTab> createState() => _OwnerStudentsTabState();
}

class _OwnerStudentsTabState extends State<_OwnerStudentsTab>
    with SingleTickerProviderStateMixin {
  final OrganizationService _orgService = OrganizationService();
  late TabController _subTabController;
  final TextEditingController _searchCtrl = TextEditingController();

  String _searchQuery = '';
  String? _selectedBatchFilter;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _subTabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: AppColors.primary,
            tabs: [
              const Tab(text: 'All Students'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Join Requests'),
                    if (widget.controller.pendingJoinRequests > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${widget.controller.pendingJoinRequests}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [_buildAllStudentsSubTab(), _buildJoinRequestsSubTab()],
          ),
        ),
      ],
    );
  }

  // ── Sub-tab 1: All Institute Students ─────────────────────────────────────

  Widget _buildAllStudentsSubTab() {
    return Column(
      children: [
        _buildStudentFilters(),
        Expanded(
          child: StreamBuilder<List<OrganizationMemberModel>>(
            stream: _orgService.streamInstituteStudents(
              widget.controller.orgId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final allStudents = snapshot.data ?? [];
              final filtered = allStudents.where((s) {
                if (_selectedBatchFilter != null &&
                    _selectedBatchFilter!.isNotEmpty) {
                  if (!s.assignedBatchIds.contains(_selectedBatchFilter)) {
                    return false;
                  }
                }
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return s.name.toLowerCase().contains(q) ||
                    s.email.toLowerCase().contains(q);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No students found in institute.'
                              : 'No students match your query.',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Students join via joining codes and are approved by you.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final student = filtered[index];
                  return _buildStudentCard(student);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentFilters() {
    final batches = widget.controller.batches;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search by student name or email...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (batches.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Batches'),
                    selected: _selectedBatchFilter == null,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedBatchFilter = null);
                    },
                  ),
                  const SizedBox(width: 6),
                  ...batches.map((b) {
                    final isSel = _selectedBatchFilter == b.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(b.name),
                        selected: isSel,
                        onSelected: (sel) {
                          setState(() {
                            _selectedBatchFilter = sel ? b.id : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentCard(OrganizationMemberModel student) {
    final batches = widget.controller.batches;
    final assignedBatchObjects = batches
        .where((b) => student.assignedBatchIds.contains(b.id))
        .toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showStudentProfileModal(student),
        borderRadius: BorderRadius.circular(14),
        child: Container(
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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFEEF2FF),
                    foregroundColor: AppColors.primary,
                    child: Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          student.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    onSelected: (action) {
                      if (action == 'profile') {
                        _showStudentProfileModal(student);
                      } else if (action == 'enroll') {
                        _showEnrollBatchDialog(student);
                      } else if (action == 'transfer') {
                        _showTransferStudentDialog(student);
                      } else if (action == 'remove') {
                        _showRemoveFromBatchDialog(student);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('View Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'enroll',
                        child: Row(
                          children: [
                            Icon(Icons.add_task, size: 18),
                            SizedBox(width: 8),
                            Text('Enroll in Batch'),
                          ],
                        ),
                      ),
                      if (student.assignedBatchIds.isNotEmpty) ...[
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
                                Icons.remove_circle_outline,
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
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: assignedBatchObjects.isNotEmpty
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      assignedBatchObjects.isNotEmpty
                          ? '${assignedBatchObjects.length} ${assignedBatchObjects.length == 1 ? "Batch" : "Batches"}'
                          : 'No Batches',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: assignedBatchObjects.isNotEmpty
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap to view student profile & manage batches',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (assignedBatchObjects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: assignedBatchObjects.map((b) {
                    final sessionText = b.effectiveSession.isNotEmpty
                        ? ' (${b.effectiveSession})'
                        : '';
                    return Chip(
                      label: Text(
                        '${b.name}$sessionText',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      backgroundColor: const Color(0xFFEFF6FF),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentProfileModal(OrganizationMemberModel student) {
    final parentCtx = context;
    showModalBottomSheet(
      context: parentCtx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final batches = widget.controller.batches;
          final assignedBatches = batches
              .where((b) => student.assignedBatchIds.contains(b.id))
              .toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Student Identity Card
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFEEF2FF),
                      foregroundColor: AppColors.primary,
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Student',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enrolled since ${DateFormat('MMM yyyy').format(student.joinedAt)}',
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

                // Batches Header with Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enrolled Batches',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${assignedBatches.length} active ${assignedBatches.length == 1 ? "enrollment" : "enrollments"}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _showEnrollBatchDialog(student);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Batch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Batches List
                if (assignedBatches.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.folder_off_outlined,
                          size: 36,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Not enrolled in any batch yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Click "+ Add Batch" above to assign this student to one or more batches.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: assignedBatches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final b = assignedBatches[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.class_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Session: ${b.effectiveSession.isNotEmpty ? b.effectiveSession : "All"} • Monthly Fee: ₹${b.monthlyFee.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                tooltip: 'Remove from this batch',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: parentCtx,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Remove from Batch?'),
                                      content: Text(
                                        'Remove ${student.name} from "${b.name}"? '
                                        'Student will remain in their other enrolled batches and in the institute.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () => Navigator.pop(c, true),
                                          child: const Text(
                                            'Remove',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await _orgService.removeStudentFromBatch(
                                        orgId: widget.controller.orgId,
                                        batchId: b.id,
                                        studentUid: student.uid,
                                      );
                                      student.assignedBatchIds.remove(b.id);
                                      setSheetState(() {});
                                      setState(() {});
                                      CustomSnackbar.showSuccess(
                                        context: parentCtx,
                                        title: 'Removed from Batch',
                                        message: '${student.name} removed from ${b.name}.',
                                      );
                                    } catch (e) {
                                      CustomSnackbar.showError(
                                        context: parentCtx,
                                        title: 'Error',
                                        message: 'Failed to remove: $e',
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    if (assignedBatches.isNotEmpty) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            _showTransferStudentDialog(student);
                          },
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('Transfer Batch'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEnrollBatchDialog(OrganizationMemberModel student) {
    final parentCtx = context;
    final availableBatches = widget.controller.batches
        .where((b) => !student.assignedBatchIds.contains(b.id) && !b.isArchived)
        .toList();

    showDialog(
      context: parentCtx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Enroll ${student.name} in Batch'),
        content: availableBatches.isEmpty
            ? const Text('Student is already enrolled in all active batches.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableBatches.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, index) {
                    final b = availableBatches[index];
                    return ListTile(
                      title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Session: ${b.effectiveSession.isNotEmpty ? b.effectiveSession : "All"} • Fee: ₹${b.monthlyFee.toStringAsFixed(0)}',
                      ),
                      trailing: const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.primary,
                      ),
                      onTap: () async {
                        Navigator.pop(dialogCtx);
                        try {
                          await _orgService.enrollStudentInBatch(
                            orgId: widget.controller.orgId,
                            batchId: b.id,
                            batchName: b.name,
                            studentUid: student.uid,
                            studentName: student.name,
                            studentEmail: student.email,
                          );
                          student.assignedBatchIds.add(b.id);
                          setState(() {});
                          CustomSnackbar.showSuccess(
                            context: parentCtx,
                            title: 'Enrolled',
                            message: '${student.name} enrolled in ${b.name}.',
                          );
                        } catch (e) {
                          CustomSnackbar.showError(
                            context: parentCtx,
                            title: 'Error',
                            message: 'Enrollment failed: $e',
                          );
                        }
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTransferStudentDialog(OrganizationMemberModel student) {
    final parentCtx = context;
    final currentBatches = widget.controller.batches
        .where((b) => student.assignedBatchIds.contains(b.id))
        .toList();
    final otherBatches = widget.controller.batches
        .where((b) => !student.assignedBatchIds.contains(b.id) && !b.isArchived)
        .toList();

    if (currentBatches.isEmpty || otherBatches.isEmpty) {
      CustomSnackbar.showInfo(
        context: parentCtx,
        title: 'Transfer Not Possible',
        message: 'No alternative batches available to transfer to.',
      );
      return;
    }

    String fromBatchId = currentBatches.first.id;
    String toBatchId = otherBatches.first.id;

    showDialog(
      context: parentCtx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text('Transfer ${student.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('From Batch:'),
              DropdownButton<String>(
                isExpanded: true,
                value: fromBatchId,
                items: currentBatches
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => fromBatchId = v);
                },
              ),
              const SizedBox(height: 12),
              const Text('To Batch:'),
              DropdownButton<String>(
                isExpanded: true,
                value: toBatchId,
                items: otherBatches
                    .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => toBatchId = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final targetBatch = otherBatches.firstWhere(
                  (b) => b.id == toBatchId,
                );
                try {
                  await _orgService.transferStudentBatch(
                    orgId: widget.controller.orgId,
                    fromBatchId: fromBatchId,
                    toBatchId: toBatchId,
                    toBatchName: targetBatch.name,
                    studentUid: student.uid,
                    studentName: student.name,
                    studentEmail: student.email,
                  );
                  student.assignedBatchIds.remove(fromBatchId);
                  student.assignedBatchIds.add(toBatchId);
                  setState(() {});
                  CustomSnackbar.showSuccess(
                    context: parentCtx,
                    title: 'Transferred',
                    message:
                        '${student.name} transferred to ${targetBatch.name}.',
                  );
                } catch (e) {
                  CustomSnackbar.showError(
                    context: parentCtx,
                    title: 'Error',
                    message: 'Transfer failed: $e',
                  );
                }
              },
              child: const Text(
                'Transfer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveFromBatchDialog(OrganizationMemberModel student) {
    final parentCtx = context;
    final currentBatches = widget.controller.batches
        .where((b) => student.assignedBatchIds.contains(b.id))
        .toList();

    showDialog(
      context: parentCtx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Remove from Batch: ${student.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the batch to remove the student from. '
              'The student will remain an organization member.',
            ),
            const SizedBox(height: 12),
            ...currentBatches.map(
              (b) => ListTile(
                title: Text(b.name),
                trailing: const Icon(Icons.remove_circle, color: Colors.red),
                onTap: () async {
                  Navigator.pop(dialogCtx);
                  try {
                    await _orgService.removeStudentFromBatch(
                      orgId: widget.controller.orgId,
                      batchId: b.id,
                      studentUid: student.uid,
                    );
                    student.assignedBatchIds.remove(b.id);
                    setState(() {});
                    CustomSnackbar.showSuccess(
                      context: parentCtx,
                      title: 'Removed from Batch',
                      message: '${student.name} removed from ${b.name}.',
                    );
                  } catch (e) {
                    CustomSnackbar.showError(
                      context: parentCtx,
                      title: 'Error',
                      message: 'Action failed: $e',
                    );
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ── Sub-tab 2: Pending Join Requests (Section 7) ──────────────────────────

  Widget _buildJoinRequestsSubTab() {
    return StreamBuilder<List<JoinRequestModel>>(
      stream: _orgService.streamOrganizationJoinRequests(
        widget.controller.orgId,
        status: 'pending',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No pending requests.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Student admission requests to your institute will appear here.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final req = requests[index];
            return _buildJoinRequestCard(req);
          },
        );
      },
    );
  }

  Widget _buildJoinRequestCard(JoinRequestModel req) {
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
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  req.studentName.isNotEmpty
                      ? req.studentName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.studentName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      req.studentEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (req.requestedAt != null)
                Text(
                  DateFormat('dd MMM').format(req.requestedAt!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
            ],
          ),
          if (req.batchName.isNotEmpty ||
              (req.assignedBatchName != null &&
                  req.assignedBatchName!.isNotEmpty)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Requested Batch: ${req.assignedBatchName ?? req.batchName}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _confirmRejectRequest(req),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _showApproveRequestDialog(req),
                child: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showApproveRequestDialog(JoinRequestModel req) {
    final batches = widget.controller.batches;
    String? selectedBatchId =
        req.assignedBatchId ?? (req.batchId.isNotEmpty ? req.batchId : null);
    if (selectedBatchId == null && batches.isNotEmpty) {
      selectedBatchId = batches.first.id;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Approve Admission: ${req.studentName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Approve ${req.studentName} (${req.studentEmail}) as an active student in ${widget.controller.orgName}.',
              ),
              const SizedBox(height: 14),
              const Text(
                'Assign Initial Batch (Optional):',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              if (batches.isEmpty)
                const Text(
                  'No batches available. Student will join without batch.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                )
              else
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedBatchId,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No batch (General Admission)'),
                    ),
                    ...batches.map(
                      (b) => DropdownMenuItem<String>(
                        value: b.id,
                        child: Text(b.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => selectedBatchId = v),
                ),
            ],
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
                Navigator.pop(context);
                final user = FirebaseAuth.instance.currentUser;
                final reviewerUid = user?.uid ?? '';
                final batchObj = batches
                    .where((b) => b.id == selectedBatchId)
                    .firstOrNull;

                try {
                  await _orgService.approveStudentJoinRequest(
                    orgId: widget.controller.orgId,
                    orgName: widget.controller.orgName,
                    requestId: req.id,
                    studentUid: req.studentUid,
                    studentName: req.studentName,
                    studentEmail: req.studentEmail,
                    studentPhone: req.studentPhone ?? '',
                    reviewerUid: reviewerUid,
                    assignedBatchId: selectedBatchId,
                    assignedBatchName: batchObj?.name,
                  );
                  CustomSnackbar.showSuccess(
                    context: context,
                    title: 'Student Approved',
                    message:
                        '${req.studentName} is now an active institute student.',
                  );
                } catch (e) {
                  CustomSnackbar.showError(
                    context: context,
                    title: 'Error',
                    message: 'Approval failed: $e',
                  );
                }
              },
              child: const Text(
                'Confirm Approval',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRejectRequest(JoinRequestModel req) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Join Request?'),
        content: Text(
          'Are you sure you want to reject ${req.studentName}\'s request?',
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
              final user = FirebaseAuth.instance.currentUser;
              final reviewerUid = user?.uid ?? '';
              try {
                await _orgService.rejectStudentJoinRequest(
                  orgId: widget.controller.orgId,
                  requestId: req.id,
                  reviewerUid: reviewerUid,
                );
                CustomSnackbar.showSuccess(
                  context: context,
                  title: 'Rejected',
                  message: 'Join request was rejected.',
                );
              } catch (e) {
                CustomSnackbar.showError(
                  context: context,
                  title: 'Error',
                  message: 'Action failed: $e',
                );
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 4: OWNER BATCHES MANAGEMENT
// =============================================================================

class _OwnerBatchesTab extends StatefulWidget {
  final InstituteAdminDashboardController controller;
  final ActiveTenantContext tenantCtx;

  const _OwnerBatchesTab({required this.controller, required this.tenantCtx});

  @override
  State<_OwnerBatchesTab> createState() => _OwnerBatchesTabState();
}

class _OwnerBatchesTabState extends State<_OwnerBatchesTab> {
  final OrganizationService _orgService = OrganizationService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBatchesHeader(),
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<List<BatchModel>>(
            stream: _orgService.streamInstituteBatches(widget.controller.orgId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final batches = snapshot.data ?? [];
              final filtered = batches.where((b) {
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                return b.name.toLowerCase().contains(q) ||
                    (b.subject != null && b.subject!.toLowerCase().contains(q));
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.class_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No batches created yet.'
                              : 'No batches match "$_searchQuery".',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create Batch'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _showCreateBatchSheet,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final b = filtered[index];
                  return _buildBatchCard(b);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBatchesHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Institute Batches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Batch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: _showCreateBatchSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        decoration: InputDecoration(
          hintText: 'Search batches by name or subject...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBatchCard(BatchModel b) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Get.to(
          () => BatchDetailsScreen(orgId: widget.controller.orgId, batch: b),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                          b.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (b.subject != null && b.subject!.isNotEmpty)
                          Text(
                            b.subject!,
                            style: const TextStyle(
                              fontSize: 12,
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
                      color: b.isArchived
                          ? Colors.grey.shade100
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      b.isArchived ? 'Archived' : 'Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: b.isArchived
                            ? Colors.grey.shade600
                            : const Color(0xFF166534),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                    onSelected: (val) {
                      if (val == 'delete') {
                        _confirmDeleteBatch(b);
                      } else if (val == 'archive') {
                        _toggleBatchArchive(b);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              b.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                              size: 18,
                              color: const Color(0xFF475569),
                            ),
                            const SizedBox(width: 8),
                            Text(b.isArchived ? 'Unarchive' : 'Archive'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete Batch', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (b.schedule != null && b.schedule!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      b.schedule!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${b.studentCount} Students',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${b.assignedTeacherIds.length} Teachers',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 11,
                    color: Color(0xFF2563EB),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.vpn_key_rounded, size: 12, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          'Code: ${b.activeJoinCode.isNotEmpty ? b.activeJoinCode : b.id}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      final code = b.activeJoinCode.isNotEmpty ? b.activeJoinCode : b.id;
                      Clipboard.setData(ClipboardData(text: code));
                      CustomSnackbar.showSuccess(
                        context: context,
                        title: 'Copied',
                        message: 'Batch code copied: $code',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => BatchQrCodeDialog.show(context, b),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 15, color: Color(0xFF4F46E5)),
                          SizedBox(width: 4),
                          Text(
                            'QR Code',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
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
      ),
    );
  }

  void _showCreateBatchSheet() {
    final parentCtx = context;
    final nameCtrl = TextEditingController();
    final sessionCtrl = TextEditingController(
      text: '${DateTime.now().year}-${DateTime.now().year + 1}',
    );
    final descCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    final selectedTeacherUids = <String>[];
    bool feeEnabled = true;

    showModalBottomSheet(
      context: parentCtx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Institute Batch',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Batch Name *',
                    hintText: 'e.g. Class 12 Science',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sessionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Session',
                    hintText: 'e.g. 2025-2026',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Fees (₹)',
                    hintText: '0 for free',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (widget.controller.teachers.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Assign Teachers (Optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: widget.controller.teachers.map((teacher) {
                      final isSelected = selectedTeacherUids.contains(teacher.uid);
                      return FilterChip(
                        label: Text(teacher.name),
                        selected: isSelected,
                        onSelected: (sel) {
                          setSheetState(() {
                            if (sel) {
                              selectedTeacherUids.add(teacher.uid);
                            } else {
                              selectedTeacherUids.remove(teacher.uid);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        CustomSnackbar.showError(
                          context: parentCtx,
                          message: 'Please enter a batch name',
                        );
                        return;
                      }
                      Navigator.pop(sheetCtx);
                      final fee = double.tryParse(feeCtrl.text.trim()) ?? 0.0;
                      final user = FirebaseAuth.instance.currentUser;
                      final ownerUid = user?.uid ?? '';

                      try {
                        await _orgService.createInstituteBatch(
                          orgId: widget.controller.orgId,
                          name: name,
                          ownerUid: ownerUid,
                          session: sessionCtrl.text.trim(),
                          description: descCtrl.text.trim().isNotEmpty
                              ? descCtrl.text.trim()
                              : null,
                          monthlyFee: fee,
                          feeTrackingEnabled: feeEnabled,
                          assignedTeacherIds: selectedTeacherUids,
                        );
                        CustomSnackbar.showSuccess(
                          context: parentCtx,
                          title: 'Batch Created',
                          message: 'Batch "$name" has been created.',
                        );
                      } catch (e) {
                        CustomSnackbar.showError(
                          context: parentCtx,
                          title: 'Error',
                          message: 'Failed to create batch: $e',
                        );
                      }
                    },
                    child: const Text(
                      'Create Batch',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteBatch(BatchModel b) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Batch?'),
        content: Text(
          'Are you sure you want to delete "${b.name}"?\n\n'
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
                  orgId: widget.controller.orgId,
                  batchId: b.id,
                );
                if (mounted) {
                  CustomSnackbar.showSuccess(
                    context: context,
                    title: 'Batch Deleted',
                    message: 'Batch "${b.name}" was successfully deleted.',
                  );
                }
              } catch (e) {
                if (mounted) {
                  CustomSnackbar.showError(
                    context: context,
                    title: 'Delete Failed',
                    message: 'Failed to delete batch: $e',
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

  void _toggleBatchArchive(BatchModel b) async {
    try {
      await _orgService.toggleBatchArchive(
        orgId: widget.controller.orgId,
        batchId: b.id,
        isArchived: !b.isArchived,
      );
      if (mounted) {
        CustomSnackbar.showSuccess(
          context: context,
          title: b.isArchived ? 'Batch Unarchived' : 'Batch Archived',
          message: 'Batch "${b.name}" status updated.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(
          context: context,
          title: 'Error',
          message: 'Failed to update batch: $e',
        );
      }
    }
  }
}

// =============================================================================
// TAB 5: OWNER MORE (SECONDARY MODULES & WORKSPACES)
// =============================================================================

class _OwnerMoreTab extends StatelessWidget {
  final InstituteAdminDashboardController controller;
  final ActiveTenantContext tenantCtx;

  const _OwnerMoreTab({required this.controller, required this.tenantCtx});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Text(
          'Institute Operations & Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),
        _buildFeatureTile(
          title: 'Teacher Salary Management',
          subtitle:
              'Configure base salaries and disburse monthly teacher compensation',
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF059669),
          onTap: () => Get.toNamed(AppRoutes.ownerTeacherSalaries),
        ),
        _buildFeatureTile(
          title: 'Student Fee Management',
          subtitle:
              'Track monthly student fee dues, collections, and receipt ledger',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFFD97706),
          onTap: () => Get.toNamed(AppRoutes.ownerStudentFees),
        ),
        _buildFeatureTile(
          title: 'Exam Management',
          subtitle: 'Create, schedule, and grade institute exams',
          icon: Icons.assignment_outlined,
          color: const Color(0xFF2563EB),
          onTap: () => Get.toNamed(AppRoutes.teacherExams),
        ),
        _buildFeatureTile(
          title: 'Attendance System',
          subtitle: 'Batch attendance overview, daily mark sheets and logs',
          icon: Icons.fact_check_outlined,
          color: const Color(0xFF0D9488),
          onTap: () => Get.toNamed(AppRoutes.attendanceOverview),
        ),
        _buildFeatureTile(
          title: 'Important Notices & Bulletins',
          subtitle: 'Publish institute-wide announcements to teachers & students',
          icon: Icons.campaign_outlined,
          color: const Color(0xFF7C3AED),
          onTap: () => Get.toNamed(AppRoutes.noticeList),
        ),
        _buildFeatureTile(
          title: 'Profile & Settings',
          subtitle: 'Institute administrator profile, settings & credentials',
          icon: Icons.person_outline_rounded,
          color: const Color(0xFF2563EB),
          onTap: () => showOwnerProfileModal(
            context,
            tenantCtx,
            () => _confirmSignOut(context),
          ),
        ),
        const Divider(height: 32),
        _buildFeatureTile(
          title: 'Sign Out',
          subtitle: 'Log out of your Owner account',
          icon: Icons.logout,
          color: Colors.red,
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }

  static void showOwnerProfileModal(
    BuildContext context,
    ActiveTenantContext tenantCtx,
    VoidCallback onSignOut,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final ownerName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (tenantCtx.activeOrg?.ownerName.isNotEmpty == true
            ? tenantCtx.activeOrg!.ownerName
            : 'Institute Owner');
    final ownerEmail = user?.email ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'O',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        ownerEmail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'COACHING INSTITUTE OWNER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildProfileInfoItem(
              icon: Icons.business_rounded,
              title: 'Institute Name',
              value: tenantCtx.activeOrgName.isNotEmpty
                  ? tenantCtx.activeOrgName
                  : 'Coaching Institute',
            ),
            const SizedBox(height: 12),
            _buildProfileInfoItem(
              icon: Icons.tag_rounded,
              title: 'Institute ID',
              value: tenantCtx.activeOrgId,
            ),
            const SizedBox(height: 12),
            _buildProfileInfoItem(
              icon: Icons.shield_outlined,
              title: 'Role Authority',
              value: 'Central Institute Administrator',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onSignOut();
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static Widget _buildProfileInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
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
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
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
