import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examResult/exam_result_review_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/takeExam/take_exam_screen.dart';
import 'package:test_nest/model/exam_model.dart';

class ExamDetailsScreen extends StatelessWidget {
  final ExamModel exam;
  const ExamDetailsScreen({super.key, required this.exam});
  String get teacherId => studentData?.teacherId.trim() ?? '';
  Stream<DocumentSnapshot<Map<String, dynamic>>> get submissionStream {
    final s = studentData;
    if (s == null || teacherId.isEmpty || s.id.trim().isEmpty)
      return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('exams')
        .doc(exam.examId)
        .collection('submissions')
        .doc(s.id.trim())
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Exam Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.examName,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${exam.examId} • ${exam.batch.isEmpty ? 'All Batches' : exam.batch}',
                      ),
                      const SizedBox(height: 16),
                      _row('Date', exam.examDate),
                      _row('Time', '${exam.startTime} - ${exam.endTime}'),
                      _row('Full Marks', exam.fullMarks),
                      _row('Questions', '${exam.questionCount}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        exam.instruction.trim().isEmpty
                            ? 'Follow the instructions provided by your teacher.'
                            : exam.instruction,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: submissionStream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    log('Submission stream error: ${snap.error}');
                    return const Text('Unable to check submission.');
                  }
                  if (snap.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  final submitted = snap.data?.exists ?? false;
                  final data = snap.data?.data();

                  // For exams using assigned_student_ids, assignment is
                  // mandatory. This prevents a student from starting an exam
                  // through an old/stale route even if the history screen
                  // already filtered it out.
                  final studentId = studentData?.id.trim() ?? '';
                  final isAssigned =
                      exam.assignedStudentIds.isNotEmpty &&
                      exam.assignedStudentIds.any(
                        (id) => id.trim() == studentId,
                      );

                  if (submitted) return _submitted(context, data ?? {});

                  if (exam.status == 'Active' && isAssigned)
                    return SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _start(context),
                        child: const Text(
                          'Start Exam',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );

                  if (exam.status == 'Active' && !isAssigned)
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'You are not assigned to this exam.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  return SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: null,
                      child: Text(
                        exam.status == 'Upcoming'
                            ? 'Exam has not started'
                            : 'Exam Ended',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _start(BuildContext context) {
    final studentId = studentData?.id.trim() ?? '';
    final isAssigned =
        exam.assignedStudentIds.isNotEmpty &&
        exam.assignedStudentIds.any((id) => id.trim() == studentId);

    if (!isAssigned) {
      customSnackbar(
        context: context,
        message: 'You are not assigned to this exam.',
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TakeExamScreen(exam: exam)),
      );
      return;
    }
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Enter Exam Key'),
        content: TextField(
          controller: c,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(hintText: 'Enter exact exam key'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Character-exact comparison without trim() or case-conversion.
              // Trailing space or case difference will be rejected.
              if (c.text != exam.examKey) {
                customSnackbar(
                  context: d,
                  message: 'Invalid exam key.',
                  color: Colors.red,
                  ico: Icons.error,
                );
                return;
              }
              Navigator.pop(d);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TakeExamScreen(exam: exam)),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  Widget _submitted(BuildContext context, Map<String, dynamic> data) => Card(
    color: AppColors.successSoft,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 42),
          const SizedBox(height: 8),
          const Text(
            'Exam Submitted',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          if (exam.resultPublished)
            Text('Score: ${data['score'] ?? '—'} / ${exam.fullMarks}')
          else
            const Text('Result is not published yet.'),
          const SizedBox(height: 14),
          if (exam.resultPublished)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.fact_check),
                label: const Text('View Result & Answer Review'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ExamResultReviewScreen(exam: exam, submission: data),
                  ),
                ),
              ),
            )
          else
            const Text(
              'Result will be visible after your teacher publishes it.',
              style: TextStyle(color: Colors.blueGrey),
            ),
        ],
      ),
    ),
  );
  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: Colors.blueGrey)),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
