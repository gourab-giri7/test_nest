import 'package:cloud_firestore/cloud_firestore.dart';

class ExamDetailsModel {
  // final String examId;
  final String examName;
  final String fullMarks;
  final String examKey;
  final String instruction;
  final String batch;
  final List<String> batches;
  final String? creatorName;
  final String? creatorRole;

  final DateTime examStart;
  final DateTime examEnd;
  final List<String> assignedStudentIds;

  ExamDetailsModel({
    // required this.examId,
    required this.examName,
    required this.fullMarks,
    required this.examKey,
    required this.instruction,
    required this.batch,
    this.batches = const [],
    this.creatorName,
    this.creatorRole,
    required this.examStart,
    required this.examEnd,
    this.assignedStudentIds = const [],
  });

  factory ExamDetailsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ExamDetailsModel(
        examName: '',
        fullMarks: '',
        examKey: '',
        instruction: '',
        batch: '',
        batches: const [],
        examStart: DateTime.now(),
        examEnd: DateTime.now(),
        assignedStudentIds: const [],
      );
    }
    final rawDetails = json['exam_details'];
    final details = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : json;

    final resolvedBatch = (details['batch'] ?? json['batch'] ?? '').toString();
    final rawBatches = details['batches'] ?? json['batches'];
    final resolvedBatches = rawBatches is List
        ? rawBatches.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : (resolvedBatch.isNotEmpty
            ? resolvedBatch.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : const <String>[]);

    return ExamDetailsModel(
      examName: (details['exam_name'] ?? json['exam_name'] ?? '').toString(),
      fullMarks: (details['full_marks'] ?? json['full_marks'] ?? '').toString(),
      examKey: (details['exam_key'] ?? json['exam_key'] ?? '').toString(),
      instruction: (details['instruction'] ?? json['instruction'] ?? '')
          .toString(),
      batch: resolvedBatch,
      batches: resolvedBatches,
      creatorName: (details['creator_name'] ?? json['creator_name'] ?? details['teacher_name'] ?? json['teacher_name'])?.toString(),
      creatorRole: (details['creator_role'] ?? json['creator_role'] ?? details['created_by_role'] ?? json['created_by_role'])?.toString(),
      examStart: _timestampToDateTime(
        details['exam_start'] ?? json['exam_start'],
      ),
      examEnd: _timestampToDateTime(details['exam_end'] ?? json['exam_end']),
      assignedStudentIds: () {
        final rawIds =
            json['assigned_student_ids'] ?? details['assigned_student_ids'];
        if (rawIds is List) {
          return rawIds
              .map((id) => id?.toString().trim() ?? '')
              .where((id) => id.isNotEmpty)
              .toList(growable: false);
        }
        return const <String>[];
      }(),
    );
  }

  factory ExamDetailsModel.fromMap(Map<String, dynamic>? map) =>
      ExamDetailsModel.fromJson(map);

  static DateTime _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'exam_name': examName,
      'full_marks': fullMarks,
      'exam_key': examKey,
      'instruction': instruction,
      'batch': batch,
      'batches': batches.isNotEmpty ? batches : (batch.isNotEmpty ? [batch] : const []),
      if (creatorName != null) 'creator_name': creatorName,
      if (creatorRole != null) 'creator_role': creatorRole,
      'exam_start': Timestamp.fromDate(examStart),
      'exam_end': Timestamp.fromDate(examEnd),
      'assigned_student_ids': assignedStudentIds,
    };
  }

  String get status {
    final now = DateTime.now();

    if (now.isBefore(examStart)) {
      return 'Upcoming';
    }

    if (now.isAfter(examEnd)) {
      return 'Completed';
    }

    return 'Active';
  }
}

ExamDetailsModel? examDetails;
