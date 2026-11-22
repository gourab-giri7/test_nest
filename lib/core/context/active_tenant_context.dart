import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/organization_model.dart';
import '../services/organization_service.dart';
import '../services/tenant_path_resolver.dart';

/// App-wide ChangeNotifier maintaining the active organization/workspace context.
/// Consumed across teacher/student dashboards, batch services, and UI switchers.
class ActiveTenantContext extends ChangeNotifier {
  final OrganizationService? _explicitOrgService;

  ActiveTenantContext({OrganizationService? orgService})
    : _explicitOrgService = orgService;

  OrganizationService get _orgService =>
      _explicitOrgService ?? OrganizationService();

  String? _currentUid;
  OrganizationModel? _activeOrg;
  String? _activeRole;
  String? _activeStatus;
  List<UserMembershipModel> _memberships = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // ── Getters ─────────────────────────────────────────────────────────────
  String? get currentUid => _currentUid;
  OrganizationModel? get activeOrg => _activeOrg;
  String? get activeRole => _activeRole;
  String? get activeStatus => _activeStatus;
  List<UserMembershipModel> get memberships => List.unmodifiable(_memberships);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  String get activeOrgId => _activeOrg?.id ?? (_currentUid ?? '');
  String get activeOrgName => _activeOrg?.name ?? 'Coaching Institute';
  String get activeOrgType => _activeOrg?.type ?? OrganizationType.independent;

  bool get isInstitute => _activeOrg?.isInstitute ?? false;
  bool get isIndependent => _activeOrg?.isIndependent ?? true;
  bool get isAdmin => _activeRole == OrganizationRole.admin;
  bool get isTeacher => _activeRole == OrganizationRole.teacher;
  bool get isStudent => _activeRole == OrganizationRole.student;
  bool get isActive =>
      _activeStatus == OrganizationStatus.active || _activeStatus == null;
  bool get isSuspended => _activeStatus == OrganizationStatus.suspended;
  bool get hasMultipleOrgs => _memberships.length > 1;

  /// Returns a path resolver bound to this active tenant context.
  TenantPathResolver get pathResolver =>
      TenantPathResolver(tenantContext: this);

  static const String _prefPrefix = 'active_tenant_org_';

  // ── Context Initialization ──────────────────────────────────────────────

  /// Bootstraps the tenant context for a logged-in user.
  /// Backward compatible: if no memberships exist, ensures an independent workspace.
  Future<void> init(
    String uid, {
    String? preferredOrgId,
    String? fallbackName,
    String? fallbackEmail,
  }) async {
    if (uid.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    _currentUid = uid;
    notifyListeners();

    try {
      var memberList = await _orgService.getUserMemberships(uid);

      if (memberList.isEmpty && fallbackName != null && fallbackEmail != null) {
        // Teacher without memberships yet -> lazily register independent workspace
        await _orgService.ensureIndependentWorkspace(
          teacherId: uid,
          teacherName: fallbackName,
          teacherEmail: fallbackEmail,
        );
        memberList = await _orgService.getUserMemberships(uid);
      }

      _memberships = memberList;

      // Determine active organization ID
      final prefs = await SharedPreferences.getInstance();
      final savedOrgId = preferredOrgId ?? prefs.getString('$_prefPrefix$uid');

      String? targetOrgId;
      if (_memberships.isNotEmpty) {
        final instituteMembership =
            _memberships.where((m) => m.isInstitute).firstOrNull;
        if (savedOrgId != null &&
            _memberships.any((m) => m.organizationId == savedOrgId)) {
          targetOrgId = savedOrgId;
        } else if (instituteMembership != null) {
          targetOrgId = instituteMembership.organizationId;
        } else {
          targetOrgId = _memberships.first.organizationId;
        }
      } else {
        targetOrgId = uid;
      }

      await _loadOrganizationDetails(targetOrgId);
      _isInitialized = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Switch Active Organization ──────────────────────────────────────────

  /// Switches active workspace to another organization.
  Future<void> switchOrganization(String orgId) async {
    if (_currentUid == null || orgId == _activeOrg?.id) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadOrganizationDetails(orgId);

      // Persist chosen workspace
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefPrefix$_currentUid', orgId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads memberships and current organization.
  Future<void> refresh() async {
    if (_currentUid == null) return;
    try {
      _memberships = await _orgService.getUserMemberships(_currentUid!);
      if (_activeOrg != null) {
        await _loadOrganizationDetails(_activeOrg!.id);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clears context on logout.
  void clear() {
    _currentUid = null;
    _activeOrg = null;
    _activeRole = null;
    _activeStatus = null;
    _memberships = [];
    _isLoading = false;
    _isInitialized = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Internal Helpers ────────────────────────────────────────────────────

  Future<void> _loadOrganizationDetails(String orgId) async {
    var org = await _orgService.getOrganization(orgId);

    // If org doc doesn't exist yet (e.g. legacy teacher without explicit org doc)
    if (org == null) {
      org = OrganizationModel(
        id: orgId,
        name: 'Coaching Institute',
        type: OrganizationType.independent,
        ownerId: orgId,
        ownerName: 'Educator',
        createdAt: DateTime.now(),
        status: OrganizationStatus.active,
      );
    }

    _activeOrg = org;

    // Resolve user's role in this active organization
    final match = _memberships.firstWhere(
      (m) => m.organizationId == orgId,
      orElse: () => UserMembershipModel(
        organizationId: orgId,
        organizationName: org?.name ?? 'Personal Workspace',
        organizationType: org?.type ?? OrganizationType.independent,
        role: OrganizationRole.admin,
        status: OrganizationStatus.active,
        joinedAt: DateTime.now(),
      ),
    );

    _activeRole = match.role;
    _activeStatus = match.status;
  }
}
