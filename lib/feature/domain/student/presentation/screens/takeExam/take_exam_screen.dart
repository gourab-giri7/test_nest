import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
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
        final progress = controller.totalQuestions > 0
            ? (controller.currentIndex + 1) / controller.totalQuestions
            : 0.0;

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
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.text),
                tooltip: 'Finish Exam',
                onPressed: () => _showSubmitDialog(context, controller),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.exam.examName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    'Attempted ${controller.selectedAnswers.length} of ${controller.totalQuestions}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: const [_ExamTimer()],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: _QuestionContent(
                        controller: controller,
                        question: question,
                      ),
                    ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.task_alt_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Submit Assessment?',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
              ),
            ],
          ),
          content: Text(
            'You have answered ${controller.selectedAnswers.length} '
            'out of ${controller.totalQuestions} questions.'
            'Are you sure you want to finish and submit your exam now?',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Keep Reviewing'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 44),
              ),
              onPressed: () {
                Get.back();
                controller.submitExam(
                  context: context,
                  reason: SubmissionReason.manual,
                );
              },
              child: const Text('Submit Final'),
            ),
          ],
        );
      },
    );
  }
}

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
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLow ? AppColors.dangerSoft : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLow
                      ? AppColors.danger.withOpacity(0.4)
                      : AppColors.primary.withOpacity(0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isLow ? AppColors.danger : AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    time,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: isLow ? AppColors.danger : AppColors.primary,
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

class _QuestionContent extends StatelessWidget {
  final TakeExamController controller;
  final dynamic question;

  const _QuestionContent({required this.controller, required this.question});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'QUESTION ${controller.currentIndex + 1} OF ${controller.totalQuestions}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  fontSize: 11.5,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            if (controller.isCurrentMarked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Flagged for Review',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Text(
            question.q,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _OptionsList(controller: controller, question: question),
      ],
    );
  }
}

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
      mainAxisSize: MainAxisSize.min,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: (controller.isSubmitting || controller.isSubmitted)
            ? null
            : () {
                controller.selectAnswer(label);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.text,
                    height: 1.35,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSection extends StatelessWidget {
  final TakeExamController controller;

  const _BottomSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed:
                          (controller.currentIndex > 0 &&
                              !controller.isSubmitting &&
                              !controller.isSubmitted)
                          ? controller.previous
                          : null,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                      ),
                      label: const Text(
                        'Previous',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        backgroundColor: controller.isCurrentMarked
                            ? AppColors.warningSoft
                            : Colors.transparent,
                        side: BorderSide(
                          color: controller.isCurrentMarked
                              ? AppColors.warning
                              : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed:
                          (controller.isSubmitting || controller.isSubmitted)
                          ? null
                          : controller.toggleMarkForReview,
                      icon: Icon(
                        controller.isCurrentMarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 17,
                        color: controller.isCurrentMarked
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                      label: Text(
                        controller.isCurrentMarked ? 'Flagged' : 'Flag',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: controller.isCurrentMarked
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        backgroundColor: controller.isLastQuestion
                            ? AppColors.success
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                      icon: controller.isSubmitting
                          ? const SizedBox.shrink()
                          : Icon(
                              controller.isLastQuestion
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 17,
                            ),
                      label: controller.isSubmitting
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
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _QuestionNavigator(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _QuestionNavigator extends StatelessWidget {
  final TakeExamController controller;

  const _QuestionNavigator({required this.controller});

  @override
  Widget build(BuildContext context) {
    final total = controller.totalQuestions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 4,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _legendItem(AppColors.success, 'Answered'),
              _legendItem(AppColors.warning, 'Flagged'),
              _legendItem(const Color(0xFFCBD5E1), 'Unvisited'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: total,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final isCurrent = controller.currentIndex == index;
                final isAns = controller.isAnswered(index);
                final isMark = controller.isMarked(index);

                Color bgColor;
                Color textColor;
                Widget? indicator;

                if (isMark && isAns) {
                  bgColor = AppColors.warning;
                  textColor = Colors.white;
                  indicator = const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  );
                } else if (isMark) {
                  bgColor = AppColors.warning;
                  textColor = Colors.white;
                } else if (isAns) {
                  bgColor = AppColors.success;
                  textColor = Colors.white;
                } else {
                  bgColor = AppColors.surfaceAlt;
                  textColor = AppColors.textSecondary;
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: (controller.isSubmitting || controller.isSubmitted)
                      ? null
                      : () => controller.goToQuestion(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : (isAns || isMark
                                  ? Colors.transparent
                                  : AppColors.border),
                        width: isCurrent ? 2.5 : 1,
                      ),
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
                              fontWeight: FontWeight.w800,
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
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
