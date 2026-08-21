import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/addStudents/controller/add_student_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/widgets/batch_dialog.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AddStudentController>().getNewId();
      context.read<AddStudentController>().allClear();
    });
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.blueGrey[50],
        centerTitle: true,
        title: const Text(
          'Add Student',
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
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Consumer<AddStudentController>(
              builder: (context, controller, child) => Form(
                key: controller.studentkey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Profile Avatar Badge Placeholder
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 177, 211, 255),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Field 1: Full Name
                    _buildLabel('Full Name'),
                    _buildTextField(
                      controller: controller.fullNameController,
                      hint: "Enter student name",
                      validator: controller.validator,
                    ),
                    const SizedBox(height: 16),

                    // Field 2: Student ID
                    _buildLabel('Student ID'),
                    _buildTextField(
                      controller: controller.studentIdController,
                      hint: "Create ID for student",
                      enabled: false,
                      validator: controller.validator,
                    ),
                    const SizedBox(height: 16),

                    // Field 3: Password
                    _buildLabel('Password'),
                    _buildTextField(
                      controller: controller.passwordController,
                      obscureText: false,
                      hint: "Create password for student",
                      validator: controller.passwordValidator,
                    ),
                    const SizedBox(height: 16),

                    // Field 4: Class Dropdown
                    _buildLabel('Batch'),
                    GestureDetector(
                      onTap: () {
                        batchDialog(context);
                      },
                      child: _buildTextField(
                        controller: controller.batchController,
                        obscureText: false,
                        hint: "Select class",
                        enabled: false,
                        suffix: true,
                        validator: controller.validator,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Create Student Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          controller.addStudent(context);
                        },
                        child: const Text(
                          'Create Student',
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String hint = "",
    bool obscureText = false,
    bool enabled = true,
    bool suffix = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      validator: validator,
      enabled: enabled,
      onTapOutside: (event) => FocusManager.instance.primaryFocus!.unfocus(),
      controller: controller,
      obscureText: obscureText,

      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: !enabled ? Colors.blueGrey : Color(0xFF0F172A),
      ),
      decoration: _inputDecoration(hint, suffix),
    );
  }

  InputDecoration _inputDecoration(String hint, bool suffix) {
    return InputDecoration(
      hint: Text(hint, style: TextStyle(color: Colors.blueGrey)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      suffixIcon: suffix ? Icon(Icons.arrow_drop_down_circle_outlined) : null,
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
}
