import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single evaluated exam attempt by a student.
class PerformanceRecord {
  final String examId;
  final String examName;
  final String batch;
  final String subject;
  final String studentId;
  final String studentName;
  final double score;
  final double fullMarks;
  final double percentage;
  final int totalQuestions;
  final int attemptedCount;
  final int correctCount;
  final int incorrectCount;
  final int unattemptedCount;
  final DateTime? submittedAt;
  final DateTime? examDate;
  final String status;
  final int attemptNumber;
  final Map<String, dynamic> answers;

  const PerformanceRecord({
    required this.examId,
    required this.examName,
    required this.batch,
    required this.subject,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.fullMarks,
    required this.percentage,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.unattemptedCount,
    this.submittedAt,
    this.examDate,
    required this.status,
    this.attemptNumber = 1,
    this.answers = const {},
  });

  bool get isCompleted => status == 'submitted' || status == 'graded';
  bool get hasValidScore => fullMarks > 0;

  factory PerformanceRecord.fromFirestore({
    required String examId,
    required String examName,
    required String batch,
    required String subject,
    required Map<String, dynamic> subData,
    DateTime? examDate,
  }) {
    final studentId = (subData['student_id'] ?? subData['studentId'] ?? '')
        .toString()
        .trim();
    final studentName =
        (subData['student_name'] ?? subData['studentName'] ?? 'Student')
            .toString()
            .trim();

    final scoreRaw = subData['score'];
    final score = scoreRaw is num
        ? scoreRaw.toDouble()
        : double.tryParse(scoreRaw?.toString() ?? '0') ?? 0.0;

    final fullMarksRaw = subData['full_marks'] ?? subData['fullMarks'];
    final fullMarks = fullMarksRaw is num
        ? fullMarksRaw.toDouble()
        : double.tryParse(fullMarksRaw?.toString() ?? '0') ?? 0.0;

    final percentage = fullMarks > 0 ? (score / fullMarks) * 100.0 : 0.0;

    final totalQuestionsRaw =
        subData['total_questions'] ?? subData['totalQuestions'];
    final totalQuestions = totalQuestionsRaw is num
        ? totalQuestionsRaw.toInt()
        : int.tryParse(totalQuestionsRaw?.toString() ?? '0') ?? 0;

    final attemptedRaw = subData['attempted'] ?? subData['attemptedCount'];
    final attemptedCount = attemptedRaw is num
        ? attemptedRaw.toInt()
        : int.tryParse(attemptedRaw?.toString() ?? '0') ?? 0;

    final correctRaw = subData['correct_count'] ?? subData['correctCount'];
    final correctCount = correctRaw is num
        ? correctRaw.toInt()
        : int.tryParse(correctRaw?.toString() ?? '0') ?? 0;

    final incorrectCount = (attemptedCount - correctCount).clamp(
      0,
      totalQuestions,
    );
    final unattemptedCount = (totalQuestions - attemptedCount).clamp(
      0,
      totalQuestions,
    );

    final subDateRaw = subData['submitted_at'] ?? subData['timestamp'];
    DateTime? submittedAt;
    if (subDateRaw is Timestamp) {
      submittedAt = subDateRaw.toDate();
    } else if (subDateRaw is DateTime) {
      submittedAt = subDateRaw;
    } else if (subDateRaw is String) {
      submittedAt = DateTime.tryParse(subDateRaw);
    }

    final status = (subData['status'] ?? 'submitted').toString().trim();
    final attemptNumberRaw = subData['attempt_number'];
    final attemptNumber = attemptNumberRaw is num
        ? attemptNumberRaw.toInt()
        : 1;

    final rawAnswers = subData['answers'];
    final answers = rawAnswers is Map
        ? Map<String, dynamic>.from(rawAnswers)
        : <String, dynamic>{};

    return PerformanceRecord(
      examId: examId,
      examName: examName,
      batch: batch,
      subject: subject.trim().isNotEmpty ? subject.trim() : 'General',
      studentId: studentId,
      studentName: studentName,
      score: score,
      fullMarks: fullMarks,
      percentage: double.parse(percentage.toStringAsFixed(2)),
      totalQuestions: totalQuestions,
      attemptedCount: attemptedCount,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      unattemptedCount: unattemptedCount,
      submittedAt: submittedAt,
      examDate: examDate ?? submittedAt,
      status: status,
      attemptNumber: attemptNumber,
      answers: answers,
    );
  }
}

/// Aggregated performance summary for a subject.
class SubjectPerformance {
  final String subjectName;
  final int totalExams;
  final double averagePercentage;
  final double highestScore;
  final double lowestScore;
  final double highestPercentage;
  final double lowestPercentage;
  final String? recentExamName;
  final double? recentScore;
  final double? recentPercentage;
  final DateTime? recentDate;
  final List<PerformanceRecord> records;

  const SubjectPerformance({
    required this.subjectName,
    required this.totalExams,
    required this.averagePercentage,
    required this.highestScore,
    required this.lowestScore,
    required this.highestPercentage,
    required this.lowestPercentage,
    this.recentExamName,
    this.recentScore,
    this.recentPercentage,
    this.recentDate,
    this.records = const [],
  });
}

/// Chapter-level statistical metrics.
class ChapterStat {
  final String chapterName;
  final String subjectName;
  final int questionsCount;
  final int attemptedCount;
  final int correctCount;
  final int incorrectCount;
  final int unansweredCount;
  final double accuracyPercentage;
  final bool isMetadataAvailable;

  const ChapterStat({
    required this.chapterName,
    required this.subjectName,
    required this.questionsCount,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.unansweredCount,
    required this.accuracyPercentage,
    this.isMetadataAvailable = true,
  });
}

/// Data item for exam-to-exam comparison.
class ExamComparisonItem {
  final String examId;
  final String examName;
  final DateTime? examDate;
  final double maxMarks;
  final double obtainedMarks;
  final double percentage;
  final int? rank;
  final double? percentageDiffFromPrevious;
  final bool isComparable;
  final String? note;

  const ExamComparisonItem({
    required this.examId,
    required this.examName,
    this.examDate,
    required this.maxMarks,
    required this.obtainedMarks,
    required this.percentage,
    this.rank,
    this.percentageDiffFromPrevious,
    this.isComparable = true,
    this.note,
  });
}

/// Batch Leaderboard item.
class BatchLeaderboardEntry {
  final int rank;
  final String studentId;
  final String studentName;
  final String batch;
  final int totalExamsAttempted;
  final double averagePercentage;
  final double highestPercentage;
  final String recentPerformance;
  final double? recentPercentage;
  final DateTime? recentDate;

  const BatchLeaderboardEntry({
    required this.rank,
    required this.studentId,
    required this.studentName,
    required this.batch,
    required this.totalExamsAttempted,
    required this.averagePercentage,
    required this.highestPercentage,
    required this.recentPerformance,
    this.recentPercentage,
    this.recentDate,
  });
}
