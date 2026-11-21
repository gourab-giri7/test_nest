import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/services/exam_firestore_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examHistory/controller/exam_controller.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/routes/app_routes.dart';

/// Visual status of an exam card.
enum _CardState { active, upcoming, ended, pendingResult, scored }

class ExamHistoryScreen extends StatefulWidget {
  final StudentData? initialStudentData;
  final Stream<dynamic>? examStream;
  final int initialTab;

  const ExamHistoryScreen({
    super.key,
    this.initialStudentData,
    this.examStream,
    this.initialTab = 0,
  });

  @override
  State<ExamHistoryScreen> createState() => _ExamHistoryScreenState();
}

class _ExamHistoryScreenState extends State<ExamHistoryScreen>
    with SingleTickerProviderStateMixin {
  // ── Modern Compact Design Tokens (Matched with StudentDashboardScreen) ───
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _surface = Colors.white;
  static const Color _live = Color(0xFF2563EB);
  static const Color _soon = Color(0xFF7C3AED);
  static const Color _wait = Color(0xFFF59E0B);
  static const Color _good = Color(0xFF10B981);
  static const Color _off = Color(0xFF94A3B8);

  static const double _maxContentWidth = 640;

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<ExamController>().changeTab(_tabController.index);
      }
    });
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      context.read<ExamController>().setSearchQuery(q);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ExamController>().loadProfileAndStream(
        initialStudentData: widget.initialStudentData,
        overrideStream: widget.examStream,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data / logic (behaviour unchanged) ───────────────────────────────────

  /// Times out only if the FIRST snapshot never arrives.
  Stream<T> _withInitialTimeout<T>(Stream<T> source, Duration limit) {
    late StreamController<T> controller;
    StreamSubscription<T>? sub;
    Timer? timer;

    controller = StreamController<T>(
      onListen: () {
        timer = Timer(limit, () {
          log('Exam stream timed out in ExamHistoryScreen');
          controller.addError(
            TimeoutException(
              'Loading exams took longer than expected. '
              'Please check your internet connection or tap Refresh.',
            ),
          );
        });
        sub = source.listen(
          (event) {
            timer?.cancel();
            controller.add(event);
          },
          onError: (Object e, StackTrace s) {
            timer?.cancel();
            controller.addError(e, s);
          },
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
      },
      onCancel: () {
        timer?.cancel();
        return sub?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<List<ExamModel>> _adaptStream(Stream<dynamic> raw) {
    return raw.map((event) {
      if (event is List<ExamModel>) return event;
      if (event is QuerySnapshot) {
        final docs = (event as QuerySnapshot<Map<String, dynamic>>).docs;
        final list = <ExamModel>[];
        for (final doc in docs) {
          try {
            list.add(ExamModel.fromFirestore(doc));
          } catch (_) {
            try {
              list.add(ExamModel.fromJson(doc.data()));
            } catch (_) {}
          }
        }
        return list;
      }
      return <ExamModel>[];
    });
  }

  void _onRetry() {
    context.read<ExamController>().loadProfileAndStream(
      initialStudentData: widget.initialStudentData,
      overrideStream: widget.examStream,
      forceRefresh: true,
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _getSubmissionStream(
    ExamModel exam,
  ) {
    final controller = context.read<ExamController>();
    final student = controller.currentStudent;
    if (student == null) return null;
    final teacherId = exam.teacherId.isNotEmpty
        ? exam.teacherId
        : student.teacherId.trim();
    final studentId = student.getStudentIdForTeacher(teacherId);
    if (teacherId.isEmpty || studentId.isEmpty) {
      return null;
    }
    final cacheKey = '${teacherId}_${exam.examId}_$studentId';
    return controller.submissionStreams.putIfAbsent(cacheKey, () {
      try {
        return ExamFirestoreService.submission(
          teacherId,
          exam.examId,
          studentId,
        ).snapshots();
      } catch (_) {
        return null;
      }
    });
  }

  void _onStartExam(BuildContext context, ExamModel exam) {
    final student = context.read<ExamController>().currentStudent;
    final teacherId = exam.teacherId.isNotEmpty
        ? exam.teacherId
        : (student?.teacherId ?? '');
    final studentId = student?.getStudentIdForTeacher(teacherId) ?? '';
    final enrollment = student?.getEnrollmentForTeacher(teacherId);
    final isEligible = exam.isEligibleForStudent(
      studentId: studentId,
      authUid: FirebaseAuth.instance.currentUser?.uid,
      enrollment: enrollment,
    );

    if (!isEligible) {
      customSnackbar(
        context: context,
        message:
            'You are not eligible to take this exam based on your enrollment date or assignment.',
        color: Colors.red,
        ico: Icons.block,
      );
      return;
    }

    if (exam.status != 'Active' ||
        (exam.examEnd != null && DateTime.now().isAfter(exam.examEnd!))) {
      customSnackbar(
        context: context,
        message: 'This exam has ended and is no longer active.',
        color: Colors.red,
        ico: Icons.timer_off,
      );
      return;
    }

    if (exam.examKey.isEmpty) {
      Get.toNamed(AppRoutes.studentTakeExam, arguments: exam);
      return;
    }

    _showExamKeyDialog(context, exam);
  }

  void _showExamKeyDialog(BuildContext context, ExamModel exam) {
    final keyController = TextEditingController();
    showDialog<void>(
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Enter exam key',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Your teacher shared a key for ${exam.examName}. Enter it to begin.',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: keyController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
                decoration: InputDecoration(
                  hintText: 'Exam key',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                  prefixIcon: const Icon(Icons.key_rounded, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
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
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (keyController.text.trim() == exam.examKey.trim()) {
                          Get.back();
                          Get.toNamed(
                            AppRoutes.studentTakeExam,
                            arguments: exam,
                          );
                        } else {
                          customSnackbar(
                            context: context,
                            message:
                                'Invalid Exam Key. Please check with your teacher.',
                            color: Colors.red,
                            ico: Icons.lock,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'Start exam',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        toolbarHeight: 52,
        title: const Text(
          'My exams',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: _ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton(
              tooltip: 'Refresh',
              style: IconButton.styleFrom(
                backgroundColor: _surface,
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: _line),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18, color: _ink),
              onPressed: _onRetry,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = context.watch<ExamController>();
    if (controller.isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.profileErrorMessage != null ||
        controller.currentStudent == null) {
      return _buildProfileErrorState(
        controller.profileErrorMessage ??
            'Student profile is missing. Please log in again.',
      );
    }

    final activeStream = controller.historyStream;
    if (activeStream == null) {
      return _buildStreamErrorState(
        'Unable to establish connection to exam service.',
      );
    }

    return StreamBuilder<List<ExamModel>>(
      stream: activeStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log('Exam stream error: ${snapshot.error}');
          return _buildStreamErrorState(
            'Failed to load exams. Please check your connection and try again.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final raw = List<ExamModel>.from(snapshot.data ?? const <ExamModel>[]);

        // Newest start date first
        raw.sort((a, b) {
          final aStart = a.examStart;
          final bStart = b.examStart;
          if (aStart == null && bStart == null) {
            return b.examId.compareTo(a.examId);
          }
          if (aStart == null) return 1;
          if (bStart == null) return -1;
          return bStart.compareTo(aStart);
        });

        final student = controller.currentStudent!;
        String? currentUid;
        try {
          currentUid = FirebaseAuth.instance.currentUser?.uid;
        } catch (_) {}
        final allAssigned = raw
            .where((exam) {
              final teacherId = exam.teacherId.isNotEmpty
                  ? exam.teacherId
                  : student.teacherId;
              final studentId = student.getStudentIdForTeacher(teacherId);
              final enrollment = student.getEnrollmentForTeacher(teacherId);
              return exam.isEligibleForStudent(
                studentId: studentId,
                authUid: currentUid,
                enrollment: enrollment,
              );
            })
            .toList(growable: false);

        if (allAssigned.isEmpty) return _buildEmptyAllExamsState();

        final teacherNamesSet = <String>{'All Teachers'};
        for (final exam in allAssigned) {
          if (exam.teacherName.trim().isNotEmpty) {
            teacherNamesSet.add(exam.teacherName.trim());
          }
        }
        for (final name in student.allTeacherNames) {
          if (name.trim().isNotEmpty) {
            teacherNamesSet.add(name.trim());
          }
        }
        final availableTeachers = teacherNamesSet.toList(growable: false);
        final selectedTeacher =
            availableTeachers.contains(controller.selectedTeacher)
            ? controller.selectedTeacher
            : 'All Teachers';

        final teacherFiltered = selectedTeacher == 'All Teachers'
            ? allAssigned
            : allAssigned
                  .where(
                    (e) =>
                        e.teacherName.trim().toLowerCase() ==
                        selectedTeacher.trim().toLowerCase(),
                  )
                  .toList(growable: false);

        final query = controller.searchQuery.trim().toLowerCase();
        final filtered = query.isEmpty
            ? teacherFiltered
            : teacherFiltered
                  .where((exam) {
                    return exam.examName.toLowerCase().contains(query) ||
                        exam.batch.toLowerCase().contains(query) ||
                        exam.teacherName.toLowerCase().contains(query);
                  })
                  .toList(growable: false);

        final active = filtered
            .where((e) => e.status == 'Active')
            .toList(growable: false);
        final upcoming = filtered
            .where((e) => e.status == 'Upcoming')
            .toList(growable: false);
        final completed = filtered
            .where((e) => e.status == 'Completed')
            .toList(growable: false);

        return Column(
          children: [
            _buildOverview(
              total: allAssigned.length,
              active: allAssigned.where((e) => e.status == 'Active').length,
              upcoming: allAssigned.where((e) => e.status == 'Upcoming').length,
              completed: allAssigned
                  .where((e) => e.status == 'Completed')
                  .length,
            ),
            _buildSearchField(),
            _buildTeacherFilterChips(availableTeachers),
            _buildTabs(
              all: filtered.length,
              active: active.length,
              upcoming: upcoming.length,
              completed: completed.length,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExamList(filtered, 'All'),
                  _buildExamList(active, 'Active'),
                  _buildExamList(upcoming, 'Upcoming'),
                  _buildExamList(completed, 'Completed'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Sleek Compact Header Pieces ──────────────────────────────────────────

  Widget _buildOverview({
    required int total,
    required int active,
    required int upcoming,
    required int completed,
  }) {
    final headline = active > 0
        ? 'Active Now'
        : upcoming > 0
        ? (upcoming == 1 ? '1 exam coming up' : '$upcoming exams coming up')
        : 'You’re all caught up';
    final sub = active > 0
        ? 'Start Exam'
        : '$total assigned · $completed completed';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Container(
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
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (active > 0) ...[
                  const _PulseDot(),
                  const SizedBox(width: 8),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_mosaic_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        sub,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.76),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                _overviewTile('Assigned', total, Icons.assignment_outlined),
                const SizedBox(width: 6),
                _overviewTile('Live', active, Icons.bolt_rounded),
                const SizedBox(width: 6),
                _overviewTile('Upcoming', upcoming, Icons.schedule_rounded),
                const SizedBox(width: 6),
                _overviewTile(
                  'Done',
                  completed,
                  Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewTile(String label, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
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
                Icon(icon, size: 12, color: Colors.white.withOpacity(0.85)),
                const SizedBox(width: 4),
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1.5),
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

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SizedBox(
        height: 40,
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 13, color: _ink),
          decoration: InputDecoration(
            hintText: 'Search by exam or batch...',
            hintStyle: const TextStyle(color: _off, fontSize: 12.5),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _off),
            suffixIcon: context.watch<ExamController>().searchQuery.isNotEmpty
                ? IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.clear, size: 16, color: _muted),
                    onPressed: _searchController.clear,
                  )
                : null,
            isDense: true,
            filled: true,
            fillColor: _surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherFilterChips(List<String> teachers) {
    if (teachers.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: teachers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final teacher = teachers[index];
            final selectedTeacher = context
                .watch<ExamController>()
                .selectedTeacher;
            final isSelected = teacher == selectedTeacher;
            return GestureDetector(
              onTap: () {
                context.read<ExamController>().setSelectedTeacher(teacher);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : _line,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      index == 0
                          ? Icons.people_outline_rounded
                          : Icons.person_outline_rounded,
                      size: 13,
                      color: isSelected ? Colors.white : _muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      teacher,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : _ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabs({
    required int all,
    required int active,
    required int upcoming,
    required int completed,
  }) {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _ink,
        unselectedLabelColor: _muted,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFEEF2FF),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Active'),
          Tab(text: 'Upcoming'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────────

  Widget _buildExamList(List<ExamModel> exams, String label) {
    final searchQuery = context.watch<ExamController>().searchQuery;
    if (exams.isEmpty) {
      final isSearching = searchQuery.isNotEmpty;
      return RefreshIndicator(
        onRefresh: () async => _onRetry(),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 260,
              child: _buildMessage(
                icon: isSearching
                    ? Icons.search_off_rounded
                    : Icons.inbox_outlined,
                tint: _off,
                title: isSearching
                    ? 'No matches for “$searchQuery”'
                    : label == 'All'
                    ? 'No Exam found'
                    : 'No $label exam available',
                body: isSearching
                    ? 'Try a different exam name or batch.'
                    : 'You have not been assigned to any exams yet.',
                action: isSearching
                    ? TextButton(
                        onPressed: _searchController.clear,
                        child: const Text('Clear search'),
                      )
                    : null,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _onRetry(),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        itemCount: exams.length,
        separatorBuilder: (_, __) => const SizedBox(height: 9),
        itemBuilder: (context, index) =>
            _buildLiveExamCard(exams[index], context),
      ),
    );
  }

  Widget _buildLiveExamCard(ExamModel exam, BuildContext context) {
    final submissionStream = _getSubmissionStream(exam);

    if (submissionStream == null) {
      return _buildCard(exam, context, submission: null);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: submissionStream,
      builder: (context, snap) {
        final subData = snap.data?.data();
        final isSubmitted = snap.data?.exists ?? false;
        return _buildCard(
          exam,
          context,
          submission: isSubmitted ? subData : null,
        );
      },
    );
  }

  // ── Compact Modern Exam Card ─────────────────────────────────────────────

  _CardState _stateOf(ExamModel exam, bool submitted) {
    if (submitted) {
      return exam.resultPublished
          ? _CardState.scored
          : _CardState.pendingResult;
    }
    if (exam.status == 'Active') return _CardState.active;
    if (exam.status == 'Upcoming') return _CardState.upcoming;
    return _CardState.ended;
  }

  Color _colorOf(_CardState s) {
    switch (s) {
      case _CardState.active:
        return _live;
      case _CardState.upcoming:
        return _soon;
      case _CardState.pendingResult:
        return _wait;
      case _CardState.scored:
        return _good;
      case _CardState.ended:
        return _off;
    }
  }

  String _labelOf(_CardState s) {
    switch (s) {
      case _CardState.active:
        return 'Live';
      case _CardState.upcoming:
        return 'Upcoming';
      case _CardState.pendingResult:
        return 'Pending';
      case _CardState.scored:
        return 'Scored';
      case _CardState.ended:
        return 'Ended';
    }
  }

  IconData _iconOf(_CardState s) {
    switch (s) {
      case _CardState.active:
        return Icons.bolt_rounded;
      case _CardState.upcoming:
        return Icons.schedule_rounded;
      case _CardState.pendingResult:
        return Icons.hourglass_top_rounded;
      case _CardState.scored:
        return Icons.verified_rounded;
      case _CardState.ended:
        return Icons.timer_off_outlined;
    }
  }

  Widget _buildCard(
    ExamModel exam,
    BuildContext context, {
    required Map<String, dynamic>? submission,
  }) {
    final isSubmitted = submission != null;
    final state = _stateOf(exam, isSubmitted);
    final color = _colorOf(state);
    final canStart = state == _CardState.active;

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => Get.toNamed(AppRoutes.studentExamDetails, arguments: exam),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: canStart ? color.withOpacity(0.38) : _line,
              width: canStart ? 1.3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: canStart
                    ? color.withOpacity(0.07)
                    : _ink.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardHeader(exam, state, color),
              const SizedBox(height: 9),
              _cardFacts(exam),
              if (isSubmitted) ...[
                const SizedBox(height: 9),
                _cardResult(exam, submission, state),
              ],
              const SizedBox(height: 9),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              _cardFooter(exam, context, canStart, submission, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardHeader(ExamModel exam, _CardState state, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(_iconOf(state), color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam.examName.isNotEmpty ? exam.examName : 'Untitled exam',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                '${exam.batch.isEmpty ? 'All batches' : exam.batch}${exam.teacherName.trim().isNotEmpty ? ' • ${exam.teacherName.trim()}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconOf(state), size: 11, color: color),
              const SizedBox(width: 3.5),
              Text(
                _labelOf(state),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardFacts(ExamModel exam) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _factChip(Icons.calendar_today_rounded, exam.examDate),
        _factChip(
          Icons.access_time_rounded,
          '${exam.startTime} – ${exam.endTime}',
        ),
        _factChip(Icons.workspace_premium_outlined, '${exam.fullMarks} marks'),
        _factChip(Icons.help_outline_rounded, '${exam.questionCount} Qs'),
      ],
    );
  }

  Widget _factChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEF2F6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: _off),
          const SizedBox(width: 4.5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardResult(
    ExamModel exam,
    Map<String, dynamic> submission,
    _CardState state,
  ) {
    final scoreStr = submission['score']?.toString();
    final attempted = submission['attempted']?.toString();
    final published = state == _CardState.scored && scoreStr != null;

    if (!published) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _wait.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _wait.withOpacity(0.20)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 16, color: _wait),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                attempted != null
                    ? 'Submitted ($attempted/${exam.questionCount} attempted) · Awaiting result'
                    : 'Submitted · Awaiting teacher to publish result',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final score = num.tryParse(scoreStr);
    final total = num.tryParse('${exam.fullMarks}');
    final ratio = (score != null && total != null && total > 0)
        ? (score / total).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final percent = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _good.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _good.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 3.5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: _good.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation(_good),
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF166534),
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
                Text(
                  'Score: $scoreStr / ${exam.fullMarks}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF166534),
                  ),
                ),
                if (attempted != null)
                  Text(
                    'Attempted $attempted of ${exam.questionCount} questions',
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardFooter(
    ExamModel exam,
    BuildContext context,
    bool canStart,
    Map<String, dynamic>? submission,
    _CardState state,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'ID: ${exam.examId}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: _off,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (state == _CardState.scored)
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(
              AppRoutes.studentExamResult,
              arguments: {'exam': exam, 'submission': submission},
            ),
            icon: const Icon(Icons.fact_check_outlined, size: 15),
            label: const Text(
              'Review',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 32),
              backgroundColor: _good,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          )
        else if (canStart)
          ElevatedButton.icon(
            onPressed: () => _onStartExam(context, exam),
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text(
              'Start',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 32),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          )
        else
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                Get.toNamed(AppRoutes.studentExamDetails, arguments: exam),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── States ───────────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF5),
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        Container(
          height: 112,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EEF5),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EEF5),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(150, 14),
                const SizedBox(height: 6),
                bar(90, 10),
                const SizedBox(height: 10),
                bar(double.infinity, 36),
              ],
            ),
          ),
          const SizedBox(height: 9),
        ],
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required Color tint,
    required String title,
    required String body,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: tint.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: tint),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: _muted,
                height: 1.4,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 14), action],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileErrorState(String message) {
    return _buildMessage(
      icon: Icons.person_off_outlined,
      tint: _wait,
      title: 'Profile Not Found',
      body: message,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: _onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => Get.offAllNamed(AppRoutes.login),
            icon: const Icon(Icons.login_rounded, size: 16),
            label: const Text('Log In Again'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 38),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamErrorState(String message) {
    return _buildMessage(
      icon: Icons.cloud_off_rounded,
      tint: Colors.redAccent,
      title: 'Failed to Load Exams',
      body: message,
      action: ElevatedButton.icon(
        onPressed: _onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Retry'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 38),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAllExamsState() {
    return _buildMessage(
      icon: Icons.assignment_outlined,
      tint: AppColors.primary,
      title: 'No Exam found',
      body: 'You have not been assigned to any exams yet.',
    );
  }
}

/// Small pulsing dot used to signal a live exam.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _c.repeat();
    } else {
      _c.value = 1.0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 12 * _c.value + 5,
              height: 12 * _c.value + 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ADE80).withOpacity(1 - _c.value),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4ADE80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
