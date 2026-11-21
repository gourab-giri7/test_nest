import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/performance_analytics_service.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/performance_analytics_controller.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/performance_model.dart';

void main() {
  group('Phase 5 — Performance Intelligence Unit Tests', () {
    test('Average percentage calculation & subject grouping', () {
      final records = [
        PerformanceRecord(
          examId: 'e1',
          examName: 'Physics Midterm',
          batch: 'Batch A',
          subject: 'Physics',
          studentId: 's1',
          studentName: 'Alice',
          score: 80.0,
          fullMarks: 100.0,
          percentage: 80.0,
          totalQuestions: 10,
          attemptedCount: 10,
          correctCount: 8,
          incorrectCount: 2,
          unattemptedCount: 0,
          status: 'submitted',
        ),
        PerformanceRecord(
          examId: 'e2',
          examName: 'Physics Final',
          batch: 'Batch A',
          subject: 'Physics',
          studentId: 's1',
          studentName: 'Alice',
          score: 90.0,
          fullMarks: 100.0,
          percentage: 90.0,
          totalQuestions: 10,
          attemptedCount: 10,
          correctCount: 9,
          incorrectCount: 1,
          unattemptedCount: 0,
          status: 'graded',
        ),
        PerformanceRecord(
          examId: 'e3',
          examName: 'Chemistry Quiz 1',
          batch: 'Batch A',
          subject: 'Chemistry',
          studentId: 's1',
          studentName: 'Alice',
          score: 45.0,
          fullMarks: 50.0,
          percentage: 90.0,
          totalQuestions: 10,
          attemptedCount: 10,
          correctCount: 9,
          incorrectCount: 1,
          unattemptedCount: 0,
          status: 'submitted',
        ),
      ];

      final results = PerformanceAnalyticsService.calculateSubjectPerformance(
        records,
      );
      expect(results.length, equals(2));

      final chemistry = results.firstWhere((s) => s.subjectName == 'Chemistry');
      expect(chemistry.totalExams, equals(1));
      expect(chemistry.averagePercentage, equals(90.0));
      expect(chemistry.highestScore, equals(45.0));
      expect(chemistry.lowestScore, equals(45.0));

      final physics = results.firstWhere((s) => s.subjectName == 'Physics');
      expect(physics.totalExams, equals(2));
      expect(physics.averagePercentage, equals(85.0)); // (80 + 90) / 2
      expect(physics.highestScore, equals(90.0));
      expect(physics.lowestScore, equals(80.0));
    });

    test(
      'Incomplete and ungraded submissions are excluded from calculations',
      () {
        final records = [
          PerformanceRecord(
            examId: 'e1',
            examName: 'Math Valid',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's1',
            studentName: 'Alice',
            score: 70.0,
            fullMarks: 100.0,
            percentage: 70.0,
            totalQuestions: 10,
            attemptedCount: 10,
            correctCount: 7,
            incorrectCount: 3,
            unattemptedCount: 0,
            status: 'submitted',
          ),
          PerformanceRecord(
            examId: 'e2',
            examName: 'Math Incomplete',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's1',
            studentName: 'Alice',
            score: 0.0,
            fullMarks: 100.0,
            percentage: 0.0,
            totalQuestions: 10,
            attemptedCount: 0,
            correctCount: 0,
            incorrectCount: 0,
            unattemptedCount: 10,
            status: 'in_progress', // Should be excluded
          ),
          PerformanceRecord(
            examId: 'e3',
            examName: 'Math Zero Marks',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's1',
            studentName: 'Alice',
            score: 0.0,
            fullMarks: 0.0, // Invalid max marks
            percentage: 0.0,
            totalQuestions: 5,
            attemptedCount: 5,
            correctCount: 0,
            incorrectCount: 5,
            unattemptedCount: 0,
            status: 'submitted',
          ),
        ];

        final results = PerformanceAnalyticsService.calculateSubjectPerformance(
          records,
        );
        expect(results.length, equals(1));
        final math = results.first;
        expect(math.totalExams, equals(1)); // Only the valid one counted
        expect(math.averagePercentage, equals(70.0));
      },
    );

    test('Chapter accuracy calculation & missing metadata handling', () {
      final records = [
        PerformanceRecord(
          examId: 'e1',
          examName: 'Physics Waves',
          batch: 'Batch A',
          subject: 'Physics',
          studentId: 's1',
          studentName: 'Alice',
          score: 16.0,
          fullMarks: 20.0,
          percentage: 80.0,
          totalQuestions: 3,
          attemptedCount: 2,
          correctCount: 2,
          incorrectCount: 0,
          unattemptedCount: 1,
          status: 'submitted',
          answers: {
            'q1': 'A',
            'q2': 'B',
            // q3 unattempted
          },
        ),
      ];

      final questions = {
        'e1': [
          QAModel(
            id: 'q1',
            q: 'Q1',
            a: 'A',
            b: 'B',
            c: 'C',
            d: 'D',
            ans: 'A',
            subject: 'Physics',
            chapter: 'Sound',
          ),
          QAModel(
            id: 'q2',
            q: 'Q2',
            a: 'A',
            b: 'B',
            c: 'C',
            d: 'D',
            ans: 'B',
            subject: 'Physics',
            chapter: 'Sound',
          ),
          QAModel(
            id: 'q3',
            q: 'Q3',
            a: 'A',
            b: 'B',
            c: 'C',
            d: 'D',
            ans: 'C',
            subject: 'Physics',
            chapter: 'Light',
          ),
        ],
      };

      final chapters = PerformanceAnalyticsService.calculateChapterPerformance(
        records,
        questions,
      );
      expect(chapters.length, equals(2));

      final sound = chapters.firstWhere((c) => c.chapterName == 'Sound');
      expect(sound.isMetadataAvailable, isTrue);
      expect(sound.attemptedCount, equals(2));
      expect(sound.correctCount, equals(2));
      expect(sound.accuracyPercentage, equals(100.0));

      final light = chapters.firstWhere((c) => c.chapterName == 'Light');
      expect(light.attemptedCount, equals(0));
      expect(light.unansweredCount, equals(1));
      expect(light.accuracyPercentage, equals(0.0));
    });

    test(
      'Missing chapter metadata reports unavailable state without inventing chapters',
      () {
        final records = [
          PerformanceRecord(
            examId: 'e1',
            examName: 'Legacy Exam',
            batch: 'Batch A',
            subject: 'General',
            studentId: 's1',
            studentName: 'Alice',
            score: 10.0,
            fullMarks: 10.0,
            percentage: 100.0,
            totalQuestions: 1,
            attemptedCount: 1,
            correctCount: 1,
            incorrectCount: 0,
            unattemptedCount: 0,
            status: 'submitted',
            answers: {'q1': 'A'},
          ),
        ];

        // Question without chapter or subject
        final questions = {
          'e1': [
            QAModel(
              id: 'q1',
              q: 'Q1',
              a: 'A',
              b: 'B',
              c: 'C',
              d: 'D',
              ans: 'A',
            ),
          ],
        };

        final chapters =
            PerformanceAnalyticsService.calculateChapterPerformance(
              records,
              questions,
            );
        expect(chapters.length, equals(1));
        expect(chapters.first.isMetadataAvailable, isFalse);
        expect(chapters.first.chapterName, equals('Uncategorized'));
      },
    );

    test(
      'Exam-to-exam comparison handles differing max marks using normalized percentages',
      () {
        final records = [
          PerformanceRecord(
            examId: 'e1',
            examName: 'Quiz 1',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's1',
            studentName: 'Alice',
            score: 20.0,
            fullMarks: 25.0, // 80%
            percentage: 80.0,
            totalQuestions: 5,
            attemptedCount: 5,
            correctCount: 4,
            incorrectCount: 1,
            unattemptedCount: 0,
            submittedAt: DateTime(2026, 11, 1),
            status: 'submitted',
          ),
          PerformanceRecord(
            examId: 'e2',
            examName: 'Midterm',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's1',
            studentName: 'Alice',
            score: 85.0,
            fullMarks: 100.0, // 85%
            percentage: 85.0,
            totalQuestions: 20,
            attemptedCount: 20,
            correctCount: 17,
            incorrectCount: 3,
            unattemptedCount: 0,
            submittedAt: DateTime(2026, 11, 15),
            status: 'submitted',
          ),
        ];

        final comparison = PerformanceAnalyticsService.calculateExamComparison(
          records,
          ['e1', 'e2'],
        );
        expect(comparison.length, equals(2));

        final first = comparison[0];
        expect(first.examName, equals('Quiz 1'));
        expect(first.percentage, equals(80.0));
        expect(first.percentageDiffFromPrevious, isNull);

        final second = comparison[1];
        expect(second.examName, equals('Midterm'));
        expect(second.percentage, equals(85.0));
        expect(second.percentageDiffFromPrevious, equals(5.0)); // +5%
        expect(second.note, isNotNull); // Notes max marks difference
      },
    );

    test(
      'Retake deduplication keeps latest attempt without distorting totals',
      () {
        final records = [
          // Attempt 1
          PerformanceRecord(
            examId: 'e1',
            examName: 'Quiz 1',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's1',
            studentName: 'Alice',
            score: 10.0,
            fullMarks: 20.0,
            percentage: 50.0,
            totalQuestions: 5,
            attemptedCount: 5,
            correctCount: 2,
            incorrectCount: 3,
            unattemptedCount: 0,
            attemptNumber: 1,
            submittedAt: DateTime(2026, 11, 1, 10, 0),
            status: 'submitted',
          ),
          // Retake Attempt 2
          PerformanceRecord(
            examId: 'e1',
            examName: 'Quiz 1',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's1',
            studentName: 'Alice',
            score: 18.0,
            fullMarks: 20.0,
            percentage: 90.0,
            totalQuestions: 5,
            attemptedCount: 5,
            correctCount: 4,
            incorrectCount: 1,
            unattemptedCount: 0,
            attemptNumber: 2,
            submittedAt: DateTime(2026, 11, 2, 10, 0),
            status: 'submitted',
          ),
        ];

        final leaderboard =
            PerformanceAnalyticsService.calculateBatchLeaderboard(records);
        expect(leaderboard.length, equals(1));
        final entry = leaderboard.first;
        expect(entry.totalExamsAttempted, equals(1)); // Only 1 unique exam
        expect(
          entry.averagePercentage,
          equals(90.0),
        ); // Retake replaced attempt 1
      },
    );

    test(
      'Batch Leaderboard sorts and assigns Standard Competition Ranking (1224)',
      () {
        final records = [
          PerformanceRecord(
            examId: 'e1',
            examName: 'Quiz 1',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's1',
            studentName: 'Alice (Top)',
            score: 95.0,
            fullMarks: 100.0,
            percentage: 95.0,
            totalQuestions: 10,
            attemptedCount: 10,
            correctCount: 9,
            incorrectCount: 1,
            unattemptedCount: 0,
            status: 'submitted',
          ),
          PerformanceRecord(
            examId: 'e1',
            examName: 'Quiz 1',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's2',
            studentName: 'Bob (Tied)',
            score: 80.0,
            fullMarks: 100.0,
            percentage: 80.0,
            totalQuestions: 10,
            attemptedCount: 10,
            correctCount: 8,
            incorrectCount: 2,
            unattemptedCount: 0,
            status: 'submitted',
          ),
          PerformanceRecord(
            examId: 'e1',
            examName: 'Quiz 1',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's3',
            studentName: 'Charlie (Tied)',
            score: 80.0,
            fullMarks: 100.0,
            percentage: 80.0,
            totalQuestions: 10,
            attemptedCount: 10,
            correctCount: 8,
            incorrectCount: 2,
            unattemptedCount: 0,
            status: 'submitted',
          ),
          PerformanceRecord(
            examId: 'e1',
            examName: 'Quiz 1',
            batch: 'Batch A',
            subject: 'Math',
            studentId: 's4',
            studentName: 'Dave (Fourth)',
            score: 60.0,
            fullMarks: 100.0,
            percentage: 60.0,
            totalQuestions: 10,
            attemptedCount: 10,
            correctCount: 6,
            incorrectCount: 4,
            unattemptedCount: 0,
            status: 'submitted',
          ),
        ];

        final leaderboard =
            PerformanceAnalyticsService.calculateBatchLeaderboard(records);
        expect(leaderboard.length, equals(4));

        // Alice is #1
        expect(leaderboard[0].studentId, equals('s1'));
        expect(leaderboard[0].rank, equals(1));

        // Bob & Charlie tie at #2
        expect(leaderboard[1].rank, equals(2));
        expect(leaderboard[2].rank, equals(2));

        // Dave is #4 (1224 policy)
        expect(leaderboard[3].studentId, equals('s4'));
        expect(leaderboard[3].rank, equals(4));
      },
    );

    test('PerformanceAnalyticsController filters and selection', () {
      final tenantCtx = ActiveTenantContext();
      final controller = PerformanceAnalyticsController(
        tenantContext: tenantCtx,
      );

      expect(controller.selectedBatch, equals('All Batches'));
      expect(controller.selectedSubject, equals('All Subjects'));
      expect(controller.selectedTabIndex, equals(0));

      controller.setBatchFilter('Class 10');
      expect(controller.selectedBatch, equals('Class 10'));

      controller.setSubjectFilter('Science');
      expect(controller.selectedSubject, equals('Science'));

      controller.setTabIndex(3);
      expect(controller.selectedTabIndex, equals(3));

      controller.toggleExamForComparison('exam_1');
      expect(
        controller.selectedExamIdsForComparison.contains('exam_1'),
        isTrue,
      );

      controller.toggleExamForComparison('exam_1');
      expect(
        controller.selectedExamIdsForComparison.contains('exam_1'),
        isFalse,
      );
    });
  });
}
