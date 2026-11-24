import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:test_nest/feature/domain/organization/presentation/screens/owner_student_profile_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/studentDetails/model/student_exam_submission_summary.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/organization_model.dart';

void main() {
  group('OwnerStudentProfileScreen & Exam Details Unit & Widget Tests', () {
    final sampleStudent = OrganizationMemberModel(
      uid: 'student_uid_101',
      name: 'Rahim Khan',
      email: 'rahim@testnest.com',
      phone: '+919876543210',
      role: 'student',
      status: 'active',
      joinedAt: DateTime(2025, 8, 15),
      assignedBatchIds: ['batch_1', 'batch_2'],
    );

    final sampleExamModel = ExamModel(
      examId: 'exam_phy_101',
      examKey: 'phy_101_key',
      examName: 'Physics Midterm Exam',
      instruction: 'Answer all questions carefully.',
      batch: 'Batch A',
      fullMarks: '100',
      examStart: DateTime(2026, 11, 20, 10, 0),
      examEnd: DateTime(2026, 11, 20, 11, 30),
      questions: [
        QAModel(
          id: 'q1',
          q: 'What is the SI unit of Force?',
          a: 'Newton',
          b: 'Joule',
          c: 'Watt',
          d: 'Pascal',
          ans: 'A',
          subject: 'Physics',
        ),
        QAModel(
          id: 'q2',
          q: 'Which of the following is a scalar quantity?',
          a: 'Velocity',
          b: 'Acceleration',
          c: 'Speed',
          d: 'Displacement',
          ans: 'C',
          subject: 'Physics',
        ),
        QAModel(
          id: 'q3',
          q: 'What is the speed of light in vacuum?',
          a: '3 x 10^8 m/s',
          b: '3 x 10^6 m/s',
          c: '3 x 10^10 m/s',
          d: '3 x 10^5 m/s',
          ans: 'A',
          subject: 'Physics',
        ),
      ],
    );

    final sampleSummary = StudentExamSubmissionSummary(
      examId: 'exam_phy_101',
      examName: 'Physics Midterm Exam',
      examDate: '20 Nov 2026',
      startTime: '10:00 AM',
      endTime: '11:30 AM',
      batch: 'Class 10 Physics',
      score: '67',
      fullMarks: '100',
      status: 'Completed',
      submittedAt: DateTime(2026, 11, 20, 11, 15),
      submissionData: {
        'score': '67',
        'answers': {
          'q1': 'A', // Correct
          'q2': 'A', // Incorrect (Student chose A, Correct is C)
          // q3 skipped / unattempted
        },
      },
      examModel: sampleExamModel,
    );

    testWidgets('OwnerStudentProfileScreen renders identity header and 2 tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: OwnerStudentProfileScreen(
            student: sampleStudent,
            orgId: 'org_test_1',
            autoLoad: false,
          ),
        ),
      );
      await tester.pump();

      // Verify header details
      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('Rahim Khan'), findsOneWidget);
      expect(find.text('rahim@testnest.com'), findsOneWidget);
      expect(find.text('+919876543210'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);

      // Verify TabBar with 2 tabs
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.textContaining('Fees History'), findsOneWidget);
      expect(find.textContaining('Exam History'), findsOneWidget);
    });

    testWidgets('OwnerExamResultDetailScreen shows full marks, questions, right/wrong answers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        GetMaterialApp(
          home: OwnerExamResultDetailScreen(
            student: sampleStudent,
            summary: sampleSummary,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Overview banner
      expect(find.text('Physics Midterm Exam'), findsOneWidget);
      expect(find.text('67 / 100 Marks'), findsOneWidget);
      expect(find.textContaining('Student: Rahim Khan'), findsOneWidget);

      // Stat badges
      expect(find.text('Questions'), findsOneWidget);
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Wrong'), findsOneWidget);
      expect(find.text('Skipped'), findsOneWidget);

      // Questions
      expect(find.text('What is the SI unit of Force?'), findsOneWidget);
      expect(find.text('Which of the following is a scalar quantity?'), findsOneWidget);
      expect(find.text('What is the speed of light in vacuum?'), findsOneWidget);

      // Answer states
      expect(find.text('✓ Correct Answer'), findsOneWidget);
      expect(find.text('✗ Incorrect Answer'), findsOneWidget);
      expect(find.text('Skipped / Unattempted'), findsOneWidget);

      // Option badges
      expect(find.text('Student Choice (Correct)'), findsOneWidget);
      expect(find.text('Student Choice (Wrong)'), findsOneWidget);
      expect(find.text('Correct Answer'), findsWidgets);
    });

    test('FeeRecord model calculates paid and balance status correctly', () {
      final paidRecord = FeeRecord(
        billingMonth: '2026-10',
        studentId: 'st_1',
        studentName: 'Rahim',
        amountDue: 800.0,
        amountPaid: 800.0,
      );
      expect(paidRecord.status, 'paid');
      expect(paidRecord.balance, 0.0);

      final pendingRecord = FeeRecord(
        billingMonth: '2026-11',
        studentId: 'st_1',
        studentName: 'Rahim',
        amountDue: 800.0,
        amountPaid: 0.0,
      );
      expect(pendingRecord.status, 'unpaid');
      expect(pendingRecord.balance, 800.0);

      final partialRecord = FeeRecord(
        billingMonth: '2026-09',
        studentId: 'st_1',
        studentName: 'Rahim',
        amountDue: 1000.0,
        amountPaid: 400.0,
      );
      expect(partialRecord.status, 'partial');
      expect(partialRecord.balance, 600.0);
    });
  });
}
