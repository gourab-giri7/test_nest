import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
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
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AddStudentController>().init();
    });
  }

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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.text,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Enroll New Student',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Consumer<AddStudentController>(
              builder: (context, controller, child) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Form(
                  key: controller.studentkey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Modern Avatar Header
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Student Enrollment Form',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Assign a student ID, batch, and optional monthly fee',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Student Name
                      _buildLabel('Student Full Name *'),
                      _buildTextField(
                        controller: controller.fullNameController,
                        hint: 'Enter student full name',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: controller.validator,
                      ),
                      const SizedBox(height: 16),

                      // Student ID (Read-only generated ID)
                      _buildLabel('Auto-Generated Student ID'),
                      _buildTextField(
                        controller: controller.studentIdController,
                        hint: 'Student ID',
                        prefixIcon: Icons.badge_outlined,
                        enabled: false,
                        validator: controller.validator,
                      ),
                      const SizedBox(height: 16),

                      // Batch Dropdown
                      _buildLabel('Assign Batch *'),
                      GestureDetector(
                        onTap: () {
                          batchDialog(context);
                        },
                        child: _buildTextField(
                          controller: controller.batchController,
                          hint: 'Tap to choose or add a batch',
                          prefixIcon: Icons.groups_outlined,
                          enabled: false,
                          suffix: true,
                          validator: controller.validator,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Monthly Tuition Fee
                      _buildLabel('Monthly Tuition Fee (₹)'),
                      TextFormField(
                        controller: controller.monthlyFeeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: controller.feeValidator,
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 1500 (optional, default 0)',
                          prefixIcon: Icon(
                            Icons.currency_rupee_rounded,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Add Student Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: controller.isLoading
                              ? null
                              : () {
                                  controller.addStudent(context);
                                },
                          icon: controller.isLoading
                              ? const SizedBox.shrink()
                              : const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          label: controller.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Complete Enrollment',
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

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String hint = "",
    IconData? prefixIcon,
    bool enabled = true,
    bool suffix = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      validator: validator,
      enabled: enabled,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      controller: controller,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: !enabled ? AppColors.textSecondary : AppColors.text,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        filled: true,
        fillColor: enabled ? const Color(0xFFF8FAFC) : AppColors.surfaceAlt,
        suffixIcon: suffix
            ? const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              )
            : null,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
