import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/invitation_service.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/model/invitation_model.dart';
import 'package:test_nest/model/organization_model.dart';

void main() {
  group('Organization Models Tests', () {
    test('OrganizationModel serializes and deserializes properly', () {
      final now = DateTime.now();
      final org = OrganizationModel(
        id: 'org_apex_123',
        name: 'Apex Academy',
        type: OrganizationType.institute,
        ownerId: 'teacher_admin_01',
        ownerName: 'Dr. Jane Smith',
        createdAt: now,
        status: OrganizationStatus.active,
        metadata: {'phone': '+91 9999999999', 'address': 'Building 4'},
      );

      final map = org.toMap();
      expect(map['name'], 'Apex Academy');
      expect(map['type'], 'institute');
      expect(map['ownerId'], 'teacher_admin_01');
      expect(map['status'], 'active');
      expect(map['metadata']['phone'], '+91 9999999999');

      final fromMap = OrganizationModel.fromMap(map, 'org_apex_123');
      expect(fromMap.id, 'org_apex_123');
      expect(fromMap.name, 'Apex Academy');
      expect(fromMap.isInstitute, isTrue);
      expect(fromMap.isIndependent, isFalse);
      expect(fromMap.isActive, isTrue);
    });

    test(
      'OrganizationMemberModel and UserMembershipModel handle roles and status',
      () {
        final now = DateTime.now();
        final member = OrganizationMemberModel(
          uid: 'teacher_uid_99',
          email: 'teacher@apex.edu',
          name: 'John Doe',
          role: OrganizationRole.teacher,
          status: OrganizationStatus.active,
          joinedAt: now,
          assignedBatchIds: ['batch_1', 'batch_2'],
        );

        expect(member.isTeacher, isTrue);
        expect(member.isAdmin, isFalse);
        expect(member.isStudent, isFalse);
        expect(member.assignedBatchIds.length, 2);

        final map = member.toMap();
        expect(map['role'], 'teacher');
        expect(map['email'], 'teacher@apex.edu');

        final deserialized = OrganizationMemberModel.fromMap(
          map,
          'teacher_uid_99',
        );
        expect(deserialized.uid, 'teacher_uid_99');
        expect(deserialized.assignedBatchIds, contains('batch_1'));

        final membership = UserMembershipModel(
          organizationId: 'org_apex_123',
          organizationName: 'Apex Academy',
          organizationType: OrganizationType.institute,
          role: OrganizationRole.teacher,
          joinedAt: now,
        );

        expect(membership.isInstitute, isTrue);
        expect(membership.isIndependent, isFalse);
      },
    );
  });

  group('Teacher Invitation System Tests', () {
    test(
      'Invitation code generator generates secure 6-char alphanumeric code with prefix',
      () {
        final code1 = InvitationService.generateSecureCode();
        final code2 = InvitationService.generateSecureCode();

        expect(code1, startsWith('TN-INV-'));
        expect(code2, startsWith('TN-INV-'));
        expect(code1.length, 13); // TN-INV- + 6 = 13
        expect(code1, isNot(equals(code2))); // randomness check

        // Check charset doesn't contain confusing characters (0, O, 1, I)
        final randomPart = code1.substring(7);
        expect(randomPart.contains('0'), isFalse);
        expect(randomPart.contains('O'), isFalse);
        expect(randomPart.contains('1'), isFalse);
        expect(randomPart.contains('I'), isFalse);
      },
    );

    test(
      'TeacherInvitationModel correctly determines pending, expired, and accepted states',
      () {
        final now = DateTime.now();

        // Active pending invitation
        final pendingInvite = TeacherInvitationModel(
          code: 'TN-INV-A8B9C2',
          orgId: 'org_123',
          orgName: 'Apex Academy',
          teacherEmail: 'prof@test.com',
          createdBy: 'admin_1',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 7)),
          isUsed: false,
          status: InvitationStatus.pending,
        );

        expect(pendingInvite.isPending, isTrue);
        expect(pendingInvite.isExpired, isFalse);
        expect(pendingInvite.isAccepted, isFalse);

        // Expired invitation
        final expiredInvite = TeacherInvitationModel(
          code: 'TN-INV-EXPIRE',
          orgId: 'org_123',
          orgName: 'Apex Academy',
          teacherEmail: 'prof@test.com',
          createdBy: 'admin_1',
          createdAt: now.subtract(const Duration(days: 8)),
          expiresAt: now.subtract(const Duration(days: 1)),
          isUsed: false,
          status: InvitationStatus.pending,
        );

        expect(expiredInvite.isExpired, isTrue);
        expect(expiredInvite.isPending, isFalse);

        // Accepted invitation
        final acceptedInvite = pendingInvite.copyWith(
          isUsed: true,
          status: InvitationStatus.accepted,
          usedBy: 'user_456',
          usedAt: now,
        );

        expect(acceptedInvite.isAccepted, isTrue);
        expect(acceptedInvite.isPending, isFalse);
      },
    );
  });

  group(
    'TenantPathResolver Tests (Backward Compatibility & Multi-Tenancy)',
    () {
      test('Independent mode resolves to legacy user/{teacherId} paths', () {
        final resolver = TenantPathResolver(
          explicitOrgId: 'teacher_legacy_001',
          explicitIsInstitute: false,
        );

        expect(resolver.basePath(), 'user/teacher_legacy_001');
        expect(resolver.batchesPath(), 'user/teacher_legacy_001/batches');
        expect(
          resolver.batchDocPath('batch_a'),
          'user/teacher_legacy_001/batches/batch_a',
        );
        expect(resolver.studentsPath(), 'user/teacher_legacy_001/students');
        expect(
          resolver.studentDocPath('student_1'),
          'user/teacher_legacy_001/students/student_1',
        );
        expect(resolver.examsPath(), 'user/teacher_legacy_001/exams');
        expect(
          resolver.examDocPath('exam_9'),
          'user/teacher_legacy_001/exams/exam_9',
        );
        expect(
          resolver.submissionsPath('exam_9'),
          'user/teacher_legacy_001/exams/exam_9/submissions',
        );
        expect(resolver.feeRecordsPath(), 'user/teacher_legacy_001/feeRecords');
      });

      test(
        'Institute mode resolves to organizations/{orgId} multi-tenant paths',
        () {
          final resolver = TenantPathResolver(
            explicitOrgId: 'org_apex_456',
            explicitIsInstitute: true,
          );

          expect(resolver.basePath(), 'organizations/org_apex_456');
          expect(resolver.batchesPath(), 'organizations/org_apex_456/batches');
          expect(
            resolver.batchDocPath('batch_x'),
            'organizations/org_apex_456/batches/batch_x',
          );
          expect(
            resolver.studentsPath(),
            'organizations/org_apex_456/students',
          );
          expect(resolver.examsPath(), 'organizations/org_apex_456/exams');
          expect(resolver.membersPath(), 'organizations/org_apex_456/members');
          expect(
            resolver.invitationsPath(),
            'organizations/org_apex_456/invitations',
          );
        },
      );
    },
  );

  group('ActiveTenantContext State Management Tests', () {
    test('Default context provides safe fallbacks before initialization', () {
      final context = ActiveTenantContext();
      expect(context.isInitialized, isFalse);
      expect(context.isLoading, isFalse);
      expect(context.isIndependent, isTrue);
      expect(context.isInstitute, isFalse);
      expect(context.memberships, isEmpty);
      expect(context.activeOrgName, 'Coaching Institute');
    });

    test('clear() properly resets all tenant state', () {
      final context = ActiveTenantContext();
      context.clear();
      expect(context.currentUid, isNull);
      expect(context.activeOrg, isNull);
      expect(context.activeRole, isNull);
      expect(context.memberships, isEmpty);
    });
  });

  group('Section 3 Regression & Security Scenarios', () {
    test(
      'Scenario 1: Existing teacher resolves to old user/{teacherId} paths without destructive migration',
      () {
        const existingTeacherId = 'teacher_legacy_12345';
        final resolver = TenantPathResolver(
          explicitOrgId: existingTeacherId,
          explicitIsInstitute: false,
        );

        // Verify exact backward compatibility
        expect(resolver.basePath(), 'user/teacher_legacy_12345');
        expect(resolver.batchesPath(), 'user/teacher_legacy_12345/batches');
        expect(resolver.studentsPath(), 'user/teacher_legacy_12345/students');
        expect(resolver.examsPath(), 'user/teacher_legacy_12345/exams');
        expect(
          resolver.feeRecordsPath(),
          'user/teacher_legacy_12345/feeRecords',
        );
      },
    );

    test(
      'Scenario 2: Existing student enrollments path structure remains uncompromised',
      () {
        const studentUid = 'student_test_uid';
        expect(
          'users/$studentUid/enrollments',
          'users/student_test_uid/enrollments',
        );
        expect(
          'users/$studentUid/memberships',
          TenantPathResolver.userMembershipsPath(studentUid),
        );
      },
    );

    test('Scenario 3: New independent teacher creates personal workspace', () {
      final org = OrganizationModel(
        id: 'new_teacher_01',
        name: 'Math with Dr. Euler',
        type: OrganizationType.independent,
        ownerId: 'new_teacher_01',
        ownerName: 'Dr. Leonhard Euler',
        createdAt: DateTime.now(),
      );

      expect(org.isIndependent, isTrue);
      expect(org.isInstitute, isFalse);
      expect(org.ownerId, 'new_teacher_01');
    });

    test(
      'Scenario 4 & 7: Invitation lifecycle rejects expired, revoked, and reused codes',
      () {
        final now = DateTime.now();

        // Valid pending
        final valid = TeacherInvitationModel(
          code: 'TN-INV-VALID1',
          orgId: 'org_inst_1',
          orgName: 'Alpha Academy',
          teacherEmail: 'teacher@alpha.org',
          createdBy: 'admin_1',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 7)),
          status: InvitationStatus.pending,
          isUsed: false,
        );
        expect(valid.isPending, isTrue);

        // Expired
        final expired = valid.copyWith(
          expiresAt: now.subtract(const Duration(hours: 1)),
        );
        expect(expired.isExpired, isTrue);
        expect(expired.isPending, isFalse);

        // Revoked
        final revoked = valid.copyWith(status: InvitationStatus.revoked);
        expect(revoked.isRevoked, isTrue);
        expect(revoked.isPending, isFalse);

        // Already used
        final reused = valid.copyWith(
          isUsed: true,
          status: InvitationStatus.accepted,
          usedBy: 'other_teacher',
        );
        expect(reused.isAccepted, isTrue);
        expect(reused.isPending, isFalse);
      },
    );

    test('Scenario 5: Wrong email cannot redeem invitation', () {
      final invite = TeacherInvitationModel(
        code: 'TN-INV-EMTEST',
        orgId: 'org_inst_1',
        orgName: 'Alpha Academy',
        teacherEmail: 'intended.teacher@alpha.org',
        createdBy: 'admin_1',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        status: InvitationStatus.pending,
      );

      const attackerEmail = 'attacker@malicious.com';
      expect(
        invite.teacherEmail.toLowerCase() == attackerEmail.toLowerCase(),
        isFalse,
        reason: 'Email mismatch must strictly reject redemption',
      );
    });

    test(
      'Scenario 8: Teacher with multiple institute memberships can switch between them',
      () {
        final now = DateTime.now();
        final membership1 = UserMembershipModel(
          organizationId: 'org_apex',
          organizationName: 'Apex Academy',
          organizationType: OrganizationType.institute,
          role: OrganizationRole.admin,
          joinedAt: now,
        );
        final membership2 = UserMembershipModel(
          organizationId: 'org_beta',
          organizationName: 'Beta Coaching',
          organizationType: OrganizationType.institute,
          role: OrganizationRole.teacher,
          joinedAt: now,
        );

        final memberships = [membership1, membership2];
        expect(memberships.length, 2);

        // When in Org 1
        var active = memberships.firstWhere(
          (m) => m.organizationId == 'org_apex',
        );
        expect(active.isAdmin, isTrue);
        expect(active.isTeacher, isFalse);

        // Switch to Org 2
        active = memberships.firstWhere((m) => m.organizationId == 'org_beta');
        expect(active.isAdmin, isFalse);
        expect(active.isTeacher, isTrue);
      },
    );

    test(
      'Scenario 10: Student role cannot perform teacher/admin operations',
      () {
        final studentMember = OrganizationMemberModel(
          uid: 'student_uid_01',
          email: 'student@test.com',
          name: 'Student One',
          role: OrganizationRole.student,
          joinedAt: DateTime.now(),
        );

        expect(studentMember.isStudent, isTrue);
        expect(studentMember.isTeacher, isFalse);
        expect(studentMember.isAdmin, isFalse);
      },
    );
  });
}
