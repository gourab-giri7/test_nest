import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/controller/create_exam_controller.dart';

void main() {
  group('StudentModel Batch Normalization & ID Resolution Tests', () {
    test('Batch comparison matches across case, leading, trailing, and multi-spaces', () {
      expect(StudentModel.isSameBatch('Class 12', 'class 12'), isTrue);
      expect(StudentModel.isSameBatch('Class 12', 'Class 12 '), isTrue);
      expect(StudentModel.isSameBatch('Class 12', ' CLASS 12 '), isTrue);
      expect(StudentModel.isSameBatch('Class 12', 'Class  12'), isTrue);
      expect(StudentModel.isSameBatch('Class 12', 'Class 11'), isFalse);
    });

    test('StudentModel.fromJson resolves id from id, student_id, or docId', () {
      // Case 1: Standard 'id' field
      final s1 = StudentModel.fromJson({
        'id': 'STU001',
        'name': 'Alice',
        'batch': 'Class 12',
      });
      expect(s1.id, 'STU001');

      // Case 2: 'student_id' field
      final s2 = StudentModel.fromJson({
        'student_id': 'STU002',
        'name': 'Bob',
        'batch': 'Class 12',
      });
      expect(s2.id, 'STU002');

      // Case 3: ID from docId fallback
      final s3 = StudentModel.fromJson(
        {
          'name': 'Charlie',
          'batch': 'Class 12',
        },
        docId: 'STU003',
      );
      expect(s3.id, 'STU003');
    });
  });

  group('CreateExamController Assign Students Tests', () {
    late CreateExamController controller;

    setUp(() {
      controller = CreateExamController();
    });

    test('Loads and filters students for "Class 12" batch with whitespace variations', () {
      final students = [
        StudentModel(name: 'Alice', batch: 'Class 12', id: 'S1', password: '123'),
        StudentModel(name: 'Bob', batch: 'class 12 ', id: 'S2', password: '123'),
        StudentModel(name: 'Charlie', batch: ' CLASS 12 ', id: 'S3', password: '123'),
        StudentModel(name: 'David', batch: 'Class 11', id: 'S4', password: '123'),
      ];

      controller.syncStudents(
        students: students,
        availableBatches: ['Class 11', 'Class 12'],
        activeBatch: 'Class 12',
      );

      // Verify studentsForSelectedBatch finds all 3 Class 12 students
      final batchStudents = controller.studentsForSelectedBatch;
      expect(batchStudents.length, 3);
      expect(batchStudents.map((s) => s.id).toList(), ['S1', 'S2', 'S3']);

      // All 3 should be selected by default
      expect(controller.selectedCount, 3);
      expect(controller.allStudentsSelected, isTrue);
      expect(controller.selectedStudentIds, containsAll(['S1', 'S2', 'S3']));
    });

    test('Toggle individual student updates selectedCount and allStudentsSelected', () {
      final students = [
        StudentModel(name: 'Alice', batch: 'Class 12', id: 'S1', password: '123'),
        StudentModel(name: 'Bob', batch: 'Class 12', id: 'S2', password: '123'),
      ];

      controller.syncStudents(
        students: students,
        availableBatches: ['Class 12'],
        activeBatch: 'Class 12',
      );

      expect(controller.selectedCount, 2);
      expect(controller.allStudentsSelected, isTrue);

      // Unselect Alice
      controller.toggleStudent('S1', false);
      expect(controller.selectedCount, 1);
      expect(controller.allStudentsSelected, isFalse);
      expect(controller.selectedStudentIds.contains('S1'), isFalse);
      expect(controller.selectedStudentIds.contains('S2'), isTrue);

      // Re-select Alice
      controller.toggleStudent('S1', true);
      expect(controller.selectedCount, 2);
      expect(controller.allStudentsSelected, isTrue);
    });

    test('Toggle all students selects/deselects all students in batch', () {
      final students = [
        StudentModel(name: 'Alice', batch: 'Class 12', id: 'S1', password: '123'),
        StudentModel(name: 'Bob', batch: 'Class 12', id: 'S2', password: '123'),
      ];

      controller.syncStudents(
        students: students,
        availableBatches: ['Class 12'],
        activeBatch: 'Class 12',
      );

      // Deselect all
      controller.toggleAllStudents(false);
      expect(controller.selectedCount, 0);
      expect(controller.allStudentsSelected, isFalse);

      // Select all
      controller.toggleAllStudents(true);
      expect(controller.selectedCount, 2);
      expect(controller.allStudentsSelected, isTrue);
    });

    test('Switching batch updates students and selection to new batch', () {
      final students = [
        StudentModel(name: 'Alice', batch: 'Class 12', id: 'S1', password: '123'),
        StudentModel(name: 'Bob', batch: 'Class 11', id: 'S2', password: '123'),
      ];

      controller.syncStudents(
        students: students,
        availableBatches: ['Class 11', 'Class 12'],
        activeBatch: 'Class 12',
      );

      expect(controller.studentsForSelectedBatch.length, 1);
      expect(controller.selectedStudentIds, contains('S1'));

      // Switch to Class 11
      controller.setBatch('Class 11');
      expect(controller.studentsForSelectedBatch.length, 1);
      expect(controller.studentsForSelectedBatch.first.name, 'Bob');
      expect(controller.selectedStudentIds, contains('S2'));
      expect(controller.selectedStudentIds.contains('S1'), isFalse);
    });
  });
}
