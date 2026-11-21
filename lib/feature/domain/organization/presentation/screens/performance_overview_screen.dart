import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/performance_analytics_controller.dart';
import 'package:test_nest/feature/domain/organization/presentation/widgets/performance_charts.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/model/performance_model.dart';

class PerformanceOverviewScreen extends StatefulWidget {
  const PerformanceOverviewScreen({super.key});

  @override
  State<PerformanceOverviewScreen> createState() =>
      _PerformanceOverviewScreenState();
}

class _PerformanceOverviewScreenState extends State<PerformanceOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PerformanceAnalyticsController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _controller.setTabIndex(_tabController.index);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final tenantCtx = Provider.of<ActiveTenantContext>(
        context,
        listen: false,
      );
      _controller = PerformanceAnalyticsController(tenantContext: tenantCtx);

      // Identify user IDs for data fetching
      final studentUid = studentData?.id.trim().isNotEmpty == true
          ? studentData!.id.trim()
          : null;
      final teacherUid = teacherData?.id.trim().isNotEmpty == true
          ? teacherData!.id.trim()
          : null;
      final assignedBatches = teacherData?.batch ?? [];

      _controller.loadData(
        currentStudentUid: studentUid,
        currentTeacherUid: teacherUid,
        teacherAssignedBatches: assignedBatches,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PerformanceAnalyticsController>.value(
      value: _controller,
      child: Consumer<PerformanceAnalyticsController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              title: const Text(
                'Performance Intelligence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              centerTitle: false,
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh analytics',
                  onPressed: () {
                    final studentUid = studentData?.id.trim();
                    final teacherUid = teacherData?.id.trim();
                    final assignedBatches = teacherData?.batch ?? [];
                    controller.loadData(
                      currentStudentUid: studentUid,
                      currentTeacherUid: teacherUid,
                      teacherAssignedBatches: assignedBatches,
                    );
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: const Color(0xFF4F46E5),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF4F46E5),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(text: 'Overview & Graph'),
                      Tab(text: 'Subject-wise'),
                      Tab(text: 'Chapter-wise'),
                      Tab(text: 'Comparison'),
                      Tab(text: 'Leaderboard'),
                    ],
                  ),
                ),
              ),
            ),
            body: controller.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF4F46E5)),
                        SizedBox(height: 16),
                        Text(
                          'Aggregating performance intelligence...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                : controller.errorMessage != null
                ? _buildErrorView(controller)
                : Column(
                    children: [
                      _buildFilterBar(controller),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(controller),
                            _buildSubjectTab(controller),
                            _buildChapterTab(controller),
                            _buildComparisonTab(controller),
                            _buildLeaderboardTab(controller),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(PerformanceAnalyticsController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final studentUid = studentData?.id.trim();
                final teacherUid = teacherData?.id.trim();
                final assignedBatches = teacherData?.batch ?? [];
                controller.loadData(
                  currentStudentUid: studentUid,
                  currentTeacherUid: teacherUid,
                  teacherAssignedBatches: assignedBatches,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(PerformanceAnalyticsController controller) {
    final tenantCtx = Provider.of<ActiveTenantContext>(context, listen: false);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Batch filter (Admin & Teacher)
            if (!tenantCtx.isStudent &&
                controller.availableBatches.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedBatch,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                    items: controller.availableBatches.map((b) {
                      return DropdownMenuItem<String>(value: b, child: Text(b));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) controller.setBatchFilter(val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Student filter (Admin & Teacher)
            if (!tenantCtx.isStudent &&
                controller.availableStudents.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: controller.selectedStudentId,
                    hint: const Text(
                      'All Students',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Students'),
                      ),
                      ...controller.availableStudents.map((s) {
                        return DropdownMenuItem<String?>(
                          value: s['id'],
                          child: Text(s['name'] ?? 'Student'),
                        );
                      }),
                    ],
                    onChanged: (val) => controller.setStudentFilter(val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Subject filter
            if (controller.availableSubjects.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedSubject,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                    items: controller.availableSubjects.map((s) {
                      return DropdownMenuItem<String>(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) controller.setSubjectFilter(val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Date Range button
            InkWell(
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  initialDateRange: controller.dateRange,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF4F46E5),
                          onPrimary: Colors.white,
                          onSurface: Color(0xFF1E293B),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null) {
                  controller.setDateRange(range);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: controller.dateRange != null
                      ? const Color(0xFFEEF2FF)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: controller.dateRange != null
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range_rounded,
                      size: 14,
                      color: controller.dateRange != null
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.dateRange == null
                          ? 'Date Range'
                          : '${DateFormat('MMM dd').format(controller.dateRange!.start)} - ${DateFormat('MMM dd').format(controller.dateRange!.end)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: controller.dateRange != null
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    if (controller.dateRange != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => controller.setDateRange(null),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 0: Overview & Trends ────────────────────────────────────────────────
  Widget _buildOverviewTab(PerformanceAnalyticsController controller) {
    final records = controller.filteredRecords;

    return RefreshIndicator(
      color: const Color(0xFF4F46E5),
      onRefresh: () async {
        final studentUid = studentData?.id.trim();
        final teacherUid = teacherData?.id.trim();
        final assignedBatches = teacherData?.batch ?? [];
        await controller.loadData(
          currentStudentUid: studentUid,
          currentTeacherUid: teacherUid,
          teacherAssignedBatches: assignedBatches,
        );
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stat Summary Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Exams',
                  value: controller.totalExamsAttempted.toString(),
                  icon: Icons.assignment_turned_in_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Average Score',
                  value: '${controller.overallAveragePercentage}%',
                  icon: Icons.analytics_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Highest Score',
                  value: '${controller.overallHighestPercentage}%',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Subjects Tracked',
                  value: controller.subjectsCount.toString(),
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Percentage Trend Chart
          PercentageTrendChart(records: records, height: 220),
          const SizedBox(height: 20),

          // Subject Comparison Bar Chart
          SubjectComparisonBarChart(subjects: controller.subjectPerformances),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Subject-wise Performance ─────────────────────────────────────────
  Widget _buildSubjectTab(PerformanceAnalyticsController controller) {
    final subjects = controller.subjectPerformances;

    if (subjects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 12),
              Text(
                'No subject performance records found',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sub = subjects[index];
        return _buildSubjectCard(sub);
      },
    );
  }

  Widget _buildSubjectCard(SubjectPerformance subject) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF4F46E5),
              size: 22,
            ),
          ),
          title: Text(
            subject.subjectName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            '${subject.totalExams} ${subject.totalExams == 1 ? "exam" : "exams"} • Avg: ${subject.averagePercentage}%',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getScoreColor(
                subject.averagePercentage,
              ).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${subject.averagePercentage}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(subject.averagePercentage),
              ),
            ),
          ),
          children: [
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),
            // High / Low / Recent stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSubMetric(
                  'Highest',
                  '${subject.highestPercentage}%',
                  const Color(0xFF10B981),
                ),
                _buildSubMetric(
                  'Lowest',
                  '${subject.lowestPercentage}%',
                  const Color(0xFFEF4444),
                ),
                _buildSubMetric(
                  'Recent Score',
                  subject.recentPercentage != null
                      ? '${subject.recentPercentage}%'
                      : '--',
                  const Color(0xFF3B82F6),
                ),
              ],
            ),
            if (subject.recentExamName != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Recent: ${subject.recentExamName} (${subject.recentDate != null ? DateFormat('MMM dd, yyyy').format(subject.recentDate!) : "--"})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Chapter-wise Performance ─────────────────────────────────────────
  Widget _buildChapterTab(PerformanceAnalyticsController controller) {
    final chapters = controller.chapterStats;

    if (chapters.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmarks_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 12),
              Text(
                'No chapter performance records found',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: chapters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = chapters[index];
        return _buildChapterCard(c);
      },
    );
  }

  Widget _buildChapterCard(ChapterStat chapter) {
    final color = _getScoreColor(chapter.accuracyPercentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.chapterName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chapter.subjectName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (!chapter.isMetadataAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Chapter metadata unavailable',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${chapter.accuracyPercentage}% Accuracy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Questions metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChapterStatPill(
                'Total',
                '${chapter.questionsCount}',
                const Color(0xFF334155),
              ),
              _buildChapterStatPill(
                'Attempted',
                '${chapter.attemptedCount}',
                const Color(0xFF3B82F6),
              ),
              _buildChapterStatPill(
                'Correct',
                '${chapter.correctCount}',
                const Color(0xFF10B981),
              ),
              _buildChapterStatPill(
                'Incorrect',
                '${chapter.incorrectCount}',
                const Color(0xFFEF4444),
              ),
              _buildChapterStatPill(
                'Unanswered',
                '${chapter.unansweredCount}',
                const Color(0xFF94A3B8),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 6, color: const Color(0xFFF1F5F9)),
                FractionallySizedBox(
                  widthFactor: (chapter.accuracyPercentage / 100.0).clamp(
                    0.0,
                    1.0,
                  ),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterStatPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // ── Tab 3: Exam-to-Exam Comparison ──────────────────────────────────────────
  Widget _buildComparisonTab(PerformanceAnalyticsController controller) {
    final completedRecords = controller.filteredRecords
        .where((r) => r.isCompleted)
        .toList();
    final comparisons = controller.examComparisons;

    if (completedRecords.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 12),
              Text(
                'At least 2 completed exams are needed for comparison',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get unique exam choices
    final uniqueExamsMap = <String, String>{};
    for (final r in completedRecords) {
      uniqueExamsMap[r.examId] = r.examName;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Select exams card
        Container(
          padding: const EdgeInsets.all(14),
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
                    'Select Exams to Compare',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        controller.selectedExamIdsForComparison.length ==
                            uniqueExamsMap.length
                        ? controller.clearComparison
                        : controller.selectAllExamsForComparison,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      controller.selectedExamIdsForComparison.length ==
                              uniqueExamsMap.length
                          ? 'Deselect All'
                          : 'Select All',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: uniqueExamsMap.entries.map((entry) {
                  final isSelected = controller.selectedExamIdsForComparison
                      .contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    selectedColor: const Color(0xFFEEF2FF),
                    checkmarkColor: const Color(0xFF4F46E5),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFF334155),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    onSelected: (_) =>
                        controller.toggleExamForComparison(entry.key),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Comparison cards
        if (comparisons.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Please select at least 2 exams above to see the comparison.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comparisons.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = comparisons[index];
              return _buildComparisonCard(item, index);
            },
          ),
      ],
    );
  }

  Widget _buildComparisonCard(ExamComparisonItem item, int index) {
    final color = _getScoreColor(item.percentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.examName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.examDate != null
                          ? DateFormat('dd MMM yyyy').format(item.examDate!)
                          : 'Date unavailable',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Delta badge
              if (item.percentageDiffFromPrevious != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.percentageDiffFromPrevious! >= 0
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.percentageDiffFromPrevious! >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: item.percentageDiffFromPrevious! >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.percentageDiffFromPrevious! >= 0 ? "+" : ""}${item.percentageDiffFromPrevious}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.percentageDiffFromPrevious! >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Scores & percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'Obtained Marks',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.obtainedMarks}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Max Marks',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.maxMarks}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Percentage',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.percentage}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (item.note != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Text(
                item.note!,
                style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 4: Batch Leaderboard ────────────────────────────────────────────────
  Widget _buildLeaderboardTab(PerformanceAnalyticsController controller) {
    final leaderboard = controller.batchLeaderboard;

    if (leaderboard.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.military_tech_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 12),
              Text(
                'No completed exam records for leaderboard in this batch',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = leaderboard[index];
        return _buildLeaderboardTile(entry);
      },
    );
  }

  Widget _buildLeaderboardTile(BatchLeaderboardEntry entry) {
    // Medal decoration for top 3
    Color badgeBg;
    Color badgeFg;
    Widget? icon;

    if (entry.rank == 1) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeFg = const Color(0xFFB45309);
      icon = const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFFF59E0B),
        size: 16,
      );
    } else if (entry.rank == 2) {
      badgeBg = const Color(0xFFF1F5F9);
      badgeFg = const Color(0xFF475569);
      icon = const Icon(
        Icons.military_tech_rounded,
        color: Color(0xFF94A3B8),
        size: 16,
      );
    } else if (entry.rank == 3) {
      badgeBg = const Color(0xFFFFEDD5);
      badgeFg = const Color(0xFFC2410C);
      icon = const Icon(
        Icons.military_tech_rounded,
        color: Color(0xFFF97316),
        size: 16,
      );
    } else {
      badgeBg = const Color(0xFFF8FAFC);
      badgeFg = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.rank == 1
              ? const Color(0xFFFDE68A)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
            child:
                icon ??
                Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: badgeFg,
                  ),
                ),
          ),
          const SizedBox(width: 12),

          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.batch} • ${entry.totalExamsAttempted} ${entry.totalExamsAttempted == 1 ? "exam" : "exams"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Performance stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.averagePercentage}%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Peak: ${entry.highestPercentage}%',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF10B981);
    if (percentage >= 60) return const Color(0xFF3B82F6);
    if (percentage >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
