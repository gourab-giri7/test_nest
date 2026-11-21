import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_nest/core/services/organization_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/model/organization_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class InstituteTeachersScreen extends StatefulWidget {
  final String orgId;

  const InstituteTeachersScreen({super.key, required this.orgId});

  @override
  State<InstituteTeachersScreen> createState() =>
      _InstituteTeachersScreenState();
}

class _InstituteTeachersScreenState extends State<InstituteTeachersScreen> {
  final OrganizationService _orgService = OrganizationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Institute Faculty & Staff',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Invite Teacher',
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
            onPressed: () => Get.toNamed(AppRoutes.manageInvitations),
          ),
        ],
      ),
      body: StreamBuilder<List<OrganizationMemberModel>>(
        stream: _orgService.streamOrganizationMembers(widget.orgId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading faculty: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final members = snapshot.data ?? [];
          final teachers = members
              .where((m) => m.isTeacher || m.isAdmin)
              .toList();

          if (teachers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No teachers found in this institute.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Invite educators to collaborate and manage batches.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Get.toNamed(AppRoutes.manageInvitations),
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Send Teacher Invitation'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final member = teachers[index];
              final isAdmin = member.isAdmin;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isAdmin
                            ? Colors.amber.shade100
                            : AppColors.primary.withOpacity(0.12),
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : 'T',
                          style: TextStyle(
                            color: isAdmin
                                ? Colors.amber.shade900
                                : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? Colors.amber.shade50
                                        : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isAdmin
                                          ? Colors.amber.shade300
                                          : Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    isAdmin ? 'Admin' : 'Teacher',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isAdmin
                                          ? Colors.amber.shade900
                                          : Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              member.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Assigned to ${member.assignedBatchIds.length} batch(es)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: member.assignedBatchIds.isNotEmpty
                                    ? Colors.teal.shade700
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => Get.toNamed(AppRoutes.manageInvitations),
        icon: const Icon(Icons.mail_outline),
        label: const Text('Invite Teacher'),
      ),
    );
  }
}
