import 'package:flutter/material.dart';
import 'package:test_nest/core/services/notice_service.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/model/notice_model.dart';

class NoticeManagementController extends ChangeNotifier {
  final NoticeService _service;

  NoticeManagementController({NoticeService? service})
    : _service = service ?? NoticeService();

  List<NoticeModel> _allNotices = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  int _selectedTab = 0; // 0: All, 1: Published, 2: Draft, 3: Archived
  String? _selectedCategory;
  String _searchQuery = '';

  List<NoticeModel> get allNotices => _allNotices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  int get selectedTab => _selectedTab;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  int get publishedCount =>
      _allNotices.where((n) => n.status == NoticeStatus.published).length;
  int get draftCount =>
      _allNotices.where((n) => n.status == NoticeStatus.draft).length;
  int get archivedCount =>
      _allNotices.where((n) => n.status == NoticeStatus.archived).length;

  List<NoticeModel> get filteredNotices {
    return _allNotices.where((n) {
      // Tab filter
      if (_selectedTab == 1 && n.status != NoticeStatus.published) return false;
      if (_selectedTab == 2 && n.status != NoticeStatus.draft) return false;
      if (_selectedTab == 3 && n.status != NoticeStatus.archived) return false;

      // Category filter
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (n.category.toLowerCase() != _selectedCategory!.toLowerCase()) {
          return false;
        }
      }

      // Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final inTitle = n.title.toLowerCase().contains(q);
        final inBody = n.body.toLowerCase().contains(q);
        final inAuthor = n.createdByName.toLowerCase().contains(q);
        if (!inTitle && !inBody && !inAuthor) return false;
      }

      return true;
    }).toList();
  }

  Future<void> loadNotices({
    required TenantPathResolver resolver,
    String? teacherUid,
    bool isTeacherInInstitute = false,
    String? fallbackTeacherId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allNotices = await _service.fetchNoticesForAdminOrTeacher(
        resolver: resolver,
        teacherUid: teacherUid,
        isTeacherInInstitute: isTeacherInInstitute,
        fallbackTeacherId: fallbackTeacherId,
      );
    } catch (e) {
      _errorMessage = 'Failed to load notices: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> publishNotice({
    required TenantPathResolver resolver,
    required NoticeModel notice,
    required String updaterUid,
    required String updaterName,
    String? fallbackTeacherId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _service.publishNotice(
        resolver: resolver,
        notice: notice,
        updaterUid: updaterUid,
        updaterName: updaterName,
        fallbackTeacherId: fallbackTeacherId,
      );

      final idx = _allNotices.indexWhere((n) => n.id == updated.id);
      if (idx != -1) {
        _allNotices[idx] = updated;
      }
      _successMessage = 'Notice published successfully.';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to publish notice: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> unpublishNotice({
    required TenantPathResolver resolver,
    required NoticeModel notice,
    required String updaterUid,
    required String updaterName,
    String? fallbackTeacherId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _service.unpublishNotice(
        resolver: resolver,
        notice: notice,
        updaterUid: updaterUid,
        updaterName: updaterName,
        fallbackTeacherId: fallbackTeacherId,
      );

      final idx = _allNotices.indexWhere((n) => n.id == updated.id);
      if (idx != -1) {
        _allNotices[idx] = updated;
      }
      _successMessage = 'Notice moved back to drafts.';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to unpublish notice: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> archiveNotice({
    required TenantPathResolver resolver,
    required NoticeModel notice,
    required String updaterUid,
    required String updaterName,
    String? fallbackTeacherId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await _service.archiveNotice(
        resolver: resolver,
        notice: notice,
        updaterUid: updaterUid,
        updaterName: updaterName,
        fallbackTeacherId: fallbackTeacherId,
      );

      final idx = _allNotices.indexWhere((n) => n.id == updated.id);
      if (idx != -1) {
        _allNotices[idx] = updated;
      }
      _successMessage = 'Notice archived.';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to archive notice: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteNotice({
    required TenantPathResolver resolver,
    required String noticeId,
    String? fallbackTeacherId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _service.deleteNotice(
        resolver: resolver,
        noticeId: noticeId,
        fallbackTeacherId: fallbackTeacherId,
      );

      _allNotices.removeWhere((n) => n.id == noticeId);
      _successMessage = 'Notice deleted.';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete notice: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
