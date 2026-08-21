import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/controller/create_exam_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/fileUpload/file_upload_screen.dart';

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
      if (!mounted) return;

      context.read<CreateExamController>().clearAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CreateExamController>();
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.blueGrey[50],
        centerTitle: true,
        title: const Text(
          'Create Exam',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: controller.examKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Field 1: Exam Name
                  _buildLabel(text: 'Exam Name'),
                  _buildTextField(
                    validator: controller.nameValidator,
                    controller: controller.examNameController,
                    hint: "e.g: Computer harware",
                  ),
                  const SizedBox(height: 16),

                  // Field 2: Full Marks
                  _buildLabel(text: 'Full Marks'),
                  _buildTextField(
                    validator: controller.marksValidator,
                    hint: "e.g: 100",
                    controller: controller.fullMarksController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Field 3: Exam Date
                  _buildLabel(text: 'Exam Date'),
                  _buildTextField(
                    validator: controller.nameValidator,
                    hint: "Select Exam date",
                    controller: controller.examDateController,
                    readOnly: true,
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onTap: () async {
                      controller.pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2200),
                      );
                      if (controller.pickedDate != null) {
                        controller.selectExamDate();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field 4 & 5: Start Time & End Time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(text: 'Start Time'),
                            _buildTextField(
                              validator: controller.nameValidator,
                              controller: controller.startTimeController,
                              readOnly: true,
                              onTap: () =>
                                  _selectTime(controller.startTimeController),
                              hint: "Select Time",
                              suffixIcon: Icon(
                                Icons.access_time,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(text: 'End Time'),
                            _buildTextField(
                              validator: controller.nameValidator,
                              controller: controller.endTimeController,
                              readOnly: true,
                              onTap: () =>
                                  _selectTime(controller.endTimeController),
                              hint: "Select Time",
                              suffixIcon: Icon(
                                Icons.access_time,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Field 6: Exam Key
                  _buildLabel(text: 'Exam Key'),
                  _buildTextField(
                    validator: controller.nameValidator,
                    controller: controller.examKeyController,
                    hint: "e.g: CH@123",
                  ),
                  const SizedBox(height: 16),

                  // Field 7: Instructions (Optional)
                  _buildLabel(text: 'Instructions (Optional)'),
                  _buildTextField(
                    hint: "e.g: 1st unit only",
                    controller: controller.instructionsController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // Section: Assign Students
                  const Text(
                    'Assign Students',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Field 8: Select Students Dropdown
                  _buildLabel(
                    text: teacherData.batch.isEmpty
                        ? "Please Add student before publishig exam"
                        : 'Select Batch',
                    col: teacherData.batch.isEmpty
                        ? Colors.red
                        : Colors.blueGrey,
                  ),
                  teacherData.batch.isEmpty
                      ? SizedBox.shrink()
                      : Consumer<CreateExamController>(
                          builder: (context, controller, child) =>
                              DropdownButtonFormField<String>(
                                value: controller.selectedbatch,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF64748B),
                                ),
                                decoration: _inputDecoration(),
                                items: controller.classList.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  // setState(() {
                                  //   contro = newValue;
                                  // });
                                },
                              ),
                        ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teacherData.batch.isEmpty
                            ? Colors.grey
                            : const Color(0xFF2563EB),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (teacherData.batch.isNotEmpty) {
                          controller.next(context);
                        }
                      },
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildLabel({required String text, Color col = Colors.blueGrey}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: col),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String hint = "",
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      validator: validator,
      onTapOutside: (event) => FocusManager.instance.primaryFocus!.unfocus(),
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      decoration: _inputDecoration(suffixIcon: suffixIcon, hint: hint),
    );
  }

  InputDecoration _inputDecoration({Widget? suffixIcon, String hint = ""}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB)),
      ),
    );
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text = picked.format(context);
    }
  }
}
