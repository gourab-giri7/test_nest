import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/model/Q&A_model.dart';
import 'package:test_nest/model/performance_model.dart';

class PerformanceAnalyticsService {
  final FirebaseFirestore? _explicitFirestore;

  PerformanceAnalyticsService({FirebaseFirestore? firestore})
    : _explicitFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // PURE ANALYTICAL CALCULATIONS
  // ---------------------------------------------------------------------------

  /// Calculates subject-wise performance metrics from student performance records.
  static List<SubjectPerformance> calculateSubjectPerformance(
    List<PerformanceRecord> records,
  ) {
    if (records.isEmpty) return const [];

    // Group records by subject (case-insensitive, trimmed)
    final Map<String, List<PerformanceRecord>> subjectGroups = {};
    for (final r in records) {
      final sub = r.subject.trim().isNotEmpty ? r.subject.trim() : 'General';
      subjectGroups.putIfAbsent(sub, () => []).add(r);
    }

    final List<SubjectPerformance> results = [];

    for (final entry in subjectGroups.entries) {
      final subjectName = entry.key;
      final subRecords = entry.value;

      // Sort by date descending
      subRecords.sort((a, b) {
        final aDate = a.examDate ?? a.submittedAt ?? DateTime(1970);
        final bDate = b.examDate ?? b.submittedAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      // Filter valid completed records with valid positive full marks
      final validRecords = subRecords
          .where((r) => r.isCompleted && r.hasValidScore)
          .toList(growable: false);

      if (validRecords.isEmpty) {
        results.add(
          SubjectPerformance(
            subjectName: subjectName,
            totalExams: 0,
            averagePercentage: 0.0,
            highestScore: 0.0,
            lowestScore: 0.0,
            highestPercentage: 0.0,
            lowestPercentage: 0.0,
            recentExamName: subRecords.isNotEmpty
                ? subRecords.first.examName
                : null,
            records: subRecords,
          ),
        );
        continue;
      }

      double totalPct = 0.0;
      double highestScore = -1.0;
      double lowestScore = double.infinity;
      double highestPct = -1.0;
      double lowestPct = double.infinity;

      for (final r in validRecords) {
        totalPct += r.percentage;
        if (r.score > highestScore) highestScore = r.score;
        if (r.score < lowestScore) lowestScore = r.score;
        if (r.percentage > highestPct) highestPct = r.percentage;
        if (r.percentage < lowestPct) lowestPct = r.percentage;
      }

      final avgPct = totalPct / validRecords.length;
      final recent = validRecords.first;

      results.add(
        SubjectPerformance(
          subjectName: subjectName,
          totalExams: validRecords.length,
          averagePercentage: double.parse(avgPct.toStringAsFixed(2)),
          highestScore: highestScore >= 0 ? highestScore : 0.0,
          lowestScore: lowestScore != double.infinity ? lowestScore : 0.0,
          highestPercentage: double.parse(highestPct.toStringAsFixed(2)),
          lowestPercentage: double.parse(lowestPct.toStringAsFixed(2)),
          recentExamName: recent.examName,
          recentScore: recent.score,
          recentPercentage: recent.percentage,
          recentDate: recent.examDate ?? recent.submittedAt,
          records: subRecords,
        ),
      );
    }

    results.sort(
      (a, b) =>
          a.subjectName.toLowerCase().compareTo(b.subjectName.toLowerCase()),
    );
    return results;
  }

  /// Calculates chapter-wise performance metrics.
  /// If questions lack chapter metadata, sets [isMetadataAvailable] to false
  /// so UI can display an appropriate unavailable state rather than guessing.
  static List<ChapterStat> calculateChapterPerformance(
    List<PerformanceRecord> records,
    Map<String, List<QAModel>> examQuestions,
  ) {
    if (records.isEmpty) return const [];

    // Map: ChapterIdentifier -> accumulator
    final Map<String, _ChapterAccumulator> accumulators = {};
    bool anyChapterFound = false;

    for (final r in records) {
      final questions = examQuestions[r.examId];
      if (questions == null || questions.isEmpty) continue;

      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        final chapterName = q.chapter?.trim();
        final subjectName = (q.subject?.trim().isNotEmpty == true)
            ? q.subject!.trim()
            : (r.subject.trim().isNotEmpty ? r.subject.trim() : 'General');

        final bool hasChapter = chapterName != null && chapterName.isNotEmpty;
        if (hasChapter) anyChapterFound = true;

        final resolvedChapter = hasChapter ? chapterName : 'Uncategorized';
        final key =
            '${subjectName.toLowerCase()}__${resolvedChapter.toLowerCase()}';

        final acc = accumulators.putIfAbsent(
          key,
          () => _ChapterAccumulator(
            chapterName: resolvedChapter,
            subjectName: subjectName,
            isMetadataAvailable: hasChapter,
          ),
        );

        acc.totalQuestions++;

        // Determine if student answered this question
        // Student answers can be keyed by questionId (stable) or string index (legacy)
        final studentAnswer =
            r.answers[q.id] ??
            r.answers[i.toString()] ??
            (r.answers['answers_by_index'] is Map
                ? (r.answers['answers_by_index'] as Map)[i.toString()]
                : null);

        if (studentAnswer != null &&
            studentAnswer.toString().trim().isNotEmpty) {
          acc.attemptedCount++;
          final chosen = studentAnswer.toString().trim().toUpperCase();
          final correct = q.ans.trim().toUpperCase();

          if (correct.isNotEmpty && chosen == correct) {
            acc.correctCount++;
          } else {
            acc.incorrectCount++;
          }
        } else {
          acc.unansweredCount++;
        }
      }
    }

    if (accumulators.isEmpty) {
      return [
        const ChapterStat(
          chapterName: 'No Chapter Metadata Available',
          subjectName: 'All Subjects',
          questionsCount: 0,
          attemptedCount: 0,
          correctCount: 0,
          incorrectCount: 0,
          unansweredCount: 0,
          accuracyPercentage: 0.0,
          isMetadataAvailable: false,
        ),
      ];
    }

    final results = accumulators.values.map((acc) {
      final accuracy = acc.attemptedCount > 0
          ? (acc.correctCount / acc.attemptedCount) * 100.0
          : 0.0;

      return ChapterStat(
        chapterName: acc.chapterName,
        subjectName: acc.subjectName,
        questionsCount: acc.totalQuestions,
        attemptedCount: acc.attemptedCount,
        correctCount: acc.correctCount,
        incorrectCount: acc.incorrectCount,
        unansweredCount: acc.unansweredCount,
        accuracyPercentage: double.parse(accuracy.toStringAsFixed(2)),
        isMetadataAvailable: anyChapterFound && acc.isMetadataAvailable,
      );
    }).toList();

    results.sort((a, b) {
      final subCmp = a.subjectName.toLowerCase().compareTo(
        b.subjectName.toLowerCase(),
      );
      if (subCmp != 0) return subCmp;
      return a.chapterName.toLowerCase().compareTo(b.chapterName.toLowerCase());
    });

    return results;
  }

  /// Calculates exam-to-exam comparisons for selected exams.
  static List<ExamComparisonItem> calculateExamComparison(
    List<PerformanceRecord> records,
    List<String> selectedExamIds,
  ) {
    if (records.isEmpty || selectedExamIds.isEmpty) return const [];

    final selectedSet = selectedExamIds.toSet();
    final filtered = records
        .where((r) => selectedSet.contains(r.examId) && r.isCompleted)
        .toList();

    // Deduplicate retakes by examId (take latest)
    final Map<String, PerformanceRecord> deduplicated = {};
    for (final r in filtered) {
      final existing = deduplicated[r.examId];
      if (existing == null) {
        deduplicated[r.examId] = r;
      } else {
        final existingDate =
            existing.examDate ?? existing.submittedAt ?? DateTime(1970);
        final newDate = r.examDate ?? r.submittedAt ?? DateTime(1970);
        if (newDate.isAfter(existingDate) ||
            r.attemptNumber > existing.attemptNumber) {
          deduplicated[r.examId] = r;
        }
      }
    }

    final sortedItems = deduplicated.values.toList()
      ..sort((a, b) {
        final aDate = a.examDate ?? a.submittedAt ?? DateTime(1970);
        final bDate = b.examDate ?? b.submittedAt ?? DateTime(1970);
        return aDate.compareTo(bDate); // Chronological
      });

    final List<ExamComparisonItem> results = [];
    double? previousPercentage;
    double? firstMaxMarks;

    for (var i = 0; i < sortedItems.length; i++) {
      final r = sortedItems[i];
      firstMaxMarks ??= r.fullMarks;

      double? diff;
      if (previousPercentage != null) {
        diff = double.parse(
          (r.percentage - previousPercentage).toStringAsFixed(2),
        );
      }
      previousPercentage = r.percentage;

      final bool diffMaxMarks = r.fullMarks != firstMaxMarks;
      final String? note = diffMaxMarks
          ? 'Exam scoring format differs (Max marks: ${r.fullMarks}). Comparison normalized using percentage.'
          : null;

      results.add(
        ExamComparisonItem(
          examId: r.examId,
          examName: r.examName,
          examDate: r.examDate ?? r.submittedAt,
          maxMarks: r.fullMarks,
          obtainedMarks: r.score,
          percentage: r.percentage,
          percentageDiffFromPrevious: diff,
          isComparable: true,
          note: note,
        ),
      );
    }

    return results;
  }

  /// Calculates batch leaderboard with Standard Competition Ranking (1224).
  static List<BatchLeaderboardEntry> calculateBatchLeaderboard(
    List<PerformanceRecord> records, {
    String? batchFilter,
    DateTimeRange? dateRange,
  }) {
    if (records.isEmpty) return const [];

    // 1. Filter completed and valid records
    var filtered = records.where((r) {
      if (!r.isCompleted || !r.hasValidScore) return false;
      if (batchFilter != null &&
          batchFilter.isNotEmpty &&
          batchFilter != 'All Batches') {
        if (r.batch.trim().toLowerCase() != batchFilter.trim().toLowerCase()) {
          return false;
        }
      }
      if (dateRange != null) {
        final date = r.examDate ?? r.submittedAt;
        if (date == null) return false;
        if (date.isBefore(dateRange.start) || date.isAfter(dateRange.end)) {
          return false;
        }
      }
      return true;
    }).toList();

    if (filtered.isEmpty) return const [];

    // 2. Deduplicate retakes per (studentId, examId) -> keep latest attempt
    final Map<String, PerformanceRecord> deduplicatedAttempts = {};
    for (final r in filtered) {
      final key = '${r.studentId}__${r.examId}';
      final existing = deduplicatedAttempts[key];
      if (existing == null) {
        deduplicatedAttempts[key] = r;
      } else {
        final exDate = existing.submittedAt ?? DateTime(1970);
        final curDate = r.submittedAt ?? DateTime(1970);
        if (curDate.isAfter(exDate) ||
            r.attemptNumber > existing.attemptNumber) {
          deduplicatedAttempts[key] = r;
        }
      }
    }

    // 3. Group by student
    final Map<String, List<PerformanceRecord>> studentRecords = {};
    for (final r in deduplicatedAttempts.values) {
      studentRecords.putIfAbsent(r.studentId, () => []).add(r);
    }

    // 4. Calculate aggregates for each student
    final List<_StudentAggregate> aggregates = [];
    for (final entry in studentRecords.entries) {
      final sId = entry.key;
      final attempts = entry.value;

      attempts.sort((a, b) {
        final aDate = a.submittedAt ?? a.examDate ?? DateTime(1970);
        final bDate = b.submittedAt ?? b.examDate ?? DateTime(1970);
        return bDate.compareTo(aDate); // Recent first
      });

      double totalPct = 0.0;
      double highestPct = 0.0;
      for (final a in attempts) {
        totalPct += a.percentage;
        if (a.percentage > highestPct) highestPct = a.percentage;
      }

      final avgPct = totalPct / attempts.length;
      final recent = attempts.first;
      final studentName = recent.studentName.isNotEmpty
          ? recent.studentName
          : 'Student';
      final batchName = recent.batch;

      aggregates.add(
        _StudentAggregate(
          studentId: sId,
          studentName: studentName,
          batch: batchName,
          totalExams: attempts.length,
          avgPercentage: double.parse(avgPct.toStringAsFixed(2)),
          highestPercentage: double.parse(highestPct.toStringAsFixed(2)),
          recentPerformance:
              '${recent.percentage.toStringAsFixed(1)}% in ${recent.examName}',
          recentPercentage: recent.percentage,
          recentDate: recent.submittedAt ?? recent.examDate,
        ),
      );
    }

    // 5. Sort: averagePercentage desc, highestPercentage desc, totalExams desc, name asc
    aggregates.sort((a, b) {
      final avgCmp = b.avgPercentage.compareTo(a.avgPercentage);
      if (avgCmp != 0) return avgCmp;

      final highCmp = b.highestPercentage.compareTo(a.highestPercentage);
      if (highCmp != 0) return highCmp;

      final countCmp = b.totalExams.compareTo(a.totalExams);
      if (countCmp != 0) return countCmp;

      return a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
    });

    // 6. Assign Standard Competition Ranking (1224)
    final List<BatchLeaderboardEntry> leaderboard = [];
    for (var i = 0; i < aggregates.length; i++) {
      final current = aggregates[i];
      int rank = i + 1;

      if (i > 0) {
        final prev = aggregates[i - 1];
        if (current.avgPercentage == prev.avgPercentage &&
            current.highestPercentage == prev.highestPercentage) {
          rank = leaderboard[i - 1].rank;
        }
      }

      leaderboard.add(
        BatchLeaderboardEntry(
          rank: rank,
          studentId: current.studentId,
          studentName: current.studentName,
          batch: current.batch,
          totalExamsAttempted: current.totalExams,
          averagePercentage: current.avgPercentage,
          highestPercentage: current.highestPercentage,
          recentPerformance: current.recentPerformance,
          recentPercentage: current.recentPercentage,
          recentDate: current.recentDate,
        ),
      );
    }

    return leaderboard;
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE DATA ACCESS
  // ---------------------------------------------------------------------------

  /// Fetches candidate exams and student submissions for student performance intelligence.
  Future<List<PerformanceRecord>> loadStudentPerformance({
    required TenantPathResolver resolver,
    required String studentId,
    String? fallbackTeacherId,
    List<String>? batchIds,
  }) async {
    final cleanStudentId = studentId.trim();
    if (cleanStudentId.isEmpty) return const [];

    try {
      final examsCollectionPath = resolver.examsPath(fallbackTeacherId);
      final examsSnap = await _firestore.collection(examsCollectionPath).get();

      final List<PerformanceRecord> records = [];

      for (final examDoc in examsSnap.docs) {
        try {
          final examData = examDoc.data();
          final examId = examDoc.id;
          final examName =
              (examData['exam_name'] ??
                      (examData['exam_details'] is Map
                          ? examData['exam_details']['exam_name']
                          : null) ??
                      'Exam')
                  .toString();
          final batch =
              (examData['batch'] ??
                      (examData['exam_details'] is Map
                          ? examData['exam_details']['batch']
                          : null) ??
                      '')
                  .toString();
          final subject =
              (examData['subject'] ??
                      (examData['exam_details'] is Map
                          ? examData['exam_details']['subject']
                          : null) ??
                      '')
                  .toString();

          DateTime? examDate;
          final startRaw =
              examData['exam_start'] ??
              (examData['exam_details'] is Map
                  ? examData['exam_details']['exam_start']
                  : null);
          if (startRaw is Timestamp) examDate = startRaw.toDate();

          // Submissions subcollection
          final subDoc = await examDoc.reference
              .collection('submissions')
              .doc(cleanStudentId)
              .get();

          if (subDoc.exists && subDoc.data() != null) {
            final subData = subDoc.data()!;
            records.add(
              PerformanceRecord.fromFirestore(
                examId: examId,
                examName: examName,
                batch: batch,
                subject: subject,
                subData: subData,
                examDate: examDate,
              ),
            );
          }
        } catch (e) {
          log('Error reading submission for exam ${examDoc.id}: $e');
        }
      }

      records.sort((a, b) {
        final aDate = a.examDate ?? a.submittedAt ?? DateTime(1970);
        final bDate = b.examDate ?? b.submittedAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return records;
    } catch (e) {
      log('Error loading student performance records: $e');
      return const [];
    }
  }

  /// Fetches candidate exams and all submissions for an authorized teacher or admin.
  Future<List<PerformanceRecord>> loadExamSubmissions({
    required TenantPathResolver resolver,
    String? fallbackTeacherId,
    List<String>? allowedBatchNames,
    String? teacherOwnerUid,
  }) async {
    try {
      final examsCollectionPath = resolver.examsPath(fallbackTeacherId);
      final examsSnap = await _firestore.collection(examsCollectionPath).get();

      final List<PerformanceRecord> records = [];

      for (final examDoc in examsSnap.docs) {
        final examData = examDoc.data();
        final examId = examDoc.id;
        final examName =
            (examData['exam_name'] ??
                    (examData['exam_details'] is Map
                        ? examData['exam_details']['exam_name']
                        : null) ??
                    'Exam')
                .toString();
        final batch =
            (examData['batch'] ??
                    (examData['exam_details'] is Map
                        ? examData['exam_details']['batch']
                        : null) ??
                    '')
                .toString();
        final subject =
            (examData['subject'] ??
                    (examData['exam_details'] is Map
                        ? examData['exam_details']['subject']
                        : null) ??
                    '')
                .toString();
        final examTeacherId =
            (examData['teacher_id'] ??
                    (examData['exam_details'] is Map
                        ? examData['exam_details']['teacher_id']
                        : null) ??
                    '')
                .toString();

        // Scope check for non-admin teachers
        if (teacherOwnerUid != null && teacherOwnerUid.isNotEmpty) {
          final isOwner = examTeacherId == teacherOwnerUid;
          final isBatchAssigned =
              allowedBatchNames != null &&
              allowedBatchNames.any(
                (b) => b.trim().toLowerCase() == batch.trim().toLowerCase(),
              );
          if (!isOwner && !isBatchAssigned) {
            continue;
          }
        }

        DateTime? examDate;
        final startRaw =
            examData['exam_start'] ??
            (examData['exam_details'] is Map
                ? examData['exam_details']['exam_start']
                : null);
        if (startRaw is Timestamp) examDate = startRaw.toDate();

        final subSnap = await examDoc.reference.collection('submissions').get();
        for (final subDoc in subSnap.docs) {
          final subData = subDoc.data();
          records.add(
            PerformanceRecord.fromFirestore(
              examId: examId,
              examName: examName,
              batch: batch,
              subject: subject,
              subData: subData,
              examDate: examDate,
            ),
          );
        }
      }

      records.sort((a, b) {
        final aDate = a.examDate ?? a.submittedAt ?? DateTime(1970);
        final bDate = b.examDate ?? b.submittedAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return records;
    } catch (e) {
      log('Error loading exam submissions: $e');
      return const [];
    }
  }

  /// Fetches question models for specified exams to support chapter-wise performance analysis.
  Future<Map<String, List<QAModel>>> loadExamQuestions({
    required TenantPathResolver resolver,
    required Set<String> examIds,
    String? fallbackTeacherId,
  }) async {
    final Map<String, List<QAModel>> result = {};
    if (examIds.isEmpty) return result;

    try {
      final examsCollectionPath = resolver.examsPath(fallbackTeacherId);
      for (final examId in examIds) {
        try {
          final doc = await _firestore
              .collection(examsCollectionPath)
              .doc(examId)
              .get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final questionsRaw = data['questions'];
            final list = <QAModel>[];
            if (questionsRaw is List) {
              var i = 1;
              for (final item in questionsRaw) {
                if (item is Map) {
                  final qa = QAModel.fromJson(Map<String, dynamic>.from(item));
                  if (qa.id.trim().isEmpty) qa.id = 'q_$i';
                  list.add(qa);
                  i++;
                }
              }
            }
            result[examId] = list;
          }
        } catch (_) {}
      }
    } catch (e) {
      log('Error loading exam questions: $e');
    }

    return result;
  }
}

class _ChapterAccumulator {
  final String chapterName;
  final String subjectName;
  final bool isMetadataAvailable;
  int totalQuestions = 0;
  int attemptedCount = 0;
  int correctCount = 0;
  int incorrectCount = 0;
  int unansweredCount = 0;

  _ChapterAccumulator({
    required this.chapterName,
    required this.subjectName,
    required this.isMetadataAvailable,
  });
}

class _StudentAggregate {
  final String studentId;
  final String studentName;
  final String batch;
  final int totalExams;
  final double avgPercentage;
  final double highestPercentage;
  final String recentPerformance;
  final double recentPercentage;
  final DateTime? recentDate;

  _StudentAggregate({
    required this.studentId,
    required this.studentName,
    required this.batch,
    required this.totalExams,
    required this.avgPercentage,
    required this.highestPercentage,
    required this.recentPerformance,
    required this.recentPercentage,
    this.recentDate,
  });
}
