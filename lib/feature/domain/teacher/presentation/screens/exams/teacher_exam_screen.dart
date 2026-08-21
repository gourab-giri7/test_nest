import 'package:flutter/material.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen> {
  final TextEditingController searchController = TextEditingController();

  String selectedFilter = "All";

  final List<Map<String, dynamic>> exams = [
    {
      "name": "Computer Hardware",
      "id": "EXM-2608-001",
      "date": "20 Aug 2026",
      "time": "10:00 AM - 11:00 AM",
      "batch": "Class 12",
      "students": 35,
      "marks": 100,
      "status": "Upcoming",
    },
    {
      "name": "Database Management",
      "id": "EXM-2608-002",
      "date": "18 Aug 2026",
      "time": "11:00 AM - 12:00 PM",
      "batch": "Class 11",
      "students": 28,
      "marks": 50,
      "status": "Upcoming",
    },
    {
      "name": "Programming Fundamentals",
      "id": "EXM-2608-003",
      "date": "10 Aug 2026",
      "time": "10:00 AM - 11:00 AM",
      "batch": "Class 12",
      "students": 32,
      "marks": 100,
      "status": "Completed",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[50],
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Exams",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Manage your exams",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                // Navigate to Create Exam
              },
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildSummary(),

                const SizedBox(height: 18),

                _buildSearch(),

                const SizedBox(height: 14),

                _buildFilters(),

                const SizedBox(height: 18),

                Expanded(child: _buildExamList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final upcoming = exams.where((exam) => exam["status"] == "Upcoming").length;

    final completed = exams
        .where((exam) => exam["status"] == "Completed")
        .length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.event_available_rounded,
            title: "Upcoming",
            value: upcoming.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.task_alt_rounded,
            title: "Completed",
            value: completed.toString(),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: Color(0xFF2563EB),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: searchController,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: "Search exam by name or ID",
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ["All", "Upcoming", "Completed"];

    return Row(
      children: filters.map((filter) {
        final selected = selectedFilter == filter;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
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
    );
  }

  Widget _buildExamList() {
    final search = searchController.text.toLowerCase();

    final filtered = exams.where((exam) {
      final matchesSearch =
          exam["name"].toString().toLowerCase().contains(search) ||
          exam["id"].toString().toLowerCase().contains(search);

      final matchesFilter =
          selectedFilter == "All" || exam["status"] == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 50, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              "No exams found",
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

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildExamCard(filtered[index]);
      },
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam) {
    final isUpcoming = exam["status"] == "Upcoming";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam["name"]?.toString() ?? "Untitled Exam",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exam["id"]?.toString() ?? "",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _statusBadge(exam["status"]?.toString() ?? "", isUpcoming),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          const SizedBox(height: 14),

          // Date
          _infoItem(
            Icons.calendar_today_outlined,
            exam["date"]?.toString() ?? "",
          ),

          const SizedBox(height: 10),

          // Time
          _infoItem(Icons.access_time_rounded, exam["time"]?.toString() ?? ""),

          const SizedBox(height: 10),

          // Batch
          _infoItem(
            Icons.groups_outlined,
            "${exam["batch"] ?? ""} • ${exam["students"] ?? 0} Students",
          ),

          const SizedBox(height: 10),

          // Marks
          _infoItem(Icons.star_outline_rounded, "${exam["marks"] ?? 0} Marks"),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () {
                // Open exam details
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
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
                    style: TextStyle(fontWeight: FontWeight.w600),
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

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status, bool isUpcoming) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isUpcoming ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUpcoming
                  ? const Color(0xFF10B981)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isUpcoming
                  ? const Color(0xFF047857)
                  : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
