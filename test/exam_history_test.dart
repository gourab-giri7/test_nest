import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examHistory/controller/exam_controller.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examHistory/exam_history_screen.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/model/exam_model.dart';

// Test doubles for QuerySnapshot and QueryDocumentSnapshot
class FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  FakeQuerySnapshot(this.docs);

  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => const [];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  int get size => docs.length;
}

class FakeQueryDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  @override
  final String id;

  FakeQueryDocumentSnapshot(this._data, {this.id = 'doc1'});

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pref = await SharedPreferences.getInstance();
    studentData = null;
  });

  tearDown(() {
    studentData = null;
  });

  group('StudentData Model & Robust Parsing Tests', () {
    test('fromJson parses snake_case teacher_id and id', () {
      final s = StudentData.fromJson({
        'id': 'STU101',
        'name': 'Aarav',
        'teacher_id': 'TEACH999',
        'batch': 'Batch A',
        'teacher_name': 'Dr. Sharma',
      });

      expect(s.id, 'STU101');
      expect(s.teacherId, 'TEACH999');
      expect(s.name, 'Aarav');
    });

    test('fromJson parses camelCase teacherId and studentId', () {
      final s = StudentData.fromJson({
        'studentId': 'STU202',
        'name': 'Priya',
        'teacherId': 'TEACH888',
        'batch': 'Batch B',
        'teacherName': 'Prof. Gupta',
      });

      expect(s.id, 'STU202');
      expect(s.teacherId, 'TEACH888');
      expect(s.name, 'Priya');
    });

    test('restoreFromPreferences retrieves saved studentData json', () async {
      await pref.setString(
        'studentData',
        '{"id":"STU303","name":"Ananya","teacher_id":"TEACH777","batch":"10A","teacher_name":"Sir"}',
      );

      final restored = await StudentData.restoreFromPreferences();
      expect(restored, isNotNull);
      expect(restored!.id, 'STU303');
      expect(restored.teacherId, 'TEACH777');
    });

    test('restoreFromPreferences falls back to individual pref keys', () async {
      await pref.setString('id', 'STU404');
      await pref.setString('teacherId', 'TEACH666');

      final restored = await StudentData.restoreFromPreferences();
      expect(restored, isNotNull);
      expect(restored!.id, 'STU404');
      expect(restored.teacherId, 'TEACH666');
    });
  });

  group('ExamHistoryScreen UI State Termination Tests', () {
    testWidgets(
      'Missing student profile state terminates deterministically with error and buttons',
      (tester) async {
        // studentData is null and SharedPreferences is empty
        studentData = null;

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<ExamController>(
                  create: (_) => ExamController(),
                ),
              ],
              child: const ExamHistoryScreen(),
            ),
          ),
        );

        // Allow microtasks to complete
        await tester.pumpAndSettle();

        // Must display Profile Not Found message
        expect(find.text('Profile Not Found'), findsOneWidget);
        expect(
          find.textContaining(
            'Student profile or enrolled teacher was not found',
          ),
          findsOneWidget,
        );

        // Must display action buttons: Retry and Log In Again
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Log In Again'), findsOneWidget);

        // Infinite CircularProgressIndicator must NOT be present
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'Genuinely loading stream state displays indicator and terminates when event arrives',
      (tester) async {
        final testStudent = StudentData(
          id: 'STU1',
          name: 'Student One',
          teacherId: 'T1',
          batch: 'B1',
          teacherName: 'Teacher One',
        );

        final controller =
            StreamController<QuerySnapshot<Map<String, dynamic>>>();

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<ExamController>(
                  create: (_) => ExamController(),
                ),
              ],
              child: ExamHistoryScreen(
                initialStudentData: testStudent,
                examStream: controller.stream,
              ),
            ),
          ),
        );

        // First frame: initial stream waiting state
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Now emit empty snapshot
        controller.add(FakeQuerySnapshot([]));
        await tester.pumpAndSettle();

        // Indicator must be gone, replaced by empty state
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('No Exam found'), findsOneWidget);

        await controller.close();
      },
    );

    testWidgets(
      'Firestore stream error displays error UI with Retry button and terminates',
      (tester) async {
        final testStudent = StudentData(
          id: 'STU1',
          name: 'Student One',
          teacherId: 'T1',
          batch: 'B1',
          teacherName: 'Teacher One',
        );

        final controller =
            StreamController<QuerySnapshot<Map<String, dynamic>>>();

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<ExamController>(
                  create: (_) => ExamController(),
                ),
              ],
              child: ExamHistoryScreen(
                initialStudentData: testStudent,
                examStream: controller.stream,
              ),
            ),
          ),
        );

        await tester.pump();

        // Emit an error
        controller.addError(
          FirebaseException(plugin: 'firestore', message: 'Network offline'),
        );
        await tester.pumpAndSettle();

        // Error message must be rendered
        expect(find.text('Failed to Load Exams'), findsOneWidget);
        expect(
          find.text(
            'Failed to load exams. Please check your connection and try again.',
          ),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);

        // No spinning indicator
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await controller.close();
      },
    );

    testWidgets('Empty exam list displays "No Exam found" empty state', (
      tester,
    ) async {
      final testStudent = StudentData(
        id: 'STU_TARGET',
        name: 'Target Student',
        teacherId: 'T1',
        batch: 'B1',
        teacherName: 'Teacher One',
      );

      // Stream with an exam assigned to ANOTHER student, not STU_TARGET
      final otherExam = {
        'exam_id': 'EXM001',
        'exam_details': {
          'exam_name': 'Math Final',
          'full_marks': '100',
          'instruction': 'No calculators',
          'batch': 'B1',
          'exam_start': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 1)),
          ),
          'exam_end': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 1, hours: 2)),
          ),
        },
        'assigned_student_ids': ['OTHER_STUDENT'],
      };

      final stream = Stream<QuerySnapshot<Map<String, dynamic>>>.value(
        FakeQuerySnapshot([FakeQueryDocumentSnapshot(otherExam, id: 'EXM001')]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ExamController>(
                create: (_) => ExamController(),
              ),
            ],
            child: ExamHistoryScreen(
              initialStudentData: testStudent,
              examStream: stream,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Exam found'), findsOneWidget);
      expect(
        find.text('You have not been assigned to any exams yet.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'Populated exam list displays cards and separates into 4 tabs',
      (tester) async {
        final testStudent = StudentData(
          id: 'STU_TARGET',
          name: 'Target Student',
          teacherId: 'T1',
          batch: 'B1',
          teacherName: 'Teacher One',
        );

        final now = DateTime.now();

        final upcomingExam = {
          'exam_id': 'EXM_UPCOMING',
          'exam_details': {
            'exam_name': 'Physics Upcoming Exam',
            'full_marks': '50',
            'instruction': 'Formula sheet allowed',
            'batch': 'B1',
            'exam_start': Timestamp.fromDate(now.add(const Duration(days: 2))),
            'exam_end': Timestamp.fromDate(
              now.add(const Duration(days: 2, hours: 2)),
            ),
          },
          'assigned_student_ids': ['STU_TARGET'],
        };

        final completedExam = {
          'exam_id': 'EXM_COMPLETED',
          'exam_details': {
            'exam_name': 'Chemistry Completed Exam',
            'full_marks': '40',
            'instruction': 'None',
            'batch': 'B1',
            'exam_start': Timestamp.fromDate(
              now.subtract(const Duration(days: 5, hours: 2)),
            ),
            'exam_end': Timestamp.fromDate(
              now.subtract(const Duration(days: 5)),
            ),
          },
          'assigned_student_ids': ['STU_TARGET'],
        };

        final stream = Stream<QuerySnapshot<Map<String, dynamic>>>.value(
          FakeQuerySnapshot([
            FakeQueryDocumentSnapshot(upcomingExam, id: 'EXM_UPCOMING'),
            FakeQueryDocumentSnapshot(completedExam, id: 'EXM_COMPLETED'),
          ]),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<ExamController>(
                  create: (_) => ExamController(),
                ),
              ],
              child: ExamHistoryScreen(
                initialStudentData: testStudent,
                examStream: stream,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 4 Tabs must exist
        expect(find.widgetWithText(Tab, 'All'), findsOneWidget);
        expect(find.widgetWithText(Tab, 'Active'), findsOneWidget);
        expect(find.widgetWithText(Tab, 'Upcoming'), findsOneWidget);
        expect(find.widgetWithText(Tab, 'Completed'), findsOneWidget);

        // Under "All" tab, both exams should be visible
        expect(find.text('Physics Upcoming Exam'), findsOneWidget);
        expect(find.text('Chemistry Completed Exam'), findsOneWidget);

        // Switch to "Upcoming" tab
        await tester.tap(find.widgetWithText(Tab, 'Upcoming'));
        await tester.pumpAndSettle();
        expect(find.text('Physics Upcoming Exam'), findsWidgets);

        // Switch to "Active" tab (no active exam was provided)
        await tester.tap(find.widgetWithText(Tab, 'Active'));
        await tester.pumpAndSettle();
        expect(find.text('No Active exam available'), findsOneWidget);
      },
    );
  });

  group('ExamModel & ExamDetailsModel Deserialization Safety Tests', () {
    test('ExamModel.fromJson(null) returns safe model without crashing', () {
      final exam = ExamModel.fromJson(null);
      expect(exam.examId, '');
      expect(exam.examName, '');
      expect(exam.questions, isEmpty);
      expect(exam.assignedStudentIds, isEmpty);
      expect(exam.resultPublished, isFalse);
    });

    test(
      'ExamModel.fromMap handles String dates, numeric marks, missing fields',
      () {
        final exam = ExamModel.fromMap({
          'exam_id': 'EXM999',
          'full_marks': 100,
          'exam_name': 'Biology Test',
          'exam_start': '2026-10-25T10:00:00Z',
          'exam_end': '2026-10-25T11:00:00Z',
          'assigned_student_ids': ['STU1', 1234, null],
        });

        expect(exam.examId, 'EXM999');
        expect(exam.fullMarks, '100');
        expect(exam.examName, 'Biology Test');
        expect(exam.examStart, isNotNull);
        expect(exam.assignedStudentIds, contains('STU1'));
        expect(exam.assignedStudentIds, contains('1234'));
      },
    );

    test('ExamModel.fromJson handles Timestamp and int epoch dates', () {
      final now = DateTime.now();
      final exam = ExamModel.fromJson({
        'exam_id': 'EXM888',
        'exam_details': {
          'exam_name': 'English Essay',
          'full_marks': '50',
          'exam_start': Timestamp.fromDate(now),
          'exam_end': now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
        },
      });

      expect(exam.examId, 'EXM888');
      expect(exam.examName, 'English Essay');
      expect(exam.examStart, isNotNull);
      expect(exam.examEnd, isNotNull);
    });
  });

  group('ExamController Loading State & Stream Safety Tests', () {
    test(
      'loadExams with empty teacherId immediately sets isLoading = false and returns []',
      () async {
        final controller = ExamController();
        studentData = null;

        final results = await controller.loadExams(teacherId: '');
        expect(controller.isLoading, isFalse);
        expect(results, isEmpty);
      },
    );

    test(
      'loadExams with empty batchIds immediately sets isLoading = false and returns []',
      () async {
        final controller = ExamController();
        final results = await controller.loadExams(
          teacherId: 'T100',
          batchIds: [],
        );
        expect(controller.isLoading, isFalse);
        expect(results, isEmpty);
      },
    );

    test('listenToExams sets isLoading = false on data event', () async {
      final controller = ExamController();
      final streamController =
          StreamController<QuerySnapshot<Map<String, dynamic>>>();

      controller.listenToExams(
        teacherId: 'T100',
        overrideStream: streamController.stream,
      );
      expect(controller.isLoading, isTrue);

      streamController.add(FakeQuerySnapshot([]));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isLoading, isFalse);
      expect(controller.exams, isEmpty);

      await streamController.close();
      controller.dispose();
    });

    test('listenToExams sets isLoading = false on error event', () async {
      final controller = ExamController();
      final streamController =
          StreamController<QuerySnapshot<Map<String, dynamic>>>();

      controller.listenToExams(
        teacherId: 'T100',
        overrideStream: streamController.stream,
      );
      expect(controller.isLoading, isTrue);

      streamController.addError('Connection dropped');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNotNull);

      await streamController.close();
      controller.dispose();
    });
  });

  group('ExamHistoryScreen Rich UI Features & Firestore Integration Tests', () {
    testWidgets('Stats banner and search filtering work dynamically', (
      tester,
    ) async {
      final testStudent = StudentData(
        id: 'STU_X',
        name: 'Student X',
        teacherId: 'T1',
        batch: 'Batch 10',
        teacherName: 'Teacher One',
      );

      final now = DateTime.now();
      final activeExam = {
        'exam_id': 'EX_ACTIVE_1',
        'exam_details': {
          'exam_name': 'Mathematics Algebra',
          'full_marks': '100',
          'batch': 'Batch 10',
          'exam_start': Timestamp.fromDate(
            now.subtract(const Duration(minutes: 10)),
          ),
          'exam_end': Timestamp.fromDate(now.add(const Duration(minutes: 50))),
        },
        'assigned_student_ids': ['STU_X'],
      };

      final upcomingExam = {
        'exam_id': 'EX_UPCOMING_1',
        'exam_details': {
          'exam_name': 'Physics Mechanics',
          'full_marks': '50',
          'batch': 'Batch 10',
          'exam_start': Timestamp.fromDate(now.add(const Duration(days: 1))),
          'exam_end': Timestamp.fromDate(
            now.add(const Duration(days: 1, hours: 2)),
          ),
        },
        'assigned_student_ids': ['STU_X'],
      };

      final stream = Stream<QuerySnapshot<Map<String, dynamic>>>.value(
        FakeQuerySnapshot([
          FakeQueryDocumentSnapshot(activeExam, id: 'EX_ACTIVE_1'),
          FakeQueryDocumentSnapshot(upcomingExam, id: 'EX_UPCOMING_1'),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ExamController>(
                create: (_) => ExamController(),
              ),
            ],
            child: ExamHistoryScreen(
              initialStudentData: testStudent,
              examStream: stream,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify stats overview banner
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // Total assigned is 2
      expect(find.text('Active Now'), findsOneWidget);
      expect(find.text('Start Exam'), findsOneWidget);

      // Verify both exams visible under All tab
      expect(find.text('Mathematics Algebra'), findsOneWidget);
      expect(find.text('Physics Mechanics'), findsOneWidget);

      // Search for "Physics"
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Physics');
      await tester.pumpAndSettle();

      // Only Physics should match
      expect(find.text('Physics Mechanics'), findsOneWidget);
      expect(find.text('Mathematics Algebra'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Both visible again
      expect(find.text('Mathematics Algebra'), findsOneWidget);
      expect(find.text('Physics Mechanics'), findsOneWidget);
    });

    testWidgets('initialTab parameter opens requested tab directly', (
      tester,
    ) async {
      final testStudent = StudentData(
        id: 'STU_Y',
        name: 'Student Y',
        teacherId: 'T1',
        batch: 'Batch 10',
        teacherName: 'Teacher One',
      );

      final now = DateTime.now();
      final completedExam = {
        'exam_id': 'EX_COMP_1',
        'exam_details': {
          'exam_name': 'English Literature Test',
          'full_marks': '40',
          'batch': 'Batch 10',
          'exam_start': Timestamp.fromDate(
            now.subtract(const Duration(days: 2, hours: 2)),
          ),
          'exam_end': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        },
        'assigned_student_ids': ['STU_Y'],
      };

      final stream = Stream<QuerySnapshot<Map<String, dynamic>>>.value(
        FakeQuerySnapshot([
          FakeQueryDocumentSnapshot(completedExam, id: 'EX_COMP_1'),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ExamController>(
                create: (_) => ExamController(),
              ),
            ],
            child: ExamHistoryScreen(
              initialStudentData: testStudent,
              examStream: stream,
              initialTab: 3, // Completed tab directly
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Under Completed tab, English exam should be displayed
      expect(find.text('English Literature Test'), findsOneWidget);
      expect(find.text('Ended'), findsOneWidget);
    });
  });
}
