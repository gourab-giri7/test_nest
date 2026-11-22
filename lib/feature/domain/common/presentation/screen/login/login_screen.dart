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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments;
      if (args is Map && args['portal'] != null) {
        final portal = args['portal'].toString();
        context.read<LoginController>().setPortal(portal);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<LoginController>(
        builder: (context, controller, child) {
          final Color activeAccent = controller.isOwnerLogin
              ? const Color(0xFF2563EB)
              : (controller.isTeacherLogin
                  ? const Color(0xFF0D9488)
                  : const Color(0xFF7C3AED));

          final Gradient activeGradient = controller.isOwnerLogin
              ? const LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF2563EB),
                    Color(0xFF3B82F6),
                  ],
                )
              : (controller.isTeacherLogin
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF115E59),
                        Color(0xFF0D9488),
                        Color(0xFF14B8A6),
                      ],
                    )
                  : AppGradients.student);

          final topPadding = MediaQuery.of(context).padding.top;
          final backdropHeight = (topPadding + 210.0).clamp(240.0, 300.0);

          return Stack(
            children: [
              // Modern Top Header Backdrop
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: backdropHeight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: activeGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
              ),

              // Floating Back Button if navigation history allows pop
              if (ModalRoute.of(context)?.canPop ?? false)
                Positioned(
                  top: topPadding + 6,
                  left: 16,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.18),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                ),

              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.only(
                      left: 20.0,
                      right: 20.0,
                      top: 10.0,
                      bottom: 24.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        children: [
                          // Brand Logo & Greeting Header
                          Container(
                            width: 58,
                            height: 58,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.30),
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
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            controller.isOwnerLogin
                                ? 'Sign in to your Owner Management Portal'
                                : (controller.isTeacherLogin
                                    ? 'Sign in to your Teacher Faculty Portal'
                                    : 'Sign in to your Student Learning Portal'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 16),

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
                                  // Modern 3-Segmented Role Switcher
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildRoleSegment(
                                          label: 'Owner',
                                          icon: Icons.admin_panel_settings_rounded,
                                          isSelected: controller.isOwnerLogin,
                                          color: const Color(0xFF2563EB),
                                          onTap: () {
                                            if (!controller.isOwnerLogin) {
                                              controller.changeLoginToOwner();
                                            }
                                          },
                                        ),
                                        _buildRoleSegment(
                                          label: 'Teacher',
                                          icon: Icons.cast_for_education_rounded,
                                          isSelected: controller.isTeacherLogin,
                                          color: const Color(0xFF0D9488),
                                          onTap: () {
                                            if (!controller.isTeacherLogin) {
                                              controller.changeLoginToTeacher();
                                            }
                                          },
                                        ),
                                        _buildRoleSegment(
                                          label: 'Student',
                                          icon: Icons.school_rounded,
                                          isSelected: controller.isStudentLogin,
                                          color: const Color(0xFF7C3AED),
                                          onTap: () {
                                            if (!controller.isStudentLogin) {
                                              controller.changeLoginToStudent();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // User Email Field
                                  _InputLabel(
                                    label: controller.isOwnerLogin
                                        ? 'Institute Owner Email'
                                        : (controller.isTeacherLogin
                                            ? 'Teacher Email'
                                            : 'Student Email'),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: controller.id,
                                    validator: controller.fieldeValidation,
                                    keyboardType: TextInputType.emailAddress,
                                    onTapOutside: (event) => FocusManager
                                        .instance
                                        .primaryFocus!
                                        .unfocus(),
                                    decoration: InputDecoration(
                                      hintText: controller.isOwnerLogin
                                          ? 'owner@institute.com'
                                          : (controller.isTeacherLogin
                                              ? 'teacher@institute.com'
                                              : 'student@example.com'),
                                      prefixIcon: const Icon(
                                        Icons.alternate_email_rounded,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Field
                                  const _InputLabel(label: 'Password'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    keyboardType: TextInputType.visiblePassword,
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                          : FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    controller.isOwnerLogin
                                                        ? 'Sign In as Owner'
                                                        : (controller.isTeacherLogin
                                                            ? 'Sign In as Teacher'
                                                            : 'Sign In as Student'),
                                                    style: const TextStyle(
                                                      fontSize: 15.5,
                                                      fontWeight:
                                                          FontWeight.w800,
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
                                  ),
                                  const SizedBox(height: 22),

                                  const Divider(height: 1),
                                  const SizedBox(height: 18),

                                  // Context-Sensitive Registration / Notice Footer
                                  if (controller.isTeacherLogin)
                                    Wrap(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDFA),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFCCFBF1),
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline_rounded,
                                                size: 18,
                                                color: Color(0xFF0D9488),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Teacher accounts are created by your Institute Owner. Please log in with the credentials provided to you.',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF115E59),
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: [
                                        Text(
                                          controller.isOwnerLogin
                                              ? "New Institute Owner? "
                                              : "New to Test Nest? ",
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (controller.isOwnerLogin) {
                                              Get.toNamed(
                                                AppRoutes.ownerSignup,
                                              );
                                            } else {
                                              Get.toNamed(
                                                AppRoutes.studentSignup,
                                              );
                                            }
                                          },
                                          child: Text(
                                            controller.isOwnerLogin
                                                ? 'Create Owner Account'
                                                : 'Create Student Account',
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

  Widget _buildRoleSegment({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
