import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/signup/controller/student_signup_controller.dart';
import 'package:test_nest/routes/app_routes.dart';

class StudentSignupScreen extends StatelessWidget {
  const StudentSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentSignupController(),
      child: const _StudentSignupBody(),
    );
  }
}

class _StudentSignupBody extends StatelessWidget {
  const _StudentSignupBody();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StudentSignupController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Gradient Header Backdrop
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.student,
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
                // Custom AppBar Row
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
                        'Student Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.10),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(26.0),
                          child: Form(
                            key: c.formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header Badge
                                Center(
                                  child: Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondarySoft,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: AppColors.secondary
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      color: AppColors.secondary,
                                      size: 34,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Create Student Account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.text,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Join your teacher’s batch, take live assessments & track your growth',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Full Name
                                TextFormField(
                                  controller: c.name,
                                  onTapOutside: (_) => FocusManager
                                      .instance
                                      .primaryFocus
                                      ?.unfocus(),
                                  decoration: const InputDecoration(
                                    labelText: 'Full Name *',
                                    hintText: 'Enter your full name',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                  validator: c.requiredField,
                                ),
                                const SizedBox(height: 14),

                                // Email
                                TextFormField(
                                  controller: c.email,
                                  keyboardType: TextInputType.emailAddress,
                                  onTapOutside: (_) => FocusManager
                                      .instance
                                      .primaryFocus
                                      ?.unfocus(),
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address *',
                                    hintText: 'student@email.com',
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                    ),
                                  ),
                                  validator: c.emailValidator,
                                ),
                                const SizedBox(height: 14),

                                // Mobile (Optional)
                                TextFormField(
                                  controller: c.mobile,
                                  keyboardType: TextInputType.phone,
                                  onTapOutside: (_) => FocusManager
                                      .instance
                                      .primaryFocus
                                      ?.unfocus(),
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number (Optional)',
                                    hintText: '+91 98765 43210',
                                    prefixIcon: Icon(
                                      Icons.phone_iphone_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Password
                                TextFormField(
                                  controller: c.password,
                                  obscureText: c.obscure,
                                  onTapOutside: (_) => FocusManager
                                      .instance
                                      .primaryFocus
                                      ?.unfocus(),
                                  decoration: InputDecoration(
                                    labelText: 'Password *',
                                    hintText: 'At least 6 characters',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        c.obscure
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: c.toggleObscure,
                                    ),
                                  ),
                                  validator: c.passwordValidator,
                                ),
                                const SizedBox(height: 14),

                                // Confirm Password
                                TextFormField(
                                  controller: c.confirm,
                                  obscureText: c.obscureConfirm,
                                  onTapOutside: (_) => FocusManager
                                      .instance
                                      .primaryFocus
                                      ?.unfocus(),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password *',
                                    hintText: 'Re-enter your password',
                                    prefixIcon: const Icon(
                                      Icons.verified_user_outlined,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        c.obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: c.toggleObscureConfirm,
                                    ),
                                  ),
                                  validator: c.confirmPasswordValidator,
                                ),
                                const SizedBox(height: 26),

                                // Submit Button
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: c.loading
                                        ? null
                                        : () => c.signup(context),
                                    child: c.loading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Create Student Account',
                                                style: TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Already have account
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Already registered? ',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Get.offNamed(AppRoutes.login);
                                      },
                                      child: const Text(
                                        'Sign In Here',
                                        style: TextStyle(
                                          color: AppColors.secondary,
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
    );
  }
}
