import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/create_exam_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/allStudents/all_students_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/exams/teacher_exam_screen.dart';
import 'package:test_nest/main.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  @override
  void initState() {
    // teacherData = TeacherData.fromJson(data);
    // ----------- store local
    final teacher = jsonDecode(pref.getString("teacherData") ?? "");
    teacherData = TeacherData.fromJson(teacher);
    log(teacherData.lastStdId);
    log("teacher");
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.blueGrey[50],
        // centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(Icons.school),
          ),
        ),
        title: const Text(
          'XYZ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Section
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 2),
                        color: const Color.fromARGB(255, 164, 177, 184),
                        blurRadius: 5,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: AlignmentGeometry.topLeft,
                      end: AlignmentGeometry.bottomLeft,
                      colors: [
                        Colors.orange,
                        const Color.fromARGB(255, 237, 194, 138),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              fontSize: 20,
                              // color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            teacherData.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            ' TID: ${teacherData.id}',
                            style: TextStyle(
                              // fontSize: 14,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFE2E8F0),
                        child: Icon(
                          Icons.person,
                          size: 36,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Summary Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Exams',
                        count: '12',
                        backgroundColor: const Color(0xFF008CFF),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Students',
                        count: '342',
                        backgroundColor: const Color(0xFF00BC61),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Action Menu Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 480 ? 3 : 3;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                      children: [
                        // ------------------------ create exam
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateExamScreen(),
                            ),
                          ),
                          child: InkWell(
                            child: _QuickActionButton(
                              icon: Icons.edit_note,
                              iconColor: Color(0xFF2563EB),
                              bgColor: Color(0xFFEFF6FF),
                              label: 'Create Exam',
                            ),
                          ),
                        ),
                        // ---------------------- all students
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllStudentsScreen(),
                            ),
                          ),
                          child: _QuickActionButton(
                            icon: Icons.people_outline,
                            iconColor: Color(0xFF10B981),
                            bgColor: Color(0xFFECFDF5),
                            label: 'Students',
                          ),
                        ),
                        // ----------------- exams
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeacherExamsScreen(),
                            ),
                          ),
                          child: _QuickActionButton(
                            icon: Icons.assignment_outlined,
                            iconColor: Color(0xFFF59E0B),
                            bgColor: Color(0xFFFFFBEB),
                            label: 'Exams',
                          ),
                        ),
                        // ------------------ reports
                        // _QuickActionButton(
                        //   icon: Icons.bar_chart,
                        //   iconColor: Color(0xFF2563EB),
                        //   bgColor: Color(0xFFEFF6FF),
                        //   label: 'Reports',
                        // ),
                        // _QuickActionButton(
                        //   icon: Icons.note_add_outlined,
                        //   iconColor: Color(0xFFF59E0B),
                        //   bgColor: Color(0xFFFFFBEB),
                        //   label: 'Upload QA File',
                        // ),
                        _QuickActionButton(
                          icon: Icons.settings_outlined,
                          iconColor: Color(0xFF3B82F6),
                          bgColor: Color(0xFFEFF6FF),
                          label: 'Settings',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Recent Exams Section Header
                const Text(
                  'Recent Exams',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),

                // Recent Exams List Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: const [
                      _ExamListItem(
                        title: 'Maths Mid Term',
                        dateTime: '24 May 2025 • 10:00 AM',
                        status: 'Active',
                        statusBgColor: Color(0xFFE6F4EA),
                        statusTextColor: Color(0xFF1E8E3E),
                        iconColor: Color(0xFF8B5CF6),
                      ),
                      Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _ExamListItem(
                        title: 'Physics Quiz',
                        dateTime: '22 May 2025 • 02:00 PM',
                        status: 'Upcoming',
                        statusBgColor: Color(0xFFE8F0FE),
                        statusTextColor: Color(0xFF1A73E8),
                        iconColor: Color(0xFF3B82F6),
                      ),
                      Divider(height: 1, color: Color(0xFFF1F5F9)),
                      _ExamListItem(
                        title: 'Chemistry Test',
                        dateTime: '20 May 2025 • 11:00 AM',
                        status: 'Completed',
                        statusBgColor: Color(0xFFF1F5F9),
                        statusTextColor: Color(0xFF64748B),
                        iconColor: Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // View All Link
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(offset: Offset(0, 5), blurRadius: 10, color: Colors.grey),
        ],
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;

  const _QuickActionButton({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamListItem extends StatelessWidget {
  final String title;
  final String dateTime;
  final String status;
  final Color statusBgColor;
  final Color statusTextColor;
  final Color iconColor;

  const _ExamListItem({
    required this.title,
    required this.dateTime,
    required this.status,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description_outlined, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
