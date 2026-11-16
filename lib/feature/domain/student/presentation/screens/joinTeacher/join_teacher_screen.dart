import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:get/get.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/joinTeacher/controller/join_teacher_controller.dart';
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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _openQrScanner() async {
    final scannedCode = await Get.toNamed(AppRoutes.studentScanQr);
    if (scannedCode != null &&
        scannedCode is String &&
        scannedCode.trim().isNotEmpty) {
      final cleanCode = BatchAndJoinCodeService.normalizeCode(scannedCode);
      _codeController.text = cleanCode;
      if (mounted) {
        customSnackbar(
          context: context,
          message: 'Code $cleanCode scanned! Review and submit your request.',
          color: Colors.green,
          ico: Icons.qr_code_scanner_rounded,
        );
      }
    }
  }

  Future<void> _submitCode(BuildContext context, JoinTeacherController controller) async {
    if (!_formKey.currentState!.validate() || controller.isLoading) return;

    try {
      final code = _codeController.text.trim();
      final request = await controller.submitCode(code);

      if (!context.mounted) return;
      if (request != null) {
        customSnackbar(
          context: context,
          message: 'Join request sent successfully!',
          color: Colors.green,
          ico: Icons.check_circle_outline,
        );

        Get.offNamed(
          AppRoutes.studentRequestSent,
          arguments: {
            'batchName': request.batchName,
            'teacherName': request.teacherName,
          },
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      customSnackbar(
        context: context,
        message: e is StateError ? e.message : 'Failed to submit request: $e',
        color: Colors.red,
        ico: Icons.info_outline,
      );
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

    return ChangeNotifierProvider<JoinTeacherController>(
      create: (_) => JoinTeacherController(),
      child: Consumer<JoinTeacherController>(
        builder: (context, controller, _) {
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (studentData?.hasActiveEnrollment == true) ...[
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.16),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                              ),
                              tooltip: 'Back to Dashboard',
                              onPressed: () => Get.back(),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            (studentData?.hasActiveEnrollment == true)
                                ? 'Join Another Batch'
                                : 'Join Your Coaching Batch',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
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
                                    decoration: InputDecoration(
                                      hintText: 'TN-XXXXX',
                                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                          Icons.qr_code_scanner_rounded,
                                          color: AppColors.secondary,
                                        ),
                                        tooltip: 'Scan QR Code',
                                        onPressed: controller.isLoading ? null : _openQrScanner,
                                      ),
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
                                  const SizedBox(height: 14),
                                  // Prominent "Scan QR Code" button near input
                                  SizedBox(
                                    height: 50,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF4F46E5),
                                        side: const BorderSide(
                                          color: Color(0xFFC7D2FE),
                                          width: 1.5,
                                        ),
                                        backgroundColor: const Color(0xFFEEF2FF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.qr_code_scanner_rounded,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Scan QR Code',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      onPressed: controller.isLoading ? null : _openQrScanner,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.secondary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      onPressed: controller.isLoading
                                          ? null
                                          : () => _submitCode(context, controller),
                                      icon: controller.isLoading
                                          ? const SizedBox.shrink()
                                          : const Icon(
                                              Icons.send_rounded,
                                              size: 18,
                                            ),
                                      label: controller.isLoading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              (studentData?.hasActiveEnrollment ==
                                                      true)
                                                  ? 'Submit Request to Join'
                                                  : 'Request Batch Access',
                                              style: const TextStyle(
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
                                    String statusText = 'Pending';
                                    if (status == 'approved') {
                                      statusColor = AppColors.success;
                                      statusText = 'Approved';
                                    } else if (status == 'rejected') {
                                      statusColor = AppColors.danger;
                                      statusText = 'Rejected';
                                    } else if (status == 'removed' ||
                                        status == 'removed_by_teacher') {
                                      statusColor = const Color(0xFF7C3AED);
                                      statusText = 'Removed by Teacher';
                                    }

                                    DateTime? reqDate;
                                    final rawDate =
                                        data['requested_at'] ??
                                        data['created_at'];
                                    if (rawDate is Timestamp) {
                                      reqDate = rawDate.toDate();
                                    } else if (rawDate is String) {
                                      reqDate = DateTime.tryParse(rawDate);
                                    }
                                    final dateStr = reqDate != null
                                        ? DateFormat(
                                            'dd MMM yyyy, hh:mm a',
                                          ).format(reqDate)
                                        : 'Recently';

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
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Requested: $dateStr',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary.withOpacity(0.8),
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
        },
      ),
    );
  }
}
