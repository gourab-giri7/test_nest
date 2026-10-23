import 'package:flutter/material.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/takeExam/controller/take_exam_controller.dart';
import 'package:test_nest/model/exam_model.dart';

class TakeExamScreen extends StatefulWidget {
  final ExamModel exam;

  const TakeExamScreen({super.key, required this.exam});

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen>
    with WidgetsBindingObserver {
  late final TakeExamController controller;

  @override
  void initState() {
    super.initState();
    controller = TakeExamController(widget.exam);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    controller.onLifecycle(state, context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TakeExamController>.value(
      value: controller,
      child: const _TakeExamContent(),
    );
  }
}

class _TakeExamContent extends StatelessWidget {
  const _TakeExamContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<TakeExamController>(
      builder: (context, controller, child) {
        if (controller.shuffledQuestions.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No questions available.')),
          );
        }

        final question = controller.currentQuestion;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _showSubmitDialog(context, controller);
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text(
                controller.exam.examName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: const [_ExamTimer()],
            ),
            body: Column(
              children: [
                Expanded(
                  child: _QuestionContent(
                    controller: controller,
                    question: question,
                  ),
                ),
                _BottomSection(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showSubmitDialog(
    BuildContext context,
    TakeExamController controller,
  ) {
    if (controller.isSubmitting || controller.isSubmitted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Submit Exam?'),
          content: Text(
            'Answered ${controller.selectedAnswers.length} '
            'of ${controller.totalQuestions} questions.\n\n'
            'Are you sure you want to finish and submit your exam?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Review Questions'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                controller.submitExam(
                  context: context,
                  reason: SubmissionReason.manual,
                );
              },
              child: const Text('Submit Now'),
            ),
          ],
        );
      },
    );
  }
}

///
/// ISOLATED TIMER
///
class _ExamTimer extends StatelessWidget {
  const _ExamTimer();

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TakeExamController>();
    return ValueListenableBuilder<Duration>(
      valueListenable: controller.remainingNotifier,
      builder: (context, remaining, _) {
        final time = TakeExamController.formatDuration(remaining);
        final isLow = remaining.inMinutes < 5;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isLow ? const Color(0xFFFEE2E2) : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLow
                      ? const Color(0xFFF87171)
                      : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isLow ? const Color(0xFFDC2626) : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isLow
                          ? const Color(0xFFDC2626)
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

///
/// QUESTION CONTENT
///
class _QuestionContent extends StatelessWidget {
  final TakeExamController controller;
  final dynamic question;

  const _QuestionContent({required this.controller, required this.question});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${controller.currentIndex + 1} of ${controller.totalQuestions}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 15,
              ),
            ),
            if (controller.isCurrentMarked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark, size: 14, color: Color(0xFFD97706)),
                    SizedBox(width: 4),
                    Text(
                      'Marked for Review',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              question.q,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _OptionsList(controller: controller, question: question),
      ],
    );
  }
}

///
/// OPTIONS
///
class _OptionsList extends StatelessWidget {
  final TakeExamController controller;
  final dynamic question;

  const _OptionsList({required this.controller, required this.question});

  @override
  Widget build(BuildContext context) {
    final options = <({String label, String text})>[
      (label: 'A', text: question.a as String),
      (label: 'B', text: question.b as String),
      (label: 'C', text: question.c as String),
      (label: 'D', text: question.d as String),
    ];

    return Column(
      children: [
        for (final option in options)
          _AnswerOption(
            controller: controller,
            label: option.label,
            text: option.text,
          ),
      ],
    );
  }
}

///
/// SINGLE OPTION
///
class _AnswerOption extends StatelessWidget {
  final TakeExamController controller;
  final String label;
  final String text;

  const _AnswerOption({
    required this.controller,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.selectedChoice == label;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: (controller.isSubmitting || controller.isSubmitted)
            ? null
            : () {
                controller.selectAnswer(label);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isSelected
                    ? AppColors.primary
                    : const Color(0xFFF1F5F9),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

///
/// BOTTOM SECTION (Action Buttons + Question Navigator Palette)
///
class _BottomSection extends StatelessWidget {
  final TakeExamController controller;

  const _BottomSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Actions [Previous] [Mark for Review] [Next / Submit]
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // Previous Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                        (controller.currentIndex > 0 &&
                            !controller.isSubmitting &&
                            !controller.isSubmitted)
                        ? controller.previous
                        : null,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Previous'),
                  ),
                  const SizedBox(width: 8),

                  // Mark for Review Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: controller.isCurrentMarked
                            ? const Color(0xFFFEF3C7)
                            : Colors.transparent,
                        side: BorderSide(
                          color: controller.isCurrentMarked
                              ? AppColors.warning
                              : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed:
                          (controller.isSubmitting || controller.isSubmitted)
                          ? null
                          : controller.toggleMarkForReview,
                      icon: Icon(
                        controller.isCurrentMarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        size: 16,
                        color: controller.isCurrentMarked
                            ? const Color(0xFFB45309)
                            : const Color(0xFF475569),
                      ),
                      label: Text(
                        controller.isCurrentMarked ? 'Marked' : 'Mark Review',
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.isCurrentMarked
                              ? const Color(0xFFB45309)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Next / Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.isLastQuestion
                          ? AppColors.success
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                        (controller.isSubmitting || controller.isSubmitted)
                        ? null
                        : () {
                            if (controller.isLastQuestion) {
                              _TakeExamContent._showSubmitDialog(
                                context,
                                controller,
                              );
                            } else {
                              controller.next();
                            }
                          },
                    child: controller.isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            controller.isLastQuestion ? 'Submit' : 'Next',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Row 2: Question Navigator & Palette Legend
            _QuestionNavigator(controller: controller),
          ],
        ),
      ),
    );
  }
}

///
/// QUESTION NAVIGATOR PALETTE
///
class _QuestionNavigator extends StatelessWidget {
  final TakeExamController controller;

  const _QuestionNavigator({required this.controller});

  @override
  Widget build(BuildContext context) {
    final total = controller.totalQuestions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(AppColors.warning, 'Marked (🟨)'),
              _legendItem(AppColors.success, 'Answered (🟩)'),
              _legendItem(const Color(0xFFCBD5E1), 'Not Answered (⬜)'),
            ],
          ),
          const SizedBox(height: 8),

          // Scrollable numbers palette
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: total,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final isCurrent = controller.currentIndex == index;
                final isAns = controller.isAnswered(index);
                final isMark = controller.isMarked(index);

                Color bgColor;
                Color textColor;
                Widget? indicator;

                if (isMark && isAns) {
                  // Marked + Answered: Yellow with checkmark
                  bgColor = AppColors.warning;
                  textColor = Colors.white;
                  indicator = const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  );
                } else if (isMark) {
                  // Marked only: Yellow
                  bgColor = AppColors.warning;
                  textColor = Colors.white;
                } else if (isAns) {
                  // Answered: Green
                  bgColor = AppColors.success;
                  textColor = Colors.white;
                } else {
                  // Not answered: Grey
                  bgColor = const Color(0xFFF1F5F9);
                  textColor = const Color(0xFF475569);
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: (controller.isSubmitting || controller.isSubmitted)
                      ? null
                      : () => controller.goToQuestion(index),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : (isAns || isMark
                                  ? Colors.transparent
                                  : const Color(0xFFCBD5E1)),
                        width: isCurrent ? 2.5 : 1,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (indicator != null) ...[
                            indicator,
                            const SizedBox(width: 1),
                          ],
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
