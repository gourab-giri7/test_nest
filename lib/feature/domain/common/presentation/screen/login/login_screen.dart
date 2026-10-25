import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<LoginController>(
        builder: (context, controller, child) {
          final activeAccent = controller.isStudentLogin
              ? AppColors.secondary
              : AppColors.primary;

          return Stack(
            children: [
              // Modern Top Header Backdrop
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 260,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: controller.isStudentLogin
                        ? AppGradients.student
                        : AppGradients.teacherHero,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22.0,
                      vertical: 16.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        children: [
                          // Top Bar with optional back button if canPop
                          if (ModalRoute.of(context)?.canPop ?? false)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Get.back(),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.16),
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 18,
                                ),
                              ),
                            ),

                          // Brand Logo & Greeting Header
                          Container(
                            width: 76,
                            height: 76,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/appLogo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.school_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.isStudentLogin
                                ? 'Sign in to your Student Learning Portal'
                                : 'Sign in to your Teacher Management Portal',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.84),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Elevated Main Form Card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 30.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: activeAccent.withOpacity(0.10),
                                  blurRadius: 32,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _loginFormKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Modern Segmented Role Switcher
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              if (controller.isStudentLogin) {
                                                controller
                                                    .changeLoginToTeacher();
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    !controller.isStudentLogin
                                                        ? AppColors.primary
                                                        : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                boxShadow:
                                                    !controller.isStudentLogin
                                                        ? [
                                                            BoxShadow(
                                                              color: AppColors
                                                                  .primary
                                                                  .withOpacity(
                                                                    0.25,
                                                                  ),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    3,
                                                                  ),
                                                            ),
                                                          ]
                                                        : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .cast_for_education_rounded,
                                                    size: 17,
                                                    color: !controller
                                                            .isStudentLogin
                                                        ? Colors.white
                                                        : AppColors
                                                            .textSecondary,
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Text(
                                                    'Teacher',
                                                    style: TextStyle(
                                                      color: !controller
                                                              .isStudentLogin
                                                          ? Colors.white
                                                          : AppColors
                                                              .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              if (!controller.isStudentLogin) {
                                                controller
                                                    .changeLoginToStudent();
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              decoration: BoxDecoration(
                                                color: controller.isStudentLogin
                                                    ? AppColors.secondary
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                boxShadow: controller
                                                        .isStudentLogin
                                                    ? [
                                                        BoxShadow(
                                                          color: AppColors
                                                              .secondary
                                                              .withOpacity(
                                                                0.25,
                                                              ),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            3,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.school_rounded,
                                                    size: 17,
                                                    color: controller
                                                            .isStudentLogin
                                                        ? Colors.white
                                                        : AppColors
                                                            .textSecondary,
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Text(
                                                    'Student',
                                                    style: TextStyle(
                                                      color: controller
                                                              .isStudentLogin
                                                          ? Colors.white
                                                          : AppColors
                                                              .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Optional Teacher ID field (only in legacy student login mode)
                                  if (controller.isStudentLogin &&
                                      controller.useLegacyStudentLogin) ...[
                                    const _InputLabel(label: 'Teacher ID'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: controller.teacherId,
                                      validator: controller.fieldeValidation,
                                      onTapOutside: (event) => FocusManager
                                          .instance
                                          .primaryFocus!
                                          .unfocus(),
                                      decoration: const InputDecoration(
                                        hintText: 'Enter your Teacher ID',
                                        prefixIcon: Icon(
                                          Icons.supervisor_account_outlined,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // User ID / Email Field
                                  _InputLabel(
                                    label: controller.isStudentLogin
                                        ? (controller.useLegacyStudentLogin
                                              ? 'Student ID'
                                              : 'Email Address')
                                        : 'Email or Teacher ID',
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: controller.id,
                                    validator: controller.fieldeValidation,
                                    onTapOutside: (event) => FocusManager
                                        .instance
                                        .primaryFocus!
                                        .unfocus(),
                                    decoration: InputDecoration(
                                      hintText: controller.isStudentLogin
                                          ? (controller.useLegacyStudentLogin
                                                ? 'Enter your Student ID'
                                                : 'student@example.com')
                                          : 'teacher@institute.com',
                                      prefixIcon: Icon(
                                        (controller.isStudentLogin &&
                                                controller
                                                    .useLegacyStudentLogin)
                                            ? Icons.badge_outlined
                                            : Icons.alternate_email_rounded,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Field — shown for teacher and standard student login
                                  if (!controller.isStudentLogin ||
                                      !controller.useLegacyStudentLogin) ...[
                                    const _InputLabel(label: 'Password'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      keyboardType:
                                          TextInputType.visiblePassword,
                                      controller: controller.password,
                                      validator: controller.fieldeValidation,
                                      onTapOutside: (event) => FocusManager
                                          .instance
                                          .primaryFocus!
                                          .unfocus(),
                                      obscureText: controller.obscurePassword,
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            controller.obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            controller.toggelObscurePassword();
                                          },
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Legacy student toggle button
                                  if (controller.isStudentLogin)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          controller.toggleLegacyStudentLogin();
                                        },
                                        icon: Icon(
                                          controller.useLegacyStudentLogin
                                              ? Icons.email_outlined
                                              : Icons.qr_code_rounded,
                                          size: 15,
                                          color: AppColors.secondary,
                                        ),
                                        label: Text(
                                          controller.useLegacyStudentLogin
                                              ? 'Use Email & Password'
                                              : 'Have a Teacher ID & Student ID?',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Forgot Password — only for teachers
                                  if (!controller.isStudentLogin)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {},
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),

                                  // Primary Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: activeAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: controller.ispressed
                                          ? null
                                          : () {
                                              if (!_loginFormKey.currentState!
                                                  .validate()) {
                                                return;
                                              }
                                              controller.login(context);
                                            },
                                      child: controller.ispressed
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  controller.isStudentLogin
                                                      ? 'Sign In as Student'
                                                      : 'Sign In as Teacher',
                                                  style: const TextStyle(
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),

                                  const Divider(height: 1),
                                  const SizedBox(height: 18),

                                  // Registration Footer
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "New to Test Nest? ",
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (controller.isStudentLogin) {
                                            Get.toNamed(AppRoutes.studentSignup);
                                          } else {
                                            Get.toNamed(AppRoutes.teacherSignup);
                                          }
                                        },
                                        child: Text(
                                          controller.isStudentLogin
                                              ? 'Create Student Account'
                                              : 'Create Teacher Account',
                                          style: TextStyle(
                                            color: activeAccent,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        letterSpacing: 0.1,
      ),
    );
  }
}
