import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/core/services/exam_firestore_service.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/model/exam_model.dart';

class ExamController extends ChangeNotifier {
  final FirebaseFirestore? _firestore;

  ExamController({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  int selectedTab = 0;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ExamModel> _exams = [];
  List<ExamModel> get exams => List.unmodifiable(_exams);
  List<ExamModel> get allExams => List.unmodifiable(_exams);
  List<ExamModel> get activeExams =>
      _exams.where((e) => e.status == 'Active').toList(growable: false);
  List<ExamModel> get upcomingExams =>
      _exams.where((e) => e.status == 'Upcoming').toList(growable: false);
  List<ExamModel> get completedExams =>
      _exams.where((e) => e.status == 'Completed').toList(growable: false);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _cachedStream;
  String _cachedTeacherId = '';

  void changeTab(int index) {
    if (selectedTab != index) {
      selectedTab = index;
      notifyListeners();
    }
  }

  /// Sets the internal exam list and clears error, notifying listeners.
  void setExams(List<ExamModel> list) {
    _exams = List.from(list);
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Sets error state and notifies listeners.
  void setError(String? error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Loads exams asynchronously.
  ///
  /// - If the student has no assigned [teacherId] / [batchId] or an empty [batchIds] list,
  ///   immediately sets [isLoading] to false and returns an empty list.
  /// - Ensures [isLoading] is always set to false inside a `finally` block.
  Future<List<ExamModel>> loadExams({
    String? teacherId,
    String? studentId,
    String? batchId,
    List<String>? batchIds,
  }) async {
    final resolvedTeacherId = (teacherId ?? studentData?.teacherId ?? '')
        .trim();
    final resolvedStudentId = (studentId ?? studentData?.id ?? '').trim();
    final resolvedBatchId = (batchId ?? studentData?.batch ?? '').trim();

    // Guard: Missing teacher ID or explicitly empty batchIds list
    if (resolvedTeacherId.isEmpty || (batchIds != null && batchIds.isEmpty)) {
      _isLoading = false;
      _exams = [];
      _errorMessage = null;
      notifyListeners();
      return [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await ExamFirestoreService.getExamsQuery(
        teacherId: resolvedTeacherId,
        batchIds: batchIds,
      ).get();

      final parsed = <ExamModel>[];
      for (final doc in snapshot.docs) {
        try {
          final exam = ExamModel.fromJson(doc.data());
          if (resolvedStudentId.isNotEmpty &&
              !exam.isStudentAssigned(resolvedStudentId)) {
            continue;
          }
          if (resolvedBatchId.isNotEmpty &&
              exam.batch.isNotEmpty &&
              exam.batch.toLowerCase() != resolvedBatchId.toLowerCase()) {
            continue;
          }
          parsed.add(exam);
        } catch (e) {
          log('Error parsing exam document ${doc.id}: $e');
        }
      }

      parsed.sort(_compareExams);
      _exams = parsed;
      _errorMessage = null;
      return _exams;
    } catch (e, stack) {
      log('Error in ExamController.loadExams: $e', stackTrace: stack);
      _errorMessage = e.toString();
      _exams = [];
      return [];
    } finally {
      // Always reset isLoading to false inside finally block
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listens to the Firestore exam stream.
  ///
  /// - If teacherId is missing or batchIds is an empty list, immediately sets
  ///   [isLoading] to false and clears exams.
  /// - Sets [isLoading] to false in BOTH data and onError callbacks.
  void listenToExams({
    String? teacherId,
    String? studentId,
    String? batchId,
    List<String>? batchIds,
    Stream<QuerySnapshot<Map<String, dynamic>>>? overrideStream,
  }) {
    final resolvedTeacherId = (teacherId ?? studentData?.teacherId ?? '')
        .trim();
    final resolvedStudentId = (studentId ?? studentData?.id ?? '').trim();
    final resolvedBatchId = (batchId ?? studentData?.batch ?? '').trim();

    _subscription?.cancel();
    _subscription = null;

    if (overrideStream == null &&
        (resolvedTeacherId.isEmpty || (batchIds != null && batchIds.isEmpty))) {
      _isLoading = false;
      _exams = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final stream =
        overrideStream ??
        ExamFirestoreService.getStudentExamsStream(
          teacherId: resolvedTeacherId,
          batchIds: batchIds,
        );

    _subscription = stream.listen(
      (snapshot) {
        final parsed = <ExamModel>[];
        for (final doc in snapshot.docs) {
          try {
            final exam = ExamModel.fromJson(doc.data());
            if (resolvedStudentId.isNotEmpty &&
                !exam.isStudentAssigned(resolvedStudentId)) {
              continue;
            }
            if (resolvedBatchId.isNotEmpty &&
                exam.batch.isNotEmpty &&
                exam.batch.toLowerCase() != resolvedBatchId.toLowerCase()) {
              continue;
            }
            parsed.add(exam);
          } catch (e) {
            log('Error parsing exam doc ${doc.id}: $e');
          }
        }

        parsed.sort(_compareExams);
        _exams = parsed;
        _errorMessage = null;
        // Ensure isLoading is false inside data callback
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        log('ExamController stream onError: $error');
        _errorMessage = error.toString();
        _exams = [];
        // Ensure isLoading is false inside onError callback
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  static int _compareExams(ExamModel a, ExamModel b) {
    final aStart = a.examStart;
    final bStart = b.examStart;
    if (aStart == null && bStart == null) {
      return b.examId.compareTo(a.examId);
    }
    if (aStart == null) return 1;
    if (bStart == null) return -1;
    return bStart.compareTo(aStart);
  }

  /// Returns a Firestore stream of exams for the given [teacherId]
  /// or from the globally initialized [studentData].
  Stream<QuerySnapshot<Map<String, dynamic>>> getExamStream({
    String? teacherId,
    List<String>? batchIds,
    bool forceFresh = true,
  }) {
    final resolvedTeacherId = (teacherId ?? studentData?.teacherId ?? '')
        .trim();

    if (resolvedTeacherId.isEmpty || (batchIds != null && batchIds.isEmpty)) {
      return Stream.error(
        StateError(
          'Student profile or teacher ID is missing. '
          'Please ensure the student is enrolled and logged in.',
        ),
      );
    }

    if (!forceFresh && _cachedStream != null && _cachedTeacherId == resolvedTeacherId) {
      return _cachedStream!;
    }

    _cachedTeacherId = resolvedTeacherId;
    _cachedStream = ExamFirestoreService.getStudentExamsStream(
      teacherId: resolvedTeacherId,
      batchIds: batchIds,
    );

    return _cachedStream!;
  }

  /// Backward-compatible alias for [getExamStream].
  Stream<QuerySnapshot<Map<String, dynamic>>> getExam() {
    return getExamStream();
  }

  /// Clears the cached stream and forces a fresh query subscription on next build or retry.
  void refreshStream({String? teacherId}) {
    _cachedStream = null;
    _cachedTeacherId = '';
    notifyListeners();
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    selectedTab = 0;
    _isLoading = false;
    _exams = [];
    _errorMessage = null;
    _cachedStream = null;
    _cachedTeacherId = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
