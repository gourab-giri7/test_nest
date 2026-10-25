import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>>? studentsStream;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? examsStream;
  final Stream<QuerySnapshot<Map<String, dynamic>>>? recentExamsStream;

  const TeacherDashboardScreen({
    super.key,
    this.studentsStream,
    this.examsStream,
    this.recentExamsStream,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _currentNavIndex = 0;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _studentsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _examsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _recentExamsStream;
  String _cachedTeacherId = '';

  void _initStreams(String teacherId) {
    if (widget.studentsStream != null) {
      _studentsStream = widget.studentsStream;
      _examsStream = widget.examsStream;
      _recentExamsStream = widget.recentExamsStream;
      return;
    }
    if (_cachedTeacherId == teacherId && _studentsStream != null) return;
    _cachedTeacherId = teacherId;
    _studentsStream = FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('students')
        .snapshots();
    _examsStream = FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('exams')
        .snapshots();
    _recentExamsStream = FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('exams')
        .orderBy('exam_id', descending: true)
        .limit(4)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    if (teacherData == null) {
      final teacherString = pref.getString("teacherData");
      if (teacherString != null && teacherString.trim().isNotEmpty) {
        try {
          teacherData = TeacherData.fromJson(jsonDecode(teacherString));
        } catch (e) {
          log("Decode error: $e");
        }
      }
    }
    if (teacherData != null) {
      _initStreams(teacherData!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tData = teacherData;
    if (tData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Test Nest')),
        body: const Center(
          child: Text('Session expired. Please log in again.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildTopHeader(tData),
            Transform.translate(
              offset: const Offset(0, -34),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFloatingMetricsCard(tData),
                        const SizedBox(height: 24),

                        const Row(
                          children: [
                            Icon(
                              Icons.grid_view_rounded,
                              size: 19,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Command Center',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildQuickActionsGrid(context),
                        const SizedBox(height: 24),

                        _buildBannerCard(context),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.assignment_turned_in_rounded,
                                    size: 19,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Recent Assessments',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.text,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                minimumSize: const Size(50, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => Get.toNamed(AppRoutes.teacherExams),
                              icon: const Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              label: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _buildRecentExamsStream(tData),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildTopHeader(TeacherData tData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56, bottom: 62, left: 22, right: 22),
      decoration: const BoxDecoration(
        gradient: AppGradients.teacherHero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'EDUCATOR PORTAL',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFC7D2FE),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tData.name.isNotEmpty ? 'Welcome, ${tData.name}' : 'Welcome, Educator',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tData.email.isNotEmpty
                      ? tData.email
                      : 'Manage your batches, exams & student progress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.45),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Text(
                  tData.name.isNotEmpty ? tData.name[0].toUpperCase() : 'T',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingMetricsCard(TeacherData tData) {
    _initStreams(tData.id);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _studentsStream,
      builder: (context, studentSnap) {
        final studentCount = studentSnap.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _examsStream,
          builder: (context, examSnap) {
            final examDocs = examSnap.data?.docs ?? [];
            final totalExams = examDocs.length;

            final exams = examDocs
                .map((d) => ExamModel.fromJson(d.data()))
                .toList();
            final activeCount = exams.where((e) => e.status == 'Active').length;
            final completedCount = exams
                .where((e) => e.status == 'Completed')
                .length;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  _statItem(
                    'Students',
                    studentCount.toString(),
                    AppColors.primary,
                  ),
                  _vDivider(),
                  _statItem(
                    'Total Exams',
                    totalExams.toString(),
                    AppColors.secondary,
                  ),
                  _vDivider(),
                  _statItem(
                    'Active',
                    activeCount.toString(),
                    AppColors.success,
                  ),
                  _vDivider(),
                  _statItem(
                    'Completed',
                    completedCount.toString(),
                    AppColors.warning,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(width: 1, height: 32, color: AppColors.border);
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final tData = teacherData;
    final isFeeEnabled = tData?.feeTrackingEnabled != false;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionCard(
                title: 'Students',
                subtitle: 'Enrolled roster',
                icon: Icons.people_alt_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
                onTap: () => Get.toNamed(AppRoutes.teacherAllStudents),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _actionCard(
                title: 'Batches',
                subtitle: 'Batches & codes',
                icon: Icons.groups_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                ),
                onTap: () => Get.toNamed(AppRoutes.teacherBatches),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                title: 'Create Exam',
                subtitle: 'Build assessment',
                icon: Icons.edit_note_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                ),
                onTap: () => Get.toNamed(AppRoutes.teacherCreateExam),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _actionCard(
                title: 'Exams',
                subtitle: 'All assessments',
                icon: Icons.assignment_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                onTap: () => Get.toNamed(AppRoutes.teacherExams),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                title: 'Join Requests',
                subtitle: 'Student approvals',
                icon: Icons.group_add_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                ),
                onTap: () => Get.toNamed(AppRoutes.teacherJoinRequests),
              ),
            ),
            const SizedBox(width: 14),
            if (isFeeEnabled)
              Expanded(
                child: _actionCard(
                  title: 'Fee Ledger',
                  subtitle: 'Monthly dues',
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  ),
                  onTap: () {
                    final t = teacherData;
                    if (t == null) return;
                    Get.toNamed(AppRoutes.teacherFeeManagement);
                  },
                ),
              )
            else
              Expanded(
                child: _actionCard(
                  title: 'Results',
                  subtitle: 'Analytics & marks',
                  icon: Icons.insert_chart_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                  ),
                  onTap: () => Get.toNamed(AppRoutes.teacherExams),
                ),
              ),
          ],
        ),
        if (isFeeEnabled) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  title: 'Results',
                  subtitle: 'Analytics & marks',
                  icon: Icons.insert_chart_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                  ),
                  onTap: () => Get.toNamed(AppRoutes.teacherExams),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Launch a Timed Exam',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Import Excel questions or enter manually in minutes',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              minimumSize: const Size(88, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Get.toNamed(AppRoutes.teacherCreateExam),
            child: const Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExamsStream(TeacherData tData) {
    _initStreams(tData.id);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _recentExamsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                "No exams created yet. Tap 'Create Exam' to get started.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final exams = docs.map((d) => ExamModel.fromJson(d.data())).toList();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              for (int i = 0; i < exams.length; i++) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Get.toNamed(
                      AppRoutes.teacherExamDetails,
                      arguments: exams[i],
                    );
                  },
                  child: _buildRecentExamItem(exams[i]),
                ),
                if (i < exams.length - 1)
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentExamItem(ExamModel exam) {
    final statusColor = exam.status == 'Completed'
        ? AppColors.success
        : (exam.status == 'Active' ? AppColors.primary : AppColors.warning);
    final statusBg = exam.status == 'Completed'
        ? AppColors.successSoft
        : (exam.status == 'Active'
              ? AppColors.primarySoft
              : AppColors.warningSoft);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.examName.isNotEmpty ? exam.examName : "Untitled Exam",
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${exam.examDate}  •  ${exam.startTime}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              exam.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isFeeEnabled = teacherData?.feeTrackingEnabled != false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              _navItem(0, Icons.dashboard_rounded, 'Home', () {}),
              _navItem(1, Icons.people_alt_rounded, 'Students', () {
                Get.toNamed(AppRoutes.teacherAllStudents);
              }),
              _navItem(2, Icons.assignment_rounded, 'Exams', () {
                Get.toNamed(AppRoutes.teacherExams);
              }),
              if (isFeeEnabled)
                _navItem(3, Icons.account_balance_wallet_rounded, 'Fees', () {
                  final t = teacherData;
                  if (t == null) return;
                  Get.toNamed(AppRoutes.teacherFeeManagement);
                })
              else
                _navItem(3, Icons.groups_rounded, 'Batches', () {
                  Get.toNamed(AppRoutes.teacherBatches);
                }),
              _navItem(4, Icons.logout_rounded, 'Sign Out', () {
                _showLogoutDialog(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, VoidCallback onTap) {
    final isSelected = _currentNavIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _currentNavIndex = index);
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          "Sign Out",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final loginController = context.read<LoginController>();
              Get.back();
              loginController.logout(context);
            },
            child: const Text(
              "Sign Out",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
