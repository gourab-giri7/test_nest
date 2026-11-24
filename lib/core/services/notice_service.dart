import 'package:cloud_firestore/cloud_firestore.dart';
import '../../feature/domain/teacher/data/models/student_model.dart';
import '../../model/batch_model.dart';
import '../../model/notice_model.dart';
import 'attendance_service.dart';
import 'tenant_path_resolver.dart';

class NoticeService {
  final FirebaseFirestore? _explicitFirestore;
  final AttendanceService _attendanceService;

  NoticeService({
    FirebaseFirestore? firestore,
    AttendanceService? attendanceService,
  }) : _explicitFirestore = firestore,
       _attendanceService =
           attendanceService ?? AttendanceService(firestore: firestore);

  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  /// Validates audience constraints on a notice before saving or publishing.
  static void validateAudience(NoticeModel notice) {
    if (notice.title.trim().isEmpty) {
      throw ArgumentError('Notice title cannot be empty.');
    }
    if (notice.body.trim().isEmpty) {
      throw ArgumentError('Notice body/message cannot be empty.');
    }

    if (notice.audienceType == NoticeAudienceType.batches) {
      if (notice.targetBatchIds.isEmpty) {
        throw ArgumentError(
          'At least one batch must be selected when targeting batches.',
        );
      }
    } else if (notice.audienceType == NoticeAudienceType.students) {
      if (notice.targetStudentIds.isEmpty) {
        throw ArgumentError(
          'At least one student must be selected when targeting students.',
        );
      }
    }
  }

  /// Creates a new notice in Firestore.
  Future<NoticeModel> createNotice({
    required TenantPathResolver resolver,
    required NoticeModel notice,
    String? fallbackTeacherId,
  }) async {
    validateAudience(notice);

    final path = resolver.noticesPath(fallbackTeacherId);
    final docRef = notice.id.isNotEmpty
        ? _firestore.collection(path).doc(notice.id)
        : _firestore.collection(path).doc();

    final now = DateTime.now();
    final toSave = notice.copyWith(
      id: docRef.id,
      organizationId: resolver.isInstitute ? resolver.orgId : '',
      teacherId: !resolver.isInstitute
          ? (fallbackTeacherId ?? notice.teacherId)
          : notice.teacherId,
      createdAt: now,
      updatedAt: now,
      publishedAt: notice.isPublished ? (notice.publishedAt ?? now) : null,
    );

    await docRef.set(toSave.toMap());
    return toSave;
  }

  /// Updates an existing notice in Firestore.
  Future<NoticeModel> updateNotice({
    required TenantPathResolver resolver,
    required NoticeModel notice,
    String? fallbackTeacherId,
  }) async {
    validateAudience(notice);

    final docPath = resolver.noticeDocPath(notice.id, fallbackTeacherId);
    final now = DateTime.now();
    final toSave = notice.copyWith(
      updatedAt: now,
      publishedAt: notice.isPublished
          ? (notice.publishedAt ?? now)
          : notice.publishedAt,
    );

    await _firestore.doc(docPath).update(toSave.toMap());
    return toSave;
  }

  /// Publishes a draft notice.
  Future<NoticeModel> publishNotice({
    required TenantPathResolver resolver,
    required NoticeModel notice,
    required String updaterUid,
    required String updaterName,
    String? fallbackTeacherId,
  }) async {
    validateAudience(notice);

    final now = DateTime.now();
    final updated = notice.copyWith(
      status: NoticeStatus.published,
      publishedAt: notice.publishedAt ?? now,
      updatedAt: now,
      updatedBy: updaterUid,
      updatedByName: updaterName,
    );

    return updateNotice(
      resolver: resolver,
      notice: updated,
      fallbackTeacherId: fallbackTeacherId,
    );
  }

  /// Unpublishes an active notice back to draft status.
  Future<NoticeModel> unpublishNotice({
    required TenantPathResolver resolver,
    required NoticeModel notice,
    required String updaterUid,
    required String updaterName,
    String? fallbackTeacherId,
  }) async {
    final now = DateTime.now();
    final updated = notice.copyWith(
      status: NoticeStatus.draft,
      updatedAt: now,
      updatedBy: updaterUid,
      updatedByName: updaterName,
    );

    return updateNotice(
      resolver: resolver,
      notice: updated,
      fallbackTeacherId: fallbackTeacherId,
    );
  }

  /// Archives a notice.
  Future<NoticeModel> archiveNotice({
    required TenantPathResolver resolver,
    required NoticeModel notice,
    required String updaterUid,
    required String updaterName,
    String? fallbackTeacherId,
  }) async {
    final now = DateTime.now();
    final updated = notice.copyWith(
      status: NoticeStatus.archived,
      archivedAt: now,
      updatedAt: now,
      updatedBy: updaterUid,
      updatedByName: updaterName,
    );

    return updateNotice(
      resolver: resolver,
      notice: updated,
      fallbackTeacherId: fallbackTeacherId,
    );
  }

  /// Deletes a notice document permanently.
  Future<void> deleteNotice({
    required TenantPathResolver resolver,
    required String noticeId,
    String? fallbackTeacherId,
  }) async {
    final docPath = resolver.noticeDocPath(noticeId, fallbackTeacherId);
    await _firestore.doc(docPath).delete();
  }

  /// Fetches notices for Admin or Teacher view.
  Future<List<NoticeModel>> fetchNoticesForAdminOrTeacher({
    required TenantPathResolver resolver,
    String? teacherUid,
    bool isTeacherInInstitute = false,
    String? fallbackTeacherId,
  }) async {
    final path = resolver.noticesPath(fallbackTeacherId);
    final snap = await _firestore.collection(path).get();

    var notices = snap.docs
        .map((d) => NoticeModel.fromMap(d.data(), d.id))
        .toList();

    // In coaching institute mode, a teacher who is not admin should see:
    // 1. Notices they created
    // 2. Published institute-wide notices (audienceType == 'all')
    // 3. Notices targeting batches assigned to them
    if (resolver.isInstitute &&
        isTeacherInInstitute &&
        teacherUid != null &&
        teacherUid.isNotEmpty) {
      final assignedBatches = await _attendanceService.fetchBatches(
        resolver: resolver,
        filterTeacherUid: teacherUid,
        fallbackTeacherId: fallbackTeacherId,
      );
      final assignedBatchIds = assignedBatches.map((b) => b.id).toSet();

      notices = notices.where((n) {
        if (n.createdBy == teacherUid) return true;
        if (n.audienceType == NoticeAudienceType.all &&
            n.isPublished &&
            !n.isArchived) {
          return true;
        }
        if (n.targetBatchIds.any((bId) => assignedBatchIds.contains(bId))) {
          return true;
        }
        return false;
      }).toList();
    }

    notices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notices;
  }

  /// Fetches published notices targeted to a student.
  /// Uses a multi-query merge strategy to comply strictly with Firestore Rules:
  /// - Query 1: Published notices targeting all students (audienceType == 'all')
  /// - Query 2: Published notices targeting the student's enrolled batches (audienceType == 'batches')
  /// - Query 3: Published notices targeting the student's individual studentId (audienceType == 'students')
  Future<List<NoticeModel>> fetchPublishedNoticesForStudent({
    required TenantPathResolver resolver,
    required String studentUid,
    required List<String> enrolledBatchIds,
    String? fallbackTeacherId,
  }) async {
    final path = resolver.noticesPath(fallbackTeacherId);
    final Map<String, NoticeModel> noticeMap = {};

    // Query 1: All-students notices
    try {
      final snapAll = await _firestore
          .collection(path)
          .where('status', isEqualTo: NoticeStatus.published)
          .where('audienceType', isEqualTo: NoticeAudienceType.all)
          .get();

      for (final doc in snapAll.docs) {
        noticeMap[doc.id] = NoticeModel.fromMap(doc.data(), doc.id);
      }
    } catch (_) {}

    // Query 2: Batch-targeted notices (chunked in groups of 10 for Firestore arrayContainsAny)
    if (enrolledBatchIds.isNotEmpty) {
      final cleanBatches = enrolledBatchIds
          .map((b) => b.trim())
          .where((b) => b.isNotEmpty)
          .toList();

      const int chunkSize = 10;
      for (int i = 0; i < cleanBatches.length; i += chunkSize) {
        final chunk = cleanBatches.skip(i).take(chunkSize).toList();
        try {
          final snapBatches = await _firestore
              .collection(path)
              .where('status', isEqualTo: NoticeStatus.published)
              .where('targetBatchIds', arrayContainsAny: chunk)
              .get();

          for (final doc in snapBatches.docs) {
            final model = NoticeModel.fromMap(doc.data(), doc.id);
            if (model.isPublished && !model.isArchived) {
              noticeMap[doc.id] = model;
            }
          }
        } catch (_) {}
      }
    }

    // Query 3: Student-targeted notices
    if (studentUid.trim().isNotEmpty) {
      try {
        final snapStudents = await _firestore
            .collection(path)
            .where('status', isEqualTo: NoticeStatus.published)
            .where('targetStudentIds', arrayContains: studentUid.trim())
            .get();

        for (final doc in snapStudents.docs) {
          final model = NoticeModel.fromMap(doc.data(), doc.id);
          if (model.isPublished && !model.isArchived) {
            noticeMap[doc.id] = model;
          }
        }
      } catch (_) {}
    }

    final result = noticeMap.values.toList();
    result.sort((a, b) {
      final dateA = a.publishedAt ?? a.createdAt;
      final dateB = b.publishedAt ?? b.createdAt;
      return dateB.compareTo(dateA);
    });

    return result;
  }

  /// Real-time stream of published notices targeted to a student.
  /// Listens to real-time snapshots without requiring composite indexes.
  Stream<List<NoticeModel>> streamPublishedNoticesForStudent({
    required TenantPathResolver resolver,
    required String studentUid,
    required List<String> enrolledBatchIds,
    String? fallbackTeacherId,
  }) {
    final path = resolver.noticesPath(fallbackTeacherId);
    final cleanStudentUid = studentUid.trim();
    final cleanBatches = enrolledBatchIds
        .map((b) => b.trim().toLowerCase())
        .where((b) => b.isNotEmpty)
        .toSet();

    return _firestore
        .collection(path)
        .where('status', isEqualTo: NoticeStatus.published)
        .snapshots()
        .map((snapshot) {
          final notices = <NoticeModel>[];
          for (final doc in snapshot.docs) {
            final model = NoticeModel.fromMap(doc.data(), doc.id);
            if (!model.isPublished || model.isArchived) continue;

            // Target check:
            if (model.audienceType == NoticeAudienceType.all) {
              notices.add(model);
            } else if (model.audienceType == NoticeAudienceType.batches) {
              final matchesBatch = model.targetBatchIds.any((bId) {
                final clean = bId.trim().toLowerCase();
                return cleanBatches.contains(clean) ||
                    model.targetBatchNames.any(
                      (name) => cleanBatches.contains(name.trim().toLowerCase()),
                    );
              });
              if (matchesBatch) notices.add(model);
            } else if (model.audienceType == NoticeAudienceType.students) {
              if (cleanStudentUid.isNotEmpty &&
                  model.targetStudentIds.contains(cleanStudentUid)) {
                notices.add(model);
              }
            }
          }

          notices.sort((a, b) {
            final dateA = a.publishedAt ?? a.createdAt;
            final dateB = b.publishedAt ?? b.createdAt;
            return dateB.compareTo(dateA);
          });
          return notices;
        });
  }

  /// Real-time stream of all notices for Admin or Teacher view.
  Stream<List<NoticeModel>> streamNoticesForAdminOrTeacher({
    required TenantPathResolver resolver,
    String? teacherUid,
    bool isTeacherInInstitute = false,
    String? fallbackTeacherId,
  }) {
    final path = resolver.noticesPath(fallbackTeacherId);

    return _firestore.collection(path).snapshots().map((snapshot) {
      var notices = snapshot.docs
          .map((d) => NoticeModel.fromMap(d.data(), d.id))
          .toList();

      if (isTeacherInInstitute && teacherUid != null && teacherUid.isNotEmpty) {
        notices = notices.where((n) {
          final isAuthor = n.teacherId.trim() == teacherUid.trim() ||
              n.createdBy.trim() == teacherUid.trim();
          final isAllAudience =
              n.isPublished && n.audienceType == NoticeAudienceType.all;
          return isAuthor || isAllAudience;
        }).toList();
      }

      notices.sort((a, b) {
        final dateA = a.publishedAt ?? a.createdAt;
        final dateB = b.publishedAt ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
      return notices;
    });
  }

  /// Fetches available batches for notice target selection.
  Future<List<BatchModel>> fetchAvailableBatches({
    required TenantPathResolver resolver,
    String? filterTeacherUid,
    String? fallbackTeacherId,
  }) async {
    return _attendanceService.fetchBatches(
      resolver: resolver,
      filterTeacherUid: filterTeacherUid,
      fallbackTeacherId: fallbackTeacherId,
    );
  }

  /// Fetches available students for notice target selection.
  Future<List<StudentModel>> fetchAvailableStudentsForBatches({
    required TenantPathResolver resolver,
    required List<BatchModel> selectedBatches,
    String? fallbackTeacherId,
  }) async {
    final Map<String, StudentModel> studentMap = {};

    for (final batch in selectedBatches) {
      final students = await _attendanceService.fetchStudentsForBatch(
        resolver: resolver,
        batchId: batch.id,
        batchName: batch.name,
        fallbackTeacherId: fallbackTeacherId,
      );

      for (final s in students) {
        final key = s.authUid.isNotEmpty ? s.authUid : s.id;
        if (key.isNotEmpty) {
          studentMap[key] = s;
        }
      }
    }

    final list = studentMap.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }
}
