import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/fee_service.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/owner_finance_controller.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/payment_model.dart';
import 'package:test_nest/model/teacher_salary_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 6: Student Fee Models & Calculations', () {
    test('FeeRecord calculates status and outstanding balance accurately', () {
      // 1. Unpaid / Pending
      const unpaid = FeeRecord(
        billingMonth: '2026-11',
        studentId: 'stud_001',
        studentName: 'Alice',
        amountDue: 5000.0,
        amountPaid: 0.0,
      );
      expect(unpaid.balance, 5000.0);
      expect(unpaid.status, 'unpaid');

      // 2. Partial
      const partial = FeeRecord(
        billingMonth: '2026-11',
        studentId: 'stud_001',
        studentName: 'Alice',
        amountDue: 5000.0,
        amountPaid: 2000.0,
      );
      expect(partial.balance, 3000.0);
      expect(partial.status, 'partial');

      // 3. Fully paid
      const paid = FeeRecord(
        billingMonth: '2026-11',
        studentId: 'stud_001',
        studentName: 'Alice',
        amountDue: 5000.0,
        amountPaid: 5000.0,
      );
      expect(paid.balance, 0.0);
      expect(paid.status, 'paid');

      // 4. Overdue (due date in past)
      final overdueDate = DateTime.now().subtract(const Duration(days: 5));
      final overdue = FeeRecord(
        billingMonth: '2026-11',
        studentId: 'stud_001',
        studentName: 'Alice',
        amountDue: 5000.0,
        amountPaid: 0.0,
        dueDate: overdueDate,
      );
      expect(overdue.status, 'overdue');
    });

    test(
      'PaymentEntry serializes and deserializes with append-only metadata',
      () {
        final now = DateTime(2026, 11, 21, 14, 30);
        final payment = PaymentEntry(
          paymentId: 'pay_xyz_100',
          studentUid: 'student_alice_01',
          orgId: 'org_apex_100',
          billingMonth: '2026-11',
          amount: 2500.0,
          paidAt: now,
          method: 'upi',
          recordedBy: 'Institute Owner',
          receiptRef: 'TXN-987654321',
          note: 'First installment',
          createdAt: now,
        );

        final json = payment.toJson();
        expect(json['payment_id'], 'pay_xyz_100');
        expect(json['student_uid'], 'student_alice_01');
        expect(json['org_id'], 'org_apex_100');
        expect(json['billing_month'], '2026-11');
        expect(json['amount'], 2500.0);
        expect(json['method'], 'upi');
        expect(json['recorded_by'], 'Institute Owner');
        expect(json['receipt_ref'], 'TXN-987654321');
        expect(json['reference_number'], 'TXN-987654321');

        final fromJson = PaymentEntry.fromJson(json, docId: 'pay_xyz_100');
        expect(fromJson.paymentId, 'pay_xyz_100');
        expect(fromJson.studentUid, 'student_alice_01');
        expect(fromJson.amount, 2500.0);
        expect(fromJson.method, 'upi');
        expect(fromJson.referenceNumber, 'TXN-987654321');
        expect(fromJson.isReversal, isFalse);
      },
    );

    test('FeeService billing month navigation and human label formatting', () {
      expect(FeeService.monthLabel('2026-11'), 'November 2026');
      expect(FeeService.monthLabel('2026-01'), 'January 2026');
      expect(FeeService.nextMonth('2026-11'), '2026-12');
      expect(FeeService.nextMonth('2026-12'), '2027-01');
      expect(FeeService.prevMonth('2026-01'), '2025-12');
      expect(FeeService.prevMonth('2026-11'), '2026-10');
    });
  });

  group('Step 6: Teacher Salary Models & Historical Protection', () {
    test(
      'TeacherSalaryModel calculates remaining amount and payment statuses',
      () {
        // 1. Pending
        const pending = TeacherSalaryModel(
          id: 'sal_001',
          orgId: 'org_apex_100',
          teacherUid: 'teacher_jane_001',
          teacherName: 'Jane Doe',
          amount: 40000.0,
          amountPaid: 0.0,
          month: '2026-11',
        );
        expect(pending.baseSalary, 40000.0);
        expect(pending.amountPaid, 0.0);
        expect(pending.remainingAmount, 40000.0);
        expect(pending.isPending, isTrue);
        expect(pending.isPaid, isFalse);

        // 2. Partial
        final partial = pending.copyWith(
          amountPaid: 15000.0,
          status: 'partial',
        );
        expect(partial.baseSalary, 40000.0);
        expect(partial.amountPaid, 15000.0);
        expect(partial.remainingAmount, 25000.0);
        expect(partial.isPartial, isTrue);
        expect(partial.isPaid, isFalse);

        // 3. Paid
        final paid = partial.copyWith(amountPaid: 40000.0, status: 'paid');
        expect(paid.remainingAmount, 0.0);
        expect(paid.isPaid, isTrue);
        expect(paid.isPartial, isFalse);
      },
    );

    test('SalaryPaymentEntry serializes and deserializes properly', () {
      final now = DateTime(2026, 11, 21, 15, 0);
      final payment = SalaryPaymentEntry(
        paymentId: 'sal_pay_88',
        salaryRecordId: 'teacher_jane_001_2026-11',
        amount: 20000.0,
        paymentDate: now,
        paymentMethod: 'bank_transfer',
        referenceNumber: 'NEFT-54321987',
        note: 'Mid-month stipend',
        recordedBy: 'Institute Owner',
        createdAt: now,
      );

      final json = payment.toJson();
      expect(json['payment_id'], 'sal_pay_88');
      expect(json['amount'], 20000.0);
      expect(json['payment_method'], 'bank_transfer');
      expect(json['reference_number'], 'NEFT-54321987');
      expect(json['recorded_by'], 'Institute Owner');

      final fromJson = SalaryPaymentEntry.fromJson(json, docId: 'sal_pay_88');
      expect(fromJson.paymentId, 'sal_pay_88');
      expect(fromJson.amount, 20000.0);
      expect(fromJson.paymentMethod, 'bank_transfer');
      expect(fromJson.referenceNumber, 'NEFT-54321987');
    });

    test(
      'Historical Salary Protection: Monthly snapshot preserves past salary amounts',
      () {
        // January record created with base salary 30,000
        const janSalary = TeacherSalaryModel(
          id: 'teacher_1_2026-01',
          orgId: 'org_apex_100',
          teacherUid: 'teacher_1',
          teacherName: 'John',
          amount: 30000.0,
          amountPaid: 30000.0,
          remainingAmount: 0.0,
          month: '2026-01',
          status: 'paid',
        );

        // In March, owner raises default salary to 45,000
        const updatedMarchDefault = 45000.0;
        final marchSalary = TeacherSalaryModel(
          id: 'teacher_1_2026-03',
          orgId: 'org_apex_100',
          teacherUid: 'teacher_1',
          teacherName: 'John',
          amount: updatedMarchDefault,
          amountPaid: 0.0,
          remainingAmount: 45000.0,
          month: '2026-03',
          status: 'pending',
        );

        // Verify January base amount remains strictly 30,000 and is not overwritten
        expect(janSalary.baseSalary, 30000.0);
        expect(janSalary.amountPaid, 30000.0);
        expect(marchSalary.baseSalary, 45000.0);
        expect(janSalary.baseSalary != marchSalary.baseSalary, isTrue);
      },
    );
  });

  group('Step 6: TenantPathResolver - Financial Path Resolution', () {
    test(
      'Resolves student monthly fee paths in Institute Mode and Single Teacher Mode',
      () {
        // Institute Mode
        final orgResolver = TenantPathResolver(
          explicitOrgId: 'org_apex_100',
          explicitIsInstitute: true,
        );

        expect(
          orgResolver.studentFeeMonthsPath('student_123'),
          'organizations/org_apex_100/feeRecords/student_123/months',
        );
        expect(
          orgResolver.studentFeeMonthDocPath('student_123', '2026-11'),
          'organizations/org_apex_100/feeRecords/student_123/months/2026-11',
        );
        expect(
          orgResolver.studentFeePaymentsPath('student_123', '2026-11'),
          'organizations/org_apex_100/feeRecords/student_123/months/2026-11/payments',
        );

        // Single Teacher Mode
        final teacherResolver = TenantPathResolver(explicitIsInstitute: false);

        expect(
          teacherResolver.studentFeeMonthsPath('student_123', 'teacher_bob_42'),
          'user/teacher_bob_42/students/student_123/feeRecords',
        );
        expect(
          teacherResolver.studentFeeMonthDocPath(
            'student_123',
            '2026-11',
            'teacher_bob_42',
          ),
          'user/teacher_bob_42/students/student_123/feeRecords/2026-11',
        );
        expect(
          teacherResolver.studentFeePaymentsPath(
            'student_123',
            '2026-11',
            'teacher_bob_42',
          ),
          'user/teacher_bob_42/students/student_123/feeRecords/2026-11/payments',
        );
      },
    );

    test('Resolves teacher salary paths in organization-scoped structure', () {
      final resolver = TenantPathResolver(
        explicitOrgId: 'org_apex_100',
        explicitIsInstitute: true,
      );

      expect(
        resolver.teacherSalaryMonthsPath('teacher_jane_001'),
        'organizations/org_apex_100/teacherSalaryRecords/teacher_jane_001/months',
      );
      expect(
        resolver.teacherSalaryMonthDocPath('teacher_jane_001', '2026-11'),
        'organizations/org_apex_100/teacherSalaryRecords/teacher_jane_001/months/2026-11',
      );
      expect(
        resolver.teacherSalaryPaymentsPath('teacher_jane_001', '2026-11'),
        'organizations/org_apex_100/teacherSalaryRecords/teacher_jane_001/months/2026-11/payments',
      );
    });
  });

  group('Step 6: OwnerStudentFeesController - Search, Filter, & Totals', () {
    late OwnerStudentFeesController controller;

    setUp(() {
      controller = OwnerStudentFeesController(
        tenantContext: ActiveTenantContext(),
        autoLoad: false,
      );

      final batches = [
        BatchModel(
          id: 'batch_math',
          name: 'Class 12 Mathematics',
          activeJoinCode: 'TN-MATH12',
          teacherId: 'teacher_01',
        ),
        BatchModel(
          id: 'batch_phy',
          name: 'Class 12 Physics',
          activeJoinCode: 'TN-PHYS12',
          teacherId: 'teacher_01',
        ),
      ];

      final items = [
        const StudentFeeItem(
          studentUid: 'stud_1',
          studentName: 'Alice Walker',
          studentEmail: 'alice@apex.edu',
          studentPhone: '+91 9876543210',
          batchNames: ['Class 12 Mathematics'],
          feeRecord: FeeRecord(
            billingMonth: '2026-11',
            studentId: 'stud_1',
            studentName: 'Alice Walker',
            amountDue: 4000.0,
            amountPaid: 4000.0,
          ),
        ),
        const StudentFeeItem(
          studentUid: 'stud_2',
          studentName: 'Bob Miller',
          studentEmail: 'bob@apex.edu',
          studentPhone: '+91 9123456789',
          batchNames: ['Class 12 Physics'],
          feeRecord: FeeRecord(
            billingMonth: '2026-11',
            studentId: 'stud_2',
            studentName: 'Bob Miller',
            amountDue: 4000.0,
            amountPaid: 1500.0,
          ),
        ),
        const StudentFeeItem(
          studentUid: 'stud_3',
          studentName: 'Charlie Green',
          studentEmail: 'charlie@apex.edu',
          batchNames: ['Class 12 Mathematics', 'Class 12 Physics'],
          defaultMonthlyFee: 6000.0,
          feeRecord: null, // Unpaid
        ),
      ];

      controller.setTestData(items: items, batches: batches);
    });

    test('Computes financial summary totals accurately', () {
      expect(controller.allItems.length, 3);
      expect(controller.totalExpectedFees, 14000.0); // 4000 + 4000 + 6000
      expect(controller.totalCollected, 5500.0); // 4000 + 1500 + 0
      expect(controller.outstandingBalance, 8500.0); // 0 + 2500 + 6000
      expect(controller.paidCount, 1);
      expect(controller.partialCount, 1);
      expect(controller.pendingCount, 1);
    });

    test('Filters students by status and batch', () {
      // Status filter
      controller.setStatusFilter('paid');
      expect(controller.filteredItems.length, 1);
      expect(controller.filteredItems.first.studentName, 'Alice Walker');

      controller.setStatusFilter('partial');
      expect(controller.filteredItems.length, 1);
      expect(controller.filteredItems.first.studentName, 'Bob Miller');

      controller.setStatusFilter('pending');
      expect(controller.filteredItems.length, 1);
      expect(controller.filteredItems.first.studentName, 'Charlie Green');

      controller.setStatusFilter('all');
      expect(controller.filteredItems.length, 3);

      // Batch filter
      controller.setBatchId('batch_phy');
      expect(controller.filteredItems.length, 2); // Bob and Charlie
      expect(
        controller.filteredItems.any((s) => s.studentName == 'Alice Walker'),
        isFalse,
      );

      controller.setBatchId('all');
      expect(controller.filteredItems.length, 3);
    });

    test('Searches students by name, email, phone, or batch', () {
      controller.setSearchQuery('miller');
      expect(controller.filteredItems.length, 1);
      expect(controller.filteredItems.first.studentName, 'Bob Miller');

      controller.setSearchQuery('987654');
      expect(controller.filteredItems.length, 1);
      expect(controller.filteredItems.first.studentName, 'Alice Walker');

      controller.setSearchQuery('charlie@apex.edu');
      expect(controller.filteredItems.length, 1);
      expect(controller.filteredItems.first.studentName, 'Charlie Green');

      controller.setSearchQuery('NonExistent');
      expect(controller.filteredItems, isEmpty);
    });
  });

  group(
    'Step 6: OwnerTeacherSalariesController - Search, Filter, & Totals',
    () {
      late OwnerTeacherSalariesController controller;

      setUp(() {
        controller = OwnerTeacherSalariesController(
          tenantContext: ActiveTenantContext(),
          autoLoad: false,
        );

        final items = [
          const TeacherSalaryItem(
            teacherUid: 'teach_1',
            teacherName: 'Dr. Jane Smith',
            teacherEmail: 'jane@apex.edu',
            salaryRecord: TeacherSalaryModel(
              id: 'teach_1_2026-11',
              orgId: 'org_apex',
              teacherUid: 'teach_1',
              teacherName: 'Dr. Jane Smith',
              amount: 50000.0,
              amountPaid: 50000.0,
              remainingAmount: 0.0,
              month: '2026-11',
              status: 'paid',
            ),
          ),
          const TeacherSalaryItem(
            teacherUid: 'teach_2',
            teacherName: 'Prof. Alan Turing',
            teacherEmail: 'alan@apex.edu',
            salaryRecord: TeacherSalaryModel(
              id: 'teach_2_2026-11',
              orgId: 'org_apex',
              teacherUid: 'teach_2',
              teacherName: 'Prof. Alan Turing',
              amount: 60000.0,
              amountPaid: 20000.0,
              remainingAmount: 40000.0,
              month: '2026-11',
              status: 'partial',
            ),
          ),
          const TeacherSalaryItem(
            teacherUid: 'teach_3',
            teacherName: 'Marie Curie',
            teacherEmail: 'marie@apex.edu',
            configuredBaseSalary: 45000.0,
            salaryRecord: null, // Pending disbursal
          ),
        ];

        controller.setTestData(items: items);
      });

      test(
        'Computes teacher salary totals accurately and separately from fees',
        () {
          expect(controller.allItems.length, 3);
          expect(controller.totalObligation, 155000.0); // 50k + 60k + 45k
          expect(controller.totalPaid, 70000.0); // 50k + 20k + 0
          expect(controller.totalPending, 85000.0); // 0 + 40k + 45k
          expect(controller.paidCount, 1);
          expect(controller.partialCount, 1);
          expect(controller.pendingCount, 1);
        },
      );

      test('Filters teachers by payment status', () {
        controller.setStatusFilter('paid');
        expect(controller.filteredItems.length, 1);
        expect(controller.filteredItems.first.teacherName, 'Dr. Jane Smith');

        controller.setStatusFilter('partial');
        expect(controller.filteredItems.length, 1);
        expect(controller.filteredItems.first.teacherName, 'Prof. Alan Turing');

        controller.setStatusFilter('pending');
        expect(controller.filteredItems.length, 1);
        expect(controller.filteredItems.first.teacherName, 'Marie Curie');

        controller.setStatusFilter('all');
        expect(controller.filteredItems.length, 3);
      });

      test('Searches teachers by name and email', () {
        controller.setSearchQuery('turing');
        expect(controller.filteredItems.length, 1);
        expect(controller.filteredItems.first.teacherName, 'Prof. Alan Turing');

        controller.setSearchQuery('marie@apex.edu');
        expect(controller.filteredItems.length, 1);
        expect(controller.filteredItems.first.teacherName, 'Marie Curie');

        controller.setSearchQuery('Unknown');
        expect(controller.filteredItems, isEmpty);
      });
    },
  );
}
