import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/exam_firestore_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/exams/controller/teacher_exam_controller.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class TeacherExamsScreen extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>>? examStream;
  const TeacherExamsScreen({super.key, this.examStream});

  Future<void> _deleteExams(
    BuildContext context,
    List<ExamModel> examsToDelete,
  ) async {
    final tData = teacherData;
    final controller = context.read<TeacherExamController>();
    if (tData == null || examsToDelete.isEmpty || controller.isDeleting) return;

    final isSingle = examsToDelete.length == 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          isSingle ? 'Delete Exam' : 'Delete ${examsToDelete.length} Exams',
        ),
        content: Text(
          isSingle
              ? 'Are you sure you want to delete "${examsToDelete.first.examName}"?\n\nThis exam will be removed from your portal and student schedules. Completed historical attempts and results remain preserved.'
              : 'Are you sure you want to delete these ${examsToDelete.length} exams?\n\nThey will be removed from your portal and student schedules. Completed historical attempts and results remain preserved.',
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
            child: const Text('Delete'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    controller.setDeleting(true);

    try {
      await ExamFirestoreService.deleteExams(
        teacherId: tData.id,
        examIds: examsToDelete.map((e) => e.examId).toList(),
      );

      controller.clearSelection();
      controller.setDeleting(false);

      if (context.mounted) {
        customSnackbar(
          context: context,
          message: isSingle
              ? 'Exam deleted successfully.'
              : '${examsToDelete.length} exams deleted successfully.',
          color: Colors.green,
          ico: Icons.delete_outline_rounded,
        );
      }
    } catch (e) {
      controller.setDeleting(false);
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Failed to delete exams: $e',
          color: Colors.red,
          ico: Icons.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tData = teacherData;
    if (tData == null) {
      return const Scaffold(
        body: Center(child: Text('Teacher session not found')),
      );
    }
    return Consumer<TeacherExamController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: controller.isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => controller.clearSelection(),
                  )
                : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.isSelectionMode
                      ? '${controller.selectedExamIds.length} Selected'
                      : 'Exams',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.isSelectionMode
                      ? 'Select exams to delete'
                      : 'Manage your exams',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              if (controller.isSelectionMode) ...[
                if (controller.selectedExamIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      tooltip: 'Delete Selected',
                      onPressed: controller.isDeleting
                          ? null
                          : () {
                              // Handled via stream builder visible exams
                            },
                      icon: controller.isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFEF4444),
                              ),
                            )
                          : const Icon(
                              Icons.delete_forever_rounded,
                              color: Color(0xFFEF4444),
                            ),
                    ),
                  ),
              ] else ...[
                IconButton(
                  tooltip: 'Select Exams',
                  icon: const Icon(Icons.checklist_rounded),
                  onPressed: () => controller.toggleSelectionMode(),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    tooltip: 'Create Exam',
                    onPressed: () => Get.toNamed(AppRoutes.teacherCreateExam),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          body: Builder(
            builder: (ctx) {
              ActiveTenantContext? tenantCtx;
              try {
                tenantCtx = ctx.watch<ActiveTenantContext>();
              } catch (_) {}
              final isInstitute = tenantCtx != null &&
                  tenantCtx.isInstitute &&
                  tenantCtx.activeOrgId.isNotEmpty;
              final isInstituteTeacher =
                  isInstitute && tenantCtx.isTeacher && !tenantCtx.isAdmin;
              final orgId = tenantCtx?.activeOrgId ?? '';
              final effectiveTeacherUid =
                  FirebaseAuth.instance.currentUser?.uid.trim().isNotEmpty == true
                      ? FirebaseAuth.instance.currentUser!.uid.trim()
                      : tData.id.trim();

              final resolvedStream = examStream ??
                  (isInstitute
                      ? FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(orgId)
                          .collection('exams')
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('user')
                          .doc(tData.id.trim())
                          .collection('exams')
                          .orderBy('exam_id', descending: true)
                          .snapshots());

              final Stream<QuerySnapshot<Map<String, dynamic>>>? batchesStream =
                  isInstituteTeacher
                      ? FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(orgId)
                          .collection('batches')
                          .snapshots()
                      : null;

              final Stream<DocumentSnapshot<Map<String, dynamic>>>? memberStream =
                  isInstituteTeacher && effectiveTeacherUid.isNotEmpty
                      ? FirebaseFirestore.instance
                          .collection('organizations')
                          .doc(orgId)
                          .collection('members')
                          .doc(effectiveTeacherUid)
                          .snapshots()
                      : null;

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: memberStream,
                builder: (context, memberSnap) {
                  final rawMemberBatchIds =
                      memberSnap.data?.data()?['assignedBatchIds'];
                  final memberAssignedBatchIds = <String>{
                    if (rawMemberBatchIds is List)
                      ...rawMemberBatchIds.map((e) => e.toString().trim()),
                  };

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: batchesStream,
                    builder: (context, batchSnap) {
                      final assignedBatchNames = <String>[];
                      final assignedBatchKeys = <String>{};
                      if (isInstituteTeacher) {
                        for (final d in (batchSnap.data?.docs ?? const [])) {
                          final data = d.data();
                          if (data['isArchived'] == true ||
                              data['is_archived'] == true) {
                            continue;
                          }
                          final rawTeachers = data['assignedTeacherIds'] ??
                              data['assigned_teacher_ids'];
                          final assignedTeachers = rawTeachers is List
                              ? rawTeachers
                                  .map((e) => e.toString().trim())
                                  .toSet()
                              : <String>{};
                          final bTeacherId =
                              (data['teacher_id'] ?? data['teacherId'] ?? '')
                                  .toString()
                                  .trim();
                          final isAssigned =
                              assignedTeachers.contains(effectiveTeacherUid) ||
                                  bTeacherId == effectiveTeacherUid ||
                                  memberAssignedBatchIds.contains(d.id);
                          if (isAssigned) {
                            final bName = (data['name'] ?? '').toString().trim();
                            if (bName.isNotEmpty) {
                              assignedBatchNames.add(bName);
                              assignedBatchKeys.add(bName.toLowerCase());
                            }
                            assignedBatchKeys.add(d.id.trim().toLowerCase());
                          }
                        }
                      }

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: resolvedStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('Something went wrong loading exams'),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final allExams = (snapshot.data?.docs ?? [])
                              .map((d) => ExamModel.fromJson(d.data()))
                              .toList(growable: false);

                          final exams = isInstituteTeacher
                              ? allExams.where((exam) {
                                  if (exam.teacherId.trim() ==
                                      effectiveTeacherUid) {
                                    return true;
                                  }
                                  if (assignedBatchKeys.contains(
                                    exam.batch.trim().toLowerCase(),
                                  )) {
                                    return true;
                                  }
                                  return exam.batches.any(
                                    (eb) => assignedBatchKeys.contains(
                                      eb.trim().toLowerCase(),
                                    ),
                                  );
                                }).toList(growable: false)
                              : allExams;

                          final search = controller.search.toLowerCase();
                          final activeBatch = controller.selectedBatch;

                          final visibleExams = exams
                              .where((exam) {
                                final matchesSearch =
                                    search.isEmpty ||
                                    exam.examName.toLowerCase().contains(
                                      search,
                                    ) ||
                                    exam.examId.toLowerCase().contains(search);

                                final matchesFilter =
                                    controller.selectedFilter == 'All' ||
                                    exam.status == controller.selectedFilter;

                                final matchesBatch =
                                    activeBatch == 'All Batches' ||
                                    exam.batch.trim().toLowerCase() ==
                                        activeBatch.trim().toLowerCase() ||
                                    exam.batches.any(
                                      (eb) =>
                                          eb.trim().toLowerCase() ==
                                          activeBatch.trim().toLowerCase(),
                                    );

                                return matchesSearch &&
                                    matchesFilter &&
                                    matchesBatch;
                              })
                              .toList(growable: false);

              final allSelected =
                  visibleExams.isNotEmpty &&
                  visibleExams.every(
                    (e) => controller.selectedExamIds.contains(e.examId),
                  );

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  final horizontalPadding = isWide ? 24.0 : 12.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      8,
                      horizontalPadding,
                      12,
                    ),
                    child: Column(
                      children: [
                        if (controller.isSelectionMode) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFC7D2FE),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: allSelected,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) {
                                    if (v == true) {
                                      controller.selectAllExams(
                                        visibleExams
                                            .map((e) => e.examId)
                                            .toList(),
                                      );
                                    } else {
                                      controller.clearSelection();
                                      controller.toggleSelectionMode();
                                    }
                                  },
                                ),
                                const Text(
                                  'Select All',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                if (controller.selectedExamIds.isNotEmpty)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: controller.isDeleting
                                        ? null
                                        : () {
                                            final selectedExams = visibleExams
                                                .where(
                                                  (e) => controller
                                                      .selectedExamIds
                                                      .contains(e.examId),
                                                )
                                                .toList();
                                            _deleteExams(
                                              context,
                                              selectedExams,
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'Delete (${controller.selectedExamIds.length})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ] else ...[
                              _buildSummary(
                                exams,
                                isWide: isWide,
                                controller: controller,
                              ),
                              const SizedBox(height: 16),
                              _buildSearch(controller),
                              const SizedBox(height: 12),
                              _buildFilters(controller),
                              const SizedBox(height: 10),
                              _buildBatchFilter(
                                () {
                                  if (isInstituteTeacher) {
                                    return assignedBatchNames
                                        .where((b) => b.trim().isNotEmpty)
                                        .toSet()
                                        .toList();
                                  }
                                  final bSet = <String>{...tData.batch};
                                  for (final e in exams) {
                                    if (e.batches.isNotEmpty) {
                                      bSet.addAll(e.batches);
                                    } else if (e.batch.trim().isNotEmpty) {
                                      bSet.add(e.batch.trim());
                                    }
                                  }
                                  return bSet
                                      .where((b) => b.trim().isNotEmpty)
                                      .toList();
                                }(),
                                activeBatch,
                                controller,
                              ),
                              const SizedBox(height: 16),
                            ],

                            Expanded(
                              child: _buildExamList(
                                visibleExams,
                                controller,
                                isWide: isWide,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummary(
    List<ExamModel> exams, {
    required bool isWide,
    TeacherExamController? controller,
  }) {
    final now = DateTime.now();
    final live = exams.where((exam) => exam.status == "Live" || (exam.examStart != null && exam.examEnd != null && now.isAfter(exam.examStart!) && now.isBefore(exam.examEnd!))).length;
    final upcoming = exams.where((exam) => exam.status == "Upcoming" || (exam.examStart != null && now.isBefore(exam.examStart!))).length;
    final completed = exams.where((exam) => exam.status == "Completed" || (exam.examEnd != null && now.isAfter(exam.examEnd!))).length;

    final cards = [
      _summaryCard(
        icon: Icons.task_alt_rounded,
        title: "Completed",
        value: completed.toString(),
        color: const Color(0xFF10B981),
        onTap: controller != null ? () => controller.setFilter("Completed") : null,
      ),
      _summaryCard(
        icon: Icons.play_circle_outline_rounded,
        title: "Live",
        value: live.toString(),
        color: const Color(0xFF2563EB),
        onTap: controller != null ? () => controller.setFilter("Active") : null,
      ),
      _summaryCard(
        icon: Icons.event_available_rounded,
        title: "Upcoming",
        value: upcoming.toString(),
        color: const Color(0xFF7C3AED),
        onTap: controller != null ? () => controller.setFilter("Upcoming") : null,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: c,
                ),
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 8),
        Expanded(child: cards[1]),
        const SizedBox(width: 8),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    Color color = AppColors.primary,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch(TeacherExamController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.setSearch,
        decoration: InputDecoration(
          hintText: "Search exams by name or ID...",
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          suffixIcon: controller.search.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: controller.clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(TeacherExamController controller) {
    final filters = ['All', 'Active', 'Upcoming', 'Completed'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = controller.selectedFilter == f;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => controller.setFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBatchFilter(
    List<String> batches,
    String activeBatch,
    TeacherExamController controller,
  ) {
    controller.normalizeBatch(batches);

    final all = [
      'All Batches',
      ...batches.map((e) => e.trim()).where((e) => e.isNotEmpty),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: all.map((batch) {
          final isSelected = activeBatch == batch;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => controller.setBatch(batch),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySoft
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  batch,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExamList(
    List<ExamModel> exams,
    TeacherExamController controller, {
    required bool isWide,
  }) {
    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 38,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "No Exams Found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "No exams match your current filter",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (isWide) {
      return GridView.builder(
        padding: const EdgeInsets.only(bottom: 12),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 320,
        ),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          return _buildExamCard(exams[index], controller, context);
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: exams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildExamCard(exams[index], controller, context);
      },
    );
  }

  Widget _buildExamCard(
    ExamModel exam,
    TeacherExamController controller,
    BuildContext context,
  ) {
    final status = exam.status;
    final isSelected = controller.selectedExamIds.contains(exam.examId);

    return InkWell(
      onLongPress: () {
        if (!controller.isSelectionMode) {
          controller.toggleSelectionMode();
        }
        controller.toggleExamSelection(exam.examId);
      },
      onTap: () {
        if (controller.isSelectionMode) {
          controller.toggleExamSelection(exam.examId);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    activeColor: AppColors.primary,
                    onChanged: (_) =>
                        controller.toggleExamSelection(exam.examId),
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.examName.isNotEmpty
                            ? exam.examName
                            : "Untitled Exam",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exam.examId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(status),
                if (!controller.isSelectionMode)
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    icon: const Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    onSelected: (val) {
                      if (val == 'details') {
                        Get.toNamed(
                          AppRoutes.teacherExamDetails,
                          arguments: exam,
                        );
                      } else if (val == 'delete') {
                        _deleteExams(context, [exam]);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Exam',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 13),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _compactInfoChip(Icons.calendar_today_outlined, exam.examDate),
                _compactInfoChip(
                  Icons.access_time_rounded,
                  "${exam.startTime} - ${exam.endTime}",
                ),
                _compactInfoChip(Icons.groups_outlined, exam.batch),
                _compactInfoChip(
                  Icons.quiz_outlined,
                  "${exam.questionCount} Questions",
                ),
                _compactInfoChip(
                  Icons.star_outline_rounded,
                  "${exam.fullMarks} Marks",
                ),
              ],
            ),

            const SizedBox(height: 13),

            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.teacherExamDetails, arguments: exam);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: const Color(0xFFFAFCFF),
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "View Details",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 17),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactInfoChip(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Active':
        bgColor = AppColors.primarySoft;
        textColor = AppColors.primary;
        break;
      case 'Upcoming':
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFC2410C);
        break;
      case 'Completed':
        bgColor = AppColors.successSoft;
        textColor = const Color(0xFF047857);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
