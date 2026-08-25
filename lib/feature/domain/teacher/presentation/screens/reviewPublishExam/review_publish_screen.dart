import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/teacher/data/models/exam_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/fileUpload/controller/file_upload_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/reviewPublishExam/controller/publishExamController.dart';

class ReviewPublishScreen extends StatelessWidget {
  const ReviewPublishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.blueGrey[50],
        centerTitle: true,
        title: const Text(
          'Review & Publish',
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
            padding: const EdgeInsets.all(24.0),
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exam Details Section
                  const Text(
                    'Exam Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Key-Value Details List
                  _buildDetailItem('Exam Name', examDetails.examName),
                  _buildDivider(),
                  _buildDetailItem('Full Marks', examDetails.fullMarks),
                  _buildDivider(),
                  _buildDetailItem(
                    'Date & Time',
                    '${DateFormat('dd MMM yyyy').format(examDetails.examStart)}, '
                        '${DateFormat('hh:mm a').format(examDetails.examStart)} - '
                        '${DateFormat('hh:mm a').format(examDetails.examEnd)}',
                  ),
                  _buildDivider(),
                  _buildDetailItem('Exam Key', examDetails.examKey),
                  _buildDivider(),
                  // _buildDetailItem('Total Questions', '50'),
                  // _buildDivider(),
                  _buildDetailItem('Assigned Students', examDetails.batch),
                  _buildDivider(),

                  // QA File Item with Checkmark Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QA File',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context
                                      .read<FileUploadController>()
                                      .slectedFileName ??
                                  "",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Button
                  Consumer<Publishexamcontroller>(
                    builder: (context, controller, child) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          controller.publishExam(context);
                        },
                        child:controller.isLoad?Center(child: CircularProgressIndicator(color: Colors.white,),): const Text(
                          'Publish Exam',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
  }
}
