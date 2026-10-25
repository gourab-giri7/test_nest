import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/studentDetails/controller/student_details_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/studentDetails/model/student_exam_submission_summary.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/exam_model.dart';

void main() {
  group('StudentDetailsController & Summary Unit Tests', () {
    late StudentModel testStudent;

    setUp(() {
      testStudent = StudentModel(
        name: 'Rahul Kumar',
        batch: 'Class 12',
        id: 'GO2608001',
        password: 'password123',
        docId: 'doc_123',
      );
    });

    test('Initial password is masked by default and toggles correctly', () {
      final controller = StudentDetailsController(
        student: testStudent,
        teacherId: 'T1001',
      );

      expect(controller.isPasswordVisible, isFalse);
      expect(controller.student.name, 'Rahul Kumar');
      expect(controller.student.id, 'GO2608001');
      expect(controller.student.batch, 'Class 12');

      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible, isTrue);

      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible, isFalse);
    });

    test(
      'StudentExamSubmissionSummary calculates correct, incorrect, unattempted metrics correctly',
      () {
        final exam = ExamModel(
          examId: 'EXM2609011',
          examName: 'Python Basics',
          fullMarks: '20',
          examKey: 'pass',
          instruction: 'None',
          batch: 'Class 12',
          examStart: DateTime(2026, 9, 23, 10, 0),
          examEnd: DateTime(2026, 9, 23, 11, 0),
          questions: [
            QAModel(
              id: 'q1',
              q: 'Q1',
              a: 'A',
              b: 'B',
              c: 'C',
              d: 'D',
              ans: 'B',
            ),
            QAModel(
              id: 'q2',
              q: 'Q2',
              a: 'A',
              b: 'B',
              c: 'C',
              d: 'D',
              ans: 'A',
            ),
            QAModel(
              id: 'q3',
              q: 'Q3',
              a: 'A',
              b: 'B',
              c: 'C',
              d: 'D',
              ans: 'C',
            ),
            QAModel(
              id: 'q4',
              q: 'Q4',
              a: 'A',
              b: 'B',
              c: 'C',
              d: 'D',
              ans: 'D',
            ),
          ],
        );

        final summary = StudentExamSubmissionSummary(
          examId: 'EXM2609011',
          examName: 'Python Basics',
          examDate: '23 Sep 2026',
          startTime: '10:00 AM',
          endTime: '11:00 AM',
          batch: 'Class 12',
          score: '15',
          fullMarks: '20',
          status: 'Completed',
          submittedAt: DateTime(2026, 9, 23, 10, 45),
          submissionData: {
            'correct_count': 3,
            'attempted': 3,
            'answers': {'q1': 'B', 'q2': 'A', 'q3': 'C'},
          },
          examModel: exam,
        );

        expect(summary.totalQuestions, 4);
        expect(summary.correctCount, 3);
        expect(summary.attemptedCount, 3);
        expect(summary.incorrectCount, 0);
        expect(summary.unattemptedCount, 1);
      },
    );

    test(
      'StudentExamSubmissionSummary works in lightweight mode without ExamModel',
      () {
        final summary = StudentExamSubmissionSummary(
          examId: 'EXM2609012',
          examName: 'Lightweight Quiz',
          examDate: '24 Sep 2026',
          startTime: '02:00 PM',
          endTime: '03:00 PM',
          batch: 'Class 12',
          score: '18',
          fullMarks: '20',
          status: 'Completed',
          submittedAt: DateTime(2026, 9, 24, 14, 30),
          submissionData: {
            'correct_count': 9,
            'attempted': 10,
            'total_questions': 10,
            'answers': {'q1': 'A', 'q2': 'B'},
          },
          examModel: null,
          totalQuestionsOverride: 10,
        );

        expect(summary.examModel, isNull);
        expect(summary.totalQuestions, 10);
        expect(summary.correctCount, 9);
        expect(summary.attemptedCount, 10);
        expect(summary.incorrectCount, 1);
        expect(summary.unattemptedCount, 0);
      },
    );

    test(
      'StudentDetailsController initial lifecycle state hasLoaded is false',
      () {
        final controller = StudentDetailsController(
          student: testStudent,
          teacherId: 'T1001',
        );

        expect(controller.hasLoaded, isFalse);
        expect(controller.isLoadingExams, isFalse);
        expect(controller.examHistory, isEmpty);
        expect(controller.examError, isNull);
      },
    );

    test(
      'StudentModel copyWith maintains immutability and updates requested fields',
      () {
        final updated = testStudent.copyWith(
          name: 'Rahul Sharma',
          batch: 'Class 11',
        );

        expect(updated.name, 'Rahul Sharma');
        expect(updated.batch, 'Class 11');
        expect(updated.id, 'GO2608001');
        expect(updated.password, 'password123');
        expect(updated.docId, 'doc_123');
      },
    );
  });
}
