import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/services/exam_firestore_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examHistory/controller/exam_controller.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
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

  static const double _maxContentWidth = 640;

  Stream<List<ExamModel>>? _examStream;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _openExamStream();
  }

  void _openExamStream() {
    try {
      if (studentData != null) {
        final active = studentData!.activeEnrollments;
        if (active.isNotEmpty) {
          _examStream = ExamFirestoreService.getMultiTeacherExamsStream(
            enrollments: active,
          );
        } else {
          _examStream = Stream.value(const <ExamModel>[]);
        }
      }
    } catch (e) {
      log('Could not open exam stream: $e');
    }
  }

  void _loadStudentData() {
    if (studentData == null) {
      final data = pref.getString("studentData");
      if (data != null && data.isNotEmpty) {
        try {
          studentData = StudentData.fromJson(jsonDecode(data));
        } catch (e) {
          log('Error parsing studentData: $e');
        }
      }
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _openExams(StudentData s, {int tab = 0}) {
    Get.toNamed(
      AppRoutes.studentExamHistory,
      arguments: {'initialStudentData': s, 'initialTab': tab},
    );
  }

  void _openDetails(ExamModel exam) {
    Get.toNamed(AppRoutes.studentExamDetails, arguments: exam);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sData = studentData;
    if (sData == null || !sData.hasActiveEnrollment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.studentJoinTeacher);
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<ExamModel>>(
          stream: _examStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              log('Dashboard exam stream error: ${snapshot.error}');
            }

            final exams = snapshot.data ?? const <ExamModel>[];
            final currentUid = FirebaseAuth.instance.currentUser?.uid;
            final assigned = exams.where((e) {
              final enrollment = sData.getEnrollmentForTeacher(e.teacherId);
              final studentId = sData.getStudentIdForTeacher(e.teacherId);
              return studentId.isNotEmpty &&
                  e.isEligibleForStudent(
                    studentId: studentId,
                    authUid: currentUid,
                    enrollment: enrollment,
                  );
            }).toList();

            assigned.sort((a, b) {
              final aS = a.examStart, bS = b.examStart;
              if (aS == null && bS == null) return b.examId.compareTo(a.examId);
              if (aS == null) return 1;
              if (bS == null) return -1;
              return bS.compareTo(aS);
            });

            final active = assigned.where((e) => e.status == 'Active').toList();
            final upcoming = assigned
                .where((e) => e.status == 'Upcoming')
                .toList();
            final completed = assigned
                .where((e) => e.status == 'Completed')
                .toList();

            ExamModel? spotlight;
            if (active.isNotEmpty) {
              spotlight = (List.of(active)..sort(_compareStartAsc)).first;
            } else if (upcoming.isNotEmpty) {
              spotlight = (List.of(upcoming)..sort(_compareStartAsc)).first;
            }

            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    _buildHeader(sData),
                    const SizedBox(height: 14),
                    if (loading)
                      _skeleton(116, 18)
                    else
                      _buildOverview(
                        total: assigned.length,
                        active: active.length,
                        upcoming: upcoming.length,
                        completed: completed.length,
                      ),
                    if (spotlight != null) ...[
                      const SizedBox(height: 12),
                      _buildSpotlight(spotlight),
                    ],
                    const SizedBox(height: 18),
                    _sectionTitle('Quick actions'),
                    const SizedBox(height: 10),
                    _buildQuickActions(
                      sData,
                      active: active.length,
                      upcoming: upcoming.length,
                      completed: completed.length,
                      total: assigned.length,
                    ),
                    const SizedBox(height: 18),
                    _buildRecentHeader(sData),
                    const SizedBox(height: 8),
                    if (loading) ...[
                      _skeleton(64, 14),
                      const SizedBox(height: 8),
                      _skeleton(64, 14),
                    ] else if (snapshot.hasError)
                      _buildEmptyCard(
                        icon: Icons.cloud_off_rounded,
                        title: 'Exams didn’t load',
                        body: 'Check your connection and try again.',
                        action: TextButton(
                          onPressed: () => setState(_openExamStream),
                          child: const Text('Try again'),
                        ),
                      )
                    else if (assigned.isEmpty)
                      _buildEmptyCard(
                        icon: Icons.assignment_outlined,
                        title: 'No exams assigned yet',
                        body:
                            'When your teacher assigns an exam, it will appear here.',
                      )
                    else
                      for (final exam in assigned.take(4)) ...[
                        _buildRecentItem(exam),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _compareStartAsc(ExamModel a, ExamModel b) {
    final aS = a.examStart, bS = b.examStart;
    if (aS == null && bS == null) return 0;
    if (aS == null) return 1;
    if (bS == null) return -1;
    return aS.compareTo(bS);
  }

  ButtonStyle _primaryButton() => ElevatedButton.styleFrom(
    minimumSize: const Size(0, 38),
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
  );

  // ── Compact Header ───────────────────────────────────────────────────────

  Widget _buildHeader(StudentData sData) {
    final name = sData.name.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

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
            onTap: () => _showProfileSheet(context),
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
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sData.batch.trim().isNotEmpty) ...[
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
                          sData.batch,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  name.isNotEmpty ? name : 'Student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    letterSpacing: -0.3,
                  ),
                ),
                if (sData.activeEnrollments.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: sData.activeEnrollments.map((enr) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _line),
                        ),
                        child: Text(
                          '${enr.teacherName.isNotEmpty ? enr.teacherName : "Teacher"} • ${enr.batchName}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: _ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showProfileSheet(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF8FAFC),
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: _line),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 18, color: _muted),
          ),
        ],
      ),
    );
  }

  // ── Sleek Compact Overview Card ──────────────────────────────────────────

  Widget _buildOverview({
    required int total,
    required int active,
    required int upcoming,
    required int completed,
  }) {
    final headline = active > 0
        ? (active == 1 ? '1 exam is live now' : '$active exams are live now')
        : upcoming > 0
        ? (upcoming == 1 ? '1 exam coming up' : '$upcoming exams coming up')
        : 'You’re all caught up';
    final sub = active > 0
        ? 'Tap the live exam card below to start.'
        : '$total assigned · $completed completed';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color.lerp(AppColors.primary, const Color(0xFF1E1B4B), 0.6)!,
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
                  active > 0
                      ? Icons.bolt_rounded
                      : Icons.auto_awesome_mosaic_rounded,
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
                  'Assigned',
                  total,
                  Icons.assignment_outlined,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _overviewTile('Live', active, Icons.bolt_rounded),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _overviewTile(
                  'Upcoming',
                  upcoming,
                  Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _overviewTile(
                  'Done',
                  completed,
                  Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewTile(String label, int value, IconData icon) {
    return Container(
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
    );
  }

  // ── Compact Horizontal Spotlight Card ────────────────────────────────────

  Widget _buildSpotlight(ExamModel exam) {
    final isActive = exam.status == 'Active';
    final accent = isActive ? _live : _soon;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.32), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isActive ? Icons.bolt_rounded : Icons.schedule_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _pill(
                      isActive ? Icons.bolt_rounded : Icons.schedule_rounded,
                      isActive ? 'Live now' : 'Up next',
                      accent,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${exam.fullMarks} marks',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  exam.examName.isNotEmpty ? exam.examName : 'Untitled exam',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exam.teacherName.isNotEmpty
                      ? '${exam.teacherName} · ${exam.examDate} · ${exam.startTime} – ${exam.endTime}'
                      : '${exam.examDate} · ${exam.startTime} – ${exam.endTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _openDetails(exam),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 36),
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isActive ? 'Start' : 'View',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ── Compact Horizontal Quick Actions Grid ────────────────────────────────

  Widget _buildQuickActions(
    StudentData sData, {
    required int total,
    required int active,
    required int upcoming,
    required int completed,
  }) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.assignment_rounded,
        title: 'All exams',
        subtitle: 'Assigned list',
        color: AppColors.primary,
        count: total,
        onTap: () => _openExams(sData, tab: 0),
      ),
      _QuickAction(
        icon: Icons.bolt_rounded,
        title: 'Live now',
        subtitle: 'Ready to start',
        color: _live,
        count: active,
        onTap: () => _openExams(sData, tab: 1),
      ),
      _QuickAction(
        icon: Icons.schedule_rounded,
        title: 'Upcoming',
        subtitle: 'Scheduled tests',
        color: _soon,
        count: upcoming,
        onTap: () => _openExams(sData, tab: 2),
      ),
      _QuickAction(
        icon: Icons.workspace_premium_rounded,
        title: 'Results',
        subtitle: 'Scores & review',
        color: _good,
        count: completed,
        onTap: () => _openExams(sData, tab: 3),
      ),
      _QuickAction(
        icon: Icons.person_rounded,
        title: 'My profile',
        subtitle: 'Account & logout',
        color: _warn,
        onTap: () => _showProfileSheet(context),
      ),
      _QuickAction(
        icon: Icons.group_add_rounded,
        title: 'Join Another Batch',
        subtitle: 'Enter joining code',
        color: const Color(0xFF0D9488),
        onTap: () => Get.toNamed(AppRoutes.studentJoinTeacher),
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

  Widget _quickTile(_QuickAction a, double width) {
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
                const SizedBox(width: 4),
                if (a.count != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${a.count}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: a.color,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _off,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Slim Recent Exam Rows ────────────────────────────────────────────────

  Widget _buildRecentHeader(StudentData sData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _sectionTitle('Recent exams'),
        TextButton(
          onPressed: () => _openExams(sData),
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

  Widget _buildRecentItem(ExamModel exam) {
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
        onTap: () => _openDetails(exam),
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
                          : 'Untitled exam',
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
                      exam.teacherName.isNotEmpty
                          ? '${exam.teacherName} · ${exam.examDate} · ${exam.fullMarks} marks'
                          : '${exam.examDate} · ${exam.startTime} · ${exam.fullMarks} marks',
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

  // ── Shared Small Widgets ─────────────────────────────────────────────────

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

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String body,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: _off),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _muted, height: 1.35),
          ),
          if (action != null) ...[const SizedBox(height: 6), action],
        ],
      ),
    );
  }

  // ── Profile Sheet & Sign Out ─────────────────────────────────────────────

  void _showProfileSheet(BuildContext screenContext) {
    final sData = studentData;
    final name = sData?.name.trim() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

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
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 13,
              color: _ink,
              fontWeight: FontWeight.w800,
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
                          name.isNotEmpty ? name : 'Student',
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const Text(
                          'Student Account',
                          style: TextStyle(
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
              row(Icons.badge_outlined, 'Student ID', sData?.id ?? ''),
              const Divider(height: 1, color: _line),
              row(Icons.class_outlined, 'Batch', sData?.batch ?? ''),
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

  void _showLogoutDialog(BuildContext screenContext) {
    showDialog<void>(
      context: screenContext,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: _surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
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
                'You’ll need to log in again to see your exams.',
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
                      onPressed: () async {
                        final loginController = screenContext
                            .read<LoginController>();
                        Get.back();
                        await loginController.logout(screenContext);
                      },
                      style: _primaryButton().copyWith(
                        minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
                        backgroundColor: const WidgetStatePropertyAll(
                          AppColors.danger,
                        ),
                      ),
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
                  'Your session has ended',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Please log in again to see your exams.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Get.offAllNamed(AppRoutes.login),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Log in'),
                  style: _primaryButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int? count;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.count,
  });
}
