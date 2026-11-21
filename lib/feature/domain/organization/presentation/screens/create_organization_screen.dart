import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/utils/theme/theme.dart';
import '../../../../../model/organization_model.dart';
import '../controllers/create_organization_controller.dart';

class CreateOrganizationScreen extends StatelessWidget {
  const CreateOrganizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CreateOrganizationController>(
      create: (_) => CreateOrganizationController(),
      child: const _CreateOrganizationContent(),
    );
  }
}

class _CreateOrganizationContent extends StatelessWidget {
  const _CreateOrganizationContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreateOrganizationController>();
    final user = FirebaseAuth.instance.currentUser;
    final ownerId = user?.uid ?? '';
    final ownerName = (user?.displayName ?? '').trim().isNotEmpty
        ? user!.displayName!.trim()
        : 'Educator';
    final ownerEmail = (user?.email ?? '').trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'New Organization',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Organization Architecture',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Create a Coaching Institute to invite and collaborate with other teachers, or an Independent Workspace for personal coaching.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mode Selector
                  const Text(
                    'Select Workspace Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _typeCard(
                          title: 'Institute Mode',
                          subtitle: 'Multi-teacher & admin',
                          icon: Icons.corporate_fare_rounded,
                          isSelected:
                              controller.selectedType ==
                              OrganizationType.institute,
                          onTap: () =>
                              controller.setType(OrganizationType.institute),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _typeCard(
                          title: 'Single Teacher',
                          subtitle: 'Personal workspace',
                          icon: Icons.person_rounded,
                          isSelected:
                              controller.selectedType ==
                              OrganizationType.independent,
                          onTap: () =>
                              controller.setType(OrganizationType.independent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Organization Name Field
                  const Text(
                    'Organization Name *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller.nameController,
                    decoration: InputDecoration(
                      hintText:
                          controller.selectedType == OrganizationType.institute
                          ? 'e.g. Apex Learning Institute'
                          : 'e.g. Math with John',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      prefixIcon: const Icon(Icons.school_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional Contact Phone
                  const Text(
                    'Contact Phone (Optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. +91 9876543210',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional Address
                  const Text(
                    'Campus / Address (Optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller.addressController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 4th Floor, Knowledge Hub, City',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: controller.isLoading
                          ? null
                          : () {
                              controller.submit(
                                context: context,
                                ownerId: ownerId,
                                ownerName: ownerName,
                                ownerEmail: ownerEmail,
                              );
                            },
                      child: controller.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Create Workspace',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primary : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
