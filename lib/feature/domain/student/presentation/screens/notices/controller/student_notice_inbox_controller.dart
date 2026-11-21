import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/core/services/notice_service.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/model/notice_model.dart';

class StudentNoticeInboxController extends ChangeNotifier {
  final NoticeService _service;

  StudentNoticeInboxController({NoticeService? service})
    : _service = service ?? NoticeService();

  List<NoticeModel> _allNotices = [];
  Set<String> _readNoticeIds = {};
  String? _studentUid;

  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<NoticeModel> get allNotices => _allNotices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  int get unreadCount =>
      _allNotices.where((n) => !_readNoticeIds.contains(n.id)).length;

  bool isRead(String noticeId) => _readNoticeIds.contains(noticeId);

  List<NoticeModel> get filteredNotices {
    return _allNotices.where((n) {
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        if (n.category.toLowerCase() != _selectedCategory!.toLowerCase()) {
          return false;
        }
      }

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
    required String studentUid,
    required List<String> enrolledBatchIds,
    String? fallbackTeacherId,
  }) async {
    _studentUid = studentUid;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load local read receipts
      final prefs = await SharedPreferences.getInstance();
      final readList = prefs.getStringList('read_notices_$studentUid') ?? [];
      _readNoticeIds = readList.toSet();

      _allNotices = await _service.fetchPublishedNoticesForStudent(
        resolver: resolver,
        studentUid: studentUid,
        enrolledBatchIds: enrolledBatchIds,
        fallbackTeacherId: fallbackTeacherId,
      );
    } catch (e) {
      _errorMessage = 'Failed to load notices: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String noticeId) async {
    if (_readNoticeIds.contains(noticeId)) return;
    _readNoticeIds.add(noticeId);
    notifyListeners();

    if (_studentUid != null && _studentUid!.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'read_notices_$_studentUid',
          _readNoticeIds.toList(),
        );
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _allNotices) {
      _readNoticeIds.add(n.id);
    }
    notifyListeners();

    if (_studentUid != null && _studentUid!.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'read_notices_$_studentUid',
          _readNoticeIds.toList(),
        );
      } catch (_) {}
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
}
