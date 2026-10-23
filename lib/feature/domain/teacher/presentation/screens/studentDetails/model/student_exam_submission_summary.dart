import 'package:test_nest/model/exam_model.dart';

class StudentExamSubmissionSummary {
  final String examId;
  final String examName;
  final String examDate;
  final String startTime;
  final String endTime;
  final String batch;
  final String score;
  final String fullMarks;
  final String status;
  final DateTime? submittedAt;
  final Map<String, dynamic> submissionData;
  final ExamModel? examModel;
  final int? totalQuestionsOverride;

  const StudentExamSubmissionSummary({
    required this.examId,
    required this.examName,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    required this.batch,
    required this.score,
    required this.fullMarks,
    required this.status,
    required this.submittedAt,
    required this.submissionData,
    this.examModel,
    this.totalQuestionsOverride,
  });

  int get correctCount {
    if (submissionData['correct_count'] is num) {
      return (submissionData['correct_count'] as num).toInt();
    }
    return 0;
  }

  int get totalQuestions {
    if (totalQuestionsOverride != null) {
      return totalQuestionsOverride!;
    }
    if (examModel != null) {
      return examModel!.questions.length;
    }
    if (submissionData['total_questions'] is num) {
      return (submissionData['total_questions'] as num).toInt();
    }
    return 0;
  }

  int get attemptedCount {
    if (submissionData['attempted'] is num) {
      return (submissionData['attempted'] as num).toInt();
    }
    final answers = submissionData['answers'];
    if (answers is Map) return answers.length;
    return 0;
  }

  int get incorrectCount {
    final incorrect = attemptedCount - correctCount;
    return incorrect > 0 ? incorrect : 0;
  }

  int get unattemptedCount {
    final unattempted = totalQuestions - attemptedCount;
    return unattempted > 0 ? unattempted : 0;
  }
}
