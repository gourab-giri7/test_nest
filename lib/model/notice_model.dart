import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeCategory {
  static const String general = 'general';
  static const String exam = 'exam';
  static const String classSession = 'class';
  static const String fee = 'fee';
  static const String holiday = 'holiday';
  static const String urgent = 'urgent';

  static const List<String> all = [
    general,
    exam,
    classSession,
    fee,
    holiday,
    urgent,
  ];

  static String displayName(String category) {
    switch (category.toLowerCase().trim()) {
      case general:
        return 'General';
      case exam:
        return 'Exam';
      case classSession:
        return 'Class';
      case fee:
        return 'Fee';
      case holiday:
        return 'Holiday';
      case urgent:
        return 'Urgent';
      default:
        return category.isNotEmpty
            ? '${category[0].toUpperCase()}${category.substring(1)}'
            : 'General';
    }
  }

  static bool isValid(String s) => all.contains(s.toLowerCase().trim());
}

class NoticeStatus {
  static const String draft = 'draft';
  static const String published = 'published';
  static const String archived = 'archived';

  static const List<String> all = [draft, published, archived];

  static bool isValid(String s) => all.contains(s.toLowerCase().trim());
}

class NoticeAudienceType {
  static const String all = 'all';
  static const String batches = 'batches';
  static const String students = 'students';

  static const List<String> allTypes = [all, batches, students];

  static bool isValid(String s) => allTypes.contains(s.toLowerCase().trim());
}

class NoticeModel {
  final String id;
  final String organizationId;
  final String teacherId;
  final String title;
  final String body;
  final String category;
  final String status;
  final String audienceType;
  final List<String> targetBatchIds;
  final List<String> targetBatchNames;
  final List<String> targetStudentIds;
  final List<String> targetStudentNames;
  final String? attachmentUrl;
  final String createdBy;
  final String createdByName;
  final String updatedBy;
  final String updatedByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? archivedAt;

  const NoticeModel({
    required this.id,
    this.organizationId = '',
    this.teacherId = '',
    required this.title,
    required this.body,
    this.category = NoticeCategory.general,
    this.status = NoticeStatus.draft,
    this.audienceType = NoticeAudienceType.all,
    this.targetBatchIds = const [],
    this.targetBatchNames = const [],
    this.targetStudentIds = const [],
    this.targetStudentNames = const [],
    this.attachmentUrl,
    required this.createdBy,
    this.createdByName = '',
    required this.updatedBy,
    this.updatedByName = '',
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.archivedAt,
  });

  bool get isDraft => status == NoticeStatus.draft;
  bool get isPublished => status == NoticeStatus.published;
  bool get isArchived => status == NoticeStatus.archived;
  bool get hasAttachment =>
      attachmentUrl != null && attachmentUrl!.trim().isNotEmpty;

  /// Returns a clean human-readable audience summary
  String get audienceSummary {
    switch (audienceType) {
      case NoticeAudienceType.all:
        return 'All Students';
      case NoticeAudienceType.batches:
        if (targetBatchNames.isNotEmpty) {
          if (targetBatchNames.length == 1) {
            return targetBatchNames.first;
          }
          return '${targetBatchNames.length} Batches (${targetBatchNames.take(2).join(', ')}${targetBatchNames.length > 2 ? '...' : ''})';
        }
        return '${targetBatchIds.length} Batches';
      case NoticeAudienceType.students:
        if (targetStudentNames.isNotEmpty) {
          if (targetStudentNames.length == 1) {
            return targetStudentNames.first;
          }
          return '${targetStudentNames.length} Students';
        }
        return '${targetStudentIds.length} Students';
      default:
        return 'Targeted';
    }
  }

  factory NoticeModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) {
        return DateTime.tryParse(val) ?? (fallback ?? DateTime.now());
      }
      return fallback ?? DateTime.now();
    }

    List<String> parseList(dynamic val) {
      if (val is List) {
        return val
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return const [];
    }

    final now = DateTime.now();
    final cAt = parseDate(map['createdAt'] ?? map['created_at'], now);
    final uAt = parseDate(map['updatedAt'] ?? map['updated_at'], cAt);
    final pAt = map['publishedAt'] != null || map['published_at'] != null
        ? parseDate(map['publishedAt'] ?? map['published_at'])
        : null;
    final aAt = map['archivedAt'] != null || map['archived_at'] != null
        ? parseDate(map['archivedAt'] ?? map['archived_at'])
        : null;

    final resolvedCat = (map['category'] ?? NoticeCategory.general)
        .toString()
        .toLowerCase()
        .trim();
    final resolvedStat = (map['status'] ?? NoticeStatus.draft)
        .toString()
        .toLowerCase()
        .trim();
    final resolvedAud =
        (map['audienceType'] ?? map['audience_type'] ?? NoticeAudienceType.all)
            .toString()
            .toLowerCase()
            .trim();

    return NoticeModel(
      id: docId.isNotEmpty ? docId : (map['id'] ?? '').toString(),
      organizationId:
          (map['organizationId'] ?? map['orgId'] ?? map['org_id'] ?? '')
              .toString(),
      teacherId: (map['teacherId'] ?? map['teacher_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString().trim(),
      body: (map['body'] ?? map['message'] ?? '').toString().trim(),
      category: NoticeCategory.isValid(resolvedCat)
          ? resolvedCat
          : NoticeCategory.general,
      status: NoticeStatus.isValid(resolvedStat)
          ? resolvedStat
          : NoticeStatus.draft,
      audienceType: NoticeAudienceType.isValid(resolvedAud)
          ? resolvedAud
          : NoticeAudienceType.all,
      targetBatchIds: parseList(
        map['targetBatchIds'] ?? map['target_batch_ids'],
      ),
      targetBatchNames: parseList(
        map['targetBatchNames'] ?? map['target_batch_names'],
      ),
      targetStudentIds: parseList(
        map['targetStudentIds'] ?? map['target_student_ids'],
      ),
      targetStudentNames: parseList(
        map['targetStudentNames'] ?? map['target_student_names'],
      ),
      attachmentUrl:
          map['attachmentUrl']?.toString() ?? map['attachment_url']?.toString(),
      createdBy: (map['createdBy'] ?? map['created_by'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? map['created_by_name'] ?? '')
          .toString(),
      updatedBy: (map['updatedBy'] ?? map['updated_by'] ?? '').toString(),
      updatedByName: (map['updatedByName'] ?? map['updated_by_name'] ?? '')
          .toString(),
      createdAt: cAt,
      updatedAt: uAt,
      publishedAt: pAt,
      archivedAt: aAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'teacherId': teacherId,
      'title': title,
      'body': body,
      'category': category,
      'status': status,
      'audienceType': audienceType,
      'targetBatchIds': targetBatchIds,
      'targetBatchNames': targetBatchNames,
      'targetStudentIds': targetStudentIds,
      'targetStudentNames': targetStudentNames,
      if (attachmentUrl != null && attachmentUrl!.isNotEmpty)
        'attachmentUrl': attachmentUrl,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
      if (archivedAt != null) 'archivedAt': Timestamp.fromDate(archivedAt!),
    };
  }

  NoticeModel copyWith({
    String? id,
    String? organizationId,
    String? teacherId,
    String? title,
    String? body,
    String? category,
    String? status,
    String? audienceType,
    List<String>? targetBatchIds,
    List<String>? targetBatchNames,
    List<String>? targetStudentIds,
    List<String>? targetStudentNames,
    String? attachmentUrl,
    String? createdBy,
    String? createdByName,
    String? updatedBy,
    String? updatedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    DateTime? archivedAt,
  }) {
    return NoticeModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      teacherId: teacherId ?? this.teacherId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      status: status ?? this.status,
      audienceType: audienceType ?? this.audienceType,
      targetBatchIds: targetBatchIds ?? this.targetBatchIds,
      targetBatchNames: targetBatchNames ?? this.targetBatchNames,
      targetStudentIds: targetStudentIds ?? this.targetStudentIds,
      targetStudentNames: targetStudentNames ?? this.targetStudentNames,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByName: updatedByName ?? this.updatedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
