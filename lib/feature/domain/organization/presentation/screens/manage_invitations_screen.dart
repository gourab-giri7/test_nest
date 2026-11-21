import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/context/active_tenant_context.dart';
import '../../../../../core/utils/theme/theme.dart';
import '../../../common/presentation/widget/custom_Snackbar.dart';
import '../../../../../model/invitation_model.dart';
import '../controllers/manage_invitations_controller.dart';

class ManageInvitationsScreen extends StatelessWidget {
  const ManageInvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ManageInvitationsController>(
      create: (_) => ManageInvitationsController(),
      child: const _ManageInvitationsContent(),
    );
  }
}

class _ManageInvitationsContent extends StatelessWidget {
  const _ManageInvitationsContent();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ManageInvitationsController>();
    final tenantCtx = context.watch<ActiveTenantContext>();
    final orgId = tenantCtx.activeOrgId;
    final orgName = tenantCtx.activeOrgName;
    final user = FirebaseAuth.instance.currentUser;
    final adminUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Teacher Invitations',
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite Teachers to $orgName',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Single-use, expiring code bound to their email.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Teacher Email Address',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'teacher@example.com',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        'Code Validity:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: controller.validityDays,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3 Days')),
                          DropdownMenuItem(value: 7, child: Text('7 Days')),
                          DropdownMenuItem(value: 14, child: Text('14 Days')),
                          DropdownMenuItem(value: 30, child: Text('30 Days')),
                        ],
                        onChanged: (days) {
                          if (days != null) controller.setValidityDays(days);
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: controller.isLoading
                            ? null
                            : () {
                                controller.createInvitation(
                                  context: context,
                                  orgId: orgId,
                                  orgName: orgName,
                                  adminUid: adminUid,
                                );
                              },
                        child: controller.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Generate Code'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Recently Generated Banner
            if (controller.recentlyCreatedInvite != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF059669),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Invitation Created Successfully',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF065F46),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => controller.clearRecentInvite(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            controller.recentlyCreatedInvite!.code,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: controller.recentlyCreatedInvite!.code,
                                ),
                              );
                              customSnackbar(
                                context: context,
                                message: 'Invitation code copied to clipboard!',
                                color: Colors.green,
                                ico: Icons.check,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              'Invitation History',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),

            // Stream of all invitations for this org
            StreamBuilder<List<TeacherInvitationModel>>(
              stream: controller.streamInvitations(orgId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final invites = snapshot.data ?? [];
                if (invites.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'No invitations created yet.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: invites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = invites[index];
                    return _invitationTile(
                      context: context,
                      controller: controller,
                      invitation: item,
                      orgId: orgId,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _invitationTile({
    required BuildContext context,
    required ManageInvitationsController controller,
    required TeacherInvitationModel invitation,
    required String orgId,
  }) {
    Color badgeColor;
    String badgeText;

    if (invitation.isAccepted) {
      badgeColor = const Color(0xFF10B981);
      badgeText = 'ACCEPTED';
    } else if (invitation.isRevoked) {
      badgeColor = const Color(0xFFEF4444);
      badgeText = 'REVOKED';
    } else if (invitation.isExpired) {
      badgeColor = const Color(0xFF94A3B8);
      badgeText = 'EXPIRED';
    } else {
      badgeColor = const Color(0xFF3B82F6);
      badgeText = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      invitation.code,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  invitation.teacherEmail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Created: ${invitation.createdAt.toLocal().toString().split(' ').first} · Expires: ${invitation.expiresAt.toLocal().toString().split(' ').first}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (invitation.isPending) ...[
            IconButton(
              tooltip: 'Copy Code',
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invitation.code));
                customSnackbar(
                  context: context,
                  message: 'Code ${invitation.code} copied!',
                  color: Colors.green,
                  ico: Icons.check,
                );
              },
            ),
            IconButton(
              tooltip: 'Revoke Code',
              icon: const Icon(
                Icons.block_rounded,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () {
                controller.revokeInvitation(
                  context: context,
                  orgId: orgId,
                  code: invitation.code,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
