import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/exam_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/fileUpload/file_upload_screen.dart';

class CreateExamController extends ChangeNotifier {
  final examKey = GlobalKey<FormState>();
  final TextEditingController examNameController = TextEditingController();
  final TextEditingController fullMarksController = TextEditingController();
  final TextEditingController examDateController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController examKeyController = TextEditingController();
  final TextEditingController instructionsController = TextEditingController();
  DateTime? pickedDate;
  final List<String> classList = teacherData.batch.isEmpty
      ? ["select batch"]
      : teacherData.batch;
  String selectedbatch = teacherData.batch.isEmpty
      ? "select batch"
      : teacherData.batch[0];
  // ------ validetor
  String? nameValidator(String? value) {
    if (value!.isEmpty) {
      return "Fil this fields before submit";
    }
    return null;
  }
  // ------ change batch

  String? marksValidator(String? value) {
    if (value!.isEmpty) {
      return "Fil this fields before submit";
    } else if (int.tryParse(value) == null) {
      return "Enter integer number only";
    } else if (int.parse(value) <= 0) {
      return "Please give valid marks";
    }
    return null;
  }

  void selectExamDate() {
    examDateController.text = DateFormat("dd-MMM-yyyy").format(pickedDate!);
    notifyListeners();
  }

  TimeOfDay? _parseTime(String value) {
  try {
    final date = DateFormat('h:mm a').parse(value);

    return TimeOfDay(
      hour: date.hour,
      minute: date.minute,
    );
  } catch (_) {
    return null;
  }
}

  // -------------- next
 void next(BuildContext context) {
  if (!examKey.currentState!.validate()) {
    return;
  }

  // Check date
  if (pickedDate == null) {
    customSnackbar(
      context: context,
      message: 'Please select exam date.',
      color: Colors.red,
      ico: Icons.error,
    );
    return;
  }

  // Parse start time
  final TimeOfDay? startTime =
      _parseTime(startTimeController.text);

  // Parse end time
  final TimeOfDay? endTime =
      _parseTime(endTimeController.text);

  if (startTime == null || endTime == null) {
    customSnackbar(
      context: context,
      message: 'Please select valid start and end time.',
      color: Colors.red,
      ico: Icons.error,
    );
    return;
  }

  // Create complete exam start DateTime
  final DateTime examStart = DateTime(
    pickedDate!.year,
    pickedDate!.month,
    pickedDate!.day,
    startTime.hour,
    startTime.minute,
  );

  // Create complete exam end DateTime
  final DateTime examEnd = DateTime(
    pickedDate!.year,
    pickedDate!.month,
    pickedDate!.day,
    endTime.hour,
    endTime.minute,
  );

  // End must be after start
  if (!examEnd.isAfter(examStart)) {
    customSnackbar(
      context: context,
      message: 'End time must be after start time.',
      color: Colors.red,
      ico: Icons.error,
    );
    return;
  }

  // Create ExamModel
  examDetails = ExamModel(
    examName: examNameController.text.trim(),
    fullMarks: fullMarksController.text.trim(),
    examKey: examKeyController.text.trim(),
    instruction: instructionsController.text.trim(),
    batch: selectedbatch,
    examStart: examStart,
    examEnd: examEnd,
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const FileUploadScreen(),
    ),
  );
}
  void clearAll() {
    examNameController.clear();
    fullMarksController.clear();
    examDateController.clear();
    startTimeController.clear();
    endTimeController.clear();
    examKeyController.clear();
    instructionsController.clear();
    selectedbatch = teacherData.batch.isEmpty
        ? "select batch"
        : teacherData.batch[0];
  }
}
