import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:intl/intl.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/exam_model.dart';

class TeacherExamDetailsScreen extends StatefulWidget {
  final ExamModel exam;
  const TeacherExamDetailsScreen({super.key, required this.exam});

  @override
  State<TeacherExamDetailsScreen> createState() =>
      _TeacherExamDetailsScreenState();
}

class _TeacherExamDetailsScreenState extends State<TeacherExamDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teacherId = teacherData?.id.trim();
    if (teacherId == null || teacherId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Teacher session not found')),
      );
    }

    final examRef = FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('exams')
        .doc(widget.exam.examId);

    final studentsRef = FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('students');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.background,
        title: const Text(
          'Exam Management & Results',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: examRef.snapshots(),
        builder: (context, examSnap) {
          final currentExam = examSnap.hasData && examSnap.data!.exists
              ? ExamModel.fromJson(examSnap.data!.data()!)
              : widget.exam;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: examRef.collection('submissions').snapshots(),
            builder: (context, subSnap) {
              final subDocs = subSnap.data?.docs ?? [];
              final submittedMap = <String, Map<String, dynamic>>{};
              for (final d in subDocs) {
                final data = d.data();
                final sId = (data['student_id'] ?? d.id).toString().trim();
                if (sId.isNotEmpty) {
                  submittedMap[sId] = data;
                }
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: studentsRef.snapshots(),
                builder: (context, studSnap) {
                  final allStudents = (studSnap.data?.docs ?? [])
                      .map((d) => StudentModel.fromJson(d.data()))
                      .toList();

                  final studentMap = {
                    for (final s in allStudents) s.id.trim(): s,
                  };

                  final assignedIds = currentExam.assignedStudentIds
                      .map((id) => id.trim())
                      .where((id) => id.isNotEmpty)
                      .toSet();

                  final submittedList = <Map<String, dynamic>>[];
                  final unsubmittedList = <StudentModel>[];

                  for (final id in assignedIds) {
                    if (submittedMap.containsKey(id)) {
                      submittedList.add(submittedMap[id]!);
                    } else {
                      final student =
                          studentMap[id] ??
                          StudentModel(
                            name: 'Student ($id)',
                            id: id,
                            password: '',
                            batch: currentExam.batch,
                          );
                      unsubmittedList.add(student);
                    }
                  }

                  // Also include any submissions that were recorded
                  for (final entry in submittedMap.entries) {
                    if (!assignedIds.contains(entry.key) &&
                        !submittedList.any(
                          (s) =>
                              (s['student_id'] ?? '').toString().trim() ==
                              entry.key,
                        )) {
                      submittedList.add(entry.value);
                    }
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = constraints.maxWidth;
                      final horizontalPadding = screenWidth < 600 ? 12.0 : 20.0;
                      final contentMaxWidth = screenWidth >= 1100
                          ? 1100.0
                          : 900.0;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentMaxWidth,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                    vertical: 12,
                                  ),
                                  children: [
                                    _header(currentExam, examRef),
                                    const SizedBox(height: 14),
                                    _metricsSummary(
                                      assignedCount: assignedIds.length,
                                      submittedCount: submittedList.length,
                                      unsubmittedCount: unsubmittedList.length,
                                    ),
                                    const SizedBox(height: 14),
                                    _assignedStudentsCard(
                                      context,
                                      examRef,
                                      currentExam,
                                    ),
                                    const SizedBox(height: 16),
                                    _tabSection(
                                      submittedList: submittedList,
                                      unsubmittedList: unsubmittedList,
                                      currentExam: currentExam,
                                      examRef: examRef,
                                    ),
                                  ],
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
            },
          );
        },
      ),
    );
  }

  Widget _header(ExamModel e, DocumentReference<Map<String, dynamic>> ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 480;

              final statusBadge = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: e.status == 'Active'
                      ? AppColors.successSoft
                      : e.status == 'Upcoming'
                      ? AppColors.primarySoft
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  e.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: e.status == 'Active'
                        ? const Color(0xFF059669)
                        : e.status == 'Upcoming'
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.examName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    statusBadge,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      e.examName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  statusBadge,
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _headerChip(Icons.tag, 'ID: ${e.examId}'),
              _headerChip(
                Icons.people_outline,
                'Batch: ${e.batch.isEmpty ? "All" : e.batch}',
              ),
              _headerChip(Icons.key, 'Exam Key: ${e.examKey}'),
              _headerChip(Icons.grade_outlined, 'Full Marks: ${e.fullMarks}'),
              _headerChip(
                Icons.calendar_today_outlined,
                '${e.examDate} • ${e.startTime} - ${e.endTime}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                e.resultPublished ? Icons.visibility : Icons.visibility_off,
                color: e.resultPublished ? AppColors.success : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.resultPublished
                          ? 'Results are Published'
                          : 'Results are Hidden',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      e.resultPublished
                          ? 'Students can now see marks & answer review'
                          : 'Turn on to let students view marks & review',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: e.resultPublished,
                activeColor: AppColors.success,
                onChanged: (val) async {
                  await ref.update({
                    'result_published': val,
                    if (val)
                      'result_published_at': FieldValue.serverTimestamp()
                    else
                      'result_published_at': FieldValue.delete(),
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              softWrap: true,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsSummary({
    required int assignedCount,
    required int submittedCount,
    required int unsubmittedCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final cards = [
          _metricCard(
            'Assigned',
            '$assignedCount',
            AppColors.primary,
            AppColors.primarySoft,
          ),
          _metricCard(
            'Submitted',
            '$submittedCount',
            AppColors.success,
            AppColors.successSoft,
          ),
          _metricCard(
            'Pending',
            '$unsubmittedCount',
            AppColors.warning,
            const Color(0xFFFEF3C7),
          ),
        ];

        if (compact) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: (constraints.maxWidth - 10) / 2,
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 10),
            Expanded(child: cards[1]),
            const SizedBox(width: 10),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _metricCard(
    String label,
    String value,
    Color primaryColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignedStudentsCard(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
    ExamModel e,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Access Management',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                'Only students in assigned_student_ids can view & take this exam',
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.blueGrey[600]),
              ),
            ],
          );

          final button = OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1, size: 16),
            label: const Text('Add More'),
            onPressed: () => _addStudents(context, ref, e),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [info, const SizedBox(height: 10), button],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }

  Widget _tabSection({
    required List<Map<String, dynamic>> submittedList,
    required List<StudentModel> unsubmittedList,
    required ExamModel currentExam,
    required DocumentReference<Map<String, dynamic>> examRef,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Submitted (${submittedList.length})'),
              Tab(text: 'Pending (${unsubmittedList.length})'),
              Tab(text: 'Questions (${currentExam.questions.length})'),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final height = MediaQuery.sizeOf(context).height;
              final tabHeight = (height * 0.52).clamp(360.0, 620.0);
              return SizedBox(
                height: tabHeight,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Submitted Students
                    _buildSubmittedTab(submittedList, currentExam, examRef),

                    // Tab 2: Pending/Unsubmitted Students
                    _buildUnsubmittedTab(unsubmittedList),

                    // Tab 3: Questions
                    _buildQuestionsTab(currentExam),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedTab(
    List<Map<String, dynamic>> submissions,
    ExamModel exam,
    DocumentReference<Map<String, dynamic>> examRef,
  ) {
    if (submissions.isEmpty) {
      return _empty('No students have submitted this exam yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: submissions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final d = submissions[index];
        final studentId = (d['student_id'] ?? '').toString().trim();
        final studentName = (d['student_name'] ?? 'Student').toString().trim();
        final score = d['score']?.toString() ?? '0';
        final attempted = d['attempted']?.toString() ?? '0';
        final totalQ =
            d['total_questions']?.toString() ?? '${exam.questions.length}';

        DateTime? submittedAt;
        if (d['submitted_at'] is Timestamp) {
          submittedAt = (d['submitted_at'] as Timestamp).toDate();
        }

        final timeString = submittedAt != null
            ? DateFormat('dd MMM, hh:mm a').format(submittedAt)
            : 'Submitted';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;

              final studentInfo = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      studentName.isNotEmpty
                          ? studentName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
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
                          studentName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: $studentId • Attempted: $attempted/$totalQ • $timeString',
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actions = Column(
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$score / ${exam.fullMarks}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showStudentReviewDialog(context, exam, d),
                        child: const Text(
                          'View Answers',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _reassignStudent(
                          context,
                          examRef,
                          exam,
                          studentId,
                          studentName,
                          d,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 11,
                                color: Color(0xFFB45309),
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Reassign',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFB45309),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showAttemptHistoryDialog(
                          context,
                          examRef,
                          studentId,
                          studentName,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history,
                                size: 11,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'History',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [studentInfo, const SizedBox(height: 10), actions],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: studentInfo),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUnsubmittedTab(List<StudentModel> unsubmitted) {
    if (unsubmitted.isEmpty) {
      return _empty('All assigned students have submitted this exam!');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: unsubmitted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = unsubmitted[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final studentInfo = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFEF3C7),
                    child: Text(
                      s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${s.id} • Batch: ${s.batch}',
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final status = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [studentInfo, const SizedBox(height: 10), status],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: studentInfo),
                  const SizedBox(width: 12),
                  status,
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuestionsTab(ExamModel exam) {
    if (exam.questions.isEmpty) {
      return _empty('No questions in this exam.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: exam.questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final q = exam.questions[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 500;
                  final number = CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                  final answerBadge = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Ans: ${q.ans}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  );
                  final question = Expanded(
                    child: Text(
                      q.q,
                      softWrap: true,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            number,
                            const SizedBox(width: 8),
                            question,
                          ],
                        ),
                        const SizedBox(height: 8),
                        answerBadge,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      number,
                      const SizedBox(width: 8),
                      question,
                      const SizedBox(width: 8),
                      answerBadge,
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              _option('A', q.a, q.ans),
              _option('B', q.b, q.ans),
              _option('C', q.c, q.ans),
              _option('D', q.d, q.ans),
            ],
          ),
        );
      },
    );
  }

  void _showStudentReviewDialog(
    BuildContext context,
    ExamModel exam,
    Map<String, dynamic> submission,
  ) {
    final answers = Map<String, dynamic>.from(
      submission['answers'] is Map ? submission['answers'] : {},
    );

    final studentName = submission['student_name'] ?? 'Student';
    final score = submission['score'] ?? 0;

    int correctCount = 0;
    int incorrectCount = 0;
    int notAnsweredCount = 0;

    for (int i = 0; i < exam.questions.length; i++) {
      final q = exam.questions[i];
      final selected = (answers[q.id] ?? answers[i.toString()] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      final correct = q.ans.trim().toUpperCase();

      if (selected.isEmpty) {
        notAnsweredCount++;
      } else if (selected == correct) {
        correctCount++;
      } else {
        incorrectCount++;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final size = MediaQuery.sizeOf(ctx);

        final dialogWidth = (size.width * 0.92).clamp(300.0, 720.0);
        final dialogHeight = (size.height * 0.78).clamp(400.0, 700.0);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              children: [
                // ─────────────────────────────────────────────
                // HEADER
                // ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Student avatar
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            ctx,
                          ).colorScheme.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Theme.of(ctx).colorScheme.primary,
                          size: 25,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Student name + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Exam Review',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Score badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            ctx,
                          ).colorScheme.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                            ),
                            Text(
                              '/ ${exam.fullMarks}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─────────────────────────────────────────────
                // SUMMARY STRIP
                // ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      _reviewSummaryItem(
                        icon: Icons.quiz_outlined,
                        label: 'Total',
                        value: exam.questions.length.toString(),
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _reviewSummaryItem(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Correct',
                        value: '$correctCount',
                        color: const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 8),
                      _reviewSummaryItem(
                        icon: Icons.cancel_outlined,
                        label: 'Incorrect',
                        value: '$incorrectCount',
                        color: const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      _reviewSummaryItem(
                        icon: Icons.remove_circle_outline_rounded,
                        label: 'Unanswered',
                        value: '$notAnsweredCount',
                        color: const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ),

                // ─────────────────────────────────────────────
                // QUESTION LIST
                // ─────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: exam.questions.length,
                    itemBuilder: (context, i) {
                      final q = exam.questions[i];

                      final selected =
                          (answers[q.id] ?? answers[i.toString()] ?? '')
                              .toString()
                              .trim()
                              .toUpperCase();

                      final correct = q.ans.trim().toUpperCase();

                      final isCorrect =
                          selected.isNotEmpty && selected == correct;

                      return _buildReviewQuestionCard(
                        context: context,
                        questionNumber: i + 1,
                        question: q,
                        selectedAnswer: selected,
                        correctAnswer: correct,
                        isCorrect: isCorrect,
                      );
                    },
                  ),
                ),

                // ─────────────────────────────────────────────
                // FOOTER
                // ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: Colors.grey.withOpacity(0.15)),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reassignStudent(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> examRef,
    ExamModel exam,
    String studentId,
    String studentName,
    Map<String, dynamic> submission,
  ) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restart_alt, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Reassign Student?'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to reassign "$studentName" (ID: $studentId)?\n\n'
                '• Their current submission (Score: ${submission['score'] ?? 0}/${exam.fullMarks}) will be safely archived to attempt history.\n'
                '• Their attempt state will be reset so they can take the exam again.\n'
                '• Previous scores and submissions remain immutable and auditable.\n'
                '• They will remain in assigned_student_ids and use the exam key.\n',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reassignment Reason (Optional)',
                  hintText: 'e.g. Technical glitch, power outage, approved retake',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Reassign Now'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final subRef = examRef.collection('submissions').doc(studentId);
      final reason = reasonController.text.trim();
      final currentTeacher = teacherData?.name ?? 'Teacher';
      final currentTeacherId = teacherData?.id ?? '';

      // Run as atomic Firestore transaction to prevent partial state corruption
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final subSnap = await tx.get(subRef);
        final examSnap = await tx.get(examRef);

        if (!subSnap.exists) {
          throw StateError('Active submission not found to reassign.');
        }

        final data = subSnap.data()!;
        final attemptNum = data['attempt_number'] ?? 1;

        // 1. Archive to submission_history
        final historyRef = examRef
            .collection('submission_history')
            .doc('${studentId}_attempt_$attemptNum');

        tx.set(historyRef, {
          ...data,
          'archived_at': FieldValue.serverTimestamp(),
          'reassigned_at': FieldValue.serverTimestamp(),
          'reassigned_by': currentTeacher,
          'reassigned_by_id': currentTeacherId,
          if (reason.isNotEmpty) 'reassign_reason': reason,
        });

        // 2. Delete the active submission so student can retake
        tx.delete(subRef);

        // 3. Atomically increment attempt count and ensure assignment
        final reassignedMap =
            (examSnap.data()?['reassigned_students'] as Map<String, dynamic>?) ?? {};
        final newAttemptCount =
            ((reassignedMap[studentId] as num?)?.toInt() ?? 0) + 1;

        final Map<String, dynamic> updateMap = {
          'reassigned_students.$studentId': newAttemptCount,
          'assigned_student_ids': FieldValue.arrayUnion([studentId]),
        };

        tx.update(examRef, updateMap);
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
              'Successfully reassigned "$studentName". Retake enabled.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to reassign student: $e'),
          ),
        );
      }
    }
  }

  void _showAttemptHistoryDialog(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> examRef,
    String studentId,
    String studentName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.history, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Attempt History: $studentName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: examRef
                    .collection('submission_history')
                    .where('student_id', isEqualTo: studentId)
                    .get(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No prior attempt history archived for this student.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final item = docs[i].data();
                      final attemptNum = item['attempt_number'] ?? (i + 1);
                      final score = item['score'] ?? 0;
                      final reason = item['reassign_reason'] ?? 'Not specified';
                      final by = item['reassigned_by'] ?? 'Teacher';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primarySoft,
                          child: Text(
                            '#$attemptNum',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        title: Text('Score: $score / ${item['full_marks'] ?? '0'}'),
                        subtitle: Text(
                          'Reassigned by: $by\nReason: $reason',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Archived',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addStudents(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
    ExamModel e,
  ) async {
    final teacherId = teacherData?.id.trim();
    if (teacherId == null || teacherId.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('students')
        .get();
    final assigned = e.assignedStudentIds.toSet();
    final available = snap.docs
        .map((d) => StudentModel.fromJson(d.data(), docId: d.id))
        .where(
          (s) =>
              StudentModel.isSameBatch(s.batch, e.batch) &&
              !assigned.contains(s.id.trim()),
        )
        .toList();
    if (!context.mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No additional students are available in this batch.'),
        ),
      );
      return;
    }
    final selected = <String>{};
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Students • ${e.batch}'),
          content: SizedBox(
            width: (MediaQuery.sizeOf(context).width * 0.88).clamp(
              280.0,
              520.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: ListView(
                shrinkWrap: true,
                children: available
                    .map(
                      (student) => CheckboxListTile(
                        value: selected.contains(student.id.trim()),
                        onChanged: (v) => setDialogState(() {
                          if (v == true) {
                            selected.add(student.id.trim());
                          } else {
                            selected.remove(student.id.trim());
                          }
                        }),
                        title: Text(student.name),
                        subtitle: Text(student.id),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, selected.toList()),
              child: const Text('Add Selected'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result.isEmpty) return;
    await ref.update({'assigned_student_ids': FieldValue.arrayUnion(result)});
  }

  Widget _option(String letter, String text, String answer) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: letter.toUpperCase() == answer.trim().toUpperCase()
              ? AppColors.successSoft
              : const Color(0xFFF1F5F9),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: letter.toUpperCase() == answer.trim().toUpperCase()
                  ? const Color(0xFF047857)
                  : const Color(0xFF475569),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: letter.toUpperCase() == answer.trim().toUpperCase()
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: letter.toUpperCase() == answer.trim().toUpperCase()
                  ? const Color(0xFF047857)
                  : const Color(0xFF334155),
            ),
          ),
        ),
        if (letter.toUpperCase() == answer.trim().toUpperCase())
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
      ],
    ),
  );

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Colors.blueGrey[600]),
      ),
    ),
  );
}

Widget _reviewSummaryItem({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildReviewQuestionCard({
  required BuildContext context,
  required int questionNumber,
  required QAModel question,
  required String selectedAnswer,
  required String correctAnswer,
  required bool isCorrect,
}) {
  final isNotAnswered = selectedAnswer.isEmpty;

  final Color statusColor = isCorrect
      ? const Color(0xFF16A34A)
      : (isNotAnswered ? const Color(0xFFD97706) : const Color(0xFFDC2626));

  final Color backgroundColor = isCorrect
      ? const Color(0xFFF0FDF4)
      : (isNotAnswered ? const Color(0xFFFAFAFA) : const Color(0xFFFFF7F7));

  final Color borderColor = isCorrect
      ? const Color(0xFFBBEFCB)
      : (isNotAnswered ? AppColors.border : const Color(0xFFFFCACA));

  final options = [
    {'key': 'A', 'text': question.a},
    {'key': 'B', 'text': question.b},
    {'key': 'C', 'text': question.c},
    {'key': 'D', 'text': question.d},
  ];

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Question Header (Number, Question text, Status Pill) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$questionNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.q,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : (isNotAnswered
                                ? Icons.remove_circle_outline_rounded
                                : Icons.cancel_rounded),
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCorrect
                          ? 'Correct'
                          : (isNotAnswered ? 'Unanswered' : 'Incorrect'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Options A, B, C, D ──
          ...options.map((opt) {
            final optKey = opt['key']!;
            final optText = (opt['text'] ?? '').trim();
            final isSelected = selectedAnswer == optKey;
            final isThisCorrect = correctAnswer == optKey;

            return _buildReviewOptionTile(
              optKey: optKey,
              optText: optText,
              isSelected: isSelected,
              isThisCorrect: isThisCorrect,
            );
          }),

          const SizedBox(height: 6),

          // ── Footer: Student selection, Correct Answer & Status ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Student: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      isNotAnswered ? 'Not answered' : selectedAnswer,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isNotAnswered
                            ? const Color(0xFFD97706)
                            : (isCorrect
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Correct: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      correctAnswer,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect
                            ? Icons.check
                            : (isNotAnswered ? Icons.remove : Icons.close),
                        size: 11,
                        color: statusColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isCorrect
                            ? 'Correct Answer'
                            : (isNotAnswered
                                  ? 'Not Answered'
                                  : 'Incorrect Answer'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildReviewOptionTile({
  required String optKey,
  required String optText,
  required bool isSelected,
  required bool isThisCorrect,
}) {
  final Color bg;
  final Border border;
  final Color keyBg;
  final Color keyTextColor;
  final Color textColor;
  final Widget? trailingIcon;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeTextColor;

  if (isSelected && isThisCorrect) {
    bg = AppColors.successSoft;
    border = Border.all(color: AppColors.success, width: 1.5);
    keyBg = AppColors.success;
    keyTextColor = Colors.white;
    textColor = const Color(0xFF065F46);
    trailingIcon = const Icon(
      Icons.check_circle_rounded,
      color: AppColors.success,
      size: 18,
    );
    badgeText = 'Student Answer • Correct Answer';
    badgeBg = const Color(0xFFD1FAE5);
    badgeTextColor = const Color(0xFF065F46);
  } else if (!isSelected && isThisCorrect) {
    bg = const Color(0xFFF0FDF4);
    border = Border.all(color: const Color(0xFF34D399), width: 1.5);
    keyBg = const Color(0xFFD1FAE5);
    keyTextColor = const Color(0xFF047857);
    textColor = const Color(0xFF065F46);
    trailingIcon = const Icon(
      Icons.check_circle_outline_rounded,
      color: AppColors.success,
      size: 18,
    );
    badgeText = 'Correct Answer';
    badgeBg = const Color(0xFFD1FAE5);
    badgeTextColor = const Color(0xFF047857);
  } else if (isSelected && !isThisCorrect) {
    bg = AppColors.dangerSoft;
    border = Border.all(color: AppColors.danger, width: 1.5);
    keyBg = AppColors.danger;
    keyTextColor = Colors.white;
    textColor = const Color(0xFF991B1B);
    trailingIcon = const Icon(
      Icons.cancel_rounded,
      color: AppColors.danger,
      size: 18,
    );
    badgeText = 'Student Answer';
    badgeBg = const Color(0xFFFEE2E2);
    badgeTextColor = const Color(0xFFB91C1C);
  } else {
    bg = Colors.white;
    border = Border.all(color: AppColors.border, width: 1);
    keyBg = const Color(0xFFF1F5F9);
    keyTextColor = AppColors.textSecondary;
    textColor = const Color(0xFF334155);
    trailingIcon = null;
    badgeText = null;
    badgeBg = null;
    badgeTextColor = null;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      border: border,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Letter indicator circle
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: keyBg, shape: BoxShape.circle),
          child: Text(
            optKey,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: keyTextColor,
            ),
          ),
        ),
        const SizedBox(width: 9),

        // Text & Badge in Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                optText.isNotEmpty ? optText : '($optKey)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: (isSelected || isThisCorrect)
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: textColor,
                  height: 1.3,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        if (trailingIcon != null) ...[
          const SizedBox(width: 6),
          Padding(padding: const EdgeInsets.only(top: 2), child: trailingIcon),
        ],
      ],
    ),
  );
}
