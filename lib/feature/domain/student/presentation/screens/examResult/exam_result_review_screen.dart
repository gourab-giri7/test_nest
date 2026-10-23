import 'package:flutter/material.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/exam_model.dart';

class ExamResultReviewScreen extends StatelessWidget {
  final ExamModel exam;
  final Map<String, dynamic> submission;

  const ExamResultReviewScreen({
    super.key,
    required this.exam,
    required this.submission,
  });

  @override
  Widget build(BuildContext context) {
    final answers = Map<String, dynamic>.from(
      submission['answers'] is Map ? submission['answers'] : {},
    );
    final score = submission['score']?.toString() ?? '0';
    final attempted = submission['attempted']?.toString() ?? '0';
    final correctCount = submission['correct_count']?.toString() ?? '0';
    final totalQuestions = exam.questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.background,
        title: const Text(
          'Result & Answer Review',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            children: [
              // Score Overview Card
              _buildOverviewCard(
                score: score,
                fullMarks: exam.fullMarks,
                correctCount: correctCount,
                attempted: attempted,
                total: totalQuestions,
              ),
              const SizedBox(height: 20),

              // Review Header
              const Text(
                'Question by Question Review',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),

              // Questions List
              ...List.generate(exam.questions.length, (i) {
                final q = exam.questions[i];
                final selected = (answers[q.id] ?? answers[i.toString()] ?? '')
                    .toString()
                    .trim()
                    .toUpperCase();
                final correct = q.ans.trim().toUpperCase();
                final bool isAnswered = selected.isNotEmpty;
                final bool isCorrect = isAnswered && selected == correct;

                return _buildQuestionReviewCard(
                  index: i + 1,
                  question: q,
                  selected: selected,
                  correct: correct,
                  isAnswered: isAnswered,
                  isCorrect: isCorrect,
                );
              }),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String score,
    required String fullMarks,
    required String correctCount,
    required String attempted,
    required int total,
  }) {
    final int numTotal = total;
    final int numCorrect = int.tryParse(correctCount) ?? 0;
    final int numAttempted = int.tryParse(attempted) ?? 0;
    final int numIncorrect = (numAttempted - numCorrect).clamp(0, numTotal);
    final int numUnattempted = (numTotal - numAttempted).clamp(0, numTotal);

    final double s = double.tryParse(score) ?? 0.0;
    final double fm =
        double.tryParse(fullMarks) ?? (total > 0 ? total.toDouble() : 100.0);
    final double pct = fm > 0 ? (s / fm).clamp(0.0, 1.0) : 0.0;
    final int pctInt = (pct * 100).round();
    final bool isPassed = pctInt >= 40;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            exam.examName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Batch: ${exam.batch} • Full Marks: $fullMarks',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Circular Score Indicator
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPassed
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score / $fullMarks',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$pctInt%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPassed
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // 4 Key Metrics
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  label: 'Total',
                  value: '$numTotal',
                  textColor: AppColors.text,
                  bgColor: const Color(0xFFF8FAFC),
                  borderColor: const Color(0xFFE2E8F0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox(
                  label: 'Correct',
                  value: '$numCorrect',
                  textColor: const Color(0xFF059669),
                  bgColor: const Color(0xFFECFDF5),
                  borderColor: const Color(0xFFA7F3D0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox(
                  label: 'Incorrect',
                  value: '$numIncorrect',
                  textColor: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox(
                  label: 'Skipped',
                  value: '$numUnattempted',
                  textColor: const Color(0xFF64748B),
                  bgColor: const Color(0xFFF1F5F9),
                  borderColor: const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox({
    required String label,
    required String value,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReviewCard({
    required int index,
    required QAModel question,
    required String selected,
    required String correct,
    required bool isAnswered,
    required bool isCorrect,
  }) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!isAnswered) {
      statusColor = AppColors.textSecondary;
      statusText = 'Unanswered';
      statusIcon = Icons.help_outline;
    } else if (isCorrect) {
      statusColor = const Color(0xFF059669);
      statusText = '✓ Correct';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = const Color(0xFFDC2626);
      statusText = '✗ Incorrect';
      statusIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF86EFAC)
              : (isAnswered ? const Color(0xFFFCA5A5) : AppColors.border),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Question # and status badge
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question.q,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                    color: AppColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.successSoft
                      : (isAnswered
                            ? AppColors.dangerSoft
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Option A, B, C, D
          _buildOptionReviewRow('A', question.a, selected, correct),
          const SizedBox(height: 6),
          _buildOptionReviewRow('B', question.b, selected, correct),
          const SizedBox(height: 6),
          _buildOptionReviewRow('C', question.c, selected, correct),
          const SizedBox(height: 6),
          _buildOptionReviewRow('D', question.d, selected, correct),
        ],
      ),
    );
  }

  Widget _buildOptionReviewRow(
    String letter,
    String text,
    String selected,
    String correct,
  ) {
    final bool isUserChoice = selected == letter;
    final bool isCorrectAnswer = correct == letter;

    Color bg;
    Color border;
    Color textColor;
    Widget? badge;

    if (isCorrectAnswer) {
      bg = AppColors.successSoft;
      border = AppColors.success;
      textColor = const Color(0xFF047857);
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isUserChoice ? 'Your Answer (Correct)' : 'Correct Answer',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else if (isUserChoice) {
      bg = AppColors.dangerSoft;
      border = AppColors.danger;
      textColor = const Color(0xFFB91C1C);
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Your Answer (Incorrect)',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    } else {
      bg = const Color(0xFFF8FAFC);
      border = AppColors.border;
      textColor = const Color(0xFF334155);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: border,
          width: (isUserChoice || isCorrectAnswer) ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: border.withOpacity(0.2),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: (isUserChoice || isCorrectAnswer)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          if (badge != null) badge,
        ],
      ),
    );
  }
}
