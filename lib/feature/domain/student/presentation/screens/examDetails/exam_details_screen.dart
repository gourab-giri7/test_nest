import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class ExamDetailsScreen extends StatelessWidget {
  final ExamModel exam;
  const ExamDetailsScreen({super.key, required this.exam});

  String get teacherId => exam.teacherId.isNotEmpty
      ? exam.teacherId
      : (studentData?.teacherId.trim() ?? '');

  String get studentId =>
      studentData?.getStudentIdForTeacher(teacherId) ??
      (studentData?.id.trim() ?? '');

  Stream<DocumentSnapshot<Map<String, dynamic>>> get submissionStream {
    final s = studentData;
    if (s == null || teacherId.isEmpty || studentId.isEmpty) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('exams')
        .doc(exam.examId)
        .collection('submissions')
        .doc(studentId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = exam.status == 'Active';
    final isUpcoming = exam.status == 'Upcoming';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Assessment Overview',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Hero Exam Banner Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: AppShadows.elevated,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            exam.batch.isEmpty ? 'All Batches' : exam.batch,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success
                                : (isUpcoming
                                      ? AppColors.warning
                                      : Colors.white24),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            exam.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      exam.examName,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Exam ID: ${exam.examId}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (exam.teacherName.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 15,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Teacher: ${exam.teacherName}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _heroMetric(
                            Icons.help_outline_rounded,
                            '${exam.questionCount}',
                            'Questions',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: Colors.white24,
                          ),
                          _heroMetric(
                            Icons.workspace_premium_rounded,
                            exam.fullMarks,
                            'Full Marks',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: Colors.white24,
                          ),
                          _heroMetric(
                            Icons.calendar_today_rounded,
                            exam.examDate,
                            'Date',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Schedule & Timing Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Schedule & Parameters',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _row('Exam Date', exam.examDate),
                    const Divider(height: 18),
                    _row('Time Window', '${exam.startTime} - ${exam.endTime}'),
                    const Divider(height: 18),
                    _row('Maximum Marks', '${exam.fullMarks} Marks'),
                    const Divider(height: 18),
                    _row('Total Questions', '${exam.questionCount} MCQs'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Instructions Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Candidate Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      exam.instruction.trim().isEmpty
                          ? '• Read every question carefully before selecting an option.• Do not switch or minimize the application during the exam.• Your exam will auto-submit if the timer expires.'
                          : exam.instruction,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Action / Submission Status Stream
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: submissionStream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    log('Submission stream error: ${snap.error}');
                    return const Text('Unable to check submission.');
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final submitted = snap.data?.exists ?? false;
                  final data = snap.data?.data();

                  final currentUid = FirebaseAuth.instance.currentUser?.uid;
                  final isAssigned = exam.isEligibleForStudent(
                    studentId: studentId,
                    authUid: currentUid,
                    enrollment: studentData?.getEnrollmentForTeacher(teacherId),
                    hasSubmitted: submitted,
                  );

                  if (submitted) return _submitted(context, data ?? {});

                  if (exam.status == 'Active' && isAssigned) {
                    return SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _start(context),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'Start Assessment Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }

                  if (exam.status == 'Active' && !isAssigned) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.danger.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'You are not assigned to this exam.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: Icon(
                        exam.status == 'Upcoming'
                            ? Icons.lock_clock_rounded
                            : Icons.timer_off_outlined,
                      ),
                      label: Text(
                        exam.status == 'Upcoming'
                            ? 'Exam Has Not Started Yet'
                            : 'Exam Window Closed',
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

  Widget _heroMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _start(BuildContext context) {
    final isEligible = exam.isEligibleForStudent(
      studentId: studentId,
      authUid: FirebaseAuth.instance.currentUser?.uid,
      enrollment: studentData?.getEnrollmentForTeacher(teacherId),
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
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Enter Exam Security Key',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: TextField(
          controller: c,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            hintText: 'Enter exact exam key',
            prefixIcon: Icon(Icons.key_rounded),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () {
              if (c.text != exam.examKey) {
                customSnackbar(
                  context: d,
                  message: 'Invalid exam key.',
                  color: Colors.red,
                  ico: Icons.error,
                );
                return;
              }
              Get.back();
              Get.toNamed(AppRoutes.studentTakeExam, arguments: exam);
            },
            child: const Text('Start Exam'),
          ),
        ],
      ),
    );
  }

  Widget _submitted(
    BuildContext context,
    Map<String, dynamic> data,
  ) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.success.withOpacity(0.4)),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: AppColors.successSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Assessment Submitted',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        if (exam.resultPublished)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Score Obtained: ${data['score'] ?? '—'} / ${exam.fullMarks}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.success,
                fontSize: 14,
              ),
            ),
          )
        else
          const Text(
            'Your responses are safely recorded. Results are awaiting publication.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        const SizedBox(height: 18),
        if (exam.resultPublished)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text('View Scorecard & Answer Review'),
              onPressed: () => Get.toNamed(
                AppRoutes.studentExamResult,
                arguments: {'exam': exam, 'submission': data},
              ),
            ),
          ),
      ],
    ),
  );

  Widget _row(String l, String v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        l,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      Flexible(
        child: Text(
          v,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.text,
            fontSize: 13.5,
          ),
        ),
      ),
    ],
  );
}
