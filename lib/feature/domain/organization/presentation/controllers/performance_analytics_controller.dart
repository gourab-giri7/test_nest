import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/performance_analytics_service.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/performance_model.dart';

class PerformanceAnalyticsController extends ChangeNotifier {
  final PerformanceAnalyticsService _service;
  final ActiveTenantContext _tenantContext;

  bool _isLoading = false;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  // Raw source records
  List<PerformanceRecord> _allRecords = [];
  Map<String, List<QAModel>> _examQuestions = {};

  // Filters
  String _selectedBatch = 'All Batches';
  String? _selectedStudentId;
  String _selectedSubject = 'All Subjects';
  DateTimeRange? _dateRange;

  // Available filter options
  List<String> _availableBatches = ['All Batches'];
  List<Map<String, String>> _availableStudents = []; // [{id, name, batch}]
  List<String> _availableSubjects = ['All Subjects'];

  // Exam comparison selection
  final Set<String> _selectedExamIdsForComparison = {};

  PerformanceAnalyticsController({
    PerformanceAnalyticsService? service,
    required ActiveTenantContext tenantContext,
  }) : _service = service ?? PerformanceAnalyticsService(),
       _tenantContext = tenantContext;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTabIndex => _selectedTabIndex;
  String get selectedBatch => _selectedBatch;
  String? get selectedStudentId => _selectedStudentId;
  String get selectedSubject => _selectedSubject;
  DateTimeRange? get dateRange => _dateRange;

  List<String> get availableBatches => List.unmodifiable(_availableBatches);
  List<Map<String, String>> get availableStudents =>
      List.unmodifiable(_availableStudents);
  List<String> get availableSubjects => List.unmodifiable(_availableSubjects);
  Set<String> get selectedExamIdsForComparison =>
      Set.unmodifiable(_selectedExamIdsForComparison);

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  void setBatchFilter(String batch) {
    if (_selectedBatch != batch) {
      _selectedBatch = batch;
      // If student is selected and not in new batch, reset student filter
      if (_selectedStudentId != null) {
        final matches = _availableStudents.any(
          (s) =>
              s['id'] == _selectedStudentId &&
              (batch == 'All Batches' || s['batch'] == batch),
        );
        if (!matches) _selectedStudentId = null;
      }
      notifyListeners();
    }
  }

  void setStudentFilter(String? studentId) {
    if (_selectedStudentId != studentId) {
      _selectedStudentId = studentId;
      notifyListeners();
    }
  }

  void setSubjectFilter(String subject) {
    if (_selectedSubject != subject) {
      _selectedSubject = subject;
      notifyListeners();
    }
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    notifyListeners();
  }

  void toggleExamForComparison(String examId) {
    if (_selectedExamIdsForComparison.contains(examId)) {
      _selectedExamIdsForComparison.remove(examId);
    } else {
      _selectedExamIdsForComparison.add(examId);
    }
    notifyListeners();
  }

  void selectAllExamsForComparison() {
    for (final r in filteredRecords) {
      _selectedExamIdsForComparison.add(r.examId);
    }
    notifyListeners();
  }

  void clearComparison() {
    _selectedExamIdsForComparison.clear();
    notifyListeners();
  }

  // Filtered records
  List<PerformanceRecord> get filteredRecords {
    return _allRecords.where((r) {
      // Batch filter
      if (_selectedBatch != 'All Batches' &&
          r.batch.trim().toLowerCase() != _selectedBatch.trim().toLowerCase()) {
        return false;
      }
      // Student filter
      if (_selectedStudentId != null &&
          _selectedStudentId!.isNotEmpty &&
          r.studentId != _selectedStudentId) {
        return false;
      }
      // Subject filter
      if (_selectedSubject != 'All Subjects' &&
          r.subject.trim().toLowerCase() !=
              _selectedSubject.trim().toLowerCase()) {
        return false;
      }
      // Date range filter
      if (_dateRange != null) {
        final date = r.examDate ?? r.submittedAt;
        if (date == null) return false;
        if (date.isBefore(_dateRange!.start) || date.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // Analytical Metrics Getters
  List<SubjectPerformance> get subjectPerformances =>
      PerformanceAnalyticsService.calculateSubjectPerformance(filteredRecords);

  List<ChapterStat> get chapterStats =>
      PerformanceAnalyticsService.calculateChapterPerformance(
        filteredRecords,
        _examQuestions,
      );

  List<ExamComparisonItem> get examComparisons {
    // If user explicitly picked exams, compare those; otherwise compare all filtered completed exams
    final examIds = _selectedExamIdsForComparison.isNotEmpty
        ? _selectedExamIdsForComparison.toList()
        : filteredRecords
              .where((r) => r.isCompleted)
              .map((r) => r.examId)
              .toSet()
              .toList();
    return PerformanceAnalyticsService.calculateExamComparison(
      filteredRecords,
      examIds,
    );
  }

  List<BatchLeaderboardEntry> get batchLeaderboard =>
      PerformanceAnalyticsService.calculateBatchLeaderboard(
        _allRecords,
        batchFilter: _selectedBatch != 'All Batches' ? _selectedBatch : null,
        dateRange: _dateRange,
      );

  int get totalExamsAttempted {
    final valid = filteredRecords
        .where((r) => r.isCompleted && r.hasValidScore)
        .toList();
    // Unique exams attempted
    return valid.map((r) => r.examId).toSet().length;
  }

  double get overallAveragePercentage {
    final valid = filteredRecords
        .where((r) => r.isCompleted && r.hasValidScore)
        .toList();
    if (valid.isEmpty) return 0.0;
    final total = valid.fold<double>(0.0, (acc, r) => acc + r.percentage);
    return double.parse((total / valid.length).toStringAsFixed(1));
  }

  double get overallHighestPercentage {
    final valid = filteredRecords
        .where((r) => r.isCompleted && r.hasValidScore)
        .toList();
    if (valid.isEmpty) return 0.0;
    final highest = valid
        .map((r) => r.percentage)
        .reduce((a, b) => a > b ? a : b);
    return double.parse(highest.toStringAsFixed(1));
  }

  int get subjectsCount => subjectPerformances.length;

  /// Loads data according to current tenant context and user role.
  Future<void> loadData({
    String? currentStudentUid,
    String? currentTeacherUid,
    List<String>? teacherAssignedBatches,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resolver = _tenantContext.pathResolver;
      List<PerformanceRecord> loadedRecords = [];

      if (_tenantContext.isStudent) {
        // Student role: Load only own performance
        final studentUid = currentStudentUid ?? '';
        loadedRecords = await _service.loadStudentPerformance(
          resolver: resolver,
          studentId: studentUid,
          fallbackTeacherId: currentTeacherUid,
        );
      } else if (_tenantContext.isTeacher && !_tenantContext.isAdmin) {
        // Non-admin teacher: Scoped to assigned batches and owned exams
        final assigned = teacherAssignedBatches ?? [];
        loadedRecords = await _service.loadExamSubmissions(
          resolver: resolver,
          fallbackTeacherId: currentTeacherUid,
          allowedBatchNames: assigned,
          teacherOwnerUid: currentTeacherUid,
        );
      } else {
        // Admin or Single Teacher owner: full access
        loadedRecords = await _service.loadExamSubmissions(
          resolver: resolver,
          fallbackTeacherId: currentTeacherUid,
        );
      }

      _allRecords = loadedRecords;

      // Extract filter options
      _populateFilterOptions();

      // Pre-select first 3 exams for comparison if available
      final uniqueExamIds = _allRecords
          .where((r) => r.isCompleted)
          .map((r) => r.examId)
          .toSet();
      _selectedExamIdsForComparison.clear();
      for (final id in uniqueExamIds.take(3)) {
        _selectedExamIdsForComparison.add(id);
      }

      // Load question models for chapter analysis
      if (uniqueExamIds.isNotEmpty) {
        _examQuestions = await _service.loadExamQuestions(
          resolver: resolver,
          examIds: uniqueExamIds,
          fallbackTeacherId: currentTeacherUid,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, st) {
      log('Error in PerformanceAnalyticsController.loadData: $e\n$st');
      _errorMessage = 'Failed to load performance analytics. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _populateFilterOptions() {
    final batchSet = <String>{};
    final studentMap = <String, Map<String, String>>{};
    final subjectSet = <String>{};

    for (final r in _allRecords) {
      if (r.batch.trim().isNotEmpty) batchSet.add(r.batch.trim());
      if (r.subject.trim().isNotEmpty) subjectSet.add(r.subject.trim());
      if (r.studentId.isNotEmpty) {
        studentMap[r.studentId] = {
          'id': r.studentId,
          'name': r.studentName.isNotEmpty
              ? r.studentName
              : 'Student (${r.studentId})',
          'batch': r.batch,
        };
      }
    }

    final sortedBatches = batchSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _availableBatches = ['All Batches', ...sortedBatches];

    final sortedSubjects = subjectSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _availableSubjects = ['All Subjects', ...sortedSubjects];

    final sortedStudents = studentMap.values.toList()
      ..sort(
        (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
          (b['name'] ?? '').toLowerCase(),
        ),
      );
    _availableStudents = sortedStudents;
  }
}
