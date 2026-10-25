import 'package:flutter/material.dart';
import 'package:test_nest/core/utils/theme/theme.dart';

class ExamStepIndicator extends StatelessWidget {
  final int currentStep; // 1, 2, or 3

  const ExamStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          _buildStep(
            stepNumber: 1,
            title: 'Setup',
            isCompleted: currentStep > 1,
            isActive: currentStep == 1,
          ),
          _buildLine(isPassed: currentStep > 1),
          _buildStep(
            stepNumber: 2,
            title: 'Questions',
            isCompleted: currentStep > 2,
            isActive: currentStep == 2,
          ),
          _buildLine(isPassed: currentStep > 2),
          _buildStep(
            stepNumber: 3,
            title: 'Publish',
            isCompleted: false,
            isActive: currentStep == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required bool isCompleted,
    required bool isActive,
  }) {
    Color circleBg;
    Color textColor;
    Widget content;

    if (isCompleted) {
      circleBg = AppColors.success;
      textColor = AppColors.text;
      content = const Icon(Icons.check_rounded, color: Colors.white, size: 15);
    } else if (isActive) {
      circleBg = AppColors.primary;
      textColor = AppColors.primary;
      content = Text(
        '$stepNumber',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      );
    } else {
      circleBg = AppColors.surfaceAlt;
      textColor = AppColors.textSecondary;
      content = Text(
        '$stepNumber',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: content,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLine({required bool isPassed}) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isPassed ? AppColors.success : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
