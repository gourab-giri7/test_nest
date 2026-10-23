import 'package:flutter/material.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/manualQuestions/controller/question_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/reviewPublishExam/review_publish_screen.dart';

import 'package:test_nest/feature/domain/teacher/presentation/widgets/exam_step_indicator.dart';

class ManualQuestionsScreen extends StatelessWidget {
  const ManualQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Consumer<QuestionController>(
            builder: (context, qc, _) {
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                children: [
                  const ExamStepIndicator(currentStep: 2),
                  const SizedBox(height: 8),
                  // Form Card to Add/Edit Question
                  _buildQuestionFormCard(context, qc),
                  const SizedBox(height: 24),

                  // Questions List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions Added (${qc.questionCount})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      if (qc.questionCount > 1)
                        Text(
                          'Hold & drag to reorder',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (qc.questionCount == 0)
                    _buildEmptyQuestionsState()
                  else
                    _buildReorderableQuestionsList(qc),

                  const SizedBox(height: 32),

                  // Bottom Action Button: Save & Preview
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (qc.questionCount == 0) {
                          customSnackbar(
                            context: context,
                            message:
                                'Please add at least one question before proceeding.',
                            color: Colors.red,
                            ico: Icons.error_outline,
                          );
                          return;
                        }
                        // Navigate to ReviewPublishScreen sharing the same QuestionController
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChangeNotifierProvider<
                                  QuestionController
                                >.value(
                                  value: qc,
                                  child: const ReviewPublishScreen(),
                                ),
                          ),
                        );
                      },
                      child: Text(
                        qc.questionCount == 0
                            ? 'Add Questions to Proceed'
                            : 'Save & Preview (${qc.questionCount} Questions)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionFormCard(BuildContext context, QuestionController qc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: qc.isEditing
                      ? const Color(0xFFFEF3C7)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  qc.isEditing ? Icons.edit_note : Icons.add_circle_outline,
                  color: qc.isEditing
                      ? const Color(0xFFD97706)
                      : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  qc.isEditing
                      ? 'Edit Question #${(qc.editingIndex! + 1)}'
                      : 'New Question #${qc.questionCount + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
              if (qc.isEditing)
                TextButton(
                  onPressed: qc.cancelEdit,
                  child: const Text('Cancel'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Input
          _buildFieldLabel('Question Text'),
          TextFormField(
            controller: qc.questionInputController,
            maxLines: 2,
            decoration: _inputDecoration(
              hint: 'e.g. What is the primary function of RAM?',
            ),
          ),
          const SizedBox(height: 16),

          // Option A
          _buildFieldLabel('Option A'),
          TextFormField(
            controller: qc.optionAController,
            decoration: _inputDecoration(
              hint: 'Enter option A',
              prefix: const Text(
                'A.  ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Option B
          _buildFieldLabel('Option B'),
          TextFormField(
            controller: qc.optionBController,
            decoration: _inputDecoration(
              hint: 'Enter option B',
              prefix: const Text(
                'B.  ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Option C
          _buildFieldLabel('Option C'),
          TextFormField(
            controller: qc.optionCController,
            decoration: _inputDecoration(
              hint: 'Enter option C',
              prefix: const Text(
                'C.  ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Option D
          _buildFieldLabel('Option D'),
          TextFormField(
            controller: qc.optionDController,
            decoration: _inputDecoration(
              hint: 'Enter option D',
              prefix: const Text(
                'D.  ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Correct Answer Selection
          _buildFieldLabel('Correct Answer'),
          Row(
            children: ['A', 'B', 'C', 'D'].map((opt) {
              final isSelected = qc.selectedAnswer == opt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => qc.setSelectedAnswer(opt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.success
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF059669)
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Option $opt',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Add / Update Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: qc.isEditing
                    ? const Color(0xFFD97706)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                final error = qc.validateDraft();
                if (error != null) {
                  customSnackbar(
                    context: context,
                    message: error,
                    color: Colors.red,
                    ico: Icons.error,
                  );
                  return;
                }
                qc.addOrUpdateQuestion();
                customSnackbar(
                  context: context,
                  message: qc.isEditing
                      ? 'Question updated successfully.'
                      : 'Question added successfully.',
                  color: Colors.green,
                  ico: Icons.check_circle_outline,
                );
              },
              icon: Icon(qc.isEditing ? Icons.check : Icons.add),
              label: Text(
                qc.isEditing ? 'Update Question' : 'Add Question',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefix: prefix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildEmptyQuestionsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 48, color: Colors.blueGrey[300]),
          const SizedBox(height: 12),
          const Text(
            'No Questions Added Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Fill out the form above to add your first question.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.blueGrey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableQuestionsList(QuestionController qc) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: qc.questionCount,
      onReorder: qc.reorderQuestions,
      itemBuilder: (context, index) {
        final q = qc.questions[index];
        final isBeingEdited = qc.editingIndex == index;

        return Container(
          key: ValueKey('question_$index'),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBeingEdited ? AppColors.primary : AppColors.border,
              width: isBeingEdited ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with number, drag handle, and actions
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Correct: Option ${q.ans}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Edit Question',
                      onPressed: () => qc.startEdit(index),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.danger,
                      ),
                      tooltip: 'Delete Question',
                      onPressed: () => qc.deleteQuestion(index),
                    ),
                    const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                  ],
                ),
                const SizedBox(height: 10),

                // Question Text
                Text(
                  q.q,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Options Grid/List
                _buildOptionPreviewRow('A', q.a, isCorrect: q.ans == 'A'),
                const SizedBox(height: 6),
                _buildOptionPreviewRow('B', q.b, isCorrect: q.ans == 'B'),
                const SizedBox(height: 6),
                _buildOptionPreviewRow('C', q.c, isCorrect: q.ans == 'C'),
                const SizedBox(height: 6),
                _buildOptionPreviewRow('D', q.d, isCorrect: q.ans == 'D'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionPreviewRow(
    String letter,
    String text, {
    required bool isCorrect,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.successSoft : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect ? AppColors.success : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Text(
            '$letter. ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isCorrect
                  ? const Color(0xFF047857)
                  : AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isCorrect
                    ? const Color(0xFF047857)
                    : const Color(0xFF1E293B),
                fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isCorrect)
            const Icon(Icons.check_circle, size: 16, color: AppColors.success),
        ],
      ),
    );
  }
}
