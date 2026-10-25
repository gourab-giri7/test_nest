import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/manualQuestions/controller/question_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/widgets/exam_step_indicator.dart';
import 'package:test_nest/model/exam_details_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class QuestionMethodChoiceScreen extends StatelessWidget {
  final QuestionController qc;

  const QuestionMethodChoiceScreen({super.key, required this.qc});

  @override
  Widget build(BuildContext context) {
    final details = examDetails;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Create Exam',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExamStepIndicator(currentStep: 2),
                const SizedBox(height: 12),

                // Title & Subtitle
                const Text(
                  'How would you like to add questions?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose manual entry for custom control or upload an Excel file to add questions in bulk.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Method 1: Manual Questions
                _buildMethodCard(
                  context: context,
                  title: 'Add Questions Manually',
                  subtitle:
                      'Type questions one by one with 4 options, mark the correct answer, and reorder effortlessly.',
                  badge: 'Interactive & Flexible',
                  badgeColor: const Color(0xFFEEF2FF),
                  badgeTextColor: const Color(0xFF4F46E5),
                  icon: Icons.edit_note_rounded,
                  iconGradient: const [Color(0xFF6366F1), Color(0xFF4338CA)],
                  buttonText: 'Add Questions Manually',
                  buttonColor: const Color(0xFF4F46E5),
                  onTap: () {
                    qc.setSource(QuestionSource.manual);
                    Get.toNamed(
                      AppRoutes.teacherManualQuestions,
                      arguments: qc,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Method 2: Excel Upload
                _buildMethodCard(
                  context: context,
                  title: 'Import from Excel',
                  subtitle:
                      'Upload a spreadsheet (.xlsx) with pre-formatted questions, choices A-D, and correct answers in bulk.',
                  badge: 'Fast & Bulk Import',
                  badgeColor: const Color(0xFFECFDF5),
                  badgeTextColor: const Color(0xFF059669),
                  icon: Icons.table_chart_rounded,
                  iconGradient: const [Color(0xFF10B981), Color(0xFF047857)],
                  buttonText: 'Upload Excel Sheet',
                  buttonColor: const Color(0xFF059669),
                  onTap: () {
                    qc.setSource(QuestionSource.excel);
                    Get.toNamed(AppRoutes.teacherFileUpload, arguments: qc);
                  },
                ),
                const SizedBox(height: 24),

                // Summary Pill / Card
                if (details != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                details.examName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Batch: ${details.batch} • ${details.assignedStudentIds.length} Students • ${details.fullMarks} Marks',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
    required List<Color> iconGradient,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: iconGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconGradient.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeTextColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
