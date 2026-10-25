import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Scorecard & Answer Review',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            children: [
              _buildOverviewCard(
                score: score,
                fullMarks: exam.fullMarks,
                correctCount: correctCount,
                attempted: attempted,
                total: totalQuestions,
              ),
              const SizedBox(height: 24),

              const Row(
                children: [
                  Icon(
                    Icons.fact_check_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Detailed Question Breakdown',
                    style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isPassed ? AppColors.successSoft : AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPassed ? 'OFFICIAL SCORECARD' : 'NEEDS IMPROVEMENT',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: isPassed ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            exam.examName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Batch: ${exam.batch}  •  Max Marks: $fullMarks',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),

          Center(
            child: SizedBox(
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPassed ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score / $fullMarks',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? AppColors.successSoft
                              : AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$pctInt%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isPassed
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _metricBox(
                  label: 'Total',
                  value: '$numTotal',
                  textColor: AppColors.primary,
                  bgColor: AppColors.primarySoft,
                  borderColor: AppColors.primary.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox(
                  label: 'Correct',
                  value: '$numCorrect',
                  textColor: AppColors.success,
                  bgColor: AppColors.successSoft,
                  borderColor: AppColors.success.withOpacity(0.25),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox(
                  label: 'Incorrect',
                  value: '$numIncorrect',
                  textColor: AppColors.danger,
                  bgColor: AppColors.dangerSoft,
                  borderColor: AppColors.danger.withOpacity(0.25),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricBox(
                  label: 'Skipped',
                  value: '$numUnattempted',
                  textColor: AppColors.textSecondary,
                  bgColor: AppColors.surfaceAlt,
                  borderColor: AppColors.border,
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor.withOpacity(0.85),
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
      statusIcon = Icons.remove_circle_outline_rounded;
    } else if (isCorrect) {
      statusColor = AppColors.success;
      statusText = 'Correct';
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = AppColors.danger;
      statusText = 'Incorrect';
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCorrect
              ? AppColors.success.withOpacity(0.45)
              : (isAnswered
                    ? AppColors.danger.withOpacity(0.45)
                    : AppColors.border),
          width: 1.4,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q$index',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.successSoft
                      : (isAnswered
                            ? AppColors.dangerSoft
                            : AppColors.surfaceAlt),
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
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.q,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.4,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),

          _buildOptionReviewRow('A', question.a, selected, correct),
          const SizedBox(height: 7),
          _buildOptionReviewRow('B', question.b, selected, correct),
          const SizedBox(height: 7),
          _buildOptionReviewRow('C', question.c, selected, correct),
          const SizedBox(height: 7),
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
      textColor = const Color(0xFF065F46);
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isUserChoice ? 'Your Choice ✓' : 'Correct Key',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    } else if (isUserChoice) {
      bg = AppColors.dangerSoft;
      border = AppColors.danger;
      textColor = const Color(0xFF991B1B);
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Your Choice ✗',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    } else {
      bg = AppColors.background;
      border = AppColors.border;
      textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: border,
          width: (isUserChoice || isCorrectAnswer) ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isUserChoice || isCorrectAnswer)
                  ? border
                  : AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: (isUserChoice || isCorrectAnswer)
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                color: textColor,
                fontWeight: (isUserChoice || isCorrectAnswer)
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
          if (badge != null) badge,
        ],
      ),
    );
  }
}
