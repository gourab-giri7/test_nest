import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/routes/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top decorative gradient header backdrop
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 290,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E1B4B),
                    Color(0xFF312E81),
                    Color(0xFF4F46E5),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(42),
                  bottomRight: Radius.circular(42),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      // Brand Header inside Hero
                      Container(
                        width: 84,
                        height: 84,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.24),
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
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Welcome to Test Nest',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select your workspace portal to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.82),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 1. Owner Portal Card
                      _buildRoleCard(
                        context: context,
                        badgeText: 'INSTITUTE ADMINISTRATION',
                        title: 'Owner Portal',
                        subtitle:
                            'Establish and oversee your coaching institute, manage faculty, student admissions, batches, fees, and exams.',
                        features: const [
                          'Full Institute Control',
                          'Create Faculty Accounts',
                          'Fees & Salary Ledger',
                        ],
                        gradientColors: const [
                          Color(0xFFEFF6FF),
                          Color(0xFFDBEAFE),
                        ],
                        accentColor: const Color(0xFF2563EB),
                        icon: Icons.admin_panel_settings_rounded,
                        onTap: () {
                          final loginController = context.read<LoginController>();
                          loginController.changeLoginToOwner();
                          Get.toNamed(
                            AppRoutes.login,
                            arguments: {'portal': 'owner'},
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // 2. Teacher Portal Card
                      _buildRoleCard(
                        context: context,
                        badgeText: 'FACULTY WORKSPACE',
                        title: 'Teacher Portal',
                        subtitle:
                            'Access all institute students, conduct exams, mark daily attendance, and track monthly salary status.',
                        features: const [
                          'All Institute Students',
                          'Assessment & Grading',
                          'Attendance Tracking',
                        ],
                        noticeText: 'Account provisioned by Institute Owner',
                        gradientColors: const [
                          Color(0xFFF0FDFA),
                          Color(0xFFCCFBF1),
                        ],
                        accentColor: const Color(0xFF0D9488),
                        icon: Icons.cast_for_education_rounded,
                        onTap: () {
                          final loginController = context.read<LoginController>();
                          loginController.changeLoginToTeacher();
                          Get.toNamed(
                            AppRoutes.login,
                            arguments: {'portal': 'teacher'},
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // 3. Student Portal Card
                      _buildRoleCard(
                        context: context,
                        badgeText: 'LEARNER WORKSPACE',
                        title: 'Student Portal',
                        subtitle:
                            'Connect directly to your coaching institute, attempt timed tests, view scorecards, and review fee status.',
                        features: const [
                          'Direct Institute Access',
                          'Live Timed Exams',
                          'Results & Attendance',
                        ],
                        gradientColors: const [
                          Color(0xFFF5F3FF),
                          Color(0xFFEDE9FE),
                        ],
                        accentColor: const Color(0xFF7C3AED),
                        icon: Icons.school_rounded,
                        onTap: () {
                          final loginController = context.read<LoginController>();
                          loginController.changeLoginToStudent();
                          Get.toNamed(
                            AppRoutes.login,
                            arguments: {'portal': 'student'},
                          );
                        },
                      ),
                      const SizedBox(height: 26),

                      // Quick Direct Sign-In Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.card,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.login_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Already registered?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  Get.toNamed(AppRoutes.login);
                                },
                                child: const Text(
                                  'Sign In directly →',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
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
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String badgeText,
    required String title,
    required String subtitle,
    required List<String> features,
    required List<Color> gradientColors,
    required Color accentColor,
    required IconData icon,
    required VoidCallback onTap,
    String? noticeText,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withOpacity(0.18),
                        ),
                      ),
                      child: Icon(icon, color: accentColor, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: accentColor,
                        size: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (noticeText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            noticeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: features
                      .map(
                        (f) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  f,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
