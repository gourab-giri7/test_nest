import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/controller/create_exam_controller.dart';
import 'package:test_nest/model/exam_model.dart';

void main() {
  group('StudentModel Directory & Removal Status Tests', () {
    test('Correctly identifies active and removed students', () {
      final activeStudent = StudentModel(
        id: 'std_01',
        name: 'John Doe',
        batch: 'Batch Alpha',
        password: '',
        status: 'Active',
      );
      expect(activeStudent.isActive, isTrue);
      expect(activeStudent.isRemoved, isFalse);

      final removedStudent = StudentModel(
        id: 'std_02',
        name: 'Jane Smith',
        batch: 'Batch Alpha',
        password: '',
        status: 'removed',
      );
      expect(removedStudent.isActive, isFalse);
      expect(removedStudent.isRemoved, isTrue);

      final removedByTeacher = StudentModel(
        id: 'std_03',
        name: 'Bob Jones',
        batch: 'Batch Alpha',
        password: '',
        status: 'removed_by_teacher',
      );
      expect(removedByTeacher.isActive, isFalse);
      expect(removedByTeacher.isRemoved, isTrue);
    });

    test(
      'Safely parses legacy and alternative field names from Firestore JSON',
      () {
        final legacyJson = {
          'student_id': 'LEGACY_99',
          'student_name': 'Legacy Student',
          'batch_name': 'Batch Legacy',
          'student_email': 'legacy@example.com',
          'mobile': '9876543210',
        };

        final parsed = StudentModel.fromJson(legacyJson, docId: 'DOC_123');
        expect(parsed.id, 'LEGACY_99');
        expect(parsed.name, 'Legacy Student');
        expect(parsed.batch, 'Batch Legacy');
        expect(parsed.email, 'legacy@example.com');
        expect(parsed.phone, '9876543210');
        expect(parsed.isActive, isTrue);
      },
    );

    test('Falls back to docId when id and student_id are missing', () {
      final json = {'fullName': 'Doc ID Student', 'batchName': 'Batch Beta'};

      final parsed = StudentModel.fromJson(json, docId: 'DOC_AUTO_ID_456');
      expect(parsed.id, 'DOC_AUTO_ID_456');
      expect(parsed.name, 'Doc ID Student');
      expect(parsed.batch, 'Batch Beta');
      expect(parsed.isActive, isTrue);
    });
  });

  group('Student Directory & Dashboard Count Synchronization Tests', () {
    test(
      'Consistent enrollment definition filters out removed students from directory',
      () {
        final activeStudent1 = StudentModel(
          id: 'std_01',
          name: 'Active One',
          batch: 'Physics',
          password: '',
          status: 'Active',
        );
        final activeStudent2 = StudentModel(
          id: 'std_02',
          name: 'Active Two',
          batch: 'Math',
          password: '',
          status: 'Active',
        );
        final removedStudent = StudentModel(
          id: 'std_03',
          name: 'Removed Three',
          batch: 'Physics',
          password: '',
          status: 'removed',
        );

        final allStudents = [activeStudent1, activeStudent2, removedStudent];

        // Dashboard count calculation using the consistent active definition
        final dashboardCount = allStudents.where((s) => s.isActive).length;
        expect(dashboardCount, 2);

        // Directory active count
        final directoryActiveStudents = allStudents
            .where((s) => s.isActive)
            .toList();
        expect(directoryActiveStudents.length, 2);
        expect(
          directoryActiveStudents.map((s) => s.id),
          containsAll(['std_01', 'std_02']),
        );
        expect(
          directoryActiveStudents.map((s) => s.id),
          isNot(contains('std_03')),
        );
      },
    );

    test(
      'CreateExamController excludes removed students from exam assignment',
      () {
        final controller = CreateExamController();
        final students = [
          StudentModel(
            id: 'std_01',
            name: 'Student 1',
            batch: 'Class 10',
            password: '',
            status: 'Active',
          ),
          StudentModel(
            id: 'std_02',
            name: 'Student 2',
            batch: 'Class 10',
            password: '',
            status: 'removed', // Removed by teacher
          ),
        ];

        controller.syncStudents(
          students: students,
          availableBatches: ['Class 10'],
          activeBatch: 'Class 10',
        );

        // Only active students should be available for assignment
        expect(controller.studentsForSelectedBatch.length, 1);
        expect(controller.studentsForSelectedBatch.first.id, 'std_01');
        expect(controller.selectedStudentIds, contains('std_01'));
        expect(controller.selectedStudentIds, isNot(contains('std_02')));
      },
    );
  });

  group('Exam Assignment Lock Tests (Post-End-Time Prevention)', () {
    test('Correctly determines if an exam has ended and locks assignment', () {
      final now = DateTime.now();

      // Exam scheduled in the past
      final endedExam = ExamModel(
        examId: 'ex_past',
        examName: 'Past Exam',
        fullMarks: '100',
        examKey: 'KEY1',
        instruction: 'None',
        batch: 'Batch Alpha',
        examStart: now.subtract(const Duration(hours: 3)),
        examEnd: now.subtract(const Duration(hours: 1)), // Ended 1 hour ago
        questions: const [],
        assignedStudentIds: ['std_01'],
      );

      expect(endedExam.status, 'Completed');
      final isEnded =
          endedExam.status == 'Completed' ||
          (endedExam.examEnd != null && now.isAfter(endedExam.examEnd!));
      expect(
        isEnded,
        isTrue,
        reason: 'Exam has ended and assignment must be locked',
      );

      // Exam currently live
      final liveExam = ExamModel(
        examId: 'ex_live',
        examName: 'Live Exam',
        fullMarks: '100',
        examKey: 'KEY2',
        instruction: 'None',
        batch: 'Batch Alpha',
        examStart: now.subtract(const Duration(minutes: 30)),
        examEnd: now.add(const Duration(minutes: 30)), // Ends in 30 minutes
        questions: const [],
        assignedStudentIds: ['std_01'],
      );

      expect(liveExam.status, 'Active');
      final isLiveEnded =
          liveExam.status == 'Completed' ||
          (liveExam.examEnd != null && now.isAfter(liveExam.examEnd!));
      expect(isLiveEnded, isFalse, reason: 'Live exam must allow assignment');

      // Exam scheduled in the future
      final upcomingExam = ExamModel(
        examId: 'ex_future',
        examName: 'Future Exam',
        fullMarks: '100',
        examKey: 'KEY3',
        instruction: 'None',
        batch: 'Batch Alpha',
        examStart: now.add(const Duration(days: 1)),
        examEnd: now.add(const Duration(days: 1, hours: 2)),
        questions: const [],
        assignedStudentIds: ['std_01'],
      );

      expect(upcomingExam.status, 'Upcoming');
      final isUpcomingEnded =
          upcomingExam.status == 'Completed' ||
          (upcomingExam.examEnd != null && now.isAfter(upcomingExam.examEnd!));
      expect(
        isUpcomingEnded,
        isFalse,
        reason: 'Upcoming exam must allow assignment',
      );
    });
  });
}
