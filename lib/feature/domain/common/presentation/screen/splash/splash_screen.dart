import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/login_screen.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/roleSelection/role_selection_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/dashboard/students_dashboard_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/dashboard/teacher_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _progressAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    _animController.forward();

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateNext();
      }
    });
  }

  void _navigateNext() {
    if (!mounted) return;
    final controller = context.read<LoginController>();

    final Widget nextScreen;
    if (controller.isLogined) {
      if (controller.role == "teacher") {
        nextScreen = const TeacherDashboardScreen();
      } else if (controller.role == "student") {
        nextScreen = const StudentDashboardScreen();
      } else {
        nextScreen = const RoleSelectionScreen();
      }
    } else {
      nextScreen = const RoleSelectionScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: Stack(
        children: [
          // Background organic soft blue wave shapes
          Positioned(
            top: -size.width * 0.35,
            left: -size.width * 0.25,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFBFDBFE).withOpacity(0.55),
                    const Color(0xFFF0F7FF).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.4,
            left: -size.width * 0.3,
            right: -size.width * 0.3,
            child: Container(
              height: size.width * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF93C5FD).withOpacity(0.45),
                    const Color(0xFFF0F7FF).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Subtle watermark educational icons
          Positioned(
            top: 70,
            left: 28,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(
                Icons.menu_book_rounded,
                size: 48,
                color: const Color(0xFF93C5FD).withOpacity(0.25),
              ),
            ),
          ),
          Positioned(
            top: 140,
            right: 28,
            child: Transform.rotate(
              angle: 0.25,
              child: Icon(
                Icons.school_outlined,
                size: 54,
                color: const Color(0xFF93C5FD).withOpacity(0.25),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: 32,
            child: Transform.rotate(
              angle: -0.15,
              child: Icon(
                Icons.assignment_turned_in_outlined,
                size: 50,
                color: const Color(0xFF93C5FD).withOpacity(0.25),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: 36,
            child: Transform.rotate(
              angle: 0.2,
              child: Icon(
                Icons.auto_stories_outlined,
                size: 44,
                color: const Color(0xFF93C5FD).withOpacity(0.22),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mascot Logo
                    Container(
                      width: 200,
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/appLogo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Test Nest Two-Tone Title
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Test ',
                            style: TextStyle(
                              color: Color(0xFF0F2942),
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Nest',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Slogan
                    const Text(
                      'Learn • Assess • Grow',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Progress bar
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Column(
                          children: [
                            Container(
                              height: 8,
                              width: min(size.width * 0.65, 260),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _progressAnimation.value.clamp(
                                  0.05,
                                  1.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF2563EB),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Preparing your learning space...',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double min(double a, double b) => a < b ? a : b;

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
