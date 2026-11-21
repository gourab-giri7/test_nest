import 'package:flutter/material.dart';
import 'package:test_nest/core/services/attendance_service.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/model/attendance_model.dart';
import 'package:test_nest/model/batch_model.dart';

class BatchAttendanceController extends ChangeNotifier {
  final AttendanceService _service;

  BatchAttendanceController({AttendanceService? service})
    : _service = service ?? AttendanceService();

  List<BatchModel> _batches = [];
  BatchModel? _selectedBatch;
  DateTime _selectedDate = DateTime.now();

  List<StudentModel> _students = [];
  Map<String, String> _attendanceMap = {};
  Map<String, String> _remarksMap = {};

  Map<String, String> _savedAttendanceMap = {};
  Map<String, String> _savedRemarksMap = {};

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  List<BatchModel> get batches => _batches;
  BatchModel? get selectedBatch => _selectedBatch;
  DateTime get selectedDate => _selectedDate;
  String get dateKey => AttendanceRecordModel.formatDateKey(_selectedDate);
  List<StudentModel> get students => _students;
  Map<String, String> get attendanceMap => _attendanceMap;
  Map<String, String> get remarksMap => _remarksMap;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Returns true if there are unsaved changes compared to the last loaded or saved state.
  bool get isDirty {
    if (_attendanceMap.length != _savedAttendanceMap.length) return true;
    for (final entry in _attendanceMap.entries) {
      if (_savedAttendanceMap[entry.key] != entry.value) return true;
    }
    for (final entry in _remarksMap.entries) {
      if ((_savedRemarksMap[entry.key] ?? '') != entry.value) return true;
    }
    return false;
  }

  int get presentCount =>
      _attendanceMap.values.where((v) => v == AttendanceStatus.present).length;
  int get absentCount =>
      _attendanceMap.values.where((v) => v == AttendanceStatus.absent).length;
  int get lateCount =>
      _attendanceMap.values.where((v) => v == AttendanceStatus.late).length;
  int get unmarkedCount => _students.length - _attendanceMap.length;

  /// Helper to get consistent student identifier
  static String studentKey(StudentModel s) {
    if (s.authUid.trim().isNotEmpty) return s.authUid.trim();
    if (s.id.trim().isNotEmpty) return s.id.trim();
    return s.docId?.trim() ?? '';
  }

  /// Initial load of batches and selecting first/default batch.
  Future<void> initialize({
    required TenantPathResolver resolver,
    String? defaultBatchId,
    String? filterTeacherUid,
    String? fallbackTeacherId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _batches = await _service.fetchBatches(
        resolver: resolver,
        filterTeacherUid: filterTeacherUid,
        fallbackTeacherId: fallbackTeacherId,
      );

      if (_batches.isNotEmpty) {
        if (defaultBatchId != null && defaultBatchId.isNotEmpty) {
          _selectedBatch = _batches.firstWhere(
            (b) => b.id == defaultBatchId,
            orElse: () => _batches.first,
          );
        } else {
          _selectedBatch = _batches.first;
        }

        await _loadStudentsAndAttendance(
          resolver,
          fallbackTeacherId: fallbackTeacherId,
        );
      } else {
        _selectedBatch = null;
        _students = [];
        _attendanceMap = {};
        _remarksMap = {};
        _savedAttendanceMap = {};
        _savedRemarksMap = {};
      }
    } catch (e) {
      _errorMessage = 'Failed to load batches: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the currently selected batch.
  Future<void> selectBatch(
    BatchModel batch, {
    required TenantPathResolver resolver,
    String? fallbackTeacherId,
  }) async {
    if (_selectedBatch?.id == batch.id) return;
    _selectedBatch = batch;
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _loadStudentsAndAttendance(
        resolver,
        fallbackTeacherId: fallbackTeacherId,
      );
    } catch (e) {
      _errorMessage = 'Failed to load students: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the currently selected date.
  Future<void> selectDate(
    DateTime date, {
    required TenantPathResolver resolver,
    String? fallbackTeacherId,
  }) async {
    _selectedDate = date;
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _loadAttendanceForCurrentDate(
        resolver,
        fallbackTeacherId: fallbackTeacherId,
      );
    } catch (e) {
      _errorMessage = 'Failed to load attendance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads students for current batch, then loads attendance for current date.
  Future<void> _loadStudentsAndAttendance(
    TenantPathResolver resolver, {
    String? fallbackTeacherId,
  }) async {
    if (_selectedBatch == null) return;

    _students = await _service.fetchStudentsForBatch(
      resolver: resolver,
      batchId: _selectedBatch!.id,
      batchName: _selectedBatch!.name,
      fallbackTeacherId: fallbackTeacherId,
    );

    _students.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    await _loadAttendanceForCurrentDate(
      resolver,
      fallbackTeacherId: fallbackTeacherId,
    );
  }

  /// Loads existing attendance records for current batch and date.
  Future<void> _loadAttendanceForCurrentDate(
    TenantPathResolver resolver, {
    String? fallbackTeacherId,
  }) async {
    if (_selectedBatch == null) return;

    final records = await _service.fetchBatchAttendanceForDate(
      resolver: resolver,
      batchId: _selectedBatch!.id,
      dateKey: dateKey,
      fallbackTeacherId: fallbackTeacherId,
    );

    _attendanceMap.clear();
    _remarksMap.clear();

    for (final r in records) {
      _attendanceMap[r.studentId] = r.status;
      if (r.remarks != null && r.remarks!.isNotEmpty) {
        _remarksMap[r.studentId] = r.remarks!;
      }
    }

    _savedAttendanceMap = Map<String, String>.from(_attendanceMap);
    _savedRemarksMap = Map<String, String>.from(_remarksMap);
  }

  /// Sets status for an individual student.
  void markStatus(String sKey, String status) {
    if (!AttendanceStatus.isValid(status)) return;
    _attendanceMap[sKey] = status;
    _successMessage = null;
    notifyListeners();
  }

  /// Sets remarks for an individual student.
  void markRemarks(String sKey, String remarks) {
    if (remarks.trim().isEmpty) {
      _remarksMap.remove(sKey);
    } else {
      _remarksMap[sKey] = remarks.trim();
    }
    _successMessage = null;
    notifyListeners();
  }

  /// Quick action: Marks all active students present.
  void markAllPresent() {
    for (final s in _students) {
      final key = studentKey(s);
      if (key.isNotEmpty) {
        _attendanceMap[key] = AttendanceStatus.present;
      }
    }
    _successMessage = null;
    notifyListeners();
  }

  /// Quick action: Marks all active students absent.
  void markAllAbsent() {
    for (final s in _students) {
      final key = studentKey(s);
      if (key.isNotEmpty) {
        _attendanceMap[key] = AttendanceStatus.absent;
      }
    }
    _successMessage = null;
    notifyListeners();
  }

  /// Saves the current attendance state to Firestore.
  Future<bool> saveAttendance({
    required TenantPathResolver resolver,
    required String markedBy,
    required String markedByName,
    required String teacherId,
    String? fallbackTeacherId,
  }) async {
    if (_selectedBatch == null || _students.isEmpty) return false;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final batchId = _selectedBatch!.id;
      final batchName = _selectedBatch!.name;
      final currentDKey = dateKey;
      final orgId = resolver.isInstitute ? resolver.orgId : '';

      final records = <AttendanceRecordModel>[];

      for (final s in _students) {
        final key = studentKey(s);
        if (key.isEmpty) continue;

        // Default to absent if unmarked, or keep whatever status was chosen
        final status = _attendanceMap[key] ?? AttendanceStatus.absent;
        final remarks = _remarksMap[key];

        final id = AttendanceRecordModel.generateId(
          batchId: batchId,
          studentId: key,
          dateKey: currentDKey,
        );

        records.add(
          AttendanceRecordModel(
            id: id,
            organizationId: orgId,
            teacherId: teacherId,
            batchId: batchId,
            batchName: batchName,
            studentId: key,
            studentName: s.name,
            date: _selectedDate,
            dateKey: currentDKey,
            status: status,
            remarks: remarks,
            markedBy: markedBy,
            markedByName: markedByName,
          ),
        );
      }

      await _service.saveBatchAttendance(
        resolver: resolver,
        batchId: batchId,
        batchName: batchName,
        date: _selectedDate,
        records: records,
        fallbackTeacherId: fallbackTeacherId,
      );

      // Update in-memory map to reflect any unmarked that defaulted to absent
      for (final r in records) {
        _attendanceMap[r.studentId] = r.status;
      }

      _savedAttendanceMap = Map<String, String>.from(_attendanceMap);
      _savedRemarksMap = Map<String, String>.from(_remarksMap);
      _successMessage = 'Attendance saved successfully!';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save attendance: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Discards unsaved changes and reverts to last saved state.
  void discardChanges() {
    _attendanceMap = Map<String, String>.from(_savedAttendanceMap);
    _remarksMap = Map<String, String>.from(_savedRemarksMap);
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
