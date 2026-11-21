import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../../../core/context/active_tenant_context.dart';
import '../../../../../core/services/invitation_service.dart';
import '../../../common/presentation/widget/custom_Snackbar.dart';
import '../../../../../model/invitation_model.dart';
import '../../../../../routes/app_routes.dart';

class JoinOrganizationController extends ChangeNotifier {
  final InvitationService _invitationService;

  JoinOrganizationController({InvitationService? invitationService})
    : _invitationService = invitationService ?? InvitationService();

  final TextEditingController codeController = TextEditingController();
  TeacherInvitationModel? _previewInvite;
  bool _isLoading = false;
  bool _isChecking = false;
  String? _errorMessage;

  TeacherInvitationModel? get previewInvite => _previewInvite;
  bool get isLoading => _isLoading;
  bool get isChecking => _isChecking;
  String? get errorMessage => _errorMessage;

  Future<void> previewInvitation(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.length < 6) {
      _previewInvite = null;
      notifyListeners();
      return;
    }

    _isChecking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final invite = await _invitationService.getInvitation(clean);
      _previewInvite = invite;
    } catch (e) {
      _previewInvite = null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<bool> redeemInvitation(BuildContext context) async {
    final code = codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      customSnackbar(
        context: context,
        message: 'Please enter the teacher invitation code',
        color: Colors.red,
        ico: Icons.error_outline,
      );
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      customSnackbar(
        context: context,
        message: 'You must be signed in to accept an invitation',
        color: Colors.red,
        ico: Icons.lock_outline,
      );
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _invitationService.redeemInvitation(code: code, user: user);

      if (context.mounted) {
        final tenantCtx = context.read<ActiveTenantContext>();
        await tenantCtx.init(user.uid);

        customSnackbar(
          context: context,
          message:
              'Successfully joined ${_previewInvite?.orgName ?? "the institute"}!',
          color: Colors.green,
          ico: Icons.check_circle_outline,
        );
      }

      Get.offAllNamed(AppRoutes.teacherDashboard);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: _errorMessage!,
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

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}
