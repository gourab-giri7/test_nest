import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/core/services/notice_service.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/notice_editor_controller.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/notice_management_controller.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/notices/controller/student_notice_inbox_controller.dart';
import 'package:test_nest/model/notice_model.dart';

void main() {
  group('NoticeModel & Serialization Tests', () {
    test('NoticeModel serialization and deserialization roundtrip', () {
      final now = DateTime(2026, 11, 21, 14, 30);
      final notice = NoticeModel(
        id: 'notice_test_01',
        organizationId: 'org_apex_100',
        teacherId: 'teacher_01',
        title: 'Midterm Exam Schedule',
        body: 'The physics exam will be held on Monday.',
        category: NoticeCategory.exam,
        status: NoticeStatus.published,
        audienceType: NoticeAudienceType.batches,
        targetBatchIds: const ['batch_01', 'batch_02'],
        targetBatchNames: const ['Mechanics XI', 'Electromagnetism XII'],
        targetStudentIds: const [],
        targetStudentNames: const [],
        attachmentUrl: 'https://example.com/exam.pdf',
        createdBy: 'teacher_01',
        createdByName: 'Prof. Sharma',
        updatedBy: 'teacher_01',
        updatedByName: 'Prof. Sharma',
        createdAt: now,
        updatedAt: now,
        publishedAt: now,
      );

      final map = notice.toMap();
      expect(map['id'], equals('notice_test_01'));
      expect(map['title'], equals('Midterm Exam Schedule'));
      expect(map['category'], equals('exam'));
      expect(map['status'], equals('published'));
      expect(map['audienceType'], equals('batches'));
      expect(map['targetBatchIds'], equals(['batch_01', 'batch_02']));

      final fromMapNotice = NoticeModel.fromMap(map, 'notice_test_01');
      expect(fromMapNotice.id, equals(notice.id));
      expect(fromMapNotice.organizationId, equals(notice.organizationId));
      expect(fromMapNotice.title, equals(notice.title));
      expect(fromMapNotice.body, equals(notice.body));
      expect(fromMapNotice.category, equals(NoticeCategory.exam));
      expect(fromMapNotice.status, equals(NoticeStatus.published));
      expect(fromMapNotice.isPublished, isTrue);
      expect(fromMapNotice.isDraft, isFalse);
      expect(fromMapNotice.isArchived, isFalse);
      expect(fromMapNotice.hasAttachment, isTrue);
      expect(fromMapNotice.targetBatchIds, equals(['batch_01', 'batch_02']));
      expect(
        fromMapNotice.targetBatchNames,
        equals(['Mechanics XI', 'Electromagnetism XII']),
      );
    });

    test('NoticeAudienceType and summary display', () {
      final now = DateTime.now();
      final allNotice = NoticeModel(
        id: '1',
        title: 'Holiday',
        body: 'School closed tomorrow',
        audienceType: NoticeAudienceType.all,
        createdBy: 'admin_1',
        updatedBy: 'admin_1',
        createdAt: now,
        updatedAt: now,
      );
      expect(allNotice.audienceSummary, equals('All Students'));

      final batchNotice = allNotice.copyWith(
        audienceType: NoticeAudienceType.batches,
        targetBatchNames: const ['Batch A'],
      );
      expect(batchNotice.audienceSummary, equals('Batch A'));

      final multiBatchNotice = allNotice.copyWith(
        audienceType: NoticeAudienceType.batches,
        targetBatchNames: const ['Batch A', 'Batch B', 'Batch C'],
      );
      expect(
        multiBatchNotice.audienceSummary,
        equals('3 Batches (Batch A, Batch B...)'),
      );

      final studentNotice = allNotice.copyWith(
        audienceType: NoticeAudienceType.students,
        targetStudentNames: const ['Alice', 'Bob'],
      );
      expect(studentNotice.audienceSummary, equals('2 Students'));
    });

    test('NoticeStatus transitions and copyWith', () {
      final now = DateTime.now();
      final draft = NoticeModel(
        id: '1',
        title: 'Draft Notice',
        body: 'Draft body',
        status: NoticeStatus.draft,
        createdBy: 't1',
        updatedBy: 't1',
        createdAt: now,
        updatedAt: now,
      );
      expect(draft.isDraft, isTrue);
      expect(draft.publishedAt, isNull);

      final published = draft.copyWith(
        status: NoticeStatus.published,
        publishedAt: now,
      );
      expect(published.isPublished, isTrue);
      expect(published.isDraft, isFalse);
      expect(published.publishedAt, equals(now));

      final archived = published.copyWith(
        status: NoticeStatus.archived,
        archivedAt: now,
      );
      expect(archived.isArchived, isTrue);
      expect(archived.isPublished, isFalse);

      final unpublished = archived.copyWith(status: NoticeStatus.draft);
      expect(unpublished.isDraft, isTrue);
    });
  });

  group('NoticeService Audience Validation Tests', () {
    final now = DateTime.now();

    test('Throws ArgumentError if title is empty', () {
      final invalid = NoticeModel(
        id: '1',
        title: '   ',
        body: 'Valid message',
        createdBy: 't1',
        updatedBy: 't1',
        createdAt: now,
        updatedAt: now,
      );
      expect(
        () => NoticeService.validateAudience(invalid),
        throwsArgumentError,
      );
    });

    test('Throws ArgumentError if body is empty', () {
      final invalid = NoticeModel(
        id: '1',
        title: 'Valid Title',
        body: '',
        createdBy: 't1',
        updatedBy: 't1',
        createdAt: now,
        updatedAt: now,
      );
      expect(
        () => NoticeService.validateAudience(invalid),
        throwsArgumentError,
      );
    });

    test(
      'Throws ArgumentError if audience is batches but targetBatchIds is empty',
      () {
        final invalid = NoticeModel(
          id: '1',
          title: 'Valid Title',
          body: 'Valid body',
          audienceType: NoticeAudienceType.batches,
          targetBatchIds: const [],
          createdBy: 't1',
          updatedBy: 't1',
          createdAt: now,
          updatedAt: now,
        );
        expect(
          () => NoticeService.validateAudience(invalid),
          throwsArgumentError,
        );
      },
    );

    test(
      'Throws ArgumentError if audience is students but targetStudentIds is empty',
      () {
        final invalid = NoticeModel(
          id: '1',
          title: 'Valid Title',
          body: 'Valid body',
          audienceType: NoticeAudienceType.students,
          targetStudentIds: const [],
          createdBy: 't1',
          updatedBy: 't1',
          createdAt: now,
          updatedAt: now,
        );
        expect(
          () => NoticeService.validateAudience(invalid),
          throwsArgumentError,
        );
      },
    );

    test('Passes validation when audience is valid', () {
      final valid = NoticeModel(
        id: '1',
        title: 'Valid Title',
        body: 'Valid body',
        audienceType: NoticeAudienceType.all,
        createdBy: 't1',
        updatedBy: 't1',
        createdAt: now,
        updatedAt: now,
      );
      expect(() => NoticeService.validateAudience(valid), returnsNormally);
    });
  });

  group('TenantPathResolver Notice Paths', () {
    test('Resolves notices path correctly in Institute Mode', () {
      final resolver = TenantPathResolver(
        explicitOrgId: 'org_test_77',
        explicitIsInstitute: true,
      );
      expect(
        resolver.noticesPath(),
        equals('organizations/org_test_77/notices'),
      );
      expect(
        resolver.noticeDocPath('not_01'),
        equals('organizations/org_test_77/notices/not_01'),
      );
    });

    test('Resolves notices path correctly in Single Teacher Mode', () {
      final resolver = TenantPathResolver(
        explicitOrgId: '',
        explicitIsInstitute: false,
      );
      expect(
        resolver.noticesPath('teacher_99'),
        equals('user/teacher_99/notices'),
      );
      expect(
        resolver.noticeDocPath('not_01', 'teacher_99'),
        equals('user/teacher_99/notices/not_01'),
      );
    });
  });

  group('NoticeManagementController Filtering Tests', () {
    test('Filters notices by tab, category, and search query', () {
      final controller = NoticeManagementController();
      final now = DateTime.now();

      final n1 = NoticeModel(
        id: '1',
        title: 'Math Exam Postponed',
        body: 'Will happen next Friday',
        category: NoticeCategory.exam,
        status: NoticeStatus.published,
        createdBy: 't1',
        createdByName: 'Mr. Raman',
        updatedBy: 't1',
        createdAt: now,
        updatedAt: now,
      );
      final n2 = NoticeModel(
        id: '2',
        title: 'Tuition Fee Due Date',
        body: 'Clear dues before 10th',
        category: NoticeCategory.fee,
        status: NoticeStatus.draft,
        createdBy: 't1',
        createdByName: 'Admin',
        updatedBy: 't1',
        createdAt: now,
        updatedAt: now,
      );
      final n3 = NoticeModel(
        id: '3',
        title: 'Diwali Holiday Notice',
        body: 'Institute closed for 3 days',
        category: NoticeCategory.holiday,
        status: NoticeStatus.archived,
        createdBy: 't1',
        createdByName: 'Principal',
        updatedBy: 't1',
        createdAt: now,
        updatedAt: now,
      );

      // Populate internal list via test injection
      controller.allNotices.addAll([n1, n2, n3]);

      // All tab
      controller.setTab(0);
      expect(controller.filteredNotices.length, equals(3));
      expect(controller.publishedCount, equals(1));
      expect(controller.draftCount, equals(1));
      expect(controller.archivedCount, equals(1));

      // Published tab
      controller.setTab(1);
      expect(controller.filteredNotices.length, equals(1));
      expect(controller.filteredNotices.first.id, equals('1'));

      // Drafts tab
      controller.setTab(2);
      expect(controller.filteredNotices.length, equals(1));
      expect(controller.filteredNotices.first.id, equals('2'));

      // Archived tab
      controller.setTab(3);
      expect(controller.filteredNotices.length, equals(1));
      expect(controller.filteredNotices.first.id, equals('3'));

      // Back to All, filter by category
      controller.setTab(0);
      controller.setCategory(NoticeCategory.fee);
      expect(controller.filteredNotices.length, equals(1));
      expect(
        controller.filteredNotices.first.title,
        equals('Tuition Fee Due Date'),
      );

      // Filter by search query
      controller.setCategory(null);
      controller.setSearchQuery('Exam');
      expect(controller.filteredNotices.length, equals(1));
      expect(controller.filteredNotices.first.title, contains('Exam'));

      controller.setSearchQuery('NonExistent');
      expect(controller.filteredNotices, isEmpty);
    });
  });

  group('NoticeEditorController State & Dirty Guard Tests', () {
    test(
      'Initial controller state is clean, detects modifications, and reverts with discard',
      () {
        final controller = NoticeEditorController();

        controller.setTitle('Initial Title');
        controller.setBody('Initial Body');
        expect(controller.title, equals('Initial Title'));
        expect(controller.body, equals('Initial Body'));

        controller.setCategory(NoticeCategory.urgent);
        expect(controller.category, equals(NoticeCategory.urgent));

        controller.setAudienceType(NoticeAudienceType.batches);
        expect(controller.audienceType, equals(NoticeAudienceType.batches));
      },
    );
  });

  group('StudentNoticeInboxController Tests', () {
    test('Filters notices by category and search query correctly', () {
      final controller = StudentNoticeInboxController();
      final now = DateTime.now();

      final n1 = NoticeModel(
        id: '1',
        title: 'Sports Day Next Week',
        body: 'Wear running shoes',
        category: NoticeCategory.general,
        status: NoticeStatus.published,
        createdBy: 't1',
        updatedBy: 't1',
        createdAt: now,
        updatedAt: now,
      );
      final n2 = NoticeModel(
        id: '2',
        title: 'Physics Revision Class',
        body: 'Room 302 at 4 PM',
        category: NoticeCategory.classSession,
        status: NoticeStatus.published,
        createdBy: 't1',
        updatedBy: 't1',
        createdAt: now,
        updatedAt: now,
      );

      controller.allNotices.addAll([n1, n2]);

      expect(controller.filteredNotices.length, equals(2));
      expect(controller.unreadCount, equals(2));
      expect(controller.isRead('1'), isFalse);

      controller.setCategory(NoticeCategory.classSession);
      expect(controller.filteredNotices.length, equals(1));
      expect(
        controller.filteredNotices.first.title,
        equals('Physics Revision Class'),
      );

      controller.setCategory(null);
      controller.setSearchQuery('Sports');
      expect(controller.filteredNotices.length, equals(1));
      expect(
        controller.filteredNotices.first.title,
        equals('Sports Day Next Week'),
      );
    });
  });
}
