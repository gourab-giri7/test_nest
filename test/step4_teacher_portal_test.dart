import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/institute_teacher_dashboard_controller.dart';
import 'package:test_nest/model/teacher_salary_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 4: Teacher Portal - Models & Deduplication Tests', () {
    test('TeacherSalaryModel serializes and deserializes properly', () {
      final now = DateTime(2026, 10, 24, 15, 30);
      final salary = TeacherSalaryModel(
        id: 'sal_101',
        orgId: 'org_apex_100',
        teacherUid: 'teacher_jane_001',
        teacherName: 'Jane Doe',
        amount: 45000.0,
        month: 'October 2026',
        status: 'paid',
        paidAt: now,
        createdAt: now,
        paymentMode: 'Bank Transfer',
        referenceNumber: 'TXN-987654',
        notes: 'Monthly compensation',
      );

      final json = salary.toJson();
      expect(json['id'], 'sal_101');
      expect(json['org_id'], 'org_apex_100');
      expect(json['teacher_uid'], 'teacher_jane_001');
      expect(json['teacher_name'], 'Jane Doe');
      expect(json['amount'], 45000.0);
      expect(json['month'], 'October 2026');
      expect(json['status'], 'paid');
      expect(json['payment_mode'], 'Bank Transfer');
      expect(json['reference_number'], 'TXN-987654');

      final fromJson = TeacherSalaryModel.fromJson(json, docId: 'sal_101');
      expect(fromJson.id, 'sal_101');
      expect(fromJson.isPaid, isTrue);
      expect(fromJson.isPending, isFalse);
      expect(fromJson.amount, 45000.0);
      expect(fromJson.month, 'October 2026');

      final pending = fromJson.copyWith(status: 'pending');
      expect(pending.isPaid, isFalse);
      expect(pending.isPending, isTrue);
    });

    test(
      'TeacherAssignedStudent matches search across name, email, and phone',
      () {
        const student = TeacherAssignedStudent(
          studentUid: 'student_001',
          studentName: 'Alice Walker',
          studentEmail: 'alice@institute.edu',
          studentPhone: '+91 9876543210',
          batchIds: ['batch_1', 'batch_2'],
          batchNames: ['Mathematics 12', 'Physics Advanced'],
        );

        expect(student.matchesSearch('alice'), isTrue);
        expect(student.matchesSearch('WALKER'), isTrue);
        expect(student.matchesSearch('institute.edu'), isTrue);
        expect(student.matchesSearch('987654'), isTrue);
        expect(student.matchesSearch('Bob'), isFalse);
      },
    );

    test('TenantPathResolver resolves correct salary paths for institute', () {
      final pathResolver = TenantPathResolver(
        explicitOrgId: 'org_apex_100',
        explicitIsInstitute: true,
      );

      expect(
        pathResolver.salariesPath(),
        'organizations/org_apex_100/salaries',
      );
      expect(
        pathResolver.salaryDocPath('sal_101'),
        'organizations/org_apex_100/salaries/sal_101',
      );
    });
  });

  group('Step 4: InstituteTeacherDashboardController Tests', () {
    test('Tab switching works smoothly across all 5 navigation tabs', () {
      final controller = InstituteTeacherDashboardController(autoListen: false);

      expect(controller.currentTabIndex, 0);

      controller.switchTab(1);
      expect(controller.currentTabIndex, 1);

      controller.switchTab(2);
      expect(controller.currentTabIndex, 2);

      controller.switchTab(3);
      expect(controller.currentTabIndex, 3);

      controller.switchTab(4);
      expect(controller.currentTabIndex, 4);

      controller.switchTab(0);
      expect(controller.currentTabIndex, 0);
    });

    test('Batch and student filters and search queries work correctly', () {
      final controller = InstituteTeacherDashboardController(autoListen: false);

      expect(controller.studentSearchQuery, isEmpty);
      expect(controller.studentBatchFilter, 'all');

      controller.setStudentSearchQuery('John');
      expect(controller.studentSearchQuery, 'John');

      controller.setStudentBatchFilter('batch_math_01');
      expect(controller.studentBatchFilter, 'batch_math_01');

      controller.setBatchSearchQuery('Physics');
      expect(controller.batchSearchQuery, 'Physics');

      controller.setExamSearchQuery('Midterm');
      expect(controller.examSearchQuery, 'Midterm');

      controller.setExamStatusFilter('active');
      expect(controller.examStatusFilter, 'active');
    });
  });
}
