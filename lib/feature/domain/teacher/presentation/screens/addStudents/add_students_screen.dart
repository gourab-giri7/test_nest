import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/addStudents/controller/add_student_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/widgets/batch_dialog.dart';
import 'package:test_nest/routes/app_routes.dart';

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
          'Student Enrollment',
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
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Icon(
                      Icons.how_to_reg_rounded,
                      size: 38,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Direct Creation Disabled',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Teachers cannot manually create student accounts. Students must register their own accounts and join using your batch joining codes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'How Enrollment Works:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '1. Share your reusable Batch Code with students.\n'
                          '2. Students create an account and enter the code.\n'
                          '3. You review and approve their request in Join Requests.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Get.offNamed(AppRoutes.teacherBatches),
                      icon: const Icon(Icons.qr_code_rounded, size: 20),
                      label: const Text(
                        'View & Share Batch Codes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFC7D2FE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          Get.offNamed(AppRoutes.teacherJoinRequests),
                      icon: const Icon(Icons.group_add_rounded, size: 20),
                      label: const Text(
                        'View Pending Join Requests',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
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
