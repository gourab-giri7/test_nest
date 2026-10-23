import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examDetails/exam_details_screen.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/create_exam_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/allStudents/all_students_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/exams/teacher_exam_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/feeManagement/controller/fee_management_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/feeManagement/fee_management_screen.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/model/exam_model.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _currentNavIndex = 0;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _studentsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _examsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _recentExamsStream;
  String _cachedTeacherId = '';

  void _initStreams(String teacherId) {
    if (_cachedTeacherId == teacherId && _studentsStream != null) return;
    _cachedTeacherId = teacherId;
    _studentsStream = FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('students')
        .snapshots();
    _examsStream = FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('exams')
        .snapshots();
    _recentExamsStream = FirebaseFirestore.instance
        .collection('user')
        .doc(teacherId)
        .collection('exams')
        .orderBy('exam_id', descending: true)
        .limit(4)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    if (teacherData == null) {
      final teacherString = pref.getString("teacherData");
      if (teacherString != null && teacherString.trim().isNotEmpty) {
        try {
          teacherData = TeacherData.fromJson(jsonDecode(teacherString));
        } catch (e) {
          log("Decode error: $e");
        }
      }
    }
    if (teacherData != null) {
      _initStreams(teacherData!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tData = teacherData;
    if (tData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Test Nest')),
        body: const Center(
          child: Text('Session expired. Please log in again.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Header (Blue Gradient with Good Morning & Avatar)
            _buildTopHeader(tData),

            // Content Overlapping Header
            Transform.translate(
              offset: const Offset(0, -32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Floating 4 Metrics Stats Card (Screen 4)
                        _buildFloatingMetricsCard(tData),
                        const SizedBox(height: 24),

                        // Quick Actions Section (2x2 Grid)
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildQuickActionsGrid(context),
                        const SizedBox(height: 24),

                        // Promotional Banner Card (Screen 4)
                        _buildBannerCard(context),
                        const SizedBox(height: 24),

                        // Recent Exams Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Exams',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TeacherExamsScreen(),
                                ),
                              ),
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Recent Exams Stream List
                        _buildRecentExamsStream(tData),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildTopHeader(TeacherData tData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 54, bottom: 58, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tData.name.isNotEmpty ? '${tData.name}!' : 'Teacher!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF2563EB), size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingMetricsCard(TeacherData tData) {
    _initStreams(tData.id);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _studentsStream,
      builder: (context, studentSnap) {
        final studentCount = studentSnap.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _examsStream,
          builder: (context, examSnap) {
            final examDocs = examSnap.data?.docs ?? [];
            final totalExams = examDocs.length;

            final exams = examDocs
                .map((d) => ExamModel.fromJson(d.data()))
                .toList();
            final activeCount = exams.where((e) => e.status == 'Active').length;
            final completedCount = exams
                .where((e) => e.status == 'Completed')
                .length;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _statItem(
                    'Students',
                    studentCount.toString(),
                    const Color(0xFF2563EB),
                  ),
                  _vDivider(),
                  _statItem(
                    'Exams',
                    totalExams.toString(),
                    const Color(0xFFEF4444),
                  ),
                  _vDivider(),
                  _statItem(
                    'Active',
                    activeCount.toString(),
                    const Color(0xFF10B981),
                  ),
                  _vDivider(),
                  _statItem(
                    'Completed',
                    completedCount.toString(),
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(width: 1, height: 32, color: const Color(0xFFF1F5F9));
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.5,
          children: [
            // Students Action Card
            _actionCard(
              title: 'Students',
              subtitle: 'Manage students',
              icon: Icons.people_alt_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllStudentsScreen()),
              ),
            ),
            // Create Exam Action Card
            _actionCard(
              title: 'Create Exam',
              subtitle: 'Add new exam',
              icon: Icons.edit_note_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateExamScreen()),
              ),
            ),
            // Exams Action Card
            _actionCard(
              title: 'Exams',
              subtitle: 'View all exams',
              icon: Icons.assignment_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeacherExamsScreen()),
              ),
            ),
            // Fee Management Action Card
            _actionCard(
              title: 'Fee Records',
              subtitle: 'Monthly fees & dues',
              icon: Icons.account_balance_wallet_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
              ),
              onTap: () {
                final t = teacherData;
                if (t == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => FeeManagementController(
                        teacherId: t.id,
                        teacherName: t.name,
                      ),
                      child: const FeeManagementScreen(),
                    ),
                  ),
                );
              },
            ),
            // Results Action Card
            _actionCard(
              title: 'Results',
              subtitle: 'Check results',
              icon: Icons.insert_chart_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeacherExamsScreen()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Create Engaging Exams',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Build better assessments for your students',
                  style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateExamScreen()),
            ),
            child: const Text(
              'Create',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExamsStream(TeacherData tData) {
    _initStreams(tData.id);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _recentExamsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                "No exams created yet. Tap 'Create Exam' to get started.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          );
        }

        final exams = docs.map((d) => ExamModel.fromJson(d.data())).toList();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              for (int i = 0; i < exams.length; i++) ...[
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExamDetailsScreen(exam: exams[i]),
                      ),
                    );
                  },
                  child: _buildRecentExamItem(exams[i]),
                ),
                if (i < exams.length - 1)
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentExamItem(ExamModel exam) {
    final statusColor = exam.status == 'Completed'
        ? const Color(0xFF059669)
        : (exam.status == 'Active'
              ? const Color(0xFF2563EB)
              : const Color(0xFFD97706));
    final statusBg = exam.status == 'Completed'
        ? const Color(0xFFECFDF5)
        : (exam.status == 'Active'
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFFFFBEB));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.examName.isNotEmpty ? exam.examName : "Untitled Exam",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${exam.examDate} • ${exam.startTime}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              exam.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Home', () {}),
              _navItem(1, Icons.people_alt_rounded, 'Students', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllStudentsScreen()),
                );
              }),
              _navItem(2, Icons.assignment_rounded, 'Exams', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherExamsScreen()),
                );
              }),
              _navItem(3, Icons.account_balance_wallet_rounded, 'Fees', () {
                final t = teacherData;
                if (t == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => FeeManagementController(
                        teacherId: t.id,
                        teacherName: t.name,
                      ),
                      child: const FeeManagementScreen(),
                    ),
                  ),
                );
              }),
              _navItem(4, Icons.logout_rounded, 'Logout', () {
                _showLogoutDialog(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, VoidCallback onTap) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentNavIndex = index);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // Resolve the provider before closing the dialog. The dialog
              // context becomes deactivated immediately after pop().
              final loginController = context.read<LoginController>();

              Navigator.of(dialogCtx).pop();

              loginController.logout(context);
            },
            child: const Text(
              "Logout",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
