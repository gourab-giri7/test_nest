import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/notices/controller/student_notice_inbox_controller.dart';
import 'package:test_nest/model/notice_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class StudentNoticeInboxScreen extends StatefulWidget {
  final String? studentUid;
  final List<String>? enrolledBatchIds;
  final String? fallbackTeacherId;

  const StudentNoticeInboxScreen({
    super.key,
    this.studentUid,
    this.enrolledBatchIds,
    this.fallbackTeacherId,
  });

  @override
  State<StudentNoticeInboxScreen> createState() =>
      _StudentNoticeInboxScreenState();
}

class _StudentNoticeInboxScreenState extends State<StudentNoticeInboxScreen> {
  late final StudentNoticeInboxController _controller;
  final TextEditingController _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = StudentNoticeInboxController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TenantPathResolver _getResolver() {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.read<ActiveTenantContext>();
    } catch (_) {}
    return TenantPathResolver(tenantContext: tenantCtx);
  }

  Future<void> _loadData() async {
    final resolver = _getResolver();
    final user = FirebaseAuth.instance.currentUser;
    final uid = widget.studentUid ?? user?.uid ?? '';

    List<String> batchIds = widget.enrolledBatchIds != null
        ? List<String>.from(widget.enrolledBatchIds!)
        : [];

    // If batchIds not provided via arguments, discover from user profile/enrollments
    if (batchIds.isEmpty && uid.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data['batch_ids'] is List) {
            batchIds = (data['batch_ids'] as List)
                .map((e) => e.toString())
                .toList();
          }
        }
      } catch (_) {}

      // Also try enrollments subcollection
      if (batchIds.isEmpty) {
        try {
          final enrollmentsSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('enrollments')
              .get();
          for (final doc in enrollmentsSnap.docs) {
            final bId = (doc.data()['batch_id'] ?? '').toString();
            if (bId.isNotEmpty && !batchIds.contains(bId)) {
              batchIds.add(bId);
            }
          }
        } catch (_) {}
      }
    }

    await _controller.loadNotices(
      resolver: resolver,
      studentUid: uid,
      enrolledBatchIds: batchIds,
      fallbackTeacherId: widget.fallbackTeacherId,
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase().trim()) {
      case NoticeCategory.exam:
        return const Color(0xFFEA580C);
      case NoticeCategory.classSession:
        return const Color(0xFF0D9488);
      case NoticeCategory.fee:
        return const Color(0xFF059669);
      case NoticeCategory.holiday:
        return const Color(0xFF7C3AED);
      case NoticeCategory.urgent:
        return const Color(0xFFEF4444);
      case NoticeCategory.general:
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase().trim()) {
      case NoticeCategory.exam:
        return Icons.assignment_outlined;
      case NoticeCategory.classSession:
        return Icons.school_outlined;
      case NoticeCategory.fee:
        return Icons.currency_rupee_rounded;
      case NoticeCategory.holiday:
        return Icons.celebration_outlined;
      case NoticeCategory.urgent:
        return Icons.warning_amber_rounded;
      case NoticeCategory.general:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentNoticeInboxController>.value(
      value: _controller,
      child: Consumer<StudentNoticeInboxController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text(
                'Notice Board',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.text,
              actions: [
                if (controller.unreadCount > 0)
                  TextButton.icon(
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text(
                      'Mark Read',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: controller.markAllAsRead,
                  ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildSearchAndFilters(controller),
                  Expanded(
                    child: controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : controller.errorMessage != null
                        ? _buildErrorView(controller)
                        : _buildNoticeList(controller),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(StudentNoticeInboxController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search announcements...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: AppColors.textMuted,
              ),
              suffixIcon: controller.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        controller.setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: AppColors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: controller.setSearchQuery,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryPill(
                  'All (${controller.allNotices.length})',
                  null,
                  controller,
                ),
                for (final cat in NoticeCategory.all)
                  _buildCategoryPill(
                    NoticeCategory.displayName(cat),
                    cat,
                    controller,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(
    String label,
    String? category,
    StudentNoticeInboxController controller,
  ) {
    final isSelected = controller.selectedCategory == category;
    final catColor = category != null
        ? _getCategoryColor(category)
        : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => controller.setCategory(category),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? catColor : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? catColor : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(StudentNoticeInboxController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeList(StudentNoticeInboxController controller) {
    final notices = controller.filteredNotices;

    if (notices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 56,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                'No Announcements Right Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'You\'re all caught up! New notices from your institute or teacher will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: notices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notice = notices[index];
        final isRead = controller.isRead(notice.id);
        return _buildNoticeTile(notice, isRead, controller);
      },
    );
  }

  Widget _buildNoticeTile(
    NoticeModel notice,
    bool isRead,
    StudentNoticeInboxController controller,
  ) {
    final catColor = _getCategoryColor(notice.category);
    final catIcon = _getCategoryIcon(notice.category);
    final date = notice.publishedAt ?? notice.createdAt;
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead ? AppColors.border : catColor.withOpacity(0.4),
          width: isRead ? 1 : 1.5,
        ),
        boxShadow: AppShadows.card,
      ),
      child: InkWell(
        onTap: () {
          controller.markAsRead(notice.id);
          Get.toNamed(AppRoutes.studentNoticeDetail, arguments: notice);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(catIcon, size: 12, color: catColor),
                            const SizedBox(width: 4),
                            Text(
                              NoticeCategory.displayName(notice.category),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notice.title,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                notice.body,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notice.createdByName.isNotEmpty
                        ? notice.createdByName
                        : 'Teacher',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
