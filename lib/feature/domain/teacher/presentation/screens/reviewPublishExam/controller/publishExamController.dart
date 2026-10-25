import 'dart:developer';
import 'package:get/get.dart';
import "package:provider/provider.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/controller/create_exam_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/fileUpload/controller/file_upload_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/manualQuestions/controller/question_controller.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/exam_details_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class Publishexamcontroller extends ChangeNotifier {
  bool isLoad = false;
  final firestore = FirebaseFirestore.instance;

  Future<void> publishExam(
    BuildContext context, [
    List<QAModel>? explicitQuestions,
  ]) async {
    final tData = teacherData;
    final details = examDetails;
    if (tData == null || details == null) {
      _error(context, 'Teacher session or exam details are missing.');
      return;
    }
    List<QAModel> questions = explicitQuestions ?? const [];
    if (questions.isEmpty) {
      try {
        final qc = context.read<QuestionController>();
        if (qc.questions.isNotEmpty) {
          questions = qc.questions;
        }
      } catch (_) {}
    }
    if (questions.isEmpty) {
      questions = context.read<FileUploadController>().questions;
    }
    if (questions.isEmpty) {
      _error(
        context,
        'No questions to publish. Please add questions before publishing.',
      );
      return;
    }
    // Re-read the students from Firestore before publishing. This prevents
    // stale/legacy IDs from being written into assigned_student_ids.
    final studentSnap = await teacherRefStudents(tData.id.trim()).get();
    final validStudentIds = studentSnap.docs
        .map(
          (doc) => (doc.data()['id'] ?? doc.data()['student_id'] ?? doc.id)
              .toString()
              .trim(),
        )
        .where((id) => id.isNotEmpty)
        .toSet();

    final validBatchStudentIds = studentSnap.docs
        .where(
          (doc) => StudentModel.isSameBatch(
            (doc.data()['batch'] ?? '').toString(),
            details.batch,
          ),
        )
        .map(
          (doc) => (doc.data()['id'] ?? doc.data()['student_id'] ?? doc.id)
              .toString()
              .trim(),
        )
        .where((id) => id.isNotEmpty)
        .toSet();

    final assignedIds =
        details.assignedStudentIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
          ..retainAll(validStudentIds)
          ..retainAll(validBatchStudentIds);

    if (assignedIds.isEmpty) {
      _error(context, 'No valid students are selected for this batch.');
      return;
    }

    if (assignedIds.length != details.assignedStudentIds.length) {
      _error(
        context,
        'Some selected student IDs are invalid or belong to another batch. Please go back and select the students again.',
      );
      return;
    }

    if (isLoad) return;

    isLoad = true;
    notifyListeners();
    try {
      final teacherRef = firestore.collection('user').doc(tData.id.trim());
      final sequence = await firestore.runTransaction<int>((tx) async {
        final snap = await tx.get(teacherRef);
        final current =
            int.tryParse(
              (snap.data()?['last_exam_id'] ?? tData.lastExamId).toString(),
            ) ??
            0;
        final next = current + 1;
        tx.set(teacherRef, {
          'last_exam_id': next.toString(),
        }, SetOptions(merge: true));
        return next;
      });

      final examId = generateExamId(tData.name, sequence);
      final exam = ExamModel(
        examId: examId,
        examName: details.examName,
        fullMarks: details.fullMarks,
        examKey: details.examKey,
        instruction: details.instruction,
        batch: details.batch,
        examStart: details.examStart,
        examEnd: details.examEnd,
        questions: List.from(questions),
        resultPublished: false,
        assignedStudentIds: assignedIds.toList(growable: false),
        teacherId: tData.id.trim(),
        teacherName: tData.name.trim(),
      );

      await teacherRef.collection('exams').doc(examId).set(exam.toJson());
      tData.lastExamId = sequence.toString();
      TeacherData.updateTeacherLocalData();

      examDetails = null;
      try {
        context.read<FileUploadController>().cancelFile();
      } catch (_) {}
      try {
        context.read<QuestionController>().clearAll();
      } catch (_) {}
      context.read<CreateExamController>().clearAll();
      isLoad = false;
      notifyListeners();

      if (!context.mounted) return;
      customSnackbar(
        context: context,
        message: 'Exam published successfully',
        color: Colors.green,
        ico: Icons.done,
      );
      Get.offAllNamed(AppRoutes.teacherDashboard);
    } catch (e, st) {
      log('Publish exam error', error: e, stackTrace: st);
      isLoad = false;
      notifyListeners();
      if (context.mounted)
        _error(context, 'Could not publish the exam. Please try again.');
    }
  }

  CollectionReference<Map<String, dynamic>> teacherRefStudents(
    String teacherDocumentId,
  ) {
    return firestore
        .collection('user')
        .doc(teacherDocumentId.trim())
        .collection('students');
  }

  Future<void> setResultPublished({
    required String examId,
    required bool published,
  }) async {
    final teacherId = teacherData?.id.trim();
    if (teacherId == null || teacherId.isEmpty)
      throw StateError('Teacher session not found');
    await firestore
        .collection('user')
        .doc(teacherId)
        .collection('exams')
        .doc(examId)
        .update({
          'result_published': published,
          'result_published_at': published
              ? FieldValue.serverTimestamp()
              : FieldValue.delete(),
        });
    notifyListeners();
  }

  void _error(BuildContext context, String message) {
    if (!context.mounted) return;
    customSnackbar(
      context: context,
      message: message,
      color: Colors.red,
      ico: Icons.error,
    );
  }

  static String generateExamId(String teacherName, int sequence) {
    final clean = teacherName.trim();
    final prefix =
        (clean.length >= 2 ? clean.substring(0, 2) : clean.padRight(2, 'T'))
            .toUpperCase();
    final now = DateTime.now();
    return '${prefix}EX${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${sequence.toString().padLeft(3, '0')}';
  }
}
