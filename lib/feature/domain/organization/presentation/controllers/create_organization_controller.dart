import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/context/active_tenant_context.dart';
import '../../../../../core/services/organization_service.dart';
import '../../../common/presentation/widget/custom_Snackbar.dart';
import '../../../../../model/organization_model.dart';
import 'package:provider/provider.dart';

class CreateOrganizationController extends ChangeNotifier {
  final OrganizationService _orgService;

  CreateOrganizationController({OrganizationService? orgService})
    : _orgService = orgService ?? OrganizationService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  String _selectedType = OrganizationType.institute;
  bool _isLoading = false;
  String? _errorMessage;

  String get selectedType => _selectedType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setType(String type) {
    if (OrganizationType.isValid(type) && _selectedType != type) {
      _selectedType = type;
      notifyListeners();
    }
  }

  Future<bool> submit({
    required BuildContext context,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
  }) async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      customSnackbar(
        context: context,
        message: 'Please enter the organization or institute name',
        color: Colors.red,
        ico: Icons.error_outline,
      );
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final metadata = <String, dynamic>{
        if (phoneController.text.trim().isNotEmpty)
          'phone': phoneController.text.trim(),
        if (addressController.text.trim().isNotEmpty)
          'address': addressController.text.trim(),
      };

      final newOrg = await _orgService.createOrganization(
        name: name,
        type: _selectedType,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        metadata: metadata,
      );

      // Refresh tenant context and switch to newly created organization
      if (context.mounted) {
        final tenantCtx = context.read<ActiveTenantContext>();
        await tenantCtx.init(ownerId, preferredOrgId: newOrg.id);

        customSnackbar(
          context: context,
          message: 'Workspace "${newOrg.name}" created successfully!',
          color: Colors.green,
          ico: Icons.check_circle_outline,
        );
      }

      Get.back();
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

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
