import 'package:flutter/material.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/model/notice_model.dart';

class StudentNoticeDetailScreen extends StatelessWidget {
  final NoticeModel notice;

  const StudentNoticeDetailScreen({super.key, required this.notice});

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
    final catColor = _getCategoryColor(notice.category);
    final catIcon = _getCategoryIcon(notice.category);
    final date = notice.publishedAt ?? notice.createdAt;
    final formattedDate =
        '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notice',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, size: 14, color: catColor),
                    const SizedBox(width: 6),
                    Text(
                      NoticeCategory.displayName(notice.category),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: catColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                notice.title,
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
                    notice.createdByName.isNotEmpty
                        ? notice.createdByName
                        : 'Teacher',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
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
                notice.body,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
