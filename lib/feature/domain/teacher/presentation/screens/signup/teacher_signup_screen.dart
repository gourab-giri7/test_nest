import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/signup/controller/teacher_signup_controller.dart';

class TeacherSignupScreen extends StatelessWidget {
  const TeacherSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeacherSignupController(),
      child: Consumer<TeacherSignupController>(
        builder: (context, c, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Teacher Registration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: c.formKey,
                      child: Column(
                        children: [
                          // Header
                          const CircleAvatar(
                            radius: 34,
                            backgroundColor: AppColors.primarySoft,
                            child: Icon(
                              Icons.school_rounded,
                              size: 34,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Create Teacher Account',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fill in the details below to register',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Full Name
                          _field(
                            c.name,
                            'Full Name',
                            Icons.person_outline,
                            c.requiredField,
                          ),
                          const SizedBox(height: 14),

                          // Email
                          _field(
                            c.email,
                            'Email Address',
                            Icons.email_outlined,
                            c.emailValidator,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),

                          // Mobile
                          _field(
                            c.mobile,
                            'Mobile Number',
                            Icons.phone_outlined,
                            c.requiredField,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),

                          // Institute/Coaching Name
                          _field(
                            c.instituteName,
                            'Institute / Coaching Name',
                            Icons.business_outlined,
                            c.requiredField,
                          ),
                          const SizedBox(height: 14),

                          // Institute Address
                          _field(
                            c.instituteAddress,
                            'Institute Address',
                            Icons.location_on_outlined,
                            c.requiredField,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: c.password,
                            validator: c.passwordValidator,
                            obscureText: c.obscure,
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus!.unfocus(),
                            decoration: _dec(
                              'Password',
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: c.toggleObscure,
                                icon: Icon(
                                  c.obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Confirm Password
                          TextFormField(
                            controller: c.confirm,
                            validator: c.confirmPasswordValidator,
                            obscureText: c.obscureConfirm,
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus!.unfocus(),
                            decoration: _dec(
                              'Confirm Password',
                              Icons.lock_reset_outlined,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: c.toggleObscureConfirm,
                                icon: Icon(
                                  c.obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed:
                                  c.loading ? null : () => c.signup(context),
                              child: c.loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  final loginController =
                                      context.read<LoginController>();
                                  loginController.changeLoginToTeacher();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
    String? Function(String?) validator, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      onTapOutside: (_) => FocusManager.instance.primaryFocus!.unfocus(),
      decoration: _dec(label, icon),
    );
  }

  static InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
