import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/create_exam_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/examDetails/teacher_exam_details_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/exams/controller/teacher_exam_controller.dart';
import 'package:test_nest/model/exam_model.dart';

class TeacherExamsScreen extends StatelessWidget {
  const TeacherExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tData = teacherData;
    if (tData == null) {
      return const Scaffold(
        body: Center(child: Text('Teacher session not found')),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exams',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage your exams',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateExamScreen()),
              ),
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(tData.id.trim())
            .collection('exams')
            .orderBy('exam_id', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
              child: Text('Something went wrong loading exams'),
            );
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          final exams = (snapshot.data?.docs ?? [])
              .map((d) => ExamModel.fromJson(d.data()))
              .toList(growable: false);
          return Consumer<TeacherExamController>(
            builder: (context, controller, _) {
              final search = controller.search.toLowerCase();

              final activeBatch = controller.selectedBatch;

              final visibleExams = exams
                  .where((exam) {
                    final matchesSearch =
                        search.isEmpty ||
                        exam.examName.toLowerCase().contains(search) ||
                        exam.examId.toLowerCase().contains(search);

                    final matchesFilter =
                        controller.selectedFilter == 'All' ||
                        exam.status == controller.selectedFilter;

                    final matchesBatch =
                        activeBatch == 'All Batches' ||
                        exam.batch.trim().toLowerCase() ==
                            activeBatch.trim().toLowerCase();

                    return matchesSearch && matchesFilter && matchesBatch;
                  })
                  .toList(growable: false);

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
                        _buildSummary(exams, isWide: isWide),

                        const SizedBox(height: 16),

                        _buildSearch(controller),

                        const SizedBox(height: 12),

                        _buildFilters(controller),

                        const SizedBox(height: 10),

                        _buildBatchFilter(tData.batch, activeBatch, controller),

                        const SizedBox(height: 16),

                        Expanded(
                          child: _buildExamList(visibleExams, isWide: isWide),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummary(List<ExamModel> exams, {required bool isWide}) {
    final upcoming = exams.where((exam) => exam.status == "Upcoming").length;
    final completed = exams.where((exam) => exam.status == "Completed").length;

    final cards = [
      _summaryCard(
        icon: Icons.event_available_rounded,
        title: "Upcoming",
        value: upcoming.toString(),
      ),
      _summaryCard(
        icon: Icons.task_alt_rounded,
        title: "Completed",
        value: completed.toString(),
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(TeacherExamController controller) {
    return TextField(
      controller: controller.searchController,
      onChanged: controller.setSearch,
      decoration: InputDecoration(
        hintText: 'Search exam by name or ID',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.search.isNotEmpty
            ? IconButton(
                onPressed: controller.clearSearch,
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    );
  }

  Widget _buildFilters(TeacherExamController controller) {
    final filters = ["All", "Active", "Upcoming", "Completed"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = controller.selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                controller.setFilter(filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF475569),
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
    final items = <String>{
      'All Batches',
      ...batches.map((e) => e.trim()).where((e) => e.isNotEmpty),
    }.toList();

    return DropdownButtonFormField<String>(
      value: items.contains(activeBatch) ? activeBatch : 'All Batches',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Batch',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: items
          .map(
            (batch) =>
                DropdownMenuItem<String>(value: batch, child: Text(batch)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          controller.setBatch(value);
        }
      },
    );
  }

  Widget _buildExamList(List<ExamModel> exams, {required bool isWide}) {
    if (exams.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 50,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'No exams found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
    }

    if (isWide) {
      return GridView.builder(
        padding: const EdgeInsets.only(bottom: 12),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 560,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.65,
        ),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          return _buildExamCard(exams[index], context);
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: exams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildExamCard(exams[index], context);
      },
    );
  }

  Widget _buildExamCard(ExamModel exam, BuildContext context) {
    final status = exam.status;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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
            ],
          ),

          const SizedBox(height: 13),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Compact information grid. UI-only; values are unchanged.
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherExamDetailsScreen(exam: exam),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: const Color(0xFFFAFCFF),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "View Details",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
            ),
          ),
        ],
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
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: textColor),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
