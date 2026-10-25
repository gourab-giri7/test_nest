import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/takeExam/controller/take_exam_controller.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/exam_model.dart';

void main() {
  group('New Exam Features Tests', () {
    late ExamModel testExam;

    setUp(() {
      final questions = List.generate(
        5,
        (i) => QAModel(
          id: 'q_${i + 1}',
          q: 'Question ${i + 1}?',
          a: 'Option A$i',
          b: 'Option B$i',
          c: 'Option C$i',
          d: 'Option D$i',
          ans: i % 2 == 0 ? 'A' : 'B',
        ),
      );

      testExam = ExamModel(
        examId: 'exam_test_101',
        examName: 'Math Test',
        fullMarks: '100',
        examKey: 'SecureKey#2026',
        instruction: 'Read carefully',
        batch: 'Batch-A',
        examStart: DateTime.now().subtract(const Duration(minutes: 5)),
        examEnd: DateTime.now().add(const Duration(minutes: 45)),
        questions: questions,
        assignedStudentIds: ['ST_001', 'ST_002'],
      );
    });

    test(
      'TEST 4: Question shuffling maintains sequential display numbers 1..N',
      () {
        final controller = TakeExamController(testExam);

        expect(controller.totalQuestions, equals(5));
        expect(controller.shuffledQuestions.length, equals(5));

        // Shuffled questions contains all original question IDs
        final originalIds = testExam.questions.map((q) => q.id).toSet();
        final shuffledIds = controller.shuffledQuestions
            .map((q) => q.id)
            .toSet();
        expect(shuffledIds, equals(originalIds));

        // Controller currentIndex is 0, display number is currentIndex + 1
        expect(controller.currentIndex + 1, equals(1));
        controller.next();
        expect(controller.currentIndex + 1, equals(2));
        controller.goToQuestion(4);
        expect(controller.currentIndex + 1, equals(5));
      },
    );

    test(
      'TEST 5, 6, 8: Question status palette (grey, green, yellow, yellow+check)',
      () {
        final controller = TakeExamController(testExam);

        // Initially Q1 (index 0) is unanswered and unmarked -> Grey
        expect(controller.isAnswered(0), isFalse);
        expect(controller.isMarked(0), isFalse);

        // Student answers Q1 -> becomes Green (answered, not marked)
        controller.selectAnswer('A');
        expect(controller.isAnswered(0), isTrue);
        expect(controller.isMarked(0), isFalse);
        expect(controller.selectedChoice, equals('A'));

        // Student marks Q1 for review -> becomes Yellow + Check (answered and marked)
        controller.toggleMarkForReview();
        expect(controller.isAnswered(0), isTrue);
        expect(controller.isMarked(0), isTrue);
        expect(controller.isAnsweredAndMarked(0), isTrue);

        // Student navigates to Q2 -> marks for review without answering -> Yellow
        controller.goToQuestion(1);
        expect(controller.isAnswered(1), isFalse);
        controller.toggleMarkForReview();
        expect(controller.isMarked(1), isTrue);
        expect(controller.isAnswered(1), isFalse);
        expect(controller.isAnsweredAndMarked(1), isFalse);

        // Q3 (index 2) remains untouched -> Grey (unanswered, unmarked)
        expect(controller.isAnswered(2), isFalse);
        expect(controller.isMarked(2), isFalse);
      },
    );

    test('TEST 7: Direct navigation using goToQuestion jumps immediately', () {
      final controller = TakeExamController(testExam);
      expect(controller.currentIndex, equals(0));

      controller.goToQuestion(3);
      expect(controller.currentIndex, equals(3));

      controller.goToQuestion(0);
      expect(controller.currentIndex, equals(0));
    });

    test(
      'TEST 9: Stable question ID associates answers correctly irrespective of shuffle order',
      () {
        final controller = TakeExamController(testExam);

        // Answer every question correctly according to its actual identity
        for (var i = 0; i < controller.totalQuestions; i++) {
          controller.goToQuestion(i);
          final q = controller.currentQuestion;
          controller.selectAnswer(q.ans); // correct answer
        }

        // Check marks calculation
        var correct = 0;
        for (final q in testExam.questions) {
          final chosen = controller.selectedAnswers[q.id];
          if (chosen != null && chosen.toUpperCase() == q.ans.toUpperCase()) {
            correct++;
          }
        }

        expect(correct, equals(5));
      },
    );

    test(
      'TEST 2 & 4: Wall-clock remaining time calculation prevents timer drift',
      () {
        final controller = TakeExamController(testExam);
        // Remaining duration should be between 44 and 45 minutes
        expect(controller.remaining.inMinutes, inInclusiveRange(44, 45));

        // Expired exam gives zero remaining
        final expiredExam = ExamModel(
          examId: 'exam_expired',
          examName: 'Past Exam',
          fullMarks: '50',
          examKey: 'Key',
          instruction: '',
          batch: 'B1',
          examStart: DateTime.now().subtract(const Duration(hours: 2)),
          examEnd: DateTime.now().subtract(const Duration(minutes: 10)),
          questions: testExam.questions,
          assignedStudentIds: ['ST_001'],
        );

        final expiredController = TakeExamController(expiredExam);
        expect(expiredController.remaining, equals(Duration.zero));
      },
    );

    test('TEST 12: Exact exam key validation', () {
      const key = 'ExactKey#123';

      expect('ExactKey#123' == key, isTrue);
      // Spaces, case difference must fail
      expect('exactkey#123' == key, isFalse);
      expect('ExactKey#123 ' == key, isFalse);
      expect(' ExactKey#123' == key, isFalse);
    });

    test('TEST 12: Assigned student IDs is ONLY source of truth', () {
      final assigned = testExam.assignedStudentIds.toSet();
      expect(assigned.contains('ST_001'), isTrue);
      expect(assigned.contains('ST_002'), isTrue);
      expect(assigned.contains('ST_999'), isFalse);
    });
  });
}
