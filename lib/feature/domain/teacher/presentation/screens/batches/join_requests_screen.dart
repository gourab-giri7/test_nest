import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/model/join_request_model.dart';

class JoinRequestsScreen extends StatefulWidget {
  const JoinRequestsScreen({super.key});

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  final Set<String> _processingIds = {};

  Future<void> _approve(JoinRequestModel request) async {
    final tData = teacherData;
    if (tData == null || tData.id != request.teacherId) {
      customSnackbar(
        context: context,
        message: 'Unauthorized: request belongs to another teacher.',
        color: Colors.red,
        ico: Icons.lock_outline,
      );
      return;
    }

    setState(() => _processingIds.add(request.id));

    try {
      await BatchAndJoinCodeService.approveJoinRequest(request: request);
      if (!mounted) return;
      customSnackbar(
        context: context,
        message: 'Approved ${request.studentName} for ${request.batchName}!',
        color: Colors.green,
        ico: Icons.check_circle,
      );
    } catch (e) {
      if (!mounted) return;
      customSnackbar(
        context: context,
        message: 'Failed to approve request: $e',
        color: Colors.red,
        ico: Icons.error,
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(request.id));
    }
  }

  Future<void> _reject(JoinRequestModel request) async {
    final tData = teacherData;
    if (tData == null || tData.id != request.teacherId) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Reject Join Request'),
        content: Text(
          'Are you sure you want to reject ${request.studentName}’s request to join ${request.batchName}?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Get.back(result: false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingIds.add(request.id));

    try {
      await BatchAndJoinCodeService.rejectJoinRequest(
        teacherId: request.teacherId,
        batchId: request.batchId,
        requestId: request.id,
      );
      if (!mounted) return;
      customSnackbar(
        context: context,
        message: 'Request rejected.',
        color: Colors.orange,
        ico: Icons.remove_circle_outline,
      );
    } catch (e) {
      if (!mounted) return;
      customSnackbar(
        context: context,
        message: 'Failed to reject request: $e',
        color: Colors.red,
        ico: Icons.error,
      );
    } finally {
      if (mounted) setState(() => _processingIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tData = teacherData;
    if (tData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Join Requests')),
        body: const Center(child: Text('Session expired. Please log in.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Join Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('joinRequests')
            .where('teacher_id', isEqualTo: tData.id)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final requests = docs
              .map((d) => JoinRequestModel.fromJson(d.data(), docId: d.id))
              .toList();

          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 40,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'All Caught Up!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No pending join requests from students right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = requests[index];
              final isProcessing = _processingIds.contains(req.id);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFEEF2FF),
                            child: Text(
                              req.studentName.isNotEmpty
                                  ? req.studentName[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.studentName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  req.studentEmail,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                if (req.studentPhone != null &&
                                    req.studentPhone!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    req.studentPhone!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Batch: ${req.batchName}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            if (req.requestedAt != null)
                              Text(
                                DateFormat(
                                  'dd MMM, hh:mm a',
                                ).format(req.requestedAt!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Approve / Reject Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(
                                  color: Color(0xFFFECACA),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isProcessing
                                  ? null
                                  : () => _reject(req),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isProcessing
                                  ? null
                                  : () => _approve(req),
                              child: isProcessing
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Approve',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
