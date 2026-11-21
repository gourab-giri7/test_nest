import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/organization_model.dart';

class InstituteAdminDashboardController extends ChangeNotifier {
  final ActiveTenantContext tenantContext;
  final FirebaseFirestore? _explicitFirestore;

  InstituteAdminDashboardController({
    required this.tenantContext,
    FirebaseFirestore? firestore,
  }) : _explicitFirestore = firestore {
    _initListeners();
  }

  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _errorMessage;

  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _totalBatches = 0;
  int _activeExams = 0;
  int _pendingJoinRequests = 0;
  double _totalFeeDue = 0.0;
  double _totalFeeCollected = 0.0;

  List<BatchModel> _batches = [];
  List<OrganizationMemberModel> _teachers = [];
  List<ExamModel> _recentExams = [];

  StreamSubscription? _batchSub;
  StreamSubscription? _memberSub;
  StreamSubscription? _studentSub;
  StreamSubscription? _examSub;

  // ── Getters ─────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalStudents => _totalStudents;
  int get totalTeachers => _totalTeachers;
  int get totalBatches => _totalBatches;
  int get activeExams => _activeExams;
  int get pendingJoinRequests => _pendingJoinRequests;
  double get totalFeeDue => _totalFeeDue;
  double get totalFeeCollected => _totalFeeCollected;

  List<BatchModel> get batches => List.unmodifiable(_batches);
  List<OrganizationMemberModel> get teachers => List.unmodifiable(_teachers);
  List<ExamModel> get recentExams => List.unmodifiable(_recentExams);

  String get orgId => tenantContext.activeOrgId;
  String get orgName => tenantContext.activeOrgName;

  void _initListeners() {
    _cancelSubscriptions();

    final currentOrgId = orgId;
    if (currentOrgId.isEmpty || !tenantContext.isInstitute) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Members stream (Teachers and Admins)
      _memberSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('members')
          .snapshots()
          .listen(
            (snapshot) {
              final list = snapshot.docs
                  .map((d) => OrganizationMemberModel.fromMap(d.data(), d.id))
                  .where((m) => m.isTeacher || m.isAdmin)
                  .toList();
              _teachers = list;
              _totalTeachers = list.length;
              _checkLoadingComplete();
            },
            onError: (e) {
              _errorMessage = 'Failed to load teachers: $e';
              _isLoading = false;
              notifyListeners();
            },
          );

      // 2. Batches stream
      _batchSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('batches')
          .snapshots()
          .listen(
            (snapshot) {
              final list = snapshot.docs
                  .map((d) => BatchModel.fromJson(d.data(), docId: d.id))
                  .where((b) => !b.isArchived)
                  .toList();
              _batches = list;
              _totalBatches = list.length;

              int pendingCount = 0;
              double calculatedFeeDue = 0.0;
              for (final b in list) {
                pendingCount += b.pendingRequestCount;
                if (b.feeTrackingEnabled) {
                  calculatedFeeDue += (b.monthlyFee * b.studentCount);
                }
              }
              _pendingJoinRequests = pendingCount;
              _totalFeeDue = calculatedFeeDue;
              _checkLoadingComplete();
            },
            onError: (e) {
              _errorMessage = 'Failed to load batches: $e';
              _isLoading = false;
              notifyListeners();
            },
          );

      // 3. Students stream
      _studentSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('students')
          .snapshots()
          .listen(
            (snapshot) {
              _totalStudents = snapshot.docs.length;
              _checkLoadingComplete();
            },
            onError: (_) {
              // If org-scoped students collection is empty or uses batch aggregation
              int sumStudents = 0;
              for (final b in _batches) {
                sumStudents += b.studentCount;
              }
              _totalStudents = sumStudents;
              _checkLoadingComplete();
            },
          );

      // 4. Exams stream
      _examSub = _firestore
          .collection('organizations')
          .doc(currentOrgId)
          .collection('exams')
          .snapshots()
          .listen(
            (snapshot) {
              final exams = snapshot.docs
                  .map((d) => ExamModel.fromJson(d.data()))
                  .toList();
              final now = DateTime.now();

              int active = 0;
              for (final e in exams) {
                if (e.examStart != null && e.examEnd != null) {
                  if (now.isAfter(e.examStart!) && now.isBefore(e.examEnd!)) {
                    active++;
                  }
                }
              }
              _activeExams = active;
              _recentExams = exams.take(5).toList();
              _checkLoadingComplete();
            },
            onError: (e) {
              // Silent fail for exams if none exist
              _activeExams = 0;
              _recentExams = [];
              _checkLoadingComplete();
            },
          );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _checkLoadingComplete() {
    _isLoading = false;
    notifyListeners();
  }

  void refresh() {
    _initListeners();
  }

  void _cancelSubscriptions() {
    _batchSub?.cancel();
    _memberSub?.cancel();
    _studentSub?.cancel();
    _examSub?.cancel();
    _batchSub = null;
    _memberSub = null;
    _studentSub = null;
    _examSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
