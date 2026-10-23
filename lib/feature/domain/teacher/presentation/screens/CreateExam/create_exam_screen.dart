import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/teacher/data/datasources/get_student_data.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/controller/create_exam_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/manualQuestions/controller/question_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/widgets/exam_step_indicator.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});
  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CreateExamController>().clearAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QuestionController>(
      create: (_) => QuestionController(),
      child: Builder(
        builder: (context) {
          final qc = context.watch<QuestionController>();
          return Consumer<CreateExamController>(
            builder: (context, c, _) {
              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  surfaceTintColor: Colors.transparent,
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Form(
                        key: c.examKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ExamStepIndicator(currentStep: 1),
                            const SizedBox(height: 8),

                            // Exam Information Section
                            _buildSectionCard(
                              title: 'Exam Information',
                              icon: Icons.assignment_outlined,
                              children: [
                                _label('Exam Title / Name'),
                                _field(
                                  controller: c.examNameController,
                                  validator: c.nameValidator,
                                  hint: 'e.g. Computer Architecture Quiz',
                                  prefixIcon: Icons.title_rounded,
                                ),
                                const SizedBox(height: 16),
                                _label('Total Marks'),
                                _field(
                                  controller: c.fullMarksController,
                                  validator: c.marksValidator,
                                  hint: 'e.g. 100',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.grade_outlined,
                                ),
                                const SizedBox(height: 16),
                                _label('Exam Date'),
                                _field(
                                  controller: c.examDateController,
                                  validator: c.nameValidator,
                                  hint: 'Select exam date',
                                  readOnly: true,
                                  prefixIcon: Icons.calendar_today_rounded,
                                  suffix: const Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.textSecondary,
                                  ),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2200),
                                    );
                                    if (d != null) {
                                      c.pickedDate = d;
                                      c.selectExamDate();
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('Start Time'),
                                          _field(
                                            controller: c.startTimeController,
                                            validator: c.nameValidator,
                                            hint: '09:00 AM',
                                            readOnly: true,
                                            prefixIcon: Icons.schedule_rounded,
                                            onTap: () => _selectTime(
                                              c.startTimeController,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _label('End Time'),
                                          _field(
                                            controller: c.endTimeController,
                                            validator: c.nameValidator,
                                            hint: '10:00 AM',
                                            readOnly: true,
                                            prefixIcon: Icons.timer_outlined,
                                            onTap: () => _selectTime(
                                              c.endTimeController,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _label('Exam Security Key'),
                                _field(
                                  controller: c.examKeyController,
                                  validator: c.nameValidator,
                                  hint: 'e.g. EXAM@2026',
                                  prefixIcon: Icons.vpn_key_outlined,
                                ),
                                const SizedBox(height: 16),
                                _label('Instructions (Optional)'),
                                _field(
                                  controller: c.instructionsController,
                                  hint:
                                      'e.g. Answer all questions within 60 mins',
                                  maxLines: 2,
                                  prefixIcon: Icons.info_outline_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Assign Students Section
                            _buildSectionCard(
                              title: 'Assign Students',
                              icon: Icons.group_outlined,
                              children: [_studentAssignment(c)],
                            ),
                            const SizedBox(height: 24),

                            // Next Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: c.selectedCount > 0
                                    ? () => c.next(context, qc)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor: AppColors.primary
                                      .withOpacity(0.4),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      c.selectedCount == 0
                                          ? 'Select Students to Continue'
                                          : 'Continue to Questions (${c.selectedCount} Students)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _studentAssignment(CreateExamController c) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: GetStudentData.getAllStudent(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snap.hasError) {
          return const Text(
            'Unable to load students.',
            style: TextStyle(color: Colors.red),
          );
        }

        final docs = snap.data?.docs ?? [];
        c.setStudentsFromSnapshot(docs);

        final batches = c.classList;
        final hasBatches =
            batches.isNotEmpty && batches.first != 'select batch';

        if (!hasBatches) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Please add batches/students before creating an exam',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          );
        }

        final students = c.studentsForSelectedBatch;
        final dropdownValue = batches.contains(c.selectedbatch)
            ? c.selectedbatch
            : batches.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Target Batch'),
            DropdownButtonFormField<String>(
              value: dropdownValue,
              isExpanded: true,
              decoration: _dec(
                hint: 'Select batch',
                prefixIcon: Icons.class_outlined,
              ),
              items: batches
                  .map(
                    (b) => DropdownMenuItem(
                      value: b,
                      child: Text(
                        b,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) c.setBatch(v);
              },
            ),
            const SizedBox(height: 16),
            if (students.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'No students found in this batch.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: c.allStudentsSelected,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (v) => c.toggleAllStudents(v ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'Select All Students',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.text,
                              ),
                            ),
                          ),
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
                              '${c.selectedCount}/${students.length}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: students.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: Color(0xFFEDF2F7),
                        ),
                        itemBuilder: (context, index) {
                          final s = students[index];
                          final isSelected = c.selectedStudentIds.contains(
                            s.id.trim(),
                          );
                          return InkWell(
                            onTap: () => c.toggleStudent(s.id, !isSelected),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (v) =>
                                        c.toggleStudent(s.id, v ?? false),
                                  ),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.1),
                                    child: Text(
                                      s.name.isNotEmpty
                                          ? s.name[0].toUpperCase()
                                          : 'S',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        Text(
                                          'ID: ${s.id}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    String? Function(String?)? validator,
    String hint = '',
    bool readOnly = false,
    Widget? suffix,
    IconData? prefixIcon,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    validator: validator,
    readOnly: readOnly,
    onTap: onTap,
    keyboardType: keyboardType,
    maxLines: maxLines,
    style: const TextStyle(fontSize: 14, color: AppColors.text),
    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    decoration: _dec(hint: hint, suffix: suffix, prefixIcon: prefixIcon),
  );

  InputDecoration _dec({
    String? label,
    String hint = '',
    Widget? suffix,
    IconData? prefixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, size: 20, color: const Color(0xFF64748B))
        : null,
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );

  Future<void> _selectTime(TextEditingController controller) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) controller.text = t.format(context);
  }
}
