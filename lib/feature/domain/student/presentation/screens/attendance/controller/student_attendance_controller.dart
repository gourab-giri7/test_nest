import 'package:flutter/material.dart';
import 'package:test_nest/core/services/attendance_service.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/model/attendance_model.dart';

class StudentAttendanceController extends ChangeNotifier {
  final AttendanceService _service;

  StudentAttendanceController({AttendanceService? service})
    : _service = service ?? AttendanceService();

  List<AttendanceRecordModel> _allRecords = [];
  StudentAttendanceSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  String? _statusFilter;
  String? _batchFilter;
  int? _selectedMonth;
  int? _selectedYear;

  List<AttendanceRecordModel> get allRecords => _allRecords;
  StudentAttendanceSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get statusFilter => _statusFilter;
  String? get batchFilter => _batchFilter;
  int? get selectedMonth => _selectedMonth;
  int? get selectedYear => _selectedYear;

  List<AttendanceRecordModel> get filteredRecords {
    return _allRecords.where((r) {
      if (_statusFilter != null && _statusFilter!.isNotEmpty) {
        if (r.status.toLowerCase() != _statusFilter!.toLowerCase())
          return false;
      }
      if (_batchFilter != null && _batchFilter!.isNotEmpty) {
        if (r.batchId != _batchFilter && r.batchName != _batchFilter)
          return false;
      }
      if (_selectedYear != null) {
        if (r.date.year != _selectedYear) return false;
      }
      if (_selectedMonth != null) {
        if (r.date.month != _selectedMonth) return false;
      }
      return true;
    }).toList();
  }

  List<String> get availableBatches {
    final batches = <String>{};
    for (final r in _allRecords) {
      if (r.batchName.isNotEmpty) {
        batches.add(r.batchName);
      }
    }
    final list = batches.toList();
    list.sort();
    return list;
  }

  Future<void> loadAttendance({
    required TenantPathResolver resolver,
    required String studentId,
    required String studentName,
    String? batchId,
    String? fallbackTeacherId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allRecords = await _service.fetchStudentAttendance(
        resolver: resolver,
        studentId: studentId,
        batchId: batchId,
        fallbackTeacherId: fallbackTeacherId,
      );

      _summary = StudentAttendanceSummary.fromRecords(
        studentId: studentId,
        studentName: studentName,
        records: _allRecords,
      );
    } catch (e) {
      _errorMessage = 'Failed to load attendance: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setBatchFilter(String? batch) {
    _batchFilter = batch;
    notifyListeners();
  }

  void setMonthFilter(int? month, int? year) {
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _batchFilter = null;
    _selectedMonth = null;
    _selectedYear = null;
    notifyListeners();
  }
}
