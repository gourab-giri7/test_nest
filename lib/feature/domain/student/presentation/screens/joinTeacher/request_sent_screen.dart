import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:get/get.dart';
import 'package:test_nest/feature/auth/loginFeatureStudents/student_login_feature.dart';
import 'package:test_nest/routes/app_routes.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';

import 'package:test_nest/main.dart';

class RequestSentScreen extends StatefulWidget {
  final String batchName;
  final String teacherName;

  const RequestSentScreen({
    super.key,
    required this.batchName,
    required this.teacherName,
  });

  @override
  State<RequestSentScreen> createState() => _RequestSentScreenState();
}

class _RequestSentScreenState extends State<RequestSentScreen> {
  bool _isChecking = false;

  Future<void> _checkApprovalStatus() async {
    setState(() => _isChecking = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isChecking = false);
      return;
    }

    try {
      final res = await StudentLoginFeature.resolveStudentState(user.uid);
      if (res['state'] == 'approved') {
        if (!mounted) return;
        Get.offAllNamed(AppRoutes.studentDashboard);
        return;
      }

      if (res['state'] == 'needs_join') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your request was not approved or has expired. Please enter another batch code.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
        Get.offAllNamed(AppRoutes.studentJoinTeacher);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your request is still awaiting approval from your teacher.',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await pref.clear();
    if (!mounted) return;
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Enrollment Status',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.elevated,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        size: 44,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 22),

                    const Text(
                      'Approval Pending',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'Your enrollment request has been sent to your educator. Once approved, your dashboard and exams will unlock automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _infoRow('Requested Batch', widget.batchName),
                          const Divider(height: 22),
                          _infoRow('Educator', widget.teacherName),
                          const Divider(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Current Status',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warningSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Awaiting Approval',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isChecking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: const Text(
                          'Refresh Approval Status',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: _isChecking ? null : _checkApprovalStatus,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.toNamed(AppRoutes.studentJoinTeacher);
                        },
                        child: const Text('Enter Another Joining Code'),
                      ),
                    ),
                    if (studentData != null &&
                        studentData!.hasActiveEnrollment) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton.icon(
                          onPressed: () =>
                              Get.offAllNamed(AppRoutes.studentDashboard),
                          icon: const Icon(Icons.dashboard_rounded, size: 18),
                          label: const Text('Return to Dashboard'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}
