import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/organization_model.dart';

void main() {
  group('Phase 2: BatchModel & Teacher Assignment Tests', () {
    test(
      'BatchModel correctly serializes and deserializes assignedTeacherIds',
      () {
        final now = DateTime.now();
        final batch = BatchModel(
          id: 'batch_phy_101',
          name: 'Physics XI',
          classLevel: 'Class 11',
          academicYear: '2026-27',
          subject: 'Physics',
          monthlyFee: 1500.0,
          activeJoinCode: 'TN-PHY11',
          teacherId: 'teacher_admin_01',
          assignedTeacherIds: ['teacher_admin_01', 'teacher_assist_02'],
          studentCount: 25,
          pendingRequestCount: 3,
          createdAt: now,
        );

        final json = batch.toJson();
        expect(json['id'], 'batch_phy_101');
        expect(json['name'], 'Physics XI');
        expect(json['assigned_teacher_ids'], contains('teacher_assist_02'));
        expect(json['assigned_teacher_ids'].length, 2);

        final fromJson = BatchModel.fromJson(json, docId: 'batch_phy_101');
        expect(fromJson.assignedTeacherIds, contains('teacher_assist_02'));
        expect(fromJson.assignedTeacherIds.length, 2);
      },
    );

    test(
      'BatchModel fallback: missing assigned_teacher_ids defaults to [teacherId]',
      () {
        final legacyJson = {
          'id': 'batch_legacy_01',
          'name': 'Chemistry XII',
          'teacher_id': 'teacher_singlemode_99',
          'monthly_fee': 1200.0,
          'active_join_code': 'TN-CHEM12',
        };

        final batch = BatchModel.fromJson(legacyJson, docId: 'batch_legacy_01');
        expect(batch.assignedTeacherIds, ['teacher_singlemode_99']);
        expect(batch.teacherId, 'teacher_singlemode_99');
      },
    );

    test(
      'BatchModel copyWith updates assignedTeacherIds without deleting batch data',
      () {
        final batch = BatchModel(
          id: 'batch_1',
          name: 'Math',
          activeJoinCode: 'TN-MTH01',
          teacherId: 'teacher_1',
          assignedTeacherIds: ['teacher_1'],
          studentCount: 15,
        );

        final updated = batch.copyWith(
          assignedTeacherIds: ['teacher_1', 'teacher_2', 'teacher_3'],
        );

        expect(updated.assignedTeacherIds.length, 3);
        expect(updated.studentCount, 15);
        expect(updated.name, 'Math');
      },
    );
  });

  group('Phase 2: OrganizationMemberModel Batch Assignment Tests', () {
    test('Member assignedBatchIds correctly tracks batch access', () {
      final member = OrganizationMemberModel(
        uid: 'teacher_faculty_1',
        email: 'faculty1@institute.edu',
        name: 'Prof. Gauss',
        role: OrganizationRole.teacher,
        joinedAt: DateTime.now(),
        assignedBatchIds: ['batch_algebra', 'batch_calculus'],
      );

      expect(member.isTeacher, isTrue);
      expect(member.isAdmin, isFalse);
      expect(member.assignedBatchIds, contains('batch_algebra'));
      expect(member.assignedBatchIds.length, 2);

      final map = member.toMap();
      expect(map['assignedBatchIds'], contains('batch_calculus'));

      final fromMap = OrganizationMemberModel.fromMap(map, 'teacher_faculty_1');
      expect(fromMap.assignedBatchIds.length, 2);
    });
  });

  group('Phase 2: Exam Ownership & Permissions Tests', () {
    test('ExamModel identifies author teacher for ownership enforcement', () {
      const exam = ExamModel(
        examId: 'exam_term1',
        examName: 'Midterm Test',
        fullMarks: '100',
        examKey: 'KEY123',
        instruction: 'No calculators',
        batch: 'Batch Alpha',
        examStart: null,
        examEnd: null,
        questions: [],
        teacherId: 'teacher_owner_abc',
        teacherName: 'Dr. Turing',
      );

      expect(exam.teacherId, 'teacher_owner_abc');
      expect(exam.teacherName, 'Dr. Turing');

      // Check ownership comparison
      const requestingTeacherUid = 'teacher_owner_abc';
      const maliciousTeacherUid = 'teacher_imposter_xyz';

      expect(exam.teacherId == requestingTeacherUid, isTrue);
      expect(exam.teacherId == maliciousTeacherUid, isFalse);
    });
  });

  group('Phase 2: ActiveTenantContext Adaptive Role Modes Tests', () {
    test(
      'ActiveTenantContext distinguishes Institute Admin, Institute Teacher, and Single Teacher',
      () {
        final context = ActiveTenantContext();
        expect(context.isIndependent, isTrue);
        expect(context.isInstitute, isFalse);
        expect(context.isAdmin, isFalse);
        expect(context.isTeacher, isFalse);

        // Verify path resolver defaults to legacy user/{teacherId}
        final resolver = context.pathResolver;
        expect(
          resolver.basePath('legacy_teacher_42'),
          'user/legacy_teacher_42',
        );
        expect(
          resolver.batchesPath('legacy_teacher_42'),
          'user/legacy_teacher_42/batches',
        );
        expect(
          resolver.studentsPath('legacy_teacher_42'),
          'user/legacy_teacher_42/students',
        );
        expect(
          resolver.examsPath('legacy_teacher_42'),
          'user/legacy_teacher_42/exams',
        );
      },
    );

    test(
      'Institute mode path resolver targets organizations/{orgId} collections',
      () {
        final instituteResolver = TenantPathResolver(
          explicitOrgId: 'org_summit_academy',
          explicitIsInstitute: true,
        );

        expect(
          instituteResolver.basePath(),
          'organizations/org_summit_academy',
        );
        expect(
          instituteResolver.batchesPath(),
          'organizations/org_summit_academy/batches',
        );
        expect(
          instituteResolver.studentsPath(),
          'organizations/org_summit_academy/students',
        );
        expect(
          instituteResolver.examsPath(),
          'organizations/org_summit_academy/exams',
        );
        expect(
          instituteResolver.membersPath(),
          'organizations/org_summit_academy/members',
        );
      },
    );
  });

  group('Phase 2: Student Role Isolation Tests', () {
    test('Student membership cannot have teacher or admin permissions', () {
      final student = OrganizationMemberModel(
        uid: 'student_learner_01',
        email: 'learner@school.com',
        name: 'Learner One',
        role: OrganizationRole.student,
        joinedAt: DateTime.now(),
        assignedBatchIds: [],
      );

      expect(student.isStudent, isTrue);
      expect(student.isTeacher, isFalse);
      expect(student.isAdmin, isFalse);
    });
  });
}
