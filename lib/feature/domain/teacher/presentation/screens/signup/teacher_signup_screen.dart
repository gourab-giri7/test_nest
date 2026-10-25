import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/signup/controller/teacher_signup_controller.dart';
import 'package:test_nest/routes/app_routes.dart';

class TeacherSignupScreen extends StatelessWidget {
  const TeacherSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeacherSignupController(),
      child: Consumer<TeacherSignupController>(
        builder: (context, c, _) => Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Top Gradient Header Backdrop
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 245,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.teacherHero,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(38),
                      bottomRight: Radius.circular(38),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Custom App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Get.back(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.16),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Educator Registration',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.10),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(26),
                              child: Form(
                                key: c.formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Header Icon
                                    Center(
                                      child: Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft,
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.cast_for_education_rounded,
                                          size: 34,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Create Teacher Account',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.text,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Set up your digital coaching institute & start managing batches',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Section Label: Personal Details
                                    const _SectionHeader(
                                      icon: Icons.badge_outlined,
                                      title: 'PERSONAL DETAILS',
                                    ),
                                    const SizedBox(height: 12),

                                    // Full Name
                                    _field(
                                      c.name,
                                      'Full Name',
                                      Icons.person_outline_rounded,
                                      c.requiredField,
                                    ),
                                    const SizedBox(height: 14),

                                    // Email
                                    _field(
                                      c.email,
                                      'Email Address',
                                      Icons.alternate_email_rounded,
                                      c.emailValidator,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 14),

                                    // Mobile
                                    _field(
                                      c.mobile,
                                      'Mobile Number',
                                      Icons.phone_iphone_rounded,
                                      c.requiredField,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 20),

                                    // Section Label: Institute Details
                                    const _SectionHeader(
                                      icon: Icons.apartment_rounded,
                                      title: 'INSTITUTE INFORMATION',
                                    ),
                                    const SizedBox(height: 12),

                                    // Institute/Coaching Name
                                    _field(
                                      c.instituteName,
                                      'Institute / Coaching Name',
                                      Icons.business_rounded,
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
                                    const SizedBox(height: 20),

                                    // Section Label: Security
                                    const _SectionHeader(
                                      icon: Icons.shield_outlined,
                                      title: 'ACCOUNT SECURITY',
                                    ),
                                    const SizedBox(height: 12),

                                    // Password
                                    TextFormField(
                                      controller: c.password,
                                      validator: c.passwordValidator,
                                      obscureText: c.obscure,
                                      onTapOutside: (_) => FocusManager
                                          .instance
                                          .primaryFocus
                                          ?.unfocus(),
                                      decoration: _dec(
                                        'Password',
                                        Icons.lock_outline_rounded,
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
                                      onTapOutside: (_) => FocusManager
                                          .instance
                                          .primaryFocus
                                          ?.unfocus(),
                                      decoration: _dec(
                                        'Confirm Password',
                                        Icons.lock_reset_rounded,
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
                                      height: 54,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: c.loading
                                            ? null
                                            : () => c.signup(context),
                                        child: c.loading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Create Educator Account',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 15.5,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Login Link
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Already have an account?',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            final loginController = context
                                                .read<LoginController>();
                                            loginController
                                                .changeLoginToTeacher();
                                            Get.offNamed(AppRoutes.login);
                                          },
                                          child: const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w800,
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
                  ],
                ),
              ),
            ],
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
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: _dec(label, icon),
    );
  }

  static InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
