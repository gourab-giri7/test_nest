import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/studentDetails/model/student_exam_submission_summary.dart';
import 'package:test_nest/model/exam_model.dart';

class StudentDetailsController extends ChangeNotifier {
  StudentModel _student;
  final String _teacherId;

  bool _isPasswordVisible = false;
  bool _isLoadingExams = false;
  bool _hasLoaded = false;
  String? _examError;
  List<StudentExamSubmissionSummary> _examHistory = const [];

  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isSendingReset = false;

  StudentDetailsController({required StudentModel student, String? teacherId})
    : _student = student,
      _teacherId = (teacherId != null && teacherId.trim().isNotEmpty)
          ? teacherId.trim()
          : (teacherData?.id.trim() ?? '');

  StudentModel get student => _student;
  String get teacherId => _teacherId;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoadingExams => _isLoadingExams;
  bool get hasLoaded => _hasLoaded;
  String? get examError => _examError;
  List<StudentExamSubmissionSummary> get examHistory => _examHistory;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  bool get isSendingReset => _isSendingReset;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  Future<void> refreshStudentData() async {
    if (_teacherId.isEmpty) return;
    try {
      final docId = (_student.docId != null && _student.docId!.isNotEmpty)
          ? _student.docId!
          : _student.id.trim();
      final snap = await FirebaseFirestore.instance
          .collection('user')
          .doc(_teacherId)
          .collection('students')
          .doc(docId)
          .get();
      if (snap.exists && snap.data() != null) {
        _student = StudentModel.fromJson(snap.data()!, docId: snap.id);
        notifyListeners();
      }
    } catch (e) {
      log('Error refreshing student data: $e');
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetEmail() async {
    final email = _student.email.trim();
    if (email.isEmpty) {
      return {
        'success': false,
        'message': 'No registered email address found for this student.',
      };
    }

    _isSendingReset = true;
    notifyListeners();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _isSendingReset = false;
      notifyListeners();
      return {
        'success': true,
        'message': 'Password reset link sent to $email.',
      };
    } on FirebaseAuthException catch (e) {
      _isSendingReset = false;
      notifyListeners();
      return {
        'success': false,
        'message': e.message ?? 'Failed to send password reset email.',
      };
    } catch (e) {
      _isSendingReset = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Failed to send password reset email: $e',
      };
    }
  }

  Future<void> loadExamHistory({bool forceRefresh = false}) async {
    if (_teacherId.isEmpty) {
      _examError = 'Teacher information is missing.';
      notifyListeners();
      return;
    }

    if (_isLoadingExams) return;
    if (_hasLoaded && !forceRefresh) return;

    _isLoadingExams = true;
    _examError = null;
    notifyListeners();

    try {
      final studentId = _student.id.trim();
      final firestore = FirebaseFirestore.instance;

      // 1. Fetch exams for this teacher
      final examsSnapshot = await firestore
          .collection('user')
          .doc(_teacherId)
          .collection('exams')
          .get();

      final examDocs = examsSnapshot.docs;

      // 2. Identify candidate exams relevant to this student (assigned or same batch)
      final candidateExams = examDocs
          .where((examDoc) {
            final data = examDoc.data();
            final assignedIds =
                (data['assigned_student_ids'] as List?)
                    ?.map((e) => e.toString().trim())
                    .toSet() ??
                {};
            if (assignedIds.contains(studentId)) return true;

            final batch = (data['batch'] ?? '').toString();
            if (StudentModel.isSameBatch(batch, _student.batch)) return true;

            return false;
          })
          .toList(growable: false);

      final List<StudentExamSubmissionSummary> summaries = [];

      // 3. Sequentially query submissions ONLY for candidate exams (prevents Future.wait concurrency bursts)
      for (final examDoc in candidateExams) {
        try {
          final subDoc = await examDoc.reference
              .collection('submissions')
              .doc(studentId)
              .get();

          if (!subDoc.exists) continue;

          final subData = subDoc.data() ?? {};
          final examData = examDoc.data();

          // Extract lightweight exam metadata without loading or parsing QAModel questions
          final examId =
              (subData['exam_id'] ?? examData['exam_id'] ?? examDoc.id)
                  .toString();
          final examName =
              (subData['exam_name'] ?? examData['exam_name'] ?? 'Exam')
                  .toString();
          final batch =
              (subData['batch'] ?? examData['batch'] ?? _student.batch)
                  .toString();
          final fullMarks =
              (subData['full_marks'] ?? examData['full_marks'] ?? '0')
                  .toString();
          final score = (subData['score'] ?? '0').toString();

          DateTime? examStart;
          final startRaw = examData['exam_start'];
          if (startRaw is Timestamp) {
            examStart = startRaw.toDate();
          } else if (startRaw is String) {
            examStart = DateTime.tryParse(startRaw);
          }

          DateTime? examEnd;
          final endRaw = examData['exam_end'];
          if (endRaw is Timestamp) {
            examEnd = endRaw.toDate();
          } else if (endRaw is String) {
            examEnd = DateTime.tryParse(endRaw);
          }

          DateTime? submittedAt;
          final subRaw = subData['submitted_at'];
          if (subRaw is Timestamp) {
            submittedAt = subRaw.toDate();
          } else if (subRaw is DateTime) {
            submittedAt = subRaw;
          } else {
            submittedAt = examStart;
          }

          final examDateStr = examStart != null
              ? DateFormat('dd-MMM-yyyy').format(examStart)
              : (examData['exam_date']?.toString() ?? '');
          final startTimeStr = examStart != null
              ? DateFormat('hh:mm a').format(examStart)
              : (examData['start_time']?.toString() ?? '');
          final endTimeStr = examEnd != null
              ? DateFormat('hh:mm a').format(examEnd)
              : (examData['end_time']?.toString() ?? '');

          final statusStr =
              (subData['status'] == 'submitted' ||
                  (examEnd != null && DateTime.now().isAfter(examEnd)))
              ? 'Completed'
              : (subData['status']?.toString() ?? 'Completed');

          final totalQuestions = (subData['total_questions'] is num)
              ? (subData['total_questions'] as num).toInt()
              : (examData['questions'] is List
                    ? (examData['questions'] as List).length
                    : 0);

          summaries.add(
            StudentExamSubmissionSummary(
              examId: examId,
              examName: examName,
              examDate: examDateStr,
              startTime: startTimeStr,
              endTime: endTimeStr,
              batch: batch,
              score: score,
              fullMarks: fullMarks,
              status: statusStr,
              submittedAt: submittedAt,
              submissionData: subData,
              totalQuestionsOverride: totalQuestions,
            ),
          );
        } catch (e) {
          log('Error reading submission for candidate exam ${examDoc.id}: $e');
        }
      }

      // 4. Sort by submission date descending (most recent first)
      summaries.sort((a, b) {
        final timeA = a.submittedAt ?? DateTime(1970);
        final timeB = b.submittedAt ?? DateTime(1970);
        return timeB.compareTo(timeA);
      });

      _examHistory = summaries;
      _hasLoaded = true;
      _isLoadingExams = false;
      notifyListeners();
    } catch (e, stack) {
      log('Error loading student exam history: $e\n$stack');
      _isLoadingExams = false;
      _examError = 'Last exam details unavailable.';
      notifyListeners();
    }
  }

  /// Lazy loads full exam model (including questions) on-demand for a single exam
  Future<ExamModel?> loadSingleExam(String examId) async {
    if (_teacherId.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(_teacherId)
          .collection('exams')
          .doc(examId)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return ExamModel.fromJson(doc.data()!);
    } catch (e) {
      log('Error loading full exam details for $examId: $e');
      return null;
    }
  }

  Future<bool> updateStudent({
    required String name,
    required String batch,
    double? monthlyFee,
    String? password,
  }) async {
    final cleanName = name.trim();
    final cleanBatch = batch.trim();

    if (cleanName.isEmpty || cleanBatch.isEmpty) {
      return false;
    }

    if (_teacherId.isEmpty) return false;

    _isUpdating = true;
    notifyListeners();

    try {
      final docId = (_student.docId != null && _student.docId!.isNotEmpty)
          ? _student.docId!
          : _student.id.trim();

      final firestore = FirebaseFirestore.instance;
      final studentRef = firestore
          .collection('user')
          .doc(_teacherId)
          .collection('students')
          .doc(docId);

      final Map<String, dynamic> updateData = {
        'name': cleanName,
        'batch': cleanBatch,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (monthlyFee != null) {
        updateData['monthly_fee'] = monthlyFee;
      }
      if (password != null && password.isNotEmpty) {
        updateData['password'] = password;
      }

      await studentRef.update(updateData);

      _student = _student.copyWith(
        name: cleanName,
        batch: cleanBatch,
        monthlyFee: monthlyFee ?? _student.monthlyFee,
        password: password ?? _student.password,
      );

      _isUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      log('Error updating student: $e');
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent() async {
    if (_teacherId.isEmpty) return false;

    _isDeleting = true;
    notifyListeners();

    try {
      final docId = (_student.docId != null && _student.docId!.isNotEmpty)
          ? _student.docId!
          : _student.id.trim();

      await BatchAndJoinCodeService.removeStudentFromBatch(
        teacherId: _teacherId,
        studentDocId: docId,
        studentAuthUid: _student.authUid,
        batchId: _student.batchId,
      );

      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      log('Error deleting/removing student: $e');
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }
}
