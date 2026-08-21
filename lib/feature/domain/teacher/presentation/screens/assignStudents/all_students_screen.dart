import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/teacher/data/datasources/get_student_data.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/addStudents/add_students_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/allStudents/controller/student_controller.dart';

class AllStudentsScreen extends StatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> {
  // final TextEditingController _searchController = TextEditingController();
  List<DropdownMenuItem<String>> drowpdownitems = [];
  @override
  void initState() {
    drowpdownitems = teacherData.batch.map((batch) {
      return DropdownMenuItem(value: batch, child: Text(batch));
    }).toList();
    context.read<StudentController>().dropDownvalue = "all";
    super.initState();
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
          'All Student',
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: GetStudentData.getAllStudent(),
              builder: (context, asyncSnapshot) {
                // ----- is wating
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }

                // -------- is no data
                if (asyncSnapshot.hasError) {
                  return Center(
                    child: Text(
                      "we are faceing some technicall issue please try agan later",
                    ),
                  );
                }
                context.read<StudentController>().studentsData =
                    asyncSnapshot.data!.docs;
                context.read<StudentController>().mainData =
                    asyncSnapshot.data!.docs;
                return Consumer<StudentController>(
                  builder: (context, controller, child) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Field
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              // controller: _searchController,
                              onChanged: controller.search,
                              decoration: InputDecoration(
                                hintText: 'Search Students',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey[400],
                                  size: 22,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFFAFCFF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              width: 50,
                              child: DropdownButton(
                                value: controller.dropDownvalue,
                                items: [
                                  DropdownMenuItem(
                                    value: "all",
                                    child: Text("all"),
                                  ),
                                  ...drowpdownitems,
                                ],
                                onChanged: (value) {
                                  controller.filter(value!);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Scrollable Student Cards
                      Expanded(
                        child:
                            // -------- is no data
                            (!asyncSnapshot.hasData ||
                                asyncSnapshot.data!.docs.isEmpty)
                            ? Center(child: Text("No Student found"))
                            :
                              //  _filteredStudents.isEmpty
                              //     ? Center(
                              //         child: Text(
                              //           'No students found',
                              //           style: TextStyle(color: Colors.grey[500]),
                              //         ),
                              //       )
                              //     :
                              ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: controller.studentsData.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  // log(
                                  //   controller.studentsData.length.toString(),
                                  // );
                                  final data = controller.studentsData[index]
                                      .data();
                                  // log(data.toString());
                                  final student = StudentModel.fromJson(data);
                                  return _buildStudentCard(student);
                                },
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Add Student Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddStudentScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Add Student',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Circular Image / Placeholder
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFEF3C7),
            child: Icon(Icons.person, color: Colors.amber[800], size: 28),
          ),
          const SizedBox(width: 16),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "ID: ${student.id}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  "Batch: ${student.batch}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Arrow Icon
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
        ],
      ),
    );
  }
}
