import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/notice_management_controller.dart';
import 'package:test_nest/model/notice_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class NoticeListScreen extends StatefulWidget {
  final String? fallbackTeacherId;

  const NoticeListScreen({super.key, this.fallbackTeacherId});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen>
    with SingleTickerProviderStateMixin {
  late final NoticeManagementController _controller;
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = NoticeManagementController();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _controller.setTab(_tabController.index);
      }
    });
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
    _tabController.dispose();
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
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.read<ActiveTenantContext>();
    } catch (_) {}

    final resolver = _getResolver();
    final user = FirebaseAuth.instance.currentUser;
    final teacherUid = user?.uid ?? widget.fallbackTeacherId ?? '';
    final isTeacherInInstitute =
        tenantCtx != null && tenantCtx.isInstitute && tenantCtx.isTeacher;

    await _controller.loadNotices(
      resolver: resolver,
      teacherUid: teacherUid,
      isTeacherInInstitute: isTeacherInInstitute,
      fallbackTeacherId: widget.fallbackTeacherId ?? teacherUid,
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
    return ChangeNotifierProvider<NoticeManagementController>.value(
      value: _controller,
      child: Consumer<NoticeManagementController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text(
                'Notices & Announcements',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.text,
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'All (${controller.allNotices.length})'),
                  Tab(text: 'Published (${controller.publishedCount})'),
                  Tab(text: 'Drafts (${controller.draftCount})'),
                  Tab(text: 'Archived (${controller.archivedCount})'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Create Notice',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Get.toNamed(AppRoutes.noticeEditor)?.then((_) => _loadData());
              },
            ),
            body: RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildSearchAndFilterHeader(controller),
                  if (controller.errorMessage != null)
                    _buildBanner(controller.errorMessage!, isError: true),
                  if (controller.successMessage != null)
                    _buildBanner(controller.successMessage!, isError: false),
                  Expanded(
                    child: controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
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

  Widget _buildSearchAndFilterHeader(NoticeManagementController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search notices by title, message, author...',
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
                _buildFilterChip('All Categories', null, controller),
                for (final cat in NoticeCategory.all)
                  _buildFilterChip(
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

  Widget _buildFilterChip(
    String label,
    String? category,
    NoticeManagementController controller,
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

  Widget _buildBanner(String message, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isError ? AppColors.dangerSoft : AppColors.successSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? AppColors.danger : AppColors.success,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? AppColors.danger : AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isError ? AppColors.danger : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeList(NoticeManagementController controller) {
    final notices = controller.filteredNotices;

    if (notices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.campaign_outlined,
                size: 56,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                'No Notices Found',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                controller.searchQuery.isNotEmpty ||
                        controller.selectedCategory != null
                    ? 'Try adjusting your search or filters.'
                    : 'Tap "Create Notice" to post a new announcement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: notices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notice = notices[index];
        return _buildNoticeCard(notice, controller);
      },
    );
  }

  Widget _buildNoticeCard(
    NoticeModel notice,
    NoticeManagementController controller,
  ) {
    final catColor = _getCategoryColor(notice.category);
    final catIcon = _getCategoryIcon(notice.category);

    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    if (notice.isPublished) {
      statusBgColor = AppColors.successSoft;
      statusTextColor = AppColors.success;
      statusText = 'Published';
    } else if (notice.isDraft) {
      statusBgColor = AppColors.warningSoft;
      statusTextColor = AppColors.warning;
      statusText = 'Draft';
    } else {
      statusBgColor = AppColors.surfaceAlt;
      statusTextColor = AppColors.textMuted;
      statusText = 'Archived';
    }

    final formattedDate = notice.publishedAt != null
        ? '${notice.publishedAt!.day}/${notice.publishedAt!.month}/${notice.publishedAt!.year}'
        : '${notice.createdAt.day}/${notice.createdAt.month}/${notice.createdAt.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(
            AppRoutes.noticeDetail,
            arguments: notice,
          )?.then((_) => _loadData());
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(catIcon, size: 13, color: catColor),
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusTextColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildCardMenu(notice, controller),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                notice.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
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
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        notice.audienceSummary,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardMenu(
    NoticeModel notice,
    NoticeManagementController controller,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final updaterUid = user?.uid ?? '';
    final updaterName = user?.displayName ?? 'Staff';

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (val) async {
        if (val == 'edit') {
          Get.toNamed(
            AppRoutes.noticeEditor,
            arguments: notice,
          )?.then((_) => _loadData());
        } else if (val == 'publish') {
          await controller.publishNotice(
            resolver: _getResolver(),
            notice: notice,
            updaterUid: updaterUid,
            updaterName: updaterName,
            fallbackTeacherId: widget.fallbackTeacherId,
          );
        } else if (val == 'unpublish') {
          await controller.unpublishNotice(
            resolver: _getResolver(),
            notice: notice,
            updaterUid: updaterUid,
            updaterName: updaterName,
            fallbackTeacherId: widget.fallbackTeacherId,
          );
        } else if (val == 'archive') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Archive Notice'),
              content: const Text(
                'Are you sure you want to archive this notice? It will be removed from student view while preserving history.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Archive'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await controller.archiveNotice(
              resolver: _getResolver(),
              notice: notice,
              updaterUid: updaterUid,
              updaterName: updaterName,
              fallbackTeacherId: widget.fallbackTeacherId,
            );
          }
        } else if (val == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Notice'),
              content: const Text(
                'Are you sure you want to permanently delete this notice? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await controller.deleteNotice(
              resolver: _getResolver(),
              noticeId: notice.id,
              fallbackTeacherId: widget.fallbackTeacherId,
            );
          }
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 8),
              Text('Edit Notice'),
            ],
          ),
        ),
        if (notice.isDraft)
          const PopupMenuItem(
            value: 'publish',
            child: Row(
              children: [
                Icon(
                  Icons.publish_outlined,
                  size: 16,
                  color: AppColors.success,
                ),
                SizedBox(width: 8),
                Text(
                  'Publish Notice',
                  style: TextStyle(color: AppColors.success),
                ),
              ],
            ),
          )
        else if (notice.isPublished)
          const PopupMenuItem(
            value: 'unpublish',
            child: Row(
              children: [
                Icon(
                  Icons.unpublished_outlined,
                  size: 16,
                  color: AppColors.warning,
                ),
                SizedBox(width: 8),
                Text('Move to Drafts'),
              ],
            ),
          ),
        if (!notice.isArchived)
          const PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 8),
                Text('Archive Notice'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Delete Notice', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
    );
  }
}
