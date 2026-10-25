import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/routes/app_routes.dart';

enum SubmissionReason { manual, timeExpired, appClosed, focusLost, reassigned }

class TakeExamController extends ChangeNotifier {
  final ExamModel exam;

  /// Shuffled question list generated once per attempt.
  /// Remains stable during the single attempt session.
  late final List<QAModel> shuffledQuestions;

  int currentIndex = 0;

  /// Answers mapped strictly by stable question ID.
  final Map<String, String> selectedAnswers = {};

  /// Questions marked for review by question ID.
  final Set<String> markedQuestionIds = {};

  Timer? _timer;
  Timer? _abandonmentTimer;
  Timer? _autosaveTimer;
  Duration remaining = Duration.zero;

  bool isSubmitting = false;
  bool isSubmitted = false;

  bool wasOutside = false;
  int focusLossCount = 0;

  /// Configurable maximum allowed focus losses (3 allowed, auto-submits on 4th).
  int allowedFocusLosses = 3;

  String get _attemptStorageKey =>
      'attempt_${studentData?.id ?? ""}_${exam.examId}';

  late final ValueNotifier<Duration> remainingNotifier;
  BuildContext? _lastContext;

  TakeExamController(this.exam) {
    // 1. Shuffle questions once per attempt.
    shuffledQuestions = List<QAModel>.from(exam.questions)..shuffle();

    // 2. Initialize timer with actual wall-clock difference.
    final end = exam.examEnd;
    if (end == null) {
      remaining = const Duration(hours: 1);
    } else {
      final diff = end.difference(DateTime.now());
      remaining = diff.isNegative ? Duration.zero : diff;
    }
    remainingNotifier = ValueNotifier<Duration>(remaining);

    _startTimer();
    _restoreProgress();

    // Periodic autosave every 10 seconds
    _autosaveTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _saveProgress(),
    );
  }

  Future<void> _restoreProgress() async {
    final s = studentData;
    if (s == null) return;
    try {
      // 1. Try local storage first for quick restore
      final localJson = pref.getString(_attemptStorageKey);
      if (localJson != null && localJson.isNotEmpty) {
        final decoded = jsonDecode(localJson);
        if (decoded is Map<String, dynamic>) {
          if (decoded['focus_loss_count'] is num) {
            focusLossCount = (decoded['focus_loss_count'] as num).toInt();
          }
          if (decoded['answers'] is Map) {
            final ansMap = Map<String, dynamic>.from(decoded['answers']);
            ansMap.forEach((k, v) => selectedAnswers[k] = v.toString());
          }
        }
      }

      // 2. Also check Firestore active attempt
      final resolvedTeacherId = exam.teacherId.isNotEmpty
          ? exam.teacherId
          : s.teacherId.trim();
      final resolvedStudentId = s.getStudentIdForTeacher(resolvedTeacherId);

      final draftDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(resolvedTeacherId)
          .collection('exams')
          .doc(exam.examId)
          .collection('active_attempts')
          .doc(resolvedStudentId)
          .get();

      if (draftDoc.exists && draftDoc.data() != null) {
        final data = draftDoc.data()!;
        final remoteFocusCount =
            (data['focus_loss_count'] as num?)?.toInt() ?? 0;
        if (remoteFocusCount > focusLossCount) {
          focusLossCount = remoteFocusCount;
        }
        if (data['answers'] is Map) {
          final ansMap = Map<String, dynamic>.from(data['answers']);
          ansMap.forEach((k, v) => selectedAnswers[k] = v.toString());
        }
      }
      notifyListeners();
    } catch (e) {
      log('Error restoring progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    if (isSubmitted || isSubmitting) return;
    final s = studentData;
    if (s == null) return;
    final resolvedTeacherId = exam.teacherId.isNotEmpty
        ? exam.teacherId
        : s.teacherId.trim();
    if (resolvedTeacherId.isEmpty) return;
    final resolvedStudentId = s.getStudentIdForTeacher(resolvedTeacherId);
    if (resolvedStudentId.isEmpty) return;

    try {
      // Save locally
      final map = {
        'student_id': resolvedStudentId,
        'focus_loss_count': focusLossCount,
        'answers': selectedAnswers,
        'last_updated': DateTime.now().toIso8601String(),
      };
      await pref.setString(_attemptStorageKey, jsonEncode(map));

      // Save to Firestore active attempt
      await FirebaseFirestore.instance
          .collection('user')
          .doc(resolvedTeacherId)
          .collection('exams')
          .doc(exam.examId)
          .collection('active_attempts')
          .doc(resolvedStudentId)
          .set({
            'student_id': resolvedStudentId,
            'student_name': s.name.trim(),
            'focus_loss_count': focusLossCount,
            'answers': selectedAnswers,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      log('Autosave error: $e');
    }
  }

  // Question getters
  int get totalQuestions => shuffledQuestions.length;
  bool get isLastQuestion => currentIndex >= totalQuestions - 1;
  QAModel get currentQuestion => shuffledQuestions[currentIndex];

  /// Current choice for the active question (e.g. 'A', 'B', 'C', 'D').
  String? get selectedChoice => selectedAnswers[currentQuestion.id];

  /// Whether active question is marked for review.
  bool get isCurrentMarked => markedQuestionIds.contains(currentQuestion.id);

  /// Status checks by displayed index (0-indexed).
  bool isAnswered(int index) {
    if (index < 0 || index >= totalQuestions) return false;
    return selectedAnswers.containsKey(shuffledQuestions[index].id);
  }

  bool isMarked(int index) {
    if (index < 0 || index >= totalQuestions) return false;
    return markedQuestionIds.contains(shuffledQuestions[index].id);
  }

  bool isAnsweredAndMarked(int index) => isAnswered(index) && isMarked(index);

  String get formattedTime => formatDuration(remaining);

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }

    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  /// Select answer for current question.
  void selectAnswer(String value) {
    if (isSubmitting || isSubmitted) return;
    selectedAnswers[currentQuestion.id] = value.trim().toUpperCase();
    _saveProgress();
    notifyListeners();
  }

  /// Toggle "Mark for Review" on current question.
  void toggleMarkForReview() {
    if (isSubmitting || isSubmitted) return;
    final id = currentQuestion.id;
    if (markedQuestionIds.contains(id)) {
      markedQuestionIds.remove(id);
    } else {
      markedQuestionIds.add(id);
    }
    notifyListeners();
  }

  /// Direct navigation to a specific question index.
  void goToQuestion(int index) {
    if (isSubmitting || isSubmitted) return;
    if (index >= 0 && index < totalQuestions) {
      currentIndex = index;
      notifyListeners();
    }
  }

  void next() {
    if (isSubmitting || isSubmitted) return;
    if (!isLastQuestion) {
      currentIndex++;
      notifyListeners();
    }
  }

  void previous() {
    if (isSubmitting || isSubmitted) return;
    if (currentIndex > 0) {
      currentIndex--;
      notifyListeners();
    }
  }

  void attachContext(BuildContext context) {
    _lastContext = context;
  }

  // ---------------------------------------------------------------------------
  // APP LIFECYCLE & AUTO-SUBMIT WHEN APP CLOSED / ABANDONED
  // ---------------------------------------------------------------------------

  void onLifecycle(AppLifecycleState state, BuildContext? context) {
    if (context != null) _lastContext = context;
    if (isSubmitting || isSubmitted) return;

    if (state == AppLifecycleState.detached) {
      // The app engine is detaching/terminating -> submit immediately.
      _abandonmentTimer?.cancel();
      submitExam(
        context: context ?? _lastContext,
        reason: SubmissionReason.appClosed,
      );
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      wasOutside = true;
      // Start short grace period (5s). If student leaves app in background, auto-submit.
      _abandonmentTimer?.cancel();
      _abandonmentTimer = Timer(const Duration(seconds: 5), () {
        if (!isSubmitting && !isSubmitted) {
          submitExam(context: _lastContext, reason: SubmissionReason.appClosed);
        }
      });
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Transient interruption (e.g. system dialog or notification pull-down).
      wasOutside = true;
      return;
    }

    if (state == AppLifecycleState.resumed && wasOutside) {
      wasOutside = false;
      _abandonmentTimer?.cancel();
      _handleFocusLoss(context ?? _lastContext);
    }
  }

  void _handleFocusLoss(BuildContext? context) {
    if (isSubmitting || isSubmitted) return;
    focusLossCount++;
    _saveProgress(); // Persist count immediately

    if (focusLossCount > allowedFocusLosses) {
      if (context != null && context.mounted) {
        customSnackbar(
          context: context,
          message:
              'Maximum $allowedFocusLosses focus losses reached. Exam auto-submitted.',
          color: Colors.red,
          ico: Icons.warning_amber_rounded,
        );
      }
      submitExam(context: context, reason: SubmissionReason.focusLost);
      return;
    }

    final remainingChances = allowedFocusLosses - focusLossCount + 1;
    if (context != null && context.mounted) {
      customSnackbar(
        context: context,
        message:
            'Focus loss warning ($focusLossCount/$allowedFocusLosses). '
            'Auto-submission on attempt ${allowedFocusLosses + 1} ($remainingChances warning${remainingChances == 1 ? '' : 's'} remaining).',
        color: Colors.orange,
        ico: Icons.warning_amber_rounded,
      );
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // TIMER & WALL-CLOCK COUNTDOWN
  // ---------------------------------------------------------------------------

  void _updateRemaining() {
    final end = exam.examEnd;
    if (end == null) {
      remaining = const Duration(hours: 1);
    } else {
      final diff = end.difference(DateTime.now());
      remaining = diff.isNegative ? Duration.zero : diff;
    }
    if (remainingNotifier != null) {
      remainingNotifier.value = remaining;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _updateRemaining();

    if (remaining.inSeconds <= 0) {
      submitExam(context: _lastContext, reason: SubmissionReason.timeExpired);
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      if (remaining.inSeconds <= 0) {
        _timer?.cancel();
        submitExam(context: _lastContext, reason: SubmissionReason.timeExpired);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // CENTRALIZED SUBMISSION METHOD
  // ---------------------------------------------------------------------------

  /// Centralized idempotent submission method.
  Future<void> submitExam({
    BuildContext? context,
    required SubmissionReason reason,
  }) async {
    final ctx = context ?? _lastContext;
    if (isSubmitting || isSubmitted) return;

    isSubmitting = true;
    _timer?.cancel();
    _abandonmentTimer?.cancel();
    notifyListeners();

    final s = studentData;
    if (s == null) {
      isSubmitting = false;
      notifyListeners();
      if (ctx != null && ctx.mounted) {
        customSnackbar(
          context: ctx,
          message: 'Student session error. Please log in again.',
          color: Colors.red,
          ico: Icons.error,
        );
      }
      return;
    }

    final resolvedTeacherId = exam.teacherId.isNotEmpty
        ? exam.teacherId
        : s.teacherId.trim();
    if (resolvedTeacherId.isEmpty) {
      isSubmitting = false;
      notifyListeners();
      if (ctx != null && ctx.mounted) {
        customSnackbar(
          context: ctx,
          message: 'Teacher information missing for this exam.',
          color: Colors.red,
          ico: Icons.error,
        );
      }
      return;
    }

    final studentId = s.getStudentIdForTeacher(resolvedTeacherId);
    final enrollment = s.getEnrollmentForTeacher(resolvedTeacherId);
    final isEligible = exam.isEligibleForStudent(
      studentId: studentId,
      authUid: FirebaseAuth.instance.currentUser?.uid,
      enrollment: enrollment,
    );

    if (!isEligible) {
      isSubmitting = false;
      notifyListeners();
      if (ctx != null && ctx.mounted) {
        customSnackbar(
          context: ctx,
          message:
              'You are not eligible to submit this exam due to membership or enrollment date restrictions.',
          color: Colors.red,
          ico: Icons.block,
        );
      }
      return;
    }

    try {
      final examRef = FirebaseFirestore.instance
          .collection('user')
          .doc(resolvedTeacherId)
          .collection('exams')
          .doc(exam.examId);

      // Re-read authoritative exam doc to verify assigned_student_ids
      final latestExamSnap = await examRef.get();
      if (!latestExamSnap.exists) {
        throw StateError('Exam no longer exists.');
      }

      final latestData = latestExamSnap.data()!;
      final latestAssigned = List<String>.from(
        latestData['assigned_student_ids'] ?? const [],
      ).map((id) => id.toString().trim()).where((id) => id.isNotEmpty).toSet();

      if (!latestAssigned.contains(studentId)) {
        isSubmitting = false;
        notifyListeners();
        if (ctx != null && ctx.mounted) {
          customSnackbar(
            context: ctx,
            message: 'You are no longer assigned to this exam.',
            color: Colors.red,
            ico: Icons.block,
          );
        }
        return;
      }

      final subRef = examRef.collection('submissions').doc(studentId);

      // Idempotency check: if submission already exists, don't overwrite
      final existingSub = await subRef.get();
      if (existingSub.exists) {
        isSubmitted = true;
        isSubmitting = false;
        notifyListeners();
        if (ctx != null && ctx.mounted) {
          Get.back();
        }
        return;
      }

      // Calculate marks strictly against stable question IDs
      final total = exam.questions.length;
      var correct = 0;

      for (final q in exam.questions) {
        final chosen = selectedAnswers[q.id];
        if (chosen != null &&
            chosen.trim().toUpperCase() == q.ans.trim().toUpperCase()) {
          correct++;
        }
      }

      final full = double.tryParse(exam.fullMarks) ?? total.toDouble();
      final raw = total == 0 ? 0 : correct * (full / total);
      final score = raw % 1 == 0
          ? raw.toInt()
          : double.parse(raw.toStringAsFixed(2));

      // Check current attempt number
      final reassignedMap = latestData['reassigned_students'];
      final attemptNumber =
          (reassignedMap is Map && reassignedMap[studentId] is num)
          ? (reassignedMap[studentId] as num).toInt() + 1
          : 1;

      await subRef.set({
        'student_id': studentId,
        'student_name': s.name.trim(),
        'exam_id': exam.examId,
        'exam_name': exam.examName,
        'batch': exam.batch,
        'total_questions': total,
        'attempted': selectedAnswers.length,
        'correct_count': correct,
        'score': score,
        'full_marks': exam.fullMarks,
        'submitted_at': FieldValue.serverTimestamp(),
        'submission_reason': reason.name,
        'attempt_number': attemptNumber,
        'focus_loss_count': focusLossCount,
        'status': 'submitted',
        // Stable questionId -> answer mapping
        'answers': selectedAnswers,
        // Backward compatibility for index-based reviews
        'answers_by_index': {
          for (var i = 0; i < exam.questions.length; i++)
            if (selectedAnswers.containsKey(exam.questions[i].id))
              i.toString(): selectedAnswers[exam.questions[i].id]!,
        },
      });

      // Clear in-progress draft attempt
      try {
        await pref.remove(_attemptStorageKey);
        await FirebaseFirestore.instance
            .collection('user')
            .doc(resolvedTeacherId)
            .collection('exams')
            .doc(exam.examId)
            .collection('active_attempts')
            .doc(studentId)
            .delete();
      } catch (_) {}

      isSubmitted = true;
      isSubmitting = false;
      notifyListeners();

      Get.offNamed(
        AppRoutes.studentExamSubmitted,
        arguments: {
          'examTitle': exam.examName,
          'totalQuestions': total,
          'attemptedQuestions': selectedAnswers.length,
          'fullMarks': exam.fullMarks,
        },
      );
    } catch (e, st) {
      log('Submission error', error: e, stackTrace: st);
      isSubmitting = false;
      notifyListeners();

      if (ctx != null && ctx.mounted) {
        customSnackbar(
          context: ctx,
          message: 'Could not submit the exam. Please try again.',
          color: Colors.red,
          ico: Icons.error,
        );
      }
    }
  }

  /// Backward-compatible submit method calling centralized submitExam
  Future<void> submit(BuildContext context, {required bool auto}) async {
    return submitExam(
      context: context,
      reason: auto ? SubmissionReason.timeExpired : SubmissionReason.manual,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _abandonmentTimer?.cancel();
    _autosaveTimer?.cancel();
    remainingNotifier.dispose();
    super.dispose();
  }
}
