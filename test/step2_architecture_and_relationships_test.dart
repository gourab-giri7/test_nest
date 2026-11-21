import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/model/batch_student_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/join_request_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 2: Core Architecture & Data Models', () {
    test('BatchStudentModel serializes and deserializes properly', () {
      final now = DateTime(2026, 10, 24, 10, 30);
      final model = BatchStudentModel(
        studentUid: 'student_uid_001',
        orgId: 'org_apex_100',
        batchId: 'batch_math_01',
        batchName: 'Class 12 Advanced Math',
        studentName: 'Alice Walker',
        studentEmail: 'alice@students.edu',
        studentPhone: '+91 9876543210',
        status: 'active',
        enrolledAt: now,
        updatedAt: now,
      );

      final json = model.toJson();
      expect(json['student_uid'], 'student_uid_001');
      expect(json['org_id'], 'org_apex_100');
      expect(json['batch_id'], 'batch_math_01');
      expect(json['batch_name'], 'Class 12 Advanced Math');
      expect(json['student_name'], 'Alice Walker');
      expect(json['student_email'], 'alice@students.edu');
      expect(json['student_phone'], '+91 9876543210');
      expect(json['status'], 'active');

      final fromJson = BatchStudentModel.fromJson(json, docId: 'doc_custom_id');
      expect(fromJson.studentUid, 'student_uid_001');
      expect(fromJson.docId, 'doc_custom_id');
      expect(fromJson.orgId, 'org_apex_100');
      expect(fromJson.batchId, 'batch_math_01');
      expect(fromJson.batchName, 'Class 12 Advanced Math');
      expect(fromJson.studentName, 'Alice Walker');
      expect(fromJson.isActive, isTrue);
    });

    test(
      'JoinRequestModel serializes and deserializes with institute fields',
      () {
        final now = DateTime(2026, 10, 24, 11, 0);
        final model = JoinRequestModel(
          id: 'req_001',
          studentUid: 'student_uid_001',
          studentName: 'Alice Walker',
          studentEmail: 'alice@students.edu',
          phone: '+91 9876543210',
          status: 'approved',
          timestamp: now,
          orgId: 'org_apex_100',
          orgName: 'Apex Academy',
          assignedBatchId: 'batch_math_01',
          assignedBatchName: 'Class 12 Advanced Math',
          reviewedBy: 'owner_admin_01',
          reviewedAt: now,
        );

        final json = model.toJson();
        expect(json['org_id'], 'org_apex_100');
        expect(json['org_name'], 'Apex Academy');
        expect(json['assigned_batch_id'], 'batch_math_01');
        expect(json['assigned_batch_name'], 'Class 12 Advanced Math');
        expect(json['reviewed_by'], 'owner_admin_01');
        expect(json['status'], 'approved');

        final fromJson = JoinRequestModel.fromJson(json, docId: 'req_001');
        expect(fromJson.orgId, 'org_apex_100');
        expect(fromJson.orgName, 'Apex Academy');
        expect(fromJson.assignedBatchId, 'batch_math_01');
        expect(fromJson.isApproved, isTrue);
        expect(fromJson.reviewedBy, 'owner_admin_01');
      },
    );

    test('StudentModel includes orgId for institute student profiles', () {
      final student = StudentModel(
        name: 'Bob Smith',
        batch: 'Physics Batch',
        batchId: 'batch_phy_01',
        id: 'std_002',
        password: '',
        orgId: 'org_apex_100',
        email: 'bob@students.edu',
        authUid: 'auth_bob_002',
      );

      expect(student.orgId, 'org_apex_100');
      final json = student.toJson();
      expect(json['org_id'], 'org_apex_100');

      final parsed = StudentModel.fromJson(json);
      expect(parsed.orgId, 'org_apex_100');
      expect(parsed.name, 'Bob Smith');
    });
  });

  group('Step 2: TenantPathResolver Canonical Paths', () {
    test('Resolves correct paths in Coaching Institute Mode', () {
      final resolver = TenantPathResolver(
        explicitOrgId: 'org_apex_100',
        explicitIsInstitute: true,
      );

      expect(resolver.basePath(), 'organizations/org_apex_100');
      expect(resolver.batchesPath(), 'organizations/org_apex_100/batches');
      expect(
        resolver.batchDocPath('batch_123'),
        'organizations/org_apex_100/batches/batch_123',
      );
      expect(
        resolver.batchStudentsPath('batch_123'),
        'organizations/org_apex_100/batches/batch_123/students',
      );
      expect(
        resolver.batchStudentDocPath('batch_123', 'student_456'),
        'organizations/org_apex_100/batches/batch_123/students/student_456',
      );
      expect(
        resolver.joinRequestsPath(),
        'organizations/org_apex_100/joinRequests',
      );
      expect(
        resolver.joinRequestDocPath('req_789'),
        'organizations/org_apex_100/joinRequests/req_789',
      );
    });

    test('Preserves Single Teacher Mode paths for backward compatibility', () {
      final resolver = TenantPathResolver(
        explicitOrgId: 'teacher_jane_01',
        explicitIsInstitute: false,
      );

      expect(resolver.basePath(), 'user/teacher_jane_01');
      expect(resolver.batchesPath(), 'user/teacher_jane_01/batches');
      expect(
        resolver.batchStudentsPath('batch_123'),
        'user/teacher_jane_01/batches/batch_123/students',
      );
      expect(resolver.studentsPath(), 'user/teacher_jane_01/students');
    });
  });

  group('Step 2: Student Login & Active Enrollment Resolution', () {
    test(
      'Institute student with orgId has active enrollment without teacherId',
      () {
        final student = StudentData(
          id: 'student_tim_004',
          name: 'Tim Student',
          teacherId: '',
          teacherName: '',
          batch: 'batch_math_01',
          orgId: 'org_apex_100',
          orgName: 'Apex Academy',
          assignedBatchIds: ['batch_math_01', 'batch_phy_02'],
        );

        // Student NEVER depends on teacherId in institute mode
        expect(student.hasActiveEnrollment, isTrue);
        expect(student.teacherId, isEmpty);
        expect(student.orgId, 'org_apex_100');
        expect(student.orgName, 'Apex Academy');
        expect(student.assignedBatchIds.length, 2);
      },
    );

    test(
      'Local preferences persist and restore orgId and orgName correctly',
      () async {
        SharedPreferences.setMockInitialValues({});
        pref = await SharedPreferences.getInstance();
        studentData = StudentData(
          id: 'student_tim_004',
          name: 'Tim Student',
          teacherId: '',
          teacherName: '',
          batch: 'Class 12',
          orgId: 'org_apex_100',
          orgName: 'Apex Academy',
          assignedBatchIds: ['batch_01'],
        );

        await StudentData.updateStudentLocalData();

        // Clear in-memory instance
        studentData = null;

        final restored = await StudentData.restoreFromPreferences();
        expect(restored, isNotNull);
        expect(studentData, isNotNull);
        expect(studentData!.id, 'student_tim_004');
        expect(studentData!.orgId, 'org_apex_100');
        expect(studentData!.orgName, 'Apex Academy');
        expect(studentData!.hasActiveEnrollment, isTrue);
      },
    );
  });

  group('Step 2: Exam Eligibility in Coaching Institute Mode', () {
    test(
      'Institute student is eligible for exam matching assignedBatchIds',
      () {
        final now = DateTime.now();
        final exam = ExamModel(
          examId: 'exam_math_01',
          examName: 'Calculus Midterm',
          fullMarks: '100',
          examKey: 'CALC101',
          instruction: 'Solve all questions',
          batch: 'batch_math_01',
          examStart: now.subtract(const Duration(minutes: 30)),
          examEnd: now.add(const Duration(hours: 1)),
          teacherId: 'owner_admin_01',
          teacherName: 'Apex Academy',
          questions: const [],
        );

        // Student has no legacy enrollment but has assignedBatchIds
        final isEligible = exam.isEligibleForStudent(
          studentId: 'student_tim_004',
          assignedBatchIds: ['batch_math_01', 'batch_phy_02'],
        );
        expect(isEligible, isTrue);

        // Student not assigned to this batch
        final isNotEligible = exam.isEligibleForStudent(
          studentId: 'student_tim_004',
          assignedBatchIds: ['batch_chem_03'],
        );
        expect(isNotEligible, isFalse);
      },
    );

    test('Historical submissions are always accessible to student', () {
      final now = DateTime.now();
      final exam = ExamModel(
        examId: 'exam_math_old',
        examName: 'Past Quiz',
        fullMarks: '50',
        examKey: 'OLD101',
        instruction: 'Old exam',
        batch: 'batch_other',
        examStart: now.subtract(const Duration(days: 5)),
        examEnd: now.subtract(const Duration(days: 5, hours: -1)),
        teacherId: 'owner_admin_01',
        questions: const [],
      );

      final isEligible = exam.isEligibleForStudent(
        studentId: 'student_tim_004',
        assignedBatchIds: ['batch_math_01'],
        hasSubmitted: true,
      );
      expect(isEligible, isTrue);
    });
  });
}
