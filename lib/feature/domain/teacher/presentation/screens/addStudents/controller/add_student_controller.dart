import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_nest/core/services/fee_service.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';

class AddStudentController extends ChangeNotifier {
  final firestore = FirebaseFirestore.instance;

  final studentkey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController monthlyFeeController = TextEditingController();
  final TextEditingController batchController = TextEditingController();

  String selectedBatche = "select_batch";
  List<String> allBatches = [];
  bool isLoading = false;

  void init() {
    selectedBatche = "select_batch";
    allBatches = List<String>.from(teacherData?.batch ?? []);
    fullNameController.clear();
    monthlyFeeController.clear();
    batchController.clear();
    getNewId();
    notifyListeners();
  }

  // - create new id
  void getNewId() {
    final tData = teacherData;
    if (tData == null) return;
    final int currentSeq = int.tryParse(tData.lastStdId) ?? 0;
    studentIdController.text = generateStudentId(tData.name, currentSeq + 1);
    notifyListeners();
  }

  // ---------------- validators
  String? feeValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Monthly fee is optional, defaults to 0
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return "Please enter a valid fee amount";
    }
    return null;
  }

  String? validator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Fill this field before submit";
    }
    return null;
  }

  // ------------- unique id create
  static String generateStudentId(String teacherName, int sequence) {
    final cleanName = teacherName.trim();
    final prefix =
        (cleanName.length >= 2
                ? cleanName.substring(0, 2)
                : cleanName.padRight(2, 'T'))
            .toUpperCase();
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final number = sequence.toString().padLeft(3, '0');
    return '$prefix$year$month$number';
  }

  Future<void> addStudent(BuildContext context) async {
    customSnackbar(
      context: context,
      message:
          "Manual student account creation is disabled. Students must register and join through your batch joining codes.",
      color: Colors.red,
      ico: Icons.info_outline,
    );
  }

  // ---------------------- dialog feature
  void selectBatch(int index) {
    if (index >= 0 && index < allBatches.length) {
      selectedBatche = allBatches[index];
      notifyListeners();
    }
  }

  Future<void> addbatch(String batchName, BuildContext context) async {
    final tData = teacherData;
    if (tData == null) return;
    final trimmedName = batchName.trim();
    if (trimmedName.isEmpty) return;

    if (!allBatches.contains(trimmedName)) {
      allBatches.add(trimmedName);
      tData.batch = allBatches;
      TeacherData.updateTeacherLocalData();
      try {
        await firestore.collection("user").doc(tData.id).update({
          "batch": tData.batch,
        });
      } catch (e) {
        log("Error updating batch in Firestore: $e");
        if (context.mounted) {
          customSnackbar(
            context: context,
            message: "Something went wrong saving the batch",
            color: Colors.orange,
            ico: Icons.info,
          );
        }
      }
      notifyListeners();
    }
  }

  void allClear() {
    fullNameController.clear();
    monthlyFeeController.clear();
    batchController.clear();
    selectedBatche = "select_batch";
    allBatches = List<String>.from(teacherData?.batch ?? []);
    getNewId();
    notifyListeners();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    studentIdController.dispose();
    monthlyFeeController.dispose();
    batchController.dispose();
    super.dispose();
  }
}
