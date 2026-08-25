import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/teacher/data/models/Q&A_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/fileUpload/controller/file_upload_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/reviewPublishExam/review_publish_screen.dart';

class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<FileUploadController>().cancelFile();
    });
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
          "Upload QA File",
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
                  // File Upload Box with Dotted Border styling
                  Consumer<FileUploadController>(
                    builder: (context, controller, child) => GestureDetector(
                      onTap: () => controller.pickFile(context),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: controller.slectedFileName != null
                            ? Column(
                                mainAxisAlignment: .center,
                                children: [
                                  Row(
                                    spacing: 5,
                                    mainAxisAlignment: .center,
                                    children: [
                                      Icon(
                                        Icons.upload_file_sharp,
                                        color: Colors.blue,
                                      ),
                                      Text(
                                        controller.slectedFileName!,
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () => controller.cancelFile(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(color: Colors.red),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      "Cancel",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                spacing: 5,
                                mainAxisAlignment: .center,
                                children: [
                                  Row(
                                    spacing: 5,
                                    mainAxisAlignment: .center,
                                    children: [
                                      Icon(
                                        Icons.upload_file_sharp,
                                        color: Colors.blue,
                                      ),
                                      Text(
                                        "Click to upload Q&A excell file",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "NOTE : File should be the bellow formate",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final success =
                              await FileUploadController.downloadTemplate();

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Template saved successfully'
                                    : 'Template download cancelled',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 5,
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(10),
                          ),
                        ),
                        child: Text(
                          "Download template file",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Guidelines Card Section
                  Consumer<FileUploadController>(
                    builder: (context, controller, child) =>
                        controller.questions.isNotEmpty
                        ? Column(children: [...questionsList(context)])
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'File Guidelines',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildGuidelineItem(
                                  'Only .xlsx files are allowed',
                                ),
                                _buildGuidelineItem(
                                  'Sheet formate should be same as the sample sheet',
                                ),
                                _buildGuidelineItem(
                                  'Format: Question, Option A, Option B, Option C, Option D, Answer',
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),

                  // Submit / Action Button
                  SizedBox(
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewPublishScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Save & Preview',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> questionsList(BuildContext context) {
    List<Widget> list = [];
    for (
      int i = 0;
      i < context.read<FileUploadController>().questions.length;
      i++
    ) {
      list.add(
        _buildQuestioncard(
          data: context.read<FileUploadController>().questions[i],
        ),
      );
    }
    return list;
  }

  Widget _buildQuestioncard({required QAModel data}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        spacing: 8,
        mainAxisAlignment: .start,
        crossAxisAlignment: .start,
        children: [
          Text(
            "Q. ${data.q}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 8),
          option("A", data.a),
          option("B", data.b),
          option("C", data.c),
          option("D", data.d),
          option("Ans", data.ans),
          // Text("Ans. ${data.ans}"),
        ],
      ),
    );
  }
}

Widget option(String number, String option) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
    width: double.maxFinite,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text.rich(
      TextSpan(
        text: "$number: ",
        style: TextStyle(fontWeight: .bold, fontSize: 15),
        children: [
          TextSpan(
            text: option,
            style: TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    ),
  );
}
