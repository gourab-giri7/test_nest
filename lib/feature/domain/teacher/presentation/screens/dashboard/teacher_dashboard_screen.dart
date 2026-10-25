import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/allStudents/all_students_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/my_batches_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/exams/teacher_exam_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/feeManagement/controller/fee_management_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/feeManagement/fee_management_screen.dart';
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
  // ── Modern Compact Design Tokens ─────────────────────────────────────────
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _surface = Colors.white;
  static const Color _live = Color(0xFF2563EB);
  static const Color _soon = Color(0xFF7C3AED);
  static const Color _good = Color(0xFF10B981);
  static const Color _warn = Color(0xFFF59E0B);
  static const Color _off = Color(0xFF94A3B8);

  static const double _maxContentWidth = 680;

  int _currentNavIndex = 0;
  late final PageController _pageController;

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
    _pageController = PageController(initialPage: _currentNavIndex);

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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Smoothly slides the PageView to the selected bottom-nav tab.
  void _switchTab(int index) {
    if (_currentNavIndex == index) return;
    setState(() => _currentNavIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tData = teacherData;
    if (tData == null) {
      return _buildSessionExpired();
    }

    final isFeeEnabled = tData.feeTrackingEnabled != false;

    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentNavIndex != 0) {
          _switchTab(0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            if (_currentNavIndex != index) {
              setState(() => _currentNavIndex = index);
            }
          },
          children: [
            // Tab 0: Home Overview
            _KeepAliveTab(child: _buildHomeTab(context, tData)),

            // Tab 1: Students Directory
            const _KeepAliveTab(child: AllStudentsScreen()),

            // Tab 2: Exams Management
            const _KeepAliveTab(child: TeacherExamsScreen()),

            // Tab 3: Fees Ledger (or Batches if Fee Tracking is disabled)
            _KeepAliveTab(
              child: isFeeEnabled
                  ? ChangeNotifierProvider(
                      create: (_) => FeeManagementController(
                        teacherId: tData.id,
                        teacherName: tData.name,
                      ),
                      child: const FeeManagementScreen(),
                    )
                  : const MyBatchesScreen(),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(context, isFeeEnabled),
      ),
    );
  }

  // ── Tab 0: Compact, Responsive Teacher Home ──────────────────────────────

  Widget _buildHomeTab(BuildContext context, TeacherData tData) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _buildTopHeader(tData),
              const SizedBox(height: 14),
              _buildOverviewBanner(tData),
              const SizedBox(height: 12),
              _buildBannerCard(context),
              const SizedBox(height: 18),
              _sectionTitle('Command center'),
              const SizedBox(height: 10),
              _buildQuickActionsGrid(context),
              const SizedBox(height: 18),
              _buildRecentHeader(),
              const SizedBox(height: 8),
              _buildRecentExamsStream(tData),
            ],
          ),
        ),
      ),
    );
  }

  // ── Compact Header Bar ───────────────────────────────────────────────────

  Widget _buildTopHeader(TeacherData tData) {
    final name = tData.name.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _showProfileSheet(context, tData),
            customBorder: const CircleBorder(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    Color.lerp(AppColors.primary, _soon, 0.5)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Educator workspace',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${tData.batch.length} Batches',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  name.isNotEmpty ? name : 'Educator',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Create Exam',
                onPressed: () => Get.toNamed(AppRoutes.teacherCreateExam),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sleek Overview Card with Live Metrics ────────────────────────────────

  Widget _buildOverviewBanner(TeacherData tData) {
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

            final headline = activeCount > 0
                ? (activeCount == 1
                      ? '1 exam is live right now'
                      : '$activeCount exams are live right now')
                : 'Institute overview';
            final sub =
                '$studentCount enrolled students · $totalExams total assessments';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    Color.lerp(
                      AppColors.primary,
                      const Color(0xFF1E1B4B),
                      0.6,
                    )!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.20),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          activeCount > 0
                              ? Icons.bolt_rounded
                              : Icons.analytics_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headline,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              sub,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.76),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _overviewTile(
                          'Students',
                          studentCount,
                          Icons.people_outline_rounded,
                          onTap: () => _switchTab(1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _overviewTile(
                          'Exams',
                          totalExams,
                          Icons.assignment_outlined,
                          onTap: () => _switchTab(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _overviewTile(
                          'Live',
                          activeCount,
                          Icons.bolt_rounded,
                          onTap: () => _switchTab(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _overviewTile(
                          'Done',
                          completedCount,
                          Icons.check_circle_outline_rounded,
                          onTap: () => _switchTab(2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _overviewTile(
    String label,
    int value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12.5, color: Colors.white.withOpacity(0.85)),
                const SizedBox(width: 4),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact Promo Action Strip ───────────────────────────────────────────

  Widget _buildBannerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withOpacity(0.28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Launch a Timed Exam',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                SizedBox(height: 1.5),
                Text(
                  'Import Excel questions or build manually',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            onPressed: () => Get.toNamed(AppRoutes.teacherCreateExam),
            icon: const Icon(Icons.add_rounded, size: 15),
            label: const Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Responsive Compact Quick Actions Grid ────────────────────────────────

  Widget _buildQuickActionsGrid(BuildContext context) {
    final tData = teacherData;
    final isFeeEnabled = tData?.feeTrackingEnabled != false;

    final actions = <_TeacherAction>[
      _TeacherAction(
        icon: Icons.people_alt_rounded,
        title: 'Students',
        subtitle: 'Enrolled roster',
        color: _live,
        onTap: () => _switchTab(1),
      ),
      _TeacherAction(
        icon: Icons.groups_rounded,
        title: 'Batches',
        subtitle: 'Batches & codes',
        color: const Color(0xFF4338CA),
        onTap: () => Get.toNamed(AppRoutes.teacherBatches),
      ),
      _TeacherAction(
        icon: Icons.edit_note_rounded,
        title: 'Create Exam',
        subtitle: 'New assessment',
        color: _soon,
        onTap: () => Get.toNamed(AppRoutes.teacherCreateExam),
      ),
      _TeacherAction(
        icon: Icons.assignment_rounded,
        title: 'All Exams',
        subtitle: 'Manage & grade',
        color: _good,
        onTap: () => _switchTab(2),
      ),
      _TeacherAction(
        icon: Icons.group_add_rounded,
        title: 'Join Requests',
        subtitle: 'Approve students',
        color: const Color(0xFF0284C7),
        onTap: () => Get.toNamed(AppRoutes.teacherJoinRequests),
      ),
      if (isFeeEnabled)
        _TeacherAction(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Fee Ledger',
          subtitle: 'Monthly dues',
          color: const Color(0xFF0D9488),
          onTap: () => _switchTab(3),
        )
      else
        _TeacherAction(
          icon: Icons.insert_chart_rounded,
          title: 'Results',
          subtitle: 'Scores & review',
          color: _warn,
          onTap: () => _switchTab(2),
        ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final cols = c.maxWidth >= 500 ? 3 : 2;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final a in actions) _quickTile(a, w)],
        );
      },
    );
  }

  Widget _quickTile(_TeacherAction a, double width) {
    return SizedBox(
      width: width,
      child: Material(
        color: _surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _line),
        ),
        child: InkWell(
          onTap: a.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: a.color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(a.icon, color: a.color, size: 18),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        a.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        a.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: _muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: _off),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Slim Recent Assessments List ─────────────────────────────────────────

  Widget _buildRecentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _sectionTitle('Recent assessments'),
        TextButton(
          onPressed: () => _switchTab(2),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            foregroundColor: AppColors.primary,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'See all',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExamsStream(TeacherData tData) {
    _initStreams(tData.id);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _recentExamsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Column(
            children: [
              _skeleton(60, 14),
              const SizedBox(height: 8),
              _skeleton(60, 14),
            ],
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: Column(
              children: [
                const Icon(Icons.assignment_outlined, size: 30, color: _off),
                const SizedBox(height: 8),
                const Text(
                  'No exams created yet',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Tap 'Create Exam' above to schedule your first assessment.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final exams = docs.map((d) => ExamModel.fromJson(d.data())).toList();

        return Column(
          children: [
            for (final exam in exams) ...[
              _buildRecentExamItem(exam),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRecentExamItem(ExamModel exam) {
    final (Color color, String label, IconData icon) = switch (exam.status) {
      'Active' => (_live, 'Live', Icons.bolt_rounded),
      'Upcoming' => (_soon, 'Upcoming', Icons.schedule_rounded),
      'Completed' => (_good, 'Done', Icons.check_circle_rounded),
      _ => (_off, 'Ended', Icons.timer_off_outlined),
    };

    return Material(
      color: _surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _line),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.teacherExamDetails, arguments: exam),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.examName.isNotEmpty
                          ? exam.examName
                          : 'Untitled Exam',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exam.batch.isEmpty ? "All Batches" : exam.batch} · ${exam.examDate} · ${exam.startTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _pill(icon, label, color),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: _off),
            ],
          ),
        ),
      ),
    );
  }

  // ── Persistent Sliding Bottom Navigation Bar ─────────────────────────────

  Widget _buildBottomNav(BuildContext context, bool isFeeEnabled) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(top: BorderSide(color: _line)),
        boxShadow: [
          BoxShadow(
            color: _ink.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _navItem(
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Home',
                onTap: () => _switchTab(0),
              ),
              _navItem(
                index: 1,
                icon: Icons.people_alt_rounded,
                label: 'Students',
                onTap: () => _switchTab(1),
              ),
              _navItem(
                index: 2,
                icon: Icons.assignment_rounded,
                label: 'Exams',
                onTap: () => _switchTab(2),
              ),
              if (isFeeEnabled)
                _navItem(
                  index: 3,
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Fees',
                  onTap: () => _switchTab(3),
                )
              else
                _navItem(
                  index: 3,
                  icon: Icons.groups_rounded,
                  label: 'Batches',
                  onTap: () => _switchTab(3),
                ),
              _navItem(
                index: 4,
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                isAction: true,
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    final isSelected = !isAction && _currentNavIndex == index;
    final activeColor = isAction ? AppColors.danger : AppColors.primary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? activeColor : _off),
              const SizedBox(height: 2.5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared Helpers & Dialogs ─────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        color: _ink,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeleton(double h, double r) {
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF5),
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }

  void _showProfileSheet(BuildContext screenContext, TeacherData tData) {
    final name = tData.name.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: _off),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    showModalBottomSheet<void>(
      context: screenContext,
      backgroundColor: _surface,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Educator',
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        Text(
                          tData.email.isNotEmpty
                              ? tData.email
                              : 'Educator Account',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: _line),
              row(Icons.badge_outlined, 'Teacher ID', tData.teacherId),
              const Divider(height: 1, color: _line),
              row(
                Icons.groups_outlined,
                'Active Batches',
                '${tData.batch.length}',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.back();
                    _showLogoutDialog(screenContext);
                  },
                  icon: const Icon(Icons.logout_rounded, size: 17),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger.withOpacity(0.45)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
      builder: (dialogCtx) => Dialog(
        backgroundColor: _surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sign out?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to log out of your educator account?',
                style: TextStyle(fontSize: 13, color: _muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        foregroundColor: _ink,
                        side: const BorderSide(color: _line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      onPressed: () {
                        final loginController = context.read<LoginController>();
                        Get.back();
                        loginController.logout(context);
                      },
                      child: const Text(
                        'Sign out',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
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

  Widget _buildSessionExpired() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: _warn.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    size: 32,
                    color: _warn,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Session expired',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Please log in again to access your educator portal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Get.offAllNamed(AppRoutes.login),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Log in'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 40),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _TeacherAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TeacherAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
