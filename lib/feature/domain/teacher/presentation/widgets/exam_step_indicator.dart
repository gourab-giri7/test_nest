import 'package:flutter/material.dart';
import 'package:test_nest/core/utils/theme/theme.dart';

class ExamStepIndicator extends StatelessWidget {
  final int currentStep; // 1, 2, or 3

  const ExamStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStep(
            stepNumber: 1,
            title: 'Basic Info',
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
            title: 'Review',
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
      circleBg = const Color(0xFF10B981);
      textColor = AppColors.text;
      content = const Icon(Icons.check_rounded, color: Colors.white, size: 16);
    } else if (isActive) {
      circleBg = AppColors.primary;
      textColor = AppColors.primary;
      content = Text(
        '$stepNumber',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    } else {
      circleBg = const Color(0xFFF1F5F9);
      textColor = AppColors.textSecondary;
      content = Text(
        '$stepNumber',
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
            border: (!isCompleted && !isActive)
                ? Border.all(color: const Color(0xFFCBD5E1), width: 1.5)
                : null,
          ),
          child: content,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLine({required bool isPassed}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isPassed ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
