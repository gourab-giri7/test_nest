import 'package:flutter/material.dart';

class ExamItem {
  final String title;
  final String dateTime;
  final String score;
  final String maxScore;
  final String status; // 'completed' or 'upcoming'

  ExamItem({
    required this.title,
    required this.dateTime,
    required this.score,
    required this.maxScore,
    required this.status,
  });
}

class ExamHistoryScreen extends StatefulWidget {
  const ExamHistoryScreen({super.key});

  @override
  State<ExamHistoryScreen> createState() => _ExamHistoryScreenState();
}

class _ExamHistoryScreenState extends State<ExamHistoryScreen> {
  int _selectedTabIndex = 0; // 0: All, 1: Completed, 2: Upcoming

  final List<ExamItem> _allExams = [
    ExamItem(
      title: 'Mathematics Mid Term',
      dateTime: '24 May 2025 • 10:00 AM',
      score: '92',
      maxScore: '100',
      status: 'completed',
    ),
    ExamItem(
      title: 'Physics Quiz',
      dateTime: '20 May 2025 • 02:00 PM',
      score: '85',
      maxScore: '100',
      status: 'completed',
    ),
    ExamItem(
      title: 'Chemistry Test',
      dateTime: '15 May 2025 • 11:00 AM',
      score: '78',
      maxScore: '100',
      status: 'completed',
    ),
    ExamItem(
      title: 'English Test',
      dateTime: '10 May 2025 • 09:00 AM',
      score: '88',
      maxScore: '100',
      status: 'completed',
    ),
  ];

  List<ExamItem> get _filteredExams {
    if (_selectedTabIndex == 1) {
      return _allExams.where((e) => e.status == 'completed').toList();
    } else if (_selectedTabIndex == 2) {
      return _allExams.where((e) => e.status == 'upcoming').toList();
    }
    return _allExams;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.blueGrey[50],
        centerTitle: true,
        title: const Text(
          'Exam History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Bar
                // Row(
                //   children: [
                //     IconButton(
                //       icon: const Icon(Icons.arrow_back),
                //       onPressed: () {},
                //       padding: EdgeInsets.zero,
                //       constraints: const BoxConstraints(),
                //       color: const Color(0xFF1E293B),
                //     ),
                //     const SizedBox(width: 16),
                //     const Text(
                //       'Exam History',
                //       style: TextStyle(
                //         fontSize: 20,
                //         fontWeight: FontWeight.bold,
                //         color: Color(0xFF0F172A),
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 24),

                // Segmented Filter Tabs
                Container(
                  // padding: const EdgeInsets.all(4),
                  // decoration: BoxDecoration(
                  //   color: const Color(0xFFFAFCFF),
                  //   borderRadius: BorderRadius.circular(16),
                  //   border: Border.all(color: const Color(0xFFF1F5F9)),
                  // ),
                  child: Row(
                    children: [
                      _buildTabButton('All', 0),
                      _buildTabButton('Completed', 1),
                      _buildTabButton('Upcoming', 2),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Exams List
                Expanded(
                  child: _filteredExams.isEmpty
                      ? Center(
                          child: Text(
                            'No exams found',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredExams.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final exam = _filteredExams[index];
                            return _buildExamCard(
                              exam,
                              isHighlighted: index == 0,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamItem exam, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exam.dateTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Right Score Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Score',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: exam.score,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    TextSpan(
                      text: '/${exam.maxScore}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
