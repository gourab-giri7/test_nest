import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/batch_student_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/notice_model.dart';

class TeacherAssignedStudent {
  final String studentUid;
  final String studentName;
  final String studentEmail;
  final String studentPhone;
  final List<String> batchIds;
  final List<String> batchNames;
  final String status;
  final DateTime? enrolledAt;

  const TeacherAssignedStudent({
    required this.studentUid,
    required this.studentName,
    required this.studentEmail,
    this.studentPhone = '',
    required this.batchIds,
    required this.batchNames,
    this.status = 'active',
    this.enrolledAt,
  });

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return studentName.toLowerCase().contains(q) ||
        studentEmail.toLowerCase().contains(q) ||
        studentPhone.toLowerCase().contains(q);
  }
}

class InstituteTeacherDashboardController extends ChangeNotifier {
  final ActiveTenantContext tenantContext;
  final String teacherUid;
  final FirebaseFirestore? _explicitFirestore;

  InstituteTeacherDashboardController({
    ActiveTenantContext? tenantContext,
    String? teacherUid,
    FirebaseFirestore? firestore,
    bool autoListen = true,
  }) : tenantContext = tenantContext ?? ActiveTenantContext(),
       teacherUid = teacherUid ?? '',
       _explicitFirestore = firestore {
    if (autoListen) {
      initListeners();
    }
  }

  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  int _currentTabIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  List<BatchModel> _batches = [];
  final Map<String, List<BatchStudentModel>> _batchStudentsMap = {};
  List<TeacherAssignedStudent> _instituteStudents = [];
  List<ExamModel> _exams = [];
  List<NoticeModel> _notices = [];

  String _studentSearchQuery = '';
  String _studentBatchFilter = 'all';
  String _batchSearchQuery = '';
  String _examSearchQuery = '';
  String _examStatusFilter = 'all';

  StreamSubscription? _batchSub;
  StreamSubscription? _studentSub;
  final Map<String, StreamSubscription> _batchStudentSubs = {};
  StreamSubscription? _examSub;
  StreamSubscription? _noticeSub;

  // ── Getters ─────────────────────────────────────────────────────────────
  int get currentTabIndex => _currentTabIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BatchModel> get batches => List.unmodifiable(_batches);
  List<ExamModel> get exams => List.unmodifiable(_exams);
  List<NoticeModel> get notices => List.unmodifiable(_notices);

  String get studentSearchQuery => _studentSearchQuery;
  String get studentBatchFilter => _studentBatchFilter;
  String get batchSearchQuery => _batchSearchQuery;
  String get examSearchQuery => _examSearchQuery;
  String get examStatusFilter => _examStatusFilter;

  String get orgId => tenantContext.activeOrgId;
  String get orgName => tenantContext.activeOrgName;
  String get effectiveTeacherUid =>
      teacherUid.isNotEmpty ? teacherUid : (tenantContext.currentUid ?? '');

  int get assignedBatchesCount => _batches.length;
  int get activeExamsCount =>
      _exams.where((e) => e.status.toLowerCase() == 'active').length;

  List<BatchModel> get todayScheduledBatches => _batches
      .where((b) => b.schedule != null && b.schedule!.trim().isNotEmpty)
      .toList();

  /// Returns deduplicated students across the entire Coaching Institute.
  /// No batch restriction: includes unassigned students and students across all batches.
  List<TeacherAssignedStudent> get deduplicatedStudents {
    final map = <String, TeacherAssignedStudent>{};

    // 1. Seed with all institute students from organizations/{orgId}/students
    for (final s in _instituteStudents) {
      map[s.studentUid] = s;
    }

    // 2. Merge with any batch-enrolled students from batches/{bid}/students
    for (final entry in _batchStudentsMap.entries) {
      final batchId = entry.key;
      final studentList = entry.value;

      final batchObj = _batches.firstWhere(
        (b) => b.id == batchId,
        orElse: () => BatchModel(
          id: batchId,
          name: batchId,
          activeJoinCode: '',
          teacherId: '',
        ),
      );

      for (final s in studentList) {
        if (!s.isActive) continue;
        final uid = s.studentUid;

        if (map.containsKey(uid)) {
          final existing = map[uid]!;
          final updatedBatchIds = List<String>.from(existing.batchIds)
            ..removeWhere((id) => id.isEmpty);
          final updatedBatchNames = List<String>.from(existing.batchNames)
            ..remove('Unassigned');

          if (!updatedBatchIds.contains(batchId)) {
            updatedBatchIds.add(batchId);
            updatedBatchNames.add(batchObj.name);
          }

          map[uid] = TeacherAssignedStudent(
            studentUid: existing.studentUid,
            studentName: existing.studentName.isNotEmpty
                ? existing.studentName
                : s.studentName,
            studentEmail: existing.studentEmail.isNotEmpty
                ? existing.studentEmail
                : s.studentEmail,
            studentPhone: existing.studentPhone.isNotEmpty
                ? existing.studentPhone
                : (s.studentPhone ?? ''),
            batchIds: updatedBatchIds,
            batchNames: updatedBatchNames.isNotEmpty
                ? updatedBatchNames
                : ['Unassigned'],
            status: existing.status,
            enrolledAt: existing.enrolledAt ?? s.enrolledAt,
          );
        } else {
          map[uid] = TeacherAssignedStudent(
            studentUid: s.studentUid,
            studentName: s.studentName,
            studentEmail: s.studentEmail,
            studentPhone: s.studentPhone ?? '',
            batchIds: [batchId],
            batchNames: [batchObj.name],
            status: s.status,
            enrolledAt: s.enrolledAt,
          );
        }
      }
    }

    final list = map.values.toList();
    list.sort(
      (a, b) =>
          a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase()),
    );
    return list;
  }

  int get assignedStudentsCount => deduplicatedStudents.length;

  List<TeacherAssignedStudent> get filteredStudents {
    var list = deduplicatedStudents;

    if (_studentBatchFilter != 'all') {
      list = list
          .where((s) => s.batchIds.contains(_studentBatchFilter))
          .toList();
    }

    if (_studentSearchQuery.trim().isNotEmpty) {
      list = list
          .where((s) => s.matchesSearch(_studentSearchQuery.trim()))
          .toList();
    }

    return list;
  }

  List<BatchModel> get filteredBatches {
    if (_batchSearchQuery.trim().isEmpty) return _batches;
    final q = _batchSearchQuery.trim().toLowerCase();
    return _batches
        .where(
          (b) =>
              b.name.toLowerCase().contains(q) ||
              (b.subject != null && b.subject!.toLowerCase().contains(q)),
        )
        .toList();
  }

  List<ExamModel> get filteredExams {
    var list = _exams;

    if (_examStatusFilter != 'all') {
      list = list
          .where(
            (e) => e.status.toLowerCase() == _examStatusFilter.toLowerCase(),
          )
          .toList();
    }

    if (_examSearchQuery.trim().isNotEmpty) {
      final q = _examSearchQuery.trim().toLowerCase();
      list = list
          .where(
            (e) =>
                e.examName.toLowerCase().contains(q) ||
                e.examId.toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  // ── Mutators ─────────────────────────────────────────────────────────────
  void switchTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void setStudentSearchQuery(String query) {
    _studentSearchQuery = query;
    notifyListeners();
  }

  void setStudentBatchFilter(String batchId) {
    _studentBatchFilter = batchId;
    notifyListeners();
  }

  void setBatchSearchQuery(String query) {
    _batchSearchQuery = query;
    notifyListeners();
  }

  void setExamSearchQuery(String query) {
    _examSearchQuery = query;
    notifyListeners();
  }

  void setExamStatusFilter(String filter) {
    _examStatusFilter = filter;
    notifyListeners();
  }

  // ── Listener Initialization ──────────────────────────────────────────────
  void initListeners() {
    _cancelSubscriptions();

    final currentOrgId = orgId;
    final currentTeacherUid = effectiveTeacherUid;

    if (currentOrgId.isEmpty ||
        !tenantContext.isInstitute ||
        currentTeacherUid.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Stream all batches for this institute so teacher can view and filter
      _batchSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('batches')
          .snapshots()
          .listen(
            (snapshot) {
              final updatedBatches = snapshot.docs
                  .map((doc) => BatchModel.fromJson(doc.data(), docId: doc.id))
                  .where((b) => !b.isArchived)
                  .toList();

              _batches = updatedBatches;
              _updateBatchStudentSubscriptions(currentOrgId, updatedBatches);
              _isLoading = false;
              notifyListeners();
            },
            onError: (e) {
              _errorMessage = 'Failed to load batches: $e';
              _isLoading = false;
              notifyListeners();
            },
          );

      // 2. Stream all institute students directly (no batch restriction)
      _studentSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('students')
          .snapshots()
          .listen(
            (snapshot) {
              final list = <TeacherAssignedStudent>[];
              for (final doc in snapshot.docs) {
                final data = doc.data();
                final uid =
                    (data['auth_uid'] ?? data['id'] ?? doc.id).toString();
                final name = (data['name'] ?? '').toString();
                final email = (data['email'] ?? '').toString();
                final phone = (data['phone'] ?? '').toString();
                final status = (data['status'] ?? 'active').toString();
                final batchName = (data['batch'] ?? '').toString();
                final batchId =
                    (data['batch_id'] ?? data['batchId'] ?? '').toString();

                List<String> bIds = [];
                List<String> bNames = [];

                if (data['assigned_batch_ids'] is List) {
                  bIds = (data['assigned_batch_ids'] as List)
                      .map((e) => e.toString())
                      .toList();
                } else if (batchId.isNotEmpty) {
                  bIds = [batchId];
                }

                for (final bId in bIds) {
                  final bObj = _batches.where((b) => b.id == bId).firstOrNull;
                  if (bObj != null) {
                    bNames.add(bObj.name);
                  }
                }
                if (bNames.isEmpty && batchName.isNotEmpty) {
                  bNames.add(batchName);
                }
                if (bNames.isEmpty) {
                  bNames.add('Unassigned');
                }

                list.add(TeacherAssignedStudent(
                  studentUid: uid,
                  studentName: name,
                  studentEmail: email,
                  studentPhone: phone,
                  batchIds: bIds,
                  batchNames: bNames,
                  status: status,
                ));
              }
              _instituteStudents = list;
              notifyListeners();
            },
            onError: (_) {},
          );

      // 3. Stream exams for this institute
      _examSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('exams')
          .orderBy('exam_id', descending: true)
          .snapshots()
          .listen((snapshot) {
            final allExams = snapshot.docs
                .map((d) => ExamModel.fromJson(d.data()))
                .toList();

            // Only keep exams matching assigned batches or created by this teacher
            final assignedBatchNamesAndIds = <String>{};
            for (final b in _batches) {
              assignedBatchNamesAndIds.add(b.id);
              assignedBatchNamesAndIds.add(b.name.trim().toLowerCase());
            }
            _exams = allExams.where((exam) {
              if (exam.teacherId == currentTeacherUid) return true;
              final b = exam.batch.trim().toLowerCase();
              return assignedBatchNamesAndIds.contains(b) ||
                  assignedBatchNamesAndIds.contains(exam.batch.trim());
            }).toList();

            notifyListeners();
          }, onError: (_) {});

      // 3. Stream notices for this institute
      _noticeSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('notices')
          .where('status', isEqualTo: 'published')
          .orderBy('publishedAt', descending: true)
          .limit(10)
          .snapshots()
          .listen((snapshot) {
            _notices = snapshot.docs
                .map((d) => NoticeModel.fromMap(d.data(), d.id))
                .toList();
            notifyListeners();
          }, onError: (_) {});
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateBatchStudentSubscriptions(
    String currentOrgId,
    List<BatchModel> currentBatches,
  ) {
    final activeBatchIds = currentBatches.map((b) => b.id).toSet();

    // Cancel subscriptions for batches no longer assigned
    final removedBatchIds = _batchStudentSubs.keys
        .where((bid) => !activeBatchIds.contains(bid))
        .toList();

    for (final bid in removedBatchIds) {
      _batchStudentSubs[bid]?.cancel();
      _batchStudentSubs.remove(bid);
      _batchStudentsMap.remove(bid);
    }

    // Add subscriptions for newly assigned batches
    for (final batch in currentBatches) {
      final bid = batch.id;
      if (_batchStudentSubs.containsKey(bid)) continue;

      _batchStudentSubs[bid] = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('batches')
          .doc(bid)
          .collection('students')
          .snapshots()
          .listen((snapshot) {
            final students = snapshot.docs
                .map((d) => BatchStudentModel.fromJson(d.data(), docId: d.id))
                .toList();

            _batchStudentsMap[bid] = students;
            notifyListeners();
          }, onError: (_) {});
    }
  }

  void _cancelSubscriptions() {
    _batchSub?.cancel();
    _batchSub = null;

    _studentSub?.cancel();
    _studentSub = null;
    _instituteStudents.clear();

    for (final sub in _batchStudentSubs.values) {
      sub.cancel();
    }
    _batchStudentSubs.clear();
    _batchStudentsMap.clear();

    _examSub?.cancel();
    _examSub = null;

    _noticeSub?.cancel();
    _noticeSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
