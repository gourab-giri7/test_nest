import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // -------------- next
  void next(BuildContext context) {
    if (examKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FileUploadScreen()),
      );
    }
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
