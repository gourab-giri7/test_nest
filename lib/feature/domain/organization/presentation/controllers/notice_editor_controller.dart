import 'package:flutter/material.dart';
import 'package:test_nest/core/services/notice_service.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/notice_model.dart';

class NoticeEditorController extends ChangeNotifier {
  final NoticeService _service;

  NoticeEditorController({NoticeService? service})
    : _service = service ?? NoticeService();

  NoticeModel? _existingNotice;
  String _title = '';
  String _body = '';
  String _category = NoticeCategory.general;
  String _audienceType = NoticeAudienceType.all;
  List<String> _selectedBatchIds = [];
  List<String> _selectedStudentIds = [];
  String? _attachmentUrl;

  List<BatchModel> _availableBatches = [];
  List<StudentModel> _availableStudents = [];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Initial snapshot for dirty checking
  late String _initialTitle;
  late String _initialBody;
  late String _initialCategory;
  late String _initialAudienceType;
  late List<String> _initialBatchIds;
  late List<String> _initialStudentIds;

  // Getters
  NoticeModel? get existingNotice => _existingNotice;
  bool get isEditing => _existingNotice != null;

  String get title => _title;
  String get body => _body;
  String get category => _category;
  String get audienceType => _audienceType;
  List<String> get selectedBatchIds => _selectedBatchIds;
  List<String> get selectedStudentIds => _selectedStudentIds;
  String? get attachmentUrl => _attachmentUrl;

  List<BatchModel> get availableBatches => _availableBatches;
  List<StudentModel> get availableStudents => _availableStudents;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool get isDirty {
    if (_title != _initialTitle) return true;
    if (_body != _initialBody) return true;
    if (_category != _initialCategory) return true;
    if (_audienceType != _initialAudienceType) return true;
    if (_selectedBatchIds.length != _initialBatchIds.length ||
        !_selectedBatchIds.toSet().containsAll(_initialBatchIds)) {
      return true;
    }
    if (_selectedStudentIds.length != _initialStudentIds.length ||
        !_selectedStudentIds.toSet().containsAll(_initialStudentIds)) {
      return true;
    }
    return false;
  }

  String? get validationError {
    if (_title.trim().isEmpty) return 'Notice title is required.';
    if (_body.trim().isEmpty) return 'Notice body/message is required.';
    if (_audienceType == NoticeAudienceType.batches &&
        _selectedBatchIds.isEmpty) {
      return 'Please select at least one batch.';
    }
    if (_audienceType == NoticeAudienceType.students &&
        _selectedStudentIds.isEmpty) {
      return 'Please select at least one student.';
    }
    return null;
  }

  bool get isValid => validationError == null;

  Future<void> initialize({
    required TenantPathResolver resolver,
    NoticeModel? existingNotice,
    String? teacherUid,
    bool isTeacherInInstitute = false,
    String? fallbackTeacherId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _existingNotice = existingNotice;

      // Teachers in an institute can only target their assigned batches
      final filterUid = (resolver.isInstitute && isTeacherInInstitute)
          ? teacherUid
          : null;

      _availableBatches = await _service.fetchAvailableBatches(
        resolver: resolver,
        filterTeacherUid: filterUid,
        fallbackTeacherId: fallbackTeacherId,
      );

      if (existingNotice != null) {
        _title = existingNotice.title;
        _body = existingNotice.body;
        _category = existingNotice.category;
        _audienceType = existingNotice.audienceType;
        _selectedBatchIds = List<String>.from(existingNotice.targetBatchIds);
        _selectedStudentIds = List<String>.from(
          existingNotice.targetStudentIds,
        );
        _attachmentUrl = existingNotice.attachmentUrl;
      } else {
        _title = '';
        _body = '';
        _category = NoticeCategory.general;
        // Non-admin teachers cannot target entire institute
        if (resolver.isInstitute && isTeacherInInstitute) {
          _audienceType = NoticeAudienceType.batches;
          if (_availableBatches.isNotEmpty) {
            _selectedBatchIds = [_availableBatches.first.id];
          }
        } else {
          _audienceType = NoticeAudienceType.all;
          _selectedBatchIds = [];
        }
        _selectedStudentIds = [];
        _attachmentUrl = null;
      }

      // Load students for available batches if student targeting is active
      await _loadStudentsForSelectedBatches(
        resolver,
        fallbackTeacherId: fallbackTeacherId,
      );

      _captureBaseline();
    } catch (e) {
      _errorMessage = 'Failed to initialize notice editor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _captureBaseline() {
    _initialTitle = _title;
    _initialBody = _body;
    _initialCategory = _category;
    _initialAudienceType = _audienceType;
    _initialBatchIds = List<String>.from(_selectedBatchIds);
    _initialStudentIds = List<String>.from(_selectedStudentIds);
  }

  void setTitle(String val) {
    _title = val;
    notifyListeners();
  }

  void setBody(String val) {
    _body = val;
    notifyListeners();
  }

  void setCategory(String val) {
    if (NoticeCategory.isValid(val)) {
      _category = val;
      notifyListeners();
    }
  }

  void setAudienceType(String val) {
    if (NoticeAudienceType.isValid(val)) {
      _audienceType = val;
      notifyListeners();
    }
  }

  Future<void> toggleBatch(
    String batchId, {
    required TenantPathResolver resolver,
    String? fallbackTeacherId,
  }) async {
    if (_selectedBatchIds.contains(batchId)) {
      _selectedBatchIds.remove(batchId);
    } else {
      _selectedBatchIds.add(batchId);
    }
    notifyListeners();

    await _loadStudentsForSelectedBatches(
      resolver,
      fallbackTeacherId: fallbackTeacherId,
    );
  }

  void selectAllBatches() {
    _selectedBatchIds = _availableBatches.map((b) => b.id).toList();
    notifyListeners();
  }

  void deselectAllBatches() {
    _selectedBatchIds.clear();
    notifyListeners();
  }

  void toggleStudent(String studentId) {
    if (_selectedStudentIds.contains(studentId)) {
      _selectedStudentIds.remove(studentId);
    } else {
      _selectedStudentIds.add(studentId);
    }
    notifyListeners();
  }

  void selectAllStudents() {
    _selectedStudentIds = _availableStudents.map((s) {
      return s.authUid.isNotEmpty ? s.authUid : s.id;
    }).toList();
    notifyListeners();
  }

  void deselectAllStudents() {
    _selectedStudentIds.clear();
    notifyListeners();
  }

  Future<void> _loadStudentsForSelectedBatches(
    TenantPathResolver resolver, {
    String? fallbackTeacherId,
  }) async {
    final targetBatches = _availableBatches
        .where((b) => _selectedBatchIds.contains(b.id))
        .toList();

    if (targetBatches.isEmpty) {
      _availableStudents = [];
    } else {
      _availableStudents = await _service.fetchAvailableStudentsForBatches(
        resolver: resolver,
        selectedBatches: targetBatches,
        fallbackTeacherId: fallbackTeacherId,
      );
    }
    notifyListeners();
  }

  /// Saves the notice either as a draft or published directly.
  Future<NoticeModel?> saveNotice({
    required TenantPathResolver resolver,
    required bool publish,
    required String userUid,
    required String userName,
    String? fallbackTeacherId,
  }) async {
    final err = validationError;
    if (err != null) {
      _errorMessage = err;
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();

      // Collect human-readable target batch and student names for easy display
      final targetBatchNames = _availableBatches
          .where((b) => _selectedBatchIds.contains(b.id))
          .map((b) => b.name)
          .toList();

      final targetStudentNames = _availableStudents
          .where((s) {
            final key = s.authUid.isNotEmpty ? s.authUid : s.id;
            return _selectedStudentIds.contains(key);
          })
          .map((s) => s.name)
          .toList();

      final noticeToSave = NoticeModel(
        id: _existingNotice?.id ?? '',
        organizationId: resolver.isInstitute ? resolver.orgId : '',
        teacherId: !resolver.isInstitute
            ? (fallbackTeacherId ?? userUid)
            : (_existingNotice?.teacherId ?? userUid),
        title: _title.trim(),
        body: _body.trim(),
        category: _category,
        status: publish ? NoticeStatus.published : NoticeStatus.draft,
        audienceType: _audienceType,
        targetBatchIds: _audienceType == NoticeAudienceType.all
            ? const []
            : _selectedBatchIds,
        targetBatchNames: _audienceType == NoticeAudienceType.all
            ? const []
            : targetBatchNames,
        targetStudentIds: _audienceType == NoticeAudienceType.students
            ? _selectedStudentIds
            : const [],
        targetStudentNames: _audienceType == NoticeAudienceType.students
            ? targetStudentNames
            : const [],
        attachmentUrl: _attachmentUrl,
        createdBy: _existingNotice?.createdBy ?? userUid,
        createdByName: _existingNotice?.createdByName.isNotEmpty == true
            ? _existingNotice!.createdByName
            : userName,
        updatedBy: userUid,
        updatedByName: userName,
        createdAt: _existingNotice?.createdAt ?? now,
        updatedAt: now,
        publishedAt: publish
            ? (_existingNotice?.publishedAt ?? now)
            : _existingNotice?.publishedAt,
        archivedAt: _existingNotice?.archivedAt,
      );

      NoticeModel result;
      if (isEditing) {
        result = await _service.updateNotice(
          resolver: resolver,
          notice: noticeToSave,
          fallbackTeacherId: fallbackTeacherId,
        );
      } else {
        result = await _service.createNotice(
          resolver: resolver,
          notice: noticeToSave,
          fallbackTeacherId: fallbackTeacherId,
        );
      }

      _existingNotice = result;
      _captureBaseline();
      return result;
    } catch (e) {
      _errorMessage = 'Failed to save notice: $e';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void discardChanges() {
    _title = _initialTitle;
    _body = _initialBody;
    _category = _initialCategory;
    _audienceType = _initialAudienceType;
    _selectedBatchIds = List<String>.from(_initialBatchIds);
    _selectedStudentIds = List<String>.from(_initialStudentIds);
    _errorMessage = null;
    notifyListeners();
  }
}
