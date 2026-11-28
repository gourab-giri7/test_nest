import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/datasources/get_student_data.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/manualQuestions/controller/question_controller.dart';
import 'package:test_nest/model/exam_details_model.dart';
import 'package:test_nest/routes/app_routes.dart';

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
  List<String> classList = ['select batch'];
  String selectedbatch = 'select batch';
  final Set<String> _selectedBatches = <String>{};
  Set<String> get selectedBatches => Set.unmodifiable(_selectedBatches);

  List<StudentModel> _students = const [];
  final Set<String> _selectedStudentIds = <String>{};
  String _lastSyncedBatch = '';

  bool studentMatchesBatch(StudentModel s, String batchName) {
    if (StudentModel.isSameBatch(s.batch, batchName)) return true;
    if (s.batchId != null && s.batchId!.trim() == batchName.trim()) return true;
    return false;
  }

  bool isBatchSelected(String batchName) {
    final clean = batchName.trim();
    if (_selectedBatches.isNotEmpty) {
      return _selectedBatches.contains(clean);
    }
    return studentMatchesBatch(StudentModel(name: '', batch: selectedbatch, id: '', password: ''), clean);
  }

  List<StudentModel> get studentsForSelectedBatch {
    if (_selectedBatches.isNotEmpty) {
      return _students.where((s) {
        return _selectedBatches.any((b) => studentMatchesBatch(s, b));
      }).toList(growable: false);
    }
    return _students
        .where((s) => studentMatchesBatch(s, selectedbatch))
        .toList(growable: false);
  }

  Set<String> get selectedStudentIds => Set.unmodifiable(_selectedStudentIds);
  bool get allStudentsSelected =>
      studentsForSelectedBatch.isNotEmpty &&
      studentsForSelectedBatch.every(
        (s) => _selectedStudentIds.contains(s.id.trim()),
      );
  int get selectedCount => _selectedStudentIds.length;

  Stream<QuerySnapshot<Map<String, dynamic>>> get studentsStream =>
      GetStudentData.getAllStudent();

  void toggleBatch(String batchName) {
    final clean = batchName.trim();
    if (clean.isEmpty || clean == 'select batch') return;
    if (_selectedBatches.contains(clean)) {
      _selectedBatches.remove(clean);
    } else {
      _selectedBatches.add(clean);
    }
    if (_selectedBatches.isNotEmpty) {
      selectedbatch = _selectedBatches.first;
    }
    _syncStudentsForActiveBatches();
    notifyListeners();
  }

  void selectAllBatches() {
    _selectedBatches.clear();
    for (final b in classList) {
      final clean = b.trim();
      if (clean.isNotEmpty && clean != 'select batch') {
        _selectedBatches.add(clean);
      }
    }
    if (_selectedBatches.isNotEmpty) {
      selectedbatch = _selectedBatches.first;
    }
    _syncStudentsForActiveBatches();
    notifyListeners();
  }

  void deselectAllBatches() {
    _selectedBatches.clear();
    _selectedStudentIds.clear();
    notifyListeners();
  }

  void _syncStudentsForActiveBatches() {
    final ids = studentsForSelectedBatch
        .map((s) => s.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    _selectedStudentIds
      ..clear()
      ..addAll(ids);
  }

  void setStudentsFromSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    List<String>? explicitBatches,
    bool restrictToExplicitBatches = false,
  }) {
    final nextStudents = docs
        .map((d) => StudentModel.fromJson(d.data(), docId: d.id))
        .where((s) => s.id.trim().isNotEmpty && s.isActive)
        .toList(growable: false);

    _students = nextStudents;

    // Aggregate available batches from explicit batches or teacherData + actual student docs
    final batchSet = <String>{};
    if (explicitBatches != null &&
        (explicitBatches.isNotEmpty || restrictToExplicitBatches)) {
      for (final b in explicitBatches) {
        final clean = b.trim();
        if (clean.isNotEmpty) batchSet.add(clean);
      }
    } else {
      if (teacherData != null) {
        for (final b in teacherData!.batch) {
          final clean = b.trim();
          if (clean.isNotEmpty) batchSet.add(clean);
        }
      }
    }
    if (!restrictToExplicitBatches) {
      for (final s in nextStudents) {
        if (s.batch.trim().isNotEmpty) {
          batchSet.add(s.batch.trim());
        }
      }
    }

    final sortedBatches = batchSet.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    classList = sortedBatches.isNotEmpty ? sortedBatches : ['select batch'];

    // If selectedbatch is not in classList or default, pick matching or first
    final hasMatch = classList.any(
      (b) => StudentModel.isSameBatch(b, selectedbatch),
    );
    if (!hasMatch) {
      selectedbatch = classList.first;
    }

    // Auto-select students for the batch if switching/initial load
    if (!StudentModel.isSameBatch(_lastSyncedBatch, selectedbatch)) {
      _lastSyncedBatch = selectedbatch;
      final batchIds = studentsForSelectedBatch
          .map((s) => s.id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      _selectedStudentIds
        ..clear()
        ..addAll(batchIds);
    } else {
      // Retain only IDs that still exist in the current batch
      final validIds = studentsForSelectedBatch
          .map((s) => s.id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      _selectedStudentIds.removeWhere((id) => !validIds.contains(id));
    }
    // Note: Do not call notifyListeners() here to avoid build-phase exception
  }

  void syncStudents({
    required List<StudentModel> students,
    List<String>? availableBatches,
    String? activeBatch,
  }) {
    _students = students.where((s) => s.isActive).toList(growable: false);
    if (availableBatches != null && availableBatches.isNotEmpty) {
      classList = List<String>.from(availableBatches);
    }
    if (activeBatch != null) {
      selectedbatch = activeBatch;
    }
    _lastSyncedBatch = selectedbatch;
    final ids = studentsForSelectedBatch
        .map((s) => s.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    _selectedStudentIds
      ..clear()
      ..addAll(ids);
  }

  void initBatches() {
    final tData = teacherData;
    classList = tData != null && tData.batch.isNotEmpty
        ? List<String>.from(tData.batch)
        : ['select batch'];
    selectedbatch = classList.first;
    _selectedStudentIds.clear();
    _lastSyncedBatch = '';
    notifyListeners();
  }

  void setBatch(String newBatch) {
    selectedbatch = newBatch;
    _selectedBatches.clear();
    if (newBatch != 'select batch' && newBatch.trim().isNotEmpty) {
      _selectedBatches.add(newBatch.trim());
    }
    _lastSyncedBatch = newBatch;
    final ids = studentsForSelectedBatch
        .map((s) => s.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    _selectedStudentIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  void toggleStudent(String id, bool selected) {
    final clean = id.trim();
    if (clean.isEmpty) return;
    if (selected) {
      _selectedStudentIds.add(clean);
    } else {
      _selectedStudentIds.remove(clean);
    }
    notifyListeners();
  }

  void toggleAllStudents(bool selected) {
    final ids = studentsForSelectedBatch
        .map((s) => s.id.trim())
        .where((id) => id.isNotEmpty);
    if (selected) {
      _selectedStudentIds.addAll(ids);
    } else {
      _selectedStudentIds.removeAll(ids);
    }
    notifyListeners();
  }

  String? nameValidator(String? value) => value == null || value.trim().isEmpty
      ? 'Fill this field before submit'
      : null;
  String? marksValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Fill this field before submit';
    }
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter integer number only';
    if (n <= 0) return 'Please give valid marks';
    return null;
  }

  void selectExamDate() {
    if (pickedDate != null) {
      examDateController.text = DateFormat('dd-MMM-yyyy').format(pickedDate!);
    }
    notifyListeners();
  }

  TimeOfDay? _parseTime(String value) {
    try {
      final d = DateFormat('h:mm a').parse(value.trim());
      return TimeOfDay(hour: d.hour, minute: d.minute);
    } catch (_) {
      try {
        final d = DateFormat('HH:mm').parse(value.trim());
        return TimeOfDay(hour: d.hour, minute: d.minute);
      } catch (_) {
        return null;
      }
    }
  }

  QuestionSource questionSource = QuestionSource.excel;

  void setQuestionSource(QuestionSource source) {
    if (questionSource != source) {
      questionSource = source;
      notifyListeners();
    }
  }

  void next(
    BuildContext context,
    QuestionController qc, {
    String? explicitCreatorName,
    String? explicitCreatorRole,
  }) {
    if (!examKey.currentState!.validate()) return;
    if (pickedDate == null) {
      _error(context, 'Please select exam date.');
      return;
    }
    final start = _parseTime(startTimeController.text),
        end = _parseTime(endTimeController.text);
    if (start == null || end == null) {
      _error(context, 'Please select valid start and end time.');
      return;
    }
    final examStart = DateTime(
      pickedDate!.year,
      pickedDate!.month,
      pickedDate!.day,
      start.hour,
      start.minute,
    );
    final examEnd = DateTime(
      pickedDate!.year,
      pickedDate!.month,
      pickedDate!.day,
      end.hour,
      end.minute,
    );
    if (!examEnd.isAfter(examStart)) {
      _error(context, 'End time must be after start time.');
      return;
    }
    final effectiveBatches = _selectedBatches.isNotEmpty
        ? _selectedBatches.toList()
        : (selectedbatch != 'select batch' && selectedbatch.trim().isNotEmpty
            ? [selectedbatch.trim()]
            : <String>[]);

    if (effectiveBatches.isEmpty) {
      _error(context, 'Please select at least one batch.');
      return;
    }
    // Only IDs belonging to the currently selected batches may be published.
    final validBatchIds = studentsForSelectedBatch
        .map((s) => s.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    _selectedStudentIds.removeWhere((id) => !validBatchIds.contains(id));
    if (_selectedStudentIds.isEmpty) {
      _error(
        context,
        'Please select at least one student from the selected batches.',
      );
      return;
    }

    final creatorName = (explicitCreatorName != null && explicitCreatorName.trim().isNotEmpty)
        ? explicitCreatorName.trim()
        : (teacherData?.name.trim() ?? '');
    final creatorRole = (explicitCreatorRole != null && explicitCreatorRole.trim().isNotEmpty)
        ? explicitCreatorRole.trim()
        : 'Teacher';

    examDetails = ExamDetailsModel(
      examName: examNameController.text.trim(),
      fullMarks: fullMarksController.text.trim(),
      examKey: examKeyController.text,
      instruction: instructionsController.text.trim(),
      batch: effectiveBatches.join(', '),
      batches: effectiveBatches,
      creatorName: creatorName,
      creatorRole: creatorRole,
      examStart: examStart,
      examEnd: examEnd,
      assignedStudentIds: _selectedStudentIds.toList(growable: false),
    );

    qc.setSource(questionSource);

    Get.toNamed(AppRoutes.teacherQuestionMethodChoice, arguments: qc);
  }

  void clearAll() {
    examNameController.clear();
    fullMarksController.clear();
    examDateController.clear();
    startTimeController.clear();
    endTimeController.clear();
    examKeyController.clear();
    instructionsController.clear();
    pickedDate = null;
    _selectedBatches.clear();
    _selectedStudentIds.clear();
    _students = const [];
    _lastSyncedBatch = '';
    questionSource = QuestionSource.excel;
    initBatches();
  }

  void _error(BuildContext context, String message) => customSnackbar(
    context: context,
    message: message,
    color: Colors.red,
    ico: Icons.error,
  );

  @override
  void dispose() {
    examNameController.dispose();
    fullMarksController.dispose();
    examDateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    examKeyController.dispose();
    instructionsController.dispose();
    super.dispose();
  }
}
