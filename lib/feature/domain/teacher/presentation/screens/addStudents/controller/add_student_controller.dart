import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    final tData = teacherData;
    if (tData == null) {
      customSnackbar(
        context: context,
        message: "Teacher session not found. Please log in again.",
        color: Colors.red,
        ico: Icons.error,
      );
      return;
    }

    if (!studentkey.currentState!.validate()) return;

    if (batchController.text.trim().isEmpty ||
        batchController.text.trim() == "select_batch") {
      customSnackbar(
        context: context,
        message: "Please select a batch for the student",
        color: Colors.red,
        ico: Icons.error,
      );
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      final teacherRef = firestore.collection('user').doc(tData.id.trim());
      final batch = batchController.text.trim();
      final name = fullNameController.text.trim();
      final feeAmount = double.tryParse(monthlyFeeController.text.trim()) ?? 0.0;

      // Reserve the sequence and create the student atomically. This prevents
      // two quick/parallel student creations from receiving the same ID.
      final newStudentId = await firestore.runTransaction<String>((tx) async {
        final teacherSnap = await tx.get(teacherRef);
        final currentSeq =
            int.tryParse(
              (teacherSnap.data()?['last_std_id'] ?? tData.lastStdId)
                  .toString(),
            ) ??
            0;
        final nextSeq = currentSeq + 1;

        final generatedId = generateStudentId(tData.name, nextSeq);
        final studentRef = teacherRef.collection('students').doc(generatedId);
        final studentSnap = await tx.get(studentRef);

        if (studentSnap.exists) {
          throw StateError('Generated student ID already exists: $generatedId');
        }

        tx.set(studentRef, {
          'batch': batch,
          'id': generatedId,
          'name': name,
          'password': '',
          'monthly_fee': feeAmount,
          // Always store the actual Firestore teacher document ID.
          'teacher_id': teacherRef.id,
          'teacher_name': tData.name.trim(),
          'created_at': FieldValue.serverTimestamp(),
        });

        tx.set(teacherRef, {
          'last_std_id': nextSeq.toString(),
        }, SetOptions(merge: true));

        return generatedId;
      });

      // If monthly fee is configured, ensure the fee record for the current month exists
      if (feeAmount > 0) {
        try {
          await FeeService.ensureFeeRecord(
            teacherId: teacherRef.id,
            studentId: newStudentId,
            studentName: name,
            batch: batch,
            amountDue: feeAmount,
          );
        } catch (feeError) {
          log("Warning: could not initialize first fee record: $feeError");
        }
      }

      final generatedSequence = int.tryParse(
        RegExp(r'(\d+)$').firstMatch(newStudentId)?.group(1) ?? '',
      );
      if (generatedSequence != null) {
        tData.lastStdId = generatedSequence.toString();
      }
      TeacherData.updateTeacherLocalData();

      isLoading = false;
      notifyListeners();

      if (!context.mounted) return;
      customSnackbar(
        context: context,
        message: "Student added successfully",
        color: Colors.green,
        ico: Icons.done,
      );

      Navigator.pop(context);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      log("Error adding student: $e");
      if (!context.mounted) return;
      customSnackbar(
        context: context,
        message: "Something went wrong, please try again later",
        color: Colors.red,
        ico: Icons.info,
      );
    }
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
