import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/allStudents/controller/student_controller.dart';

void main() {
  group('StudentController Unit Tests', () {
    late StudentController controller;

    setUp(() {
      controller = StudentController();
    });

    test('Initial state is all batches with empty search', () {
      expect(controller.dropDownvalue, 'all');
      expect(controller.searchValue, '');
      expect(controller.batchItems, isEmpty);
      expect(controller.filteredStudents, isEmpty);
    });

    test('Search updates search value and notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.search('  Alice ');
      expect(controller.searchValue, 'Alice');
      expect(notified, isTrue);

      // Calling again with same value does not notify needlessly
      notified = false;
      controller.search('Alice');
      expect(notified, isFalse);
    });

    test('Filter updates dropDownvalue and notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.filter('Batch A');
      expect(controller.dropDownvalue, 'Batch A');
      expect(notified, isTrue);

      // Calling again with same value does not notify
      notified = false;
      controller.filter('Batch A');
      expect(notified, isFalse);
    });

    test('Reset restores initial state and notifies listeners', () {
      controller.search('test');
      controller.filter('Batch X');

      var notified = false;
      controller.addListener(() => notified = true);

      controller.reset();
      expect(controller.dropDownvalue, 'all');
      expect(controller.searchValue, '');
      expect(notified, isTrue);
    });

    test('filterDocs is pure and does not mutate internal _allDocs', () {
      // Calling filterDocs with an empty list should not change _allDocs
      final result = controller.filterDocs([]);
      expect(result, isEmpty);
      expect(controller.filteredStudents, isEmpty);
    });
  });
}
