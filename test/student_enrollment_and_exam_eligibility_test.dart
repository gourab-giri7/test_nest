import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/model/exam_model.dart';

void main() {
  group('StudentEnrollment Model Tests', () {
    test('Correctly parses enrolled_at, approved_at, and status', () {
      final json = {
        'student_id': 'stud_123',
        'teacher_id': 'teacher_1',
        'teacher_name': 'Prof. John',
        'batch_id': 'batch_101',
        'batch_name': 'Physics Alpha',
        'status': 'active',
        'enrolled_at': '2026-05-10T10:00:00.000Z',
      };

      final enrollment = StudentEnrollment.fromJson(json);
      expect(enrollment.teacherId, 'teacher_1');
      expect(enrollment.teacherName, 'Prof. John');
      expect(enrollment.batchId, 'batch_101');
      expect(enrollment.batchName, 'Physics Alpha');
      expect(enrollment.status, 'active');
      expect(enrollment.isActive, true);
      expect(enrollment.isPending, false);
      expect(enrollment.isRejected, false);
      expect(enrollment.isRemoved, false);
      expect(enrollment.enrolledAt, DateTime.parse('2026-05-10T10:00:00.000Z'));
    });

    test('Correctly identifies status flags for pending, rejected, and removed', () {
      final pending = StudentEnrollment.fromJson({
        'student_id': 'stud_1',
        'teacher_id': 't1',
        'teacher_name': 'T1',
        'batch_id': 'b1',
        'batch_name': 'B1',
        'status': 'pending',
      });
      expect(pending.isActive, false);
      expect(pending.isPending, true);

      final rejected = StudentEnrollment.fromJson({
        'student_id': 'stud_1',
        'teacher_id': 't1',
        'teacher_name': 'T1',
        'batch_id': 'b1',
        'batch_name': 'B1',
        'status': 'rejected',
      });
      expect(rejected.isActive, false);
      expect(rejected.isRejected, true);

      final removed = StudentEnrollment.fromJson({
        'student_id': 'stud_1',
        'teacher_id': 't1',
        'teacher_name': 'T1',
        'batch_id': 'b1',
        'batch_name': 'B1',
        'status': 'removed',
      });
      expect(removed.isActive, false);
      expect(removed.isRemoved, true);

      final removedByTeacher = StudentEnrollment.fromJson({
        'student_id': 'stud_1',
        'teacher_id': 't1',
        'teacher_name': 'T1',
        'batch_id': 'b1',
        'batch_name': 'B1',
        'status': 'removed_by_teacher',
      });
      expect(removedByTeacher.isActive, false);
      expect(removedByTeacher.isRemoved, true);
    });
  });

  group('StudentData Multi-Teacher & Active Enrollments Tests', () {
    test('Filters out removed and pending enrollments in activeEnrollments and getters', () {
      final sData = StudentData(
        id: 'stud_123',
        name: 'Alice Wonder',
        teacherId: 'teacher_A',
        teacherName: 'Dr. Alan',
        batch: 'Math Advanced',
        enrollments: [
          StudentEnrollment(
            studentId: 'stud_123',
            teacherId: 'teacher_A',
            teacherName: 'Dr. Alan',
            batchId: 'batch_A1',
            batchName: 'Math Advanced',
            status: 'active',
            enrolledAt: DateTime(2026, 1, 15),
          ),
          StudentEnrollment(
            studentId: 'stud_123',
            teacherId: 'teacher_B',
            teacherName: 'Prof. Beth',
            batchId: 'batch_B1',
            batchName: 'Chemistry Core',
            status: 'removed',
            enrolledAt: DateTime(2026, 1, 10),
          ),
          StudentEnrollment(
            studentId: 'stud_123',
            teacherId: 'teacher_C',
            teacherName: 'Prof. Charlie',
            batchId: 'batch_C1',
            batchName: 'Biology Bio',
            status: 'pending',
          ),
        ],
      );

      expect(sData.hasActiveEnrollment, true);
      expect(sData.activeEnrollments.length, 1);
      expect(sData.activeEnrollments.first.teacherId, 'teacher_A');

      // allTeacherIds and allBatchNames should ONLY include active enrollments
      expect(sData.allTeacherIds, ['teacher_A']);
      expect(sData.allTeacherNames, ['Dr. Alan']);
      expect(sData.allBatchNames, ['Math Advanced']);

      // getEnrollmentForTeacher
      expect(sData.getEnrollmentForTeacher('teacher_A')?.batchId, 'batch_A1');
      expect(sData.getEnrollmentForTeacher('teacher_B')?.status, 'removed');
    });

    test('Returns hasActiveEnrollment false when no active enrollments exist', () {
      final sData = StudentData(
        id: 'stud_999',
        name: 'Bob New',
        teacherId: 'teacher_A',
        teacherName: 'Teacher A',
        batch: 'Batch A',
        enrollments: [
          StudentEnrollment(
            studentId: 'stud_999',
            teacherId: 'teacher_A',
            teacherName: 'Teacher A',
            batchId: 'batch_A',
            batchName: 'Batch A',
            status: 'pending',
          ),
          StudentEnrollment(
            studentId: 'stud_999',
            teacherId: 'teacher_B',
            teacherName: 'Teacher B',
            batchId: 'batch_B',
            batchName: 'Batch B',
            status: 'rejected',
          ),
        ],
      );

      expect(sData.hasActiveEnrollment, false);
      expect(sData.activeEnrollments, isEmpty);
      expect(sData.allTeacherIds, isEmpty);
    });
  });

  group('ExamModel Eligibility & Enrollment Date Access Restriction', () {
    final enrollmentDate = DateTime(2026, 6, 1, 10, 0); // Enrolled June 1, 2026
    final activeEnrollment = StudentEnrollment(
      studentId: 'stud_1',
      teacherId: 'teacher_1',
      teacherName: 'Teacher One',
      batchId: 'batch_1',
      batchName: 'Batch One',
      status: 'active',
      enrolledAt: enrollmentDate,
    );

    final inactiveEnrollment = StudentEnrollment(
      studentId: 'stud_1',
      teacherId: 'teacher_1',
      teacherName: 'Teacher One',
      batchId: 'batch_1',
      batchName: 'Batch One',
      status: 'removed',
      enrolledAt: enrollmentDate,
    );

    test('Denies exam access if student enrollment is inactive or removed', () {
      final exam = ExamModel(
        examId: 'exam_1',
        examName: 'Modern Physics',
        fullMarks: '100',
        examKey: 'KEY123',
        instruction: 'None',
        batch: 'Batch One',
        examStart: DateTime(2026, 6, 5, 10, 0),
        examEnd: DateTime(2026, 6, 5, 12, 0),
        questions: const [],
        assignedStudentIds: const ['stud_1'],
        createdAt: DateTime(2026, 6, 5),
      );

      final isEligible = exam.isEligibleForStudent(
        studentId: 'stud_1',
        enrollment: inactiveEnrollment,
      );

      expect(isEligible, false);
    });

    test('Denies exam access if exam was scheduled prior to enrollment date', () {
      final examBeforeEnrollment = ExamModel(
        examId: 'exam_prev',
        examName: 'May Midterm',
        fullMarks: '50',
        examKey: 'KEY123',
        instruction: 'None',
        batch: 'Batch One',
        examStart: DateTime(2026, 5, 15, 10, 0), // May 15, BEFORE June 1 enrollment!
        examEnd: DateTime(2026, 5, 15, 12, 0),
        questions: const [],
        assignedStudentIds: const ['stud_1'],
        createdAt: DateTime(2026, 5, 15),
      );

      final isEligible = examBeforeEnrollment.isEligibleForStudent(
        studentId: 'stud_1',
        enrollment: activeEnrollment,
        hasSubmitted: false,
      );

      expect(isEligible, false, reason: 'Exams prior to enrollment date must be blocked');
    });

    test('Allows exam access if exam was scheduled after student enrolled', () {
      final examAfterEnrollment = ExamModel(
        examId: 'exam_future',
        examName: 'June Final',
        fullMarks: '100',
        examKey: 'KEY123',
        instruction: 'None',
        batch: 'Batch One',
        examStart: DateTime(2026, 6, 15, 10, 0), // June 15, AFTER June 1 enrollment
        examEnd: DateTime(2026, 6, 15, 12, 0),
        questions: const [],
        assignedStudentIds: const ['stud_1'],
        createdAt: DateTime(2026, 6, 15),
      );

      final isEligible = examAfterEnrollment.isEligibleForStudent(
        studentId: 'stud_1',
        enrollment: activeEnrollment,
        hasSubmitted: false,
      );

      expect(isEligible, true);
    });

    test('Preserves historical results if student has already submitted exam', () {
      final pastSubmittedExam = ExamModel(
        examId: 'exam_past',
        examName: 'Special Evaluation',
        fullMarks: '100',
        examKey: 'KEY123',
        instruction: 'None',
        batch: 'Batch One',
        examStart: DateTime(2026, 5, 1, 10, 0), // Prior to enrollment date
        examEnd: DateTime(2026, 5, 1, 12, 0),
        questions: const [],
        assignedStudentIds: const ['stud_1'],
        createdAt: DateTime(2026, 5, 1),
      );

      // Even if date is before enrollment, if the student already submitted it, results must be preserved
      final isEligible = pastSubmittedExam.isEligibleForStudent(
        studentId: 'stud_1',
        enrollment: activeEnrollment,
        hasSubmitted: true,
      );

      expect(isEligible, true, reason: 'Historical submissions must be preserved');
    });

    test('Denies exam access if student is not in assigned students list', () {
      final unassignedExam = ExamModel(
        examId: 'exam_unassigned',
        examName: 'Selected Students Exam',
        fullMarks: '100',
        examKey: 'KEY123',
        instruction: 'None',
        batch: 'Batch One',
        examStart: DateTime(2026, 6, 20, 10, 0),
        examEnd: DateTime(2026, 6, 20, 12, 0),
        questions: const [],
        assignedStudentIds: const ['other_student_99'], // stud_1 is NOT assigned
        createdAt: DateTime(2026, 6, 20),
      );

      final isEligible = unassignedExam.isEligibleForStudent(
        studentId: 'stud_1',
        enrollment: activeEnrollment,
      );

      expect(isEligible, false);
    });
  });
}
