import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:get/get.dart';
import 'package:test_nest/routes/app_routes.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';

import 'package:test_nest/main.dart';

class JoinTeacherScreen extends StatefulWidget {
  const JoinTeacherScreen({super.key});

  @override
  State<JoinTeacherScreen> createState() => _JoinTeacherScreenState();
}

class _JoinTeacherScreenState extends State<JoinTeacherScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim();
      final codeModel = await BatchAndJoinCodeService.validateJoiningCode(code);

      if (codeModel == null) {
        if (!mounted) return;
        customSnackbar(
          context: context,
          message:
              'Invalid, expired, or revoked joining code. Please check and try again.',
          color: Colors.red,
          ico: Icons.error_outline,
        );
        setState(() => _isLoading = false);
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        customSnackbar(
          context: context,
          message: 'Please log in again to continue.',
          color: Colors.red,
          ico: Icons.lock_outline,
        );
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final studentName =
          (userDoc.data()?['name'] ?? user.displayName ?? 'Student').toString();
      final studentEmail = user.email ?? '';
      final studentPhone = userDoc.data()?['phone']?.toString();

      final request = await BatchAndJoinCodeService.submitJoinRequest(
        studentUid: user.uid,
        studentName: studentName,
        studentEmail: studentEmail,
        studentPhone: studentPhone,
        codeModel: codeModel,
      );

      if (!mounted) return;
      customSnackbar(
        context: context,
        message: 'Join request sent successfully!',
        color: Colors.green,
        ico: Icons.check_circle_outline,
      );

      Get.offNamed(AppRoutes.studentRequestSent, arguments: {'batchName': request.batchName, 'teacherName': request.teacherName});
    } catch (e) {
      if (!mounted) return;
      customSnackbar(
        context: context,
        message: e is StateError ? e.message : 'Failed to submit request: $e',
        color: Colors.red,
        ico: Icons.info_outline,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 230,
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Join Your Coaching Batch',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.16),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        tooltip: 'Sign Out',
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppShadows.elevated,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondarySoft,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: const Icon(
                                        Icons.qr_code_scanner_rounded,
                                        size: 36,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Enter Batch Joining Code',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Ask your teacher for the unique 8-character batch invite code (e.g., TN-7K9P2) to connect your account.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _codeController,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
                                      color: AppColors.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      hintText: 'TN-XXXXX',
                                      prefixIcon: Icon(Icons.vpn_key_rounded),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Please enter a valid joining code';
                                      }
                                      if (val.trim().length < 4) {
                                        return 'Joining code is too short';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      onPressed:
                                          _isLoading ? null : _submitCode,
                                      icon: _isLoading
                                          ? const SizedBox.shrink()
                                          : const Icon(
                                              Icons.send_rounded,
                                              size: 18,
                                            ),
                                      label: _isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Request Batch Access',
                                              style: TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          if (user != null) ...[
                            const Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Recent Join Requests',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('joinRequests')
                                  .where('student_uid', isEqualTo: user.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox.shrink();
                                }
                                final docs = snapshot.data!.docs;
                                if (docs.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: const Text(
                                      'No join requests submitted yet.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: docs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final data = docs[index].data();
                                    final batchName =
                                        data['batch_name'] ?? 'Batch';
                                    final teacherName =
                                        data['teacher_name'] ?? 'Teacher';
                                    final status = (data['status'] ?? 'pending')
                                        .toString()
                                        .toLowerCase();

                                    Color statusColor = AppColors.warning;
                                    String statusText = 'Pending Approval';
                                    if (status == 'approved') {
                                      statusColor = AppColors.success;
                                      statusText = 'Approved';
                                    } else if (status == 'rejected') {
                                      statusColor = AppColors.danger;
                                      statusText = 'Rejected';
                                    }

                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                        boxShadow: AppShadows.card,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: AppColors.primarySoft,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.groups_rounded,
                                              color: AppColors.primary,
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  batchName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14.5,
                                                    color: AppColors.text,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Educator: $teacherName',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              statusText,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ],
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
