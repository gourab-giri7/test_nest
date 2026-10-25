import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/routes/app_routes.dart';

class SubmissionScreen extends StatelessWidget {
  final String examTitle;
  final int totalQuestions;
  final int attemptedQuestions;
  final String fullMarks;

  const SubmissionScreen({
    super.key,
    this.examTitle = 'Exam',
    this.totalQuestions = 0,
    this.attemptedQuestions = 0,
    this.fullMarks = '0',
  });

  @override
  Widget build(BuildContext context) {
    final unattempted = (totalQuestions - attemptedQuestions).clamp(
      0,
      totalQuestions,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.offAllNamed(AppRoutes.studentDashboard);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Container(
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Celebration Badge
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Assessment Submitted!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your answers for "$examTitle" have been securely recorded.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Metrics Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              'Total Questions',
                              '$totalQuestions',
                              AppColors.text,
                            ),
                            const Divider(height: 22),
                            _buildSummaryRow(
                              'Attempted',
                              '$attemptedQuestions',
                              AppColors.success,
                            ),
                            const Divider(height: 22),
                            _buildSummaryRow(
                              'Skipped',
                              '$unattempted',
                              AppColors.warning,
                            ),
                            const Divider(height: 22),
                            _buildSummaryRow(
                              'Maximum Marks',
                              fullMarks,
                              AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Return Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Get.offAllNamed(AppRoutes.studentDashboard);
                          },
                          icon: const Icon(Icons.dashboard_rounded, size: 18),
                          label: const Text(
                            'Back to Student Dashboard',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
