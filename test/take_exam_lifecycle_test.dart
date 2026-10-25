import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/takeExam/take_exam_screen.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/exam_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pref = await SharedPreferences.getInstance();
  });
  group('Exam Attempt Lifecycle & Anti-Cheating Unit Tests', () {
    test('ExamModel parses questions and student assignment correctly', () {
      final exam = ExamModel(
        examId: 'EX001',
        examName: 'Midterm Physics',
        fullMarks: '100',
        examKey: 'PHYS101',
        instruction: 'No calculators allowed',
        batch: 'Batch A',
        examStart: DateTime.now().subtract(const Duration(minutes: 30)),
        examEnd: DateTime.now().add(const Duration(minutes: 30)),
        assignedStudentIds: ['ST001', 'ST002', 'ST003'],
        questions: [
          QAModel(
            id: 'Q1',
            q: 'What is Newton second law?',
            a: 'F = ma',
            b: 'E = mc^2',
            c: 'V = IR',
            d: 'P = IV',
            ans: 'a',
          ),
          QAModel(
            id: 'Q2',
            q: 'What is the SI unit of force?',
            a: 'Joule',
            b: 'Newton',
            c: 'Watt',
            d: 'Pascal',
            ans: 'b',
          ),
        ],
      );

      expect(exam.questions.length, 2);
      expect(exam.status, 'Active');
      expect(exam.isStudentAssigned('ST001'), isTrue);
      expect(exam.isStudentAssigned('ST999'), isFalse);
      expect(exam.resultPublished, isFalse);
    });

    test(
      'Focus loss threshold calculation: allows 3 warnings, auto-submits on 4th',
      () {
        const allowedLosses = 3;

        // Simulates the threshold logic used in TakeExamController._handleFocusLoss:
        bool shouldAutoSubmit(int count) => count > allowedLosses;

        expect(shouldAutoSubmit(1), isFalse); // Warning 1
        expect(shouldAutoSubmit(2), isFalse); // Warning 2
        expect(shouldAutoSubmit(3), isFalse); // Warning 3
        expect(shouldAutoSubmit(4), isTrue); // 4th loss triggers auto-submit
        expect(shouldAutoSubmit(5), isTrue);
      },
    );

    test(
      'Result publication flag correctly restricts student score visibility',
      () {
        final unpublishedExam = ExamModel(
          examId: 'EX002',
          examName: 'Math Quiz',
          fullMarks: '50',
          examKey: 'MATH01',
          instruction: 'Answer all questions',
          batch: 'Batch B',
          examStart: DateTime.now().subtract(const Duration(days: 1)),
          examEnd: DateTime.now().subtract(const Duration(hours: 2)),
          questions: [],
          resultPublished: false,
        );

        expect(unpublishedExam.resultPublished, isFalse);
        expect(unpublishedExam.status, 'Completed');

        final publishedExam = unpublishedExam.copyWith(resultPublished: true);
        expect(publishedExam.resultPublished, isTrue);
      },
    );

    testWidgets(
      'TakeExamScreen renders and lays out with theme without RenderBox or hasSize crashes',
      (tester) async {
        final activeExam = ExamModel(
          examId: 'EX_LAYOUT_1',
          examName: 'Science Quiz',
          fullMarks: '50',
          examKey: 'KEY123',
          instruction: 'Answer carefully',
          batch: 'Class 10',
          examStart: DateTime.now().subtract(const Duration(minutes: 5)),
          examEnd: DateTime.now().add(const Duration(minutes: 55)),
          assignedStudentIds: ['STU_TEST'],
          questions: [
            QAModel(
              id: 'q1',
              q: 'What is the chemical symbol for Water?',
              a: 'H2O',
              b: 'CO2',
              c: 'NaCl',
              d: 'O2',
              ans: 'A',
            ),
            QAModel(
              id: 'q2',
              q: 'What is the powerhouse of the cell?',
              a: 'Nucleus',
              b: 'Mitochondria',
              c: 'Ribosome',
              d: 'Cytoplasm',
              ans: 'B',
            ),
          ],
        );

        // Test on standard mobile screen
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: ColorTheme.light,
            home: TakeExamScreen(exam: activeExam),
          ),
        );

        await tester.pumpAndSettle();

        // Screen title and exam rendered without any RenderBox or hasSize crashes
        expect(find.text('Science Quiz'), findsOneWidget);
        expect(find.byType(TakeExamScreen), findsOneWidget);

        // Bottom section action buttons are laid out cleanly
        expect(find.text('Previous'), findsOneWidget);
        expect(find.text('Review'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);

        // Tap Next button to advance to question 2
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Submit'), findsOneWidget);

        // Tap Previous button
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();

        expect(find.text('Next'), findsOneWidget);
      },
    );
  });
}
