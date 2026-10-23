import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/studentDetails/model/student_exam_submission_summary.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/exam_model.dart';

class StudentExamDetailsScreen extends StatefulWidget {
  final StudentModel student;
  final StudentExamSubmissionSummary summary;
  final String? teacherId;

  const StudentExamDetailsScreen({
    super.key,
    required this.student,
    required this.summary,
    this.teacherId,
  });

  @override
  State<StudentExamDetailsScreen> createState() =>
      _StudentExamDetailsScreenState();
}

class _StudentExamDetailsScreenState extends State<StudentExamDetailsScreen> {
  ExamModel? _examModel;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.summary.examModel != null) {
      _examModel = widget.summary.examModel;
    } else {
      _loadExamDetails();
    }
  }

  Future<void> _loadExamDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tid =
          widget.teacherId ??
          (teacherData?.id.trim().isNotEmpty == true
              ? teacherData!.id.trim()
              : '');

      if (tid.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Teacher session is missing.';
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(tid)
          .collection('exams')
          .doc(widget.summary.examId)
          .get();

      if (!doc.exists || doc.data() == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Exam details not found.';
        });
        return;
      }

      final parsed = ExamModel.fromJson(doc.data()!);
      if (mounted) {
        setState(() {
          _examModel = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load exam questions.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2563EB)),
              const SizedBox(height: 16),
              Text(
                'Loading exam questions...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _examModel == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Unable to display exam.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadExamDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final exam = _examModel!;
    final summary = widget.summary;
    final subData = summary.submissionData;
    final questions = exam.questions;

    // Student answers can be stored by stable questionId in 'answers' or by string index in 'answers_by_index'
    final Map answersMap = (subData['answers'] is Map)
        ? (subData['answers'] as Map)
        : (subData['answers_by_index'] is Map
              ? (subData['answers_by_index'] as Map)
              : {});

    // Compute metrics
    var correctCount = 0;
    var incorrectCount = 0;
    var unattemptedCount = 0;

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final studentAns = _getStudentAnswer(answersMap, q, i);
      if (studentAns == null || studentAns.trim().isEmpty) {
        unattemptedCount++;
      } else if (studentAns.trim().toUpperCase() ==
          q.ans.trim().toUpperCase()) {
        correctCount++;
      } else {
        incorrectCount++;
      }
    }

    final totalQuestions = questions.length;
    final submissionDateStr = summary.submittedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(summary.submittedAt!)
        : 'Not recorded';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card
                _buildHeaderCard(),
                const SizedBox(height: 16),

                // Exam Information Card
                _buildExamInfoCard(submissionDateStr),
                const SizedBox(height: 16),

                // Metrics / Summary Cards Grid (20 Questions, 16 Correct, etc.)
                _buildSummaryGrid(
                  totalQuestions,
                  correctCount,
                  incorrectCount,
                  unattemptedCount,
                ),
                const SizedBox(height: 24),

                // Questions Review Title
                const Text(
                  'Questions & Answers Review',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Read-only breakdown of questions and selected options.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 14),

                // Question Cards
                if (questions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'No questions found in this exam.',
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      final studentAns = _getStudentAnswer(
                        answersMap,
                        q,
                        index,
                      );
                      return _buildQuestionCard(index + 1, q, studentAns);
                    },
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: Color(0xFF0F172A),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Student Exam Details',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  static String? _getStudentAnswer(Map answersMap, QAModel q, int index) {
    if (answersMap.containsKey(q.id)) {
      return answersMap[q.id]?.toString();
    }
    if (answersMap.containsKey(index.toString())) {
      return answersMap[index.toString()]?.toString();
    }
    if (answersMap.containsKey(index)) {
      return answersMap[index]?.toString();
    }
    return null;
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                child: Text(
                  widget.summary.examName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.summary.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Exam ID: ${widget.summary.examId}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    widget.student.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '${widget.summary.score} / ${widget.summary.fullMarks}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFEF08A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamInfoCard(String submissionDateStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exam Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          _infoRow('Date', widget.summary.examDate),
          _infoRow(
            'Time',
            '${widget.summary.startTime} - ${widget.summary.endTime}',
          ),
          _infoRow(
            'Batch',
            widget.summary.batch.isEmpty
                ? widget.student.batch
                : widget.summary.batch,
          ),
          _infoRow('Full Marks', widget.summary.fullMarks),
          _infoRow('Score Obtained', widget.summary.score),
          _infoRow('Submission Time', submissionDateStr),
          _infoRow('Status', widget.summary.status, isStatus: true),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          isStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(
    int total,
    int correct,
    int incorrect,
    int notAnswered,
  ) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            'Questions',
            total.toString(),
            const Color(0xFF2563EB),
            const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricCard(
            'Correct',
            correct.toString(),
            const Color(0xFF10B981),
            const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricCard(
            'Incorrect',
            incorrect.toString(),
            const Color(0xFFEF4444),
            const Color(0xFFFEF2F2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _metricCard(
            'Unanswered',
            notAnswered.toString(),
            const Color(0xFF64748B),
            const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String label, String count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int qNumber, QAModel q, String? studentAns) {
    final cleanStudentAns = studentAns?.trim().toUpperCase();
    final cleanCorrectAns = q.ans.trim().toUpperCase();

    final isAttempted = cleanStudentAns != null && cleanStudentAns.isNotEmpty;
    final isCorrect = isAttempted && cleanStudentAns == cleanCorrectAns;

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (!isAttempted) {
      statusColor = const Color(0xFF64748B);
      statusText = 'Not Answered';
      statusIcon = Icons.remove_circle_outline;
    } else if (isCorrect) {
      statusColor = const Color(0xFF10B981);
      statusText = 'Correct Answer';
      statusIcon = Icons.check_circle_outline;
    } else {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Incorrect Answer';
      statusIcon = Icons.highlight_off;
    }

    final options = [
      {'key': 'A', 'text': q.a},
      {'key': 'B', 'text': q.b},
      {'key': 'C', 'text': q.c},
      {'key': 'D', 'text': q.d},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFFBBF7D0)
              : (isAttempted
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header: Q1 + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Q$qNumber',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question Text
          Text(
            q.q,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // All 4 Options (A, B, C, D)
          ...options.map((opt) {
            final optKey = opt['key']!;
            final optText = opt['text']!;

            final isOptionCorrect = optKey == cleanCorrectAns;
            final isOptionSelectedByStudent = optKey == cleanStudentAns;

            // Background & Border styling
            final Color optBg;
            final Color optBorder;
            final Color optTextColor;
            Widget? badge;

            if (isOptionCorrect) {
              optBg = const Color(0xFFECFDF5);
              optBorder = const Color(0xFF10B981);
              optTextColor = const Color(0xFF065F46);
              badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 12, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      'Correct',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            } else if (isOptionSelectedByStudent) {
              optBg = const Color(0xFFFEF2F2);
              optBorder = const Color(0xFFEF4444);
              optTextColor = const Color(0xFF991B1B);
              badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 12, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      'Student',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              optBg = const Color(0xFFF8FAFC);
              optBorder = const Color(0xFFE2E8F0);
              optTextColor = const Color(0xFF334155);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: optBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: optBorder,
                  width: (isOptionCorrect || isOptionSelectedByStudent)
                      ? 1.5
                      : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isOptionCorrect
                          ? const Color(0xFF10B981)
                          : (isOptionSelectedByStudent
                                ? const Color(0xFFEF4444)
                                : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isOptionCorrect || isOptionSelectedByStudent)
                            ? Colors.transparent
                            : Colors.grey[400]!,
                      ),
                    ),
                    child: Text(
                      optKey,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: (isOptionCorrect || isOptionSelectedByStudent)
                            ? Colors.white
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      optText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            (isOptionCorrect || isOptionSelectedByStudent)
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: optTextColor,
                      ),
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 8), badge],
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 8),

          // Bottom explicit summary text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Answer: ${isAttempted ? cleanStudentAns : "Not Answered"}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAttempted
                      ? (isCorrect
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626))
                      : const Color(0xFF64748B),
                ),
              ),
              Text(
                'Correct Answer: $cleanCorrectAns',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
