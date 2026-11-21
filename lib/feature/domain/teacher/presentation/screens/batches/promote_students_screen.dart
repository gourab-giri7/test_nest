import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/controller/batch_management_controller.dart';
import 'package:test_nest/model/batch_model.dart';

class PromoteStudentsScreen extends StatelessWidget {
  final BatchModel sourceBatch;

  const PromoteStudentsScreen({super.key, required this.sourceBatch});

  Future<void> _confirmPromotion(
    BuildContext context,
    PromoteStudentsController controller,
  ) async {
    final tData = teacherData;
    if (tData == null) return;
    if (controller.targetBatch == null) {
      customSnackbar(
        context: context,
        message: 'Please select a destination batch.',
        color: Colors.red,
        ico: Icons.error_outline,
      );
      return;
    }
    if (controller.selectedStudentDocIds.isEmpty) {
      customSnackbar(
        context: context,
        message: 'Please select at least one student to promote.',
        color: Colors.red,
        ico: Icons.error_outline,
      );
      return;
    }

    final target = controller.targetBatch as BatchModel;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm Promotion'),
        content: Text(
          'Promote ${controller.selectedStudentDocIds.length} student(s) from "${sourceBatch.name}" to "${target.name}"?\n\nTheir current active batch will be updated. Historical exam scores remain preserved.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Get.back(result: false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Promotion'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    controller.setPromoting(true);

    try {
      await BatchAndJoinCodeService.promoteStudents(
        teacherId: tData.id,
        sourceBatchId: sourceBatch.id,
        targetBatchId: target.id,
        targetBatchName: target.name,
        studentDocIds: controller.selectedStudentDocIds.toList(),
      );

      if (!context.mounted) return;
      customSnackbar(
        context: context,
        message:
            'Successfully promoted ${controller.selectedStudentDocIds.length} student(s) to ${target.name}!',
        color: Colors.green,
        ico: Icons.check_circle,
      );
      Get.back();
    } catch (e) {
      if (!context.mounted) return;
      customSnackbar(
        context: context,
        message: 'Promotion failed: $e',
        color: Colors.red,
        ico: Icons.error,
      );
    } finally {
      controller.setPromoting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tData = teacherData;
    if (tData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Promote Students')),
        body: const Center(child: Text('Session expired. Please log in.')),
      );
    }

    return ChangeNotifierProvider<PromoteStudentsController>(
      create: (_) => PromoteStudentsController(),
      child: Consumer<PromoteStudentsController>(
        builder: (context, controller, _) {
          final targetBatch = controller.targetBatch as BatchModel?;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Promote Students'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Get.back(),
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SafeArea(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: controller.isPromoting
                      ? null
                      : () => _confirmPromotion(context, controller),
                  child: controller.isPromoting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Promote ${controller.selectedStudentDocIds.length} Selected Student(s)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Source & Target Step Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Step 1: Choose Destination Batch',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Current Batch',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        sourceBatch.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                              Expanded(
                                child:
                                    StreamBuilder<
                                      QuerySnapshot<Map<String, dynamic>>
                                    >(
                                      stream: FirebaseFirestore.instance
                                          .collection('user')
                                          .doc(tData.id)
                                          .collection('batches')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        final docs = snapshot.data?.docs ?? [];
                                        final batches = docs
                                            .map((d) {
                                              final data = d.data();
                                              data['id'] = d.id;
                                              return BatchModel.fromJson(data);
                                            })
                                            .where(
                                              (b) =>
                                                  !b.isArchived &&
                                                  b.id != sourceBatch.id,
                                            )
                                            .toList();

                                        return DropdownButtonFormField<
                                          BatchModel
                                        >(
                                          decoration: InputDecoration(
                                            labelText: 'Target Batch',
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 8,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          value: targetBatch,
                                          hint: const Text('Select batch'),
                                          items: batches.map((b) {
                                            return DropdownMenuItem<BatchModel>(
                                              value: b,
                                              child: Text(
                                                b.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            controller.setTargetBatch(val);
                                          },
                                        );
                                      },
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Students in Current Batch
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('user')
                        .doc(tData.id)
                        .collection('students')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final allStudents = snapshot.data?.docs ?? [];
                      final batchStudents = allStudents.where((d) {
                        final data = d.data();
                        final batch = data['batch']?.toString() ?? '';
                        final batchId = data['batch_id']?.toString() ?? '';
                        final status = (data['status'] ?? 'active')
                            .toString()
                            .toLowerCase();
                        if (status == 'removed' ||
                            status == 'removed_by_teacher') {
                          return false;
                        }
                        return batch == sourceBatch.name ||
                            batchId == sourceBatch.id;
                      }).toList();

                      if (batchStudents.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Text(
                              'No students currently enrolled in this batch.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Students (${batchStudents.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        controller.toggleAll(batchStudents),
                                    child: Text(
                                      controller.selectedStudentDocIds.length ==
                                              batchStudents.length
                                          ? 'Deselect All'
                                          : 'Select All',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: batchStudents.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final doc = batchStudents[index];
                                  final data = doc.data();
                                  final name = data['name'] ?? 'Student';
                                  final sid = data['id'] ?? doc.id;
                                  final isSelected = controller
                                      .selectedStudentDocIds
                                      .contains(doc.id);

                                  return CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: isSelected,
                                    activeColor: const Color(0xFF4F46E5),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'ID: $sid',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      controller.toggleStudent(doc.id, val);
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
