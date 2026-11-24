import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/notice_model.dart';

class StudentSubmissionResultItem {
  final String examId;
  final String examName;
  final String batch;
  final String subject;
  final DateTime? examDate;
  final double obtainedMarks;
  final double totalMarks;
  final double percentage;
  final String status;
  final Map<String, dynamic> submissionData;
  final ExamModel? exam;

  const StudentSubmissionResultItem({
    required this.examId,
    required this.examName,
    required this.batch,
    this.subject = '',
    this.examDate,
    required this.obtainedMarks,
    required this.totalMarks,
    required this.percentage,
    required this.status,
    required this.submissionData,
    this.exam,
  });
}

class StudentWorkspaceController extends ChangeNotifier {
  final ActiveTenantContext tenantContext;
  final String studentUid;
  final FirebaseFirestore? _explicitFirestore;

  StudentWorkspaceController({
    ActiveTenantContext? tenantContext,
    String? studentUid,
    FirebaseFirestore? firestore,
    bool autoListen = true,
  }) : tenantContext = tenantContext ?? ActiveTenantContext(),
       studentUid = studentUid ?? _resolveCurrentUid(),
       _explicitFirestore = firestore {
    if (autoListen) {
      initListeners();
    }
  }

  static String _resolveCurrentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  int _currentTabIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  List<BatchModel> _batches = [];
  List<ExamModel> _exams = [];
  List<StudentSubmissionResultItem> _results = [];
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<NoticeModel> _notices = [];
  Set<String> _readNoticeIds = {};
  FeeRecord? _feeRecord;

  String _examSearchQuery = '';
  String _examFilter = 'all';
  String _resultSearchQuery = '';
  String _noticeSearchQuery = '';

  StreamSubscription? _memberSub;
  StreamSubscription? _batchSub;
  StreamSubscription? _examSub;
  StreamSubscription? _attendanceSub;
  StreamSubscription? _feeSub;
  StreamSubscription? _noticeSub;

  // ── Getters ─────────────────────────────────────────────────────────────
  int get currentTabIndex => _currentTabIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<BatchModel> get batches => List.unmodifiable(_batches);
  List<ExamModel> get exams => List.unmodifiable(_exams);
  List<StudentSubmissionResultItem> get results => List.unmodifiable(_results);
  List<Map<String, dynamic>> get attendanceRecords =>
      List.unmodifiable(_attendanceRecords);
  List<NoticeModel> get notices => List.unmodifiable(_notices);
  FeeRecord? get feeRecord => _feeRecord;

  String get examSearchQuery => _examSearchQuery;
  String get examFilter => _examFilter;
  String get resultSearchQuery => _resultSearchQuery;
  String get noticeSearchQuery => _noticeSearchQuery;

  int get unreadNoticeCount =>
      _notices.where((n) => !_readNoticeIds.contains(n.id)).length;
  bool get hasUnreadNotices => unreadNoticeCount > 0;

  void _loadReadNotices(String uid) {
    if (uid.isEmpty) return;
    SharedPreferences.getInstance().then((prefs) {
      final list = prefs.getStringList('read_notices_$uid') ?? [];
      _readNoticeIds = list.toSet();
      notifyListeners();
    }).catchError((_) {});
  }

  void markAllNoticesAsRead() {
    if (_notices.isEmpty) return;
    _readNoticeIds.addAll(_notices.map((n) => n.id));
    notifyListeners();
    final uid = studentUid.isNotEmpty ? studentUid : _resolveCurrentUid();
    if (uid.isNotEmpty) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setStringList('read_notices_$uid', _readNoticeIds.toList());
      }).catchError((_) {});
    }
  }

  String get orgId {
    if (tenantContext.isInstitute && tenantContext.activeOrgId.isNotEmpty) {
      return tenantContext.activeOrgId;
    }
    return studentData?.orgId ?? '';
  }

  String get orgName {
    if (tenantContext.isInstitute && tenantContext.activeOrgName.isNotEmpty) {
      return tenantContext.activeOrgName;
    }
    return studentData?.orgName ?? 'Coaching Institute';
  }

  int get activeBatchCount => _batches.length;

  List<ExamModel> get upcomingExams =>
      _exams.where((e) => e.status.toLowerCase() == 'upcoming').toList();

  List<ExamModel> get activeExams =>
      _exams.where((e) => e.status.toLowerCase() == 'active').toList();

  // Attendance metrics
  int get attendancePresentCount => _attendanceRecords
      .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'present')
      .length;

  int get attendanceAbsentCount => _attendanceRecords
      .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'absent')
      .length;

  int get attendanceLateCount => _attendanceRecords
      .where((r) => (r['status'] ?? '').toString().toLowerCase() == 'late')
      .length;

  int get attendanceTotalCount => _attendanceRecords.length;

  double get attendancePercentage {
    if (attendanceTotalCount == 0) return 0.0;
    return (attendancePresentCount / attendanceTotalCount) * 100;
  }

  double get outstandingFeeAmount => _feeRecord?.balance ?? 0.0;

  // Filtered views
  List<ExamModel> get filteredExams {
    var list = _exams;

    if (_examFilter != 'all') {
      list = list
          .where((e) => e.status.toLowerCase() == _examFilter.toLowerCase())
          .toList();
    }

    if (_examSearchQuery.trim().isNotEmpty) {
      final q = _examSearchQuery.trim().toLowerCase();
      list = list
          .where(
            (e) =>
                e.examName.toLowerCase().contains(q) ||
                e.examId.toLowerCase().contains(q) ||
                e.batch.toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  List<StudentSubmissionResultItem> get filteredResults {
    if (_resultSearchQuery.trim().isEmpty) return _results;
    final q = _resultSearchQuery.trim().toLowerCase();
    return _results
        .where(
          (r) =>
              r.examName.toLowerCase().contains(q) ||
              r.batch.toLowerCase().contains(q) ||
              r.subject.toLowerCase().contains(q),
        )
        .toList();
  }

  List<NoticeModel> get filteredNotices {
    if (_noticeSearchQuery.trim().isEmpty) return _notices;
    final q = _noticeSearchQuery.trim().toLowerCase();
    return _notices
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.body.toLowerCase().contains(q),
        )
        .toList();
  }

  // ── Mutators ─────────────────────────────────────────────────────────────
  void switchTab(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      if (index == 3) {
        markAllNoticesAsRead();
      }
      notifyListeners();
    }
  }

  void setExamSearchQuery(String query) {
    _examSearchQuery = query;
    notifyListeners();
  }

  void setExamFilter(String filter) {
    _examFilter = filter;
    notifyListeners();
  }

  void setResultSearchQuery(String query) {
    _resultSearchQuery = query;
    notifyListeners();
  }

  void setNoticeSearchQuery(String query) {
    _noticeSearchQuery = query;
    notifyListeners();
  }

  @visibleForTesting
  void setTestData({
    List<BatchModel>? batches,
    List<ExamModel>? exams,
    List<StudentSubmissionResultItem>? results,
    List<Map<String, dynamic>>? attendanceRecords,
    List<NoticeModel>? notices,
    FeeRecord? feeRecord,
  }) {
    if (batches != null) _batches = batches;
    if (exams != null) _exams = exams;
    if (results != null) _results = results;
    if (attendanceRecords != null) _attendanceRecords = attendanceRecords;
    if (notices != null) _notices = notices;
    if (feeRecord != null) _feeRecord = feeRecord;
    _isLoading = false;
    notifyListeners();
  }

  // ── Listener Initialization ──────────────────────────────────────────────
  void initListeners() {
    _cancelSubscriptions();

    final currentOrgId = orgId;
    final currentStudentUid = studentUid;

    if (currentOrgId.isEmpty || currentStudentUid.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _loadReadNotices(currentStudentUid);
    notifyListeners();

    try {
      // 1. Listen to student's member doc in the organization
      _memberSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('members')
          .doc(currentStudentUid)
          .snapshots()
          .listen(
            (doc) {
              final data = doc.data() ?? {};
              final rawBatches = data['assignedBatchIds'];
              final assignedBatches = <String>[];
              if (rawBatches is List) {
                assignedBatches.addAll(rawBatches.map((e) => e.toString()));
              }

              _loadBatchesAndExams(currentOrgId, assignedBatches);
            },
            onError: (e) {
              _errorMessage = e.toString();
              _isLoading = false;
              notifyListeners();
            },
          );

      // 2. Attendance stream for this student
      _attendanceSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('attendance')
          .where('student_uid', isEqualTo: currentStudentUid)
          .snapshots()
          .listen((snapshot) {
            _attendanceRecords = snapshot.docs.map((d) => d.data()).toList();
            notifyListeners();
          }, onError: (_) {});

      // 3. Fee record stream for this student
      _feeSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('feeRecords')
          .doc(currentStudentUid)
          .snapshots()
          .listen((doc) {
            if (doc.exists && doc.data() != null) {
              _feeRecord = FeeRecord.fromJson(doc.data()!, docId: doc.id);
            } else {
              _feeRecord = null;
            }
            notifyListeners();
          }, onError: (_) {});

      // 4. Notices stream for this organization (indexed in memory to prevent missing index errors)
      _noticeSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('notices')
          .where('status', isEqualTo: 'published')
          .snapshots()
          .listen((snapshot) {
            final allNotices = snapshot.docs
                .map((d) => NoticeModel.fromMap(d.data(), d.id))
                .toList();

            final enrolledBatchIds = _batches.map((b) => b.id).toSet();
            final filtered = allNotices.where((n) {
              if (n.audienceType == NoticeAudienceType.all) return true;
              if (n.audienceType == NoticeAudienceType.students) {
                return n.targetStudentIds.isEmpty ||
                    n.targetStudentIds.contains(currentStudentUid);
              }
              if (n.audienceType == NoticeAudienceType.batches) {
                return n.targetBatchIds.any(
                  (bid) => enrolledBatchIds.contains(bid),
                );
              }
              return false;
            }).toList();

            filtered.sort((a, b) {
              final dateA = a.publishedAt ?? a.createdAt;
              final dateB = b.publishedAt ?? b.createdAt;
              return dateB.compareTo(dateA);
            });

            _notices = filtered;
            notifyListeners();
          }, onError: (_) {});
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadBatchesAndExams(String currentOrgId, List<String> batchIds) {
    if (batchIds.isEmpty) {
      _batches = [];
      _exams = [];
      _results = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Stream batches
    _batchSub?.cancel();
    _batchSub = _firestore
        .collection('organizations')
        .doc(currentOrgId)
        .collection('batches')
        .where(FieldPath.documentId, whereIn: batchIds.take(10).toList())
        .snapshots()
        .listen(
          (snapshot) {
            _batches = snapshot.docs
                .map((d) => BatchModel.fromJson(d.data(), docId: d.id))
                .where((b) => !b.isArchived)
                .toList();

            _loadExamsAndSubmissions(currentOrgId, _batches);
            _isLoading = false;
            notifyListeners();
          },
          onError: (_) {
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void _loadExamsAndSubmissions(
    String currentOrgId,
    List<BatchModel> activeBatches,
  ) {
    final batchNamesAndIds = <String>{};
    for (final b in activeBatches) {
      batchNamesAndIds.add(b.id);
      batchNamesAndIds.add(b.name.trim().toLowerCase());
    }

    _examSub?.cancel();
    _examSub = _firestore
        .collection('organizations')
        .doc(currentOrgId)
        .collection('exams')
        .orderBy('exam_id', descending: true)
        .snapshots()
        .listen((snapshot) async {
          final allExams = snapshot.docs
              .map((d) => ExamModel.fromJson(d.data()))
              .toList();

          // Keep exams for enrolled batches
          _exams = allExams.where((exam) {
            final b = exam.batch.trim().toLowerCase();
            return batchNamesAndIds.contains(b) ||
                batchNamesAndIds.contains(exam.batch.trim());
          }).toList();

          await _fetchSubmissionsForExams(currentOrgId, _exams);
          notifyListeners();
        }, onError: (_) {});
  }

  Future<void> _fetchSubmissionsForExams(
    String currentOrgId,
    List<ExamModel> activeExams,
  ) async {
    final resultList = <StudentSubmissionResultItem>[];

    for (final exam in activeExams) {
      try {
        final subDoc = await _firestore
            .collection('organizations')
            .doc(currentOrgId)
            .collection('exams')
            .doc(exam.examId)
            .collection('submissions')
            .doc(studentUid)
            .get();

        if (subDoc.exists && subDoc.data() != null) {
          final data = subDoc.data()!;
          final score = (data['score'] ?? data['obtained_marks'] ?? 0)
              .toDouble();
          final total = double.tryParse(exam.fullMarks) ?? 100.0;
          final pct = total > 0 ? (score / total) * 100 : 0.0;

          DateTime? subDate;
          final rawDate = data['submitted_at'] ?? data['submittedAt'];
          if (rawDate is Timestamp) {
            subDate = rawDate.toDate();
          } else if (rawDate is String) {
            subDate = DateTime.tryParse(rawDate);
          }

          resultList.add(
            StudentSubmissionResultItem(
              examId: exam.examId,
              examName: exam.examName,
              batch: exam.batch,
              subject: exam.subject ?? '',
              examDate: subDate ?? exam.examStart,
              obtainedMarks: score,
              totalMarks: total,
              percentage: pct,
              status: exam.resultPublished ? 'Published' : 'Under Review',
              submissionData: data,
              exam: exam,
            ),
          );
        }
      } catch (_) {}
    }

    resultList.sort((a, b) {
      if (a.examDate == null && b.examDate == null) return 0;
      if (a.examDate == null) return 1;
      if (b.examDate == null) return -1;
      return b.examDate!.compareTo(a.examDate!);
    });

    _results = resultList;
    notifyListeners();
  }

  void _cancelSubscriptions() {
    _memberSub?.cancel();
    _memberSub = null;

    _batchSub?.cancel();
    _batchSub = null;

    _examSub?.cancel();
    _examSub = null;

    _attendanceSub?.cancel();
    _attendanceSub = null;

    _feeSub?.cancel();
    _feeSub = null;

    _noticeSub?.cancel();
    _noticeSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
