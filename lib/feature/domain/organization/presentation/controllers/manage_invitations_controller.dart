import 'package:flutter/material.dart';
import '../../../../../core/services/invitation_service.dart';
import '../../../common/presentation/widget/custom_Snackbar.dart';
import '../../../../../model/invitation_model.dart';

class ManageInvitationsController extends ChangeNotifier {
  final InvitationService _invitationService;

  ManageInvitationsController({InvitationService? invitationService})
    : _invitationService = invitationService ?? InvitationService();

  final TextEditingController emailController = TextEditingController();
  int _validityDays = 7;
  bool _isLoading = false;
  TeacherInvitationModel? _recentlyCreatedInvite;
  String? _errorMessage;

  int get validityDays => _validityDays;
  bool get isLoading => _isLoading;
  TeacherInvitationModel? get recentlyCreatedInvite => _recentlyCreatedInvite;
  String? get errorMessage => _errorMessage;

  void setValidityDays(int days) {
    if (days > 0 && days <= 30) {
      _validityDays = days;
      notifyListeners();
    }
  }

  Stream<List<TeacherInvitationModel>> streamInvitations(String orgId) {
    return _invitationService.streamOrganizationInvitations(orgId);
  }

  Future<bool> createInvitation({
    required BuildContext context,
    required String orgId,
    required String orgName,
    required String adminUid,
  }) async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      customSnackbar(
        context: context,
        message: 'Please enter a valid teacher email address',
        color: Colors.red,
        ico: Icons.error_outline,
      );
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final invite = await _invitationService.createInvitation(
        orgId: orgId,
        orgName: orgName,
        teacherEmail: email,
        adminUid: adminUid,
        validity: Duration(days: _validityDays),
      );

      _recentlyCreatedInvite = invite;
      emailController.clear();

      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Invitation code generated: ${invite.code}',
          color: Colors.green,
          ico: Icons.check_circle_outline,
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Error: ${e.toString()}',
          color: Colors.red,
          ico: Icons.error_outline,
        );
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> revokeInvitation({
    required BuildContext context,
    required String orgId,
    required String code,
  }) async {
    try {
      await _invitationService.revokeInvitation(orgId: orgId, code: code);
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Invitation $code has been revoked',
          color: Colors.orange,
          ico: Icons.block,
        );
      }
    } catch (e) {
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Failed to revoke: ${e.toString()}',
          color: Colors.red,
          ico: Icons.error_outline,
        );
      }
    }
  }

  void clearRecentInvite() {
    _recentlyCreatedInvite = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
