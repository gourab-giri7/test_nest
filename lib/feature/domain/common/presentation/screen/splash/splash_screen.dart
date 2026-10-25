import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    _progressAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
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

    final String nextRoute;
    if (controller.isLogined) {
      if (controller.role == "teacher") {
        nextRoute = AppRoutes.teacherDashboard;
      } else if (controller.role == "student") {
        nextRoute = AppRoutes.studentDashboard;
      } else {
        nextRoute = AppRoutes.roleSelection;
      }
    } else {
      nextRoute = AppRoutes.roleSelection;
    }

    Get.offNamed(nextRoute);
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glowing orbs
            Positioned(
              top: -size.width * 0.25,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.85,
                height: size.width * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.32),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.3,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF0EA5E9).withOpacity(0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Subtle floating glass badges
            Positioned(
              top: 90,
              left: 32,
              child: _FloatingBadge(
                icon: Icons.auto_stories_rounded,
                angle: -0.15,
              ),
            ),
            Positioned(
              top: 150,
              right: 34,
              child: _FloatingBadge(
                icon: Icons.workspace_premium_rounded,
                angle: 0.18,
              ),
            ),
            Positioned(
              bottom: 140,
              left: 42,
              child: _FloatingBadge(
                icon: Icons.analytics_outlined,
                angle: 0.12,
              ),
            ),
            Positioned(
              bottom: 120,
              right: 36,
              child: _FloatingBadge(
                icon: Icons.verified_user_outlined,
                angle: -0.14,
              ),
            ),

            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Elevated Glassmorphic Logo Container
                          Container(
                            width: 156,
                            height: 156,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 36,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/appLogo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.school_rounded,
                                  size: 72,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Brand Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.16),
                              ),
                            ),
                            child: const Text(
                              'SMART COACHING & EXAM PLATFORM',
                              style: TextStyle(
                                color: Color(0xFFC7D2FE),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
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
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Nest',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Slogan
                          Text(
                            'Learn  •  Assess  •  Excel',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.74),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.2,
                            ),
                          ),
                          const SizedBox(height: 56),

                          // Modern Progress Bar
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              final pct = (_progressAnimation.value * 100)
                                  .clamp(0, 100)
                                  .toInt();
                              return Column(
                                children: [
                                  Container(
                                    height: 6,
                                    width: min(size.width * 0.64, 240),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: _progressAnimation.value
                                          .clamp(0.06, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF38BDF8),
                                              Color(0xFF818CF8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF38BDF8,
                                              ).withOpacity(0.5),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Initializing workspace... $pct%',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.4,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final double angle;

  const _FloatingBadge({required this.icon, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.22), size: 26),
      ),
    );
  }
}
