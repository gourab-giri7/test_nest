import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/dashboard/controller/student_workspace_controller.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/notice_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 5: Student Portal - Navigation & Tab Switching', () {
    test('Tab switching works smoothly across all 5 navigation tabs', () {
      final controller = StudentWorkspaceController(autoListen: false);

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
  });

  group('Step 5: Student Portal - Filter and Search Queries', () {
    late StudentWorkspaceController controller;

    setUp(() {
      controller = StudentWorkspaceController(autoListen: false);

      final now = DateTime.now();

      final exams = [
        ExamModel(
          examId: 'exam_phy_101',
          examName: 'Physics Term 1 Final',
          fullMarks: '100',
          examKey: 'PHYS101',
          instruction: 'No calculators',
          batch: 'Batch Alpha Physics',
          examStart: now.subtract(const Duration(hours: 1)),
          examEnd: now.add(const Duration(hours: 2)),
          questions: const [],
          subject: 'Physics',
        ),
        ExamModel(
          examId: 'exam_chem_201',
          examName: 'Chemistry Periodic Trends',
          fullMarks: '50',
          examKey: 'CHEM201',
          instruction: 'Open book',
          batch: 'Batch Beta Chemistry',
          examStart: now.add(const Duration(days: 2)),
          examEnd: now.add(const Duration(days: 2, hours: 2)),
          questions: const [],
          subject: 'Chemistry',
        ),
        ExamModel(
          examId: 'exam_math_301',
          examName: 'Calculus Integration',
          fullMarks: '80',
          examKey: 'MATH301',
          instruction: 'Show steps',
          batch: 'Batch Alpha Physics',
          examStart: now.subtract(const Duration(days: 3)),
          examEnd: now.subtract(const Duration(days: 3, hours: -2)),
          questions: const [],
          subject: 'Mathematics',
        ),
      ];

      final results = [
        const StudentSubmissionResultItem(
          examId: 'exam_phy_101',
          examName: 'Physics Term 1 Final',
          batch: 'Batch Alpha Physics',
          subject: 'Physics',
          obtainedMarks: 88.0,
          totalMarks: 100.0,
          percentage: 88.0,
          status: 'Graded',
          submissionData: {'answers': {}},
        ),
        const StudentSubmissionResultItem(
          examId: 'exam_bio_102',
          examName: 'Biology Genetics Quiz',
          batch: 'Batch Gamma Biology',
          subject: 'Biology',
          obtainedMarks: 45.0,
          totalMarks: 50.0,
          percentage: 90.0,
          status: 'Published',
          submissionData: {'answers': {}},
        ),
      ];

      final notices = [
        NoticeModel(
          id: 'notice_fee_01',
          title: 'Monthly Tuition Fee Reminder',
          body: 'Tuition fees for November are due by the 10th.',
          category: NoticeCategory.fee,
          status: NoticeStatus.published,
          createdBy: 'owner_01',
          updatedBy: 'owner_01',
          createdAt: now,
          updatedAt: now,
        ),
        NoticeModel(
          id: 'notice_holiday_02',
          title: 'Institute Winter Break',
          body: 'Classes will be suspended during the winter holidays.',
          category: NoticeCategory.holiday,
          status: NoticeStatus.published,
          createdBy: 'owner_01',
          updatedBy: 'owner_01',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      controller.setTestData(exams: exams, results: results, notices: notices);
    });

    test('Exam status and text search filtering works properly', () {
      expect(controller.exams.length, 3);
      expect(controller.filteredExams.length, 3);

      // Status filter
      controller.setExamFilter('active');
      expect(controller.filteredExams.length, 1);
      expect(controller.filteredExams.first.examId, 'exam_phy_101');

      controller.setExamFilter('upcoming');
      expect(controller.filteredExams.length, 1);
      expect(controller.filteredExams.first.examId, 'exam_chem_201');

      controller.setExamFilter('all');
      expect(controller.filteredExams.length, 3);

      // Search query filter
      controller.setExamSearchQuery('calculus');
      expect(controller.filteredExams.length, 1);
      expect(controller.filteredExams.first.examId, 'exam_math_301');

      controller.setExamSearchQuery('alpha');
      expect(controller.filteredExams.length, 2);

      controller.setExamSearchQuery('nonexistent');
      expect(controller.filteredExams, isEmpty);
    });

    test('Result search filtering works across name, batch, and subject', () {
      expect(controller.results.length, 2);
      expect(controller.filteredResults.length, 2);

      controller.setResultSearchQuery('Genetics');
      expect(controller.filteredResults.length, 1);
      expect(controller.filteredResults.first.subject, 'Biology');

      controller.setResultSearchQuery('alpha');
      expect(controller.filteredResults.length, 1);
      expect(controller.filteredResults.first.examName, 'Physics Term 1 Final');

      controller.setResultSearchQuery('unknown');
      expect(controller.filteredResults, isEmpty);
    });

    test('Notice search filtering works across title and body', () {
      expect(controller.notices.length, 2);
      expect(controller.filteredNotices.length, 2);

      controller.setNoticeSearchQuery('winter');
      expect(controller.filteredNotices.length, 1);
      expect(controller.filteredNotices.first.id, 'notice_holiday_02');

      controller.setNoticeSearchQuery('Tuition fees');
      expect(controller.filteredNotices.length, 1);
      expect(controller.filteredNotices.first.id, 'notice_fee_01');

      controller.setNoticeSearchQuery('xyz999');
      expect(controller.filteredNotices, isEmpty);
    });
  });

  group('Step 5: Student Portal - Attendance & Financial Calculations', () {
    test('Attendance percentage calculates correctly with mixed records', () {
      final controller = StudentWorkspaceController(autoListen: false);

      controller.setTestData(
        attendanceRecords: [
          {'status': 'present', 'date': '2026-11-01'},
          {'status': 'present', 'date': '2026-11-02'},
          {'status': 'absent', 'date': '2026-11-03'},
          {'status': 'late', 'date': '2026-11-04'},
        ],
      );

      expect(controller.attendanceTotalCount, 4);
      expect(controller.attendancePresentCount, 2);
      expect(controller.attendanceAbsentCount, 1);
      expect(controller.attendanceLateCount, 1);
      expect(controller.attendancePercentage, 50.0);
    });

    test(
      'Attendance percentage handles zero records cleanly without division by zero',
      () {
        final controller = StudentWorkspaceController(autoListen: false);

        controller.setTestData(attendanceRecords: []);

        expect(controller.attendanceTotalCount, 0);
        expect(controller.attendancePresentCount, 0);
        expect(controller.attendancePercentage, 0.0);
      },
    );

    test('Fee balance calculation accurately reflects outstanding dues', () {
      final controller = StudentWorkspaceController(autoListen: false);

      const fee = FeeRecord(
        billingMonth: '2026-11',
        studentId: 'student_123',
        studentName: 'Alex Doe',
        amountDue: 5000.0,
        amountPaid: 3500.0,
      );

      controller.setTestData(feeRecord: fee);

      expect(controller.feeRecord?.amountDue, 5000.0);
      expect(controller.feeRecord?.amountPaid, 3500.0);
      expect(controller.outstandingFeeAmount, 1500.0);
      expect(controller.feeRecord?.balance, 1500.0);
      expect(controller.feeRecord?.status, 'partial');
    });
  });

  group('Step 5: Student Portal - Submission Result Item Model', () {
    test('StudentSubmissionResultItem holds required and optional data', () {
      const item = StudentSubmissionResultItem(
        examId: 'exam_404',
        examName: 'Chemistry Midterm',
        batch: 'Grade 11 Chemistry',
        subject: 'Chemistry',
        obtainedMarks: 72.5,
        totalMarks: 75.0,
        percentage: 96.67,
        status: 'Reviewed',
        submissionData: {'score': 72.5, 'evaluated': true},
      );

      expect(item.examId, 'exam_404');
      expect(item.examName, 'Chemistry Midterm');
      expect(item.obtainedMarks, 72.5);
      expect(item.totalMarks, 75.0);
      expect(item.percentage, 96.67);
      expect(item.status, 'Reviewed');
      expect(item.submissionData['evaluated'], isTrue);
    });
  });

  group('Step 5: TenantPathResolver - Fee Paths Resolution', () {
    test('Resolves fee paths correctly for Coaching Institute mode', () {
      final resolver = TenantPathResolver(
        explicitOrgId: 'org_apex_100',
        explicitIsInstitute: true,
      );

      expect(
        resolver.feeRecordsPath(),
        'organizations/org_apex_100/feeRecords',
      );
      expect(
        resolver.feeRecordDocPath('rec_nov_2026'),
        'organizations/org_apex_100/feeRecords/rec_nov_2026',
      );
    });

    test('Resolves fee paths correctly for Single Teacher mode fallback', () {
      final resolver = TenantPathResolver(
        explicitIsInstitute: false,
      );

      expect(
        resolver.feeRecordsPath('teacher_smith_42'),
        'user/teacher_smith_42/feeRecords',
      );
      expect(
        resolver.feeRecordDocPath('rec_nov_2026', 'teacher_smith_42'),
        'user/teacher_smith_42/feeRecords/rec_nov_2026',
      );
    });
  });

  group('Step 5: Student Architecture - Direct Institute Membership', () {
    test(
      'StudentData with orgId is active without requiring teacher enrollments',
      () {
        final student = StudentData(
          id: 'student_indep_01',
          name: 'Independent Student',
          orgId: 'org_apex_100',
          orgName: 'Apex Coaching Institute',
          enrollments: const [], // No teacher-specific enrollments
        );

        expect(student.hasActiveEnrollment, isTrue);
        expect(student.orgId, 'org_apex_100');
        expect(student.orgName, 'Apex Coaching Institute');
        expect(student.enrollments, isEmpty);
      },
    );
  });
}
