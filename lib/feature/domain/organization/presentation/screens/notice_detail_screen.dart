import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/notice_service.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/model/notice_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class NoticeDetailScreen extends StatefulWidget {
  final NoticeModel notice;
  final String? fallbackTeacherId;

  const NoticeDetailScreen({
    super.key,
    required this.notice,
    this.fallbackTeacherId,
  });

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  final NoticeService _service = NoticeService();
  late NoticeModel _currentNotice;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentNotice = widget.notice;
  }

  TenantPathResolver _getResolver() {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.read<ActiveTenantContext>();
    } catch (_) {}
    return TenantPathResolver(tenantContext: tenantCtx);
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

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(_currentNotice.category);
    final user = FirebaseAuth.instance.currentUser;
    final updaterUid = user?.uid ?? '';
    final updaterName = user?.displayName ?? 'Staff';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notice Details',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Notice',
            onPressed: () {
              Get.toNamed(
                AppRoutes.noticeEditor,
                arguments: _currentNotice,
              )?.then((val) {
                if (val is NoticeModel) {
                  setState(() => _currentNotice = val);
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
              if (val == 'publish') {
                setState(() => _isLoading = true);
                try {
                  final updated = await _service.publishNotice(
                    resolver: _getResolver(),
                    notice: _currentNotice,
                    updaterUid: updaterUid,
                    updaterName: updaterName,
                    fallbackTeacherId: widget.fallbackTeacherId,
                  );
                  setState(() => _currentNotice = updated);
                } catch (_) {}
                setState(() => _isLoading = false);
              } else if (val == 'unpublish') {
                setState(() => _isLoading = true);
                try {
                  final updated = await _service.unpublishNotice(
                    resolver: _getResolver(),
                    notice: _currentNotice,
                    updaterUid: updaterUid,
                    updaterName: updaterName,
                    fallbackTeacherId: widget.fallbackTeacherId,
                  );
                  setState(() => _currentNotice = updated);
                } catch (_) {}
                setState(() => _isLoading = false);
              } else if (val == 'archive') {
                setState(() => _isLoading = true);
                try {
                  final updated = await _service.archiveNotice(
                    resolver: _getResolver(),
                    notice: _currentNotice,
                    updaterUid: updaterUid,
                    updaterName: updaterName,
                    fallbackTeacherId: widget.fallbackTeacherId,
                  );
                  setState(() => _currentNotice = updated);
                } catch (_) {}
                setState(() => _isLoading = false);
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
                  await _service.deleteNotice(
                    resolver: _getResolver(),
                    noticeId: _currentNotice.id,
                    fallbackTeacherId: widget.fallbackTeacherId,
                  );
                  if (mounted) Get.back();
                }
              }
            },
            itemBuilder: (ctx) => [
              if (_currentNotice.isDraft)
                const PopupMenuItem(
                  value: 'publish',
                  child: Text('Publish Notice'),
                )
              else if (_currentNotice.isPublished)
                const PopupMenuItem(
                  value: 'unpublish',
                  child: Text('Move to Drafts'),
                ),
              if (!_currentNotice.isArchived)
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Archive Notice'),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete Notice',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                NoticeCategory.displayName(
                                  _currentNotice.category,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: catColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(_currentNotice.status),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _currentNotice.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'By ${_currentNotice.createdByName.isNotEmpty ? _currentNotice.createdByName : 'Staff'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(
                                _currentNotice.publishedAt ??
                                    _currentNotice.createdAt,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Text(
                          _currentNotice.body,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAudienceInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case NoticeStatus.published:
        bg = AppColors.successSoft;
        fg = AppColors.success;
        label = 'Published';
        break;
      case NoticeStatus.draft:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
        label = 'Draft';
        break;
      case NoticeStatus.archived:
      default:
        bg = AppColors.surfaceAlt;
        fg = AppColors.textMuted;
        label = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildAudienceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Audience Info',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Audience: ${_currentNotice.audienceSummary}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          if (_currentNotice.targetBatchNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Batches:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _currentNotice.targetBatchNames.map((name) {
                return Chip(
                  label: Text(name, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.surfaceAlt,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
          if (_currentNotice.targetStudentNames.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Individual Students:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _currentNotice.targetStudentNames.map((name) {
                return Chip(
                  label: Text(name, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.surfaceAlt,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
