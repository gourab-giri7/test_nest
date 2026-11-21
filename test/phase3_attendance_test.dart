import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/batch_attendance_controller.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/attendance/controller/student_attendance_controller.dart';
import 'package:test_nest/model/attendance_model.dart';

void main() {
  group('AttendanceRecordModel & Deterministic ID', () {
    test('generateId creates deterministic key and handles special chars', () {
      final id1 = AttendanceRecordModel.generateId(
        batchId: 'batch-123',
        studentId: 'student-456',
        dateKey: '2026-11-18',
      );
      final id2 = AttendanceRecordModel.generateId(
        batchId: 'batch-123',
        studentId: 'student-456',
        dateKey: '2026-11-18',
      );
      expect(id1, equals(id2));
      expect(id1, equals('batch-123_student-456_2026-11-18'));

      final idSpecial = AttendanceRecordModel.generateId(
        batchId: 'batch/123@#',
        studentId: 'student:999',
        dateKey: '2026-11-18',
      );
      expect(idSpecial.contains('/'), isFalse);
      expect(idSpecial.contains('@'), isFalse);
      expect(idSpecial.contains(':'), isFalse);
    });

    test(
      'formatDateKey formats date as local YYYY-MM-DD avoiding UTC offset issues',
      () {
        final date = DateTime(2026, 5, 9, 23, 45);
        final key = AttendanceRecordModel.formatDateKey(date);
        expect(key, equals('2026-05-09'));

        final singleDigitDate = DateTime(2026, 1, 3, 1, 15);
        expect(
          AttendanceRecordModel.formatDateKey(singleDigitDate),
          equals('2026-01-03'),
        );
      },
    );

    test('isAttended counts present and late as attended', () {
      final now = DateTime.now();
      const dKey = '2026-11-18';

      final presentRecord = AttendanceRecordModel(
        id: 'id1',
        teacherId: 't1',
        batchId: 'b1',
        batchName: 'Batch A',
        studentId: 's1',
        studentName: 'Alice',
        date: now,
        dateKey: dKey,
        status: AttendanceStatus.present,
        markedBy: 't1',
        markedByName: 'Teacher 1',
      );
      expect(presentRecord.isPresent, isTrue);
      expect(presentRecord.isAbsent, isFalse);
      expect(presentRecord.isLate, isFalse);
      expect(presentRecord.isAttended, isTrue);

      final lateRecord = presentRecord.copyWith(status: AttendanceStatus.late);
      expect(lateRecord.isPresent, isFalse);
      expect(lateRecord.isAbsent, isFalse);
      expect(lateRecord.isLate, isTrue);
      expect(lateRecord.isAttended, isTrue);

      final absentRecord = presentRecord.copyWith(
        status: AttendanceStatus.absent,
      );
      expect(absentRecord.isPresent, isFalse);
      expect(absentRecord.isAbsent, isTrue);
      expect(absentRecord.isLate, isFalse);
      expect(absentRecord.isAttended, isFalse);
    });

    test('toMap and fromMap serialization roundtrip', () {
      final testDate = DateTime(2026, 11, 18, 10, 0);
      final record = AttendanceRecordModel(
        id: 'b1_s1_2026-11-18',
        organizationId: 'org1',
        teacherId: 't1',
        batchId: 'b1',
        batchName: 'Physics XI',
        studentId: 's1',
        studentName: 'Bob',
        date: testDate,
        dateKey: '2026-11-18',
        status: AttendanceStatus.late,
        remarks: 'Bus delay',
        markedBy: 't1',
        markedByName: 'Prof. X',
        createdAt: testDate,
      );

      final map = record.toMap();
      expect(map['id'], equals('b1_s1_2026-11-18'));
      expect(map['organizationId'], equals('org1'));
      expect(map['status'], equals('late'));
      expect(map['remarks'], equals('Bus delay'));

      final parsed = AttendanceRecordModel.fromMap(map, 'b1_s1_2026-11-18');
      expect(parsed.id, equals(record.id));
      expect(parsed.organizationId, equals(record.organizationId));
      expect(parsed.studentName, equals(record.studentName));
      expect(parsed.status, equals(AttendanceStatus.late));
      expect(parsed.remarks, equals('Bus delay'));
      expect(parsed.isAttended, isTrue);
    });
  });

  group('StudentAttendanceSummary & Percentage Formula', () {
    test('Attendance percentage formula: (Present + Late) / Total * 100', () {
      final now = DateTime.now();
      AttendanceRecordModel makeRecord(String status, String dKey) {
        return AttendanceRecordModel(
          id: 'b1_s1_$dKey',
          teacherId: 't1',
          batchId: 'b1',
          batchName: 'Batch 1',
          studentId: 's1',
          studentName: 'Charlie',
          date: now,
          dateKey: dKey,
          status: status,
          markedBy: 't1',
          markedByName: 'T1',
        );
      }

      // 3 present, 1 late, 1 absent -> total 5, attended 4 -> 80%
      final records = [
        makeRecord(AttendanceStatus.present, '2026-11-01'),
        makeRecord(AttendanceStatus.present, '2026-11-02'),
        makeRecord(AttendanceStatus.present, '2026-11-03'),
        makeRecord(AttendanceStatus.late, '2026-11-04'),
        makeRecord(AttendanceStatus.absent, '2026-11-05'),
      ];

      final summary = StudentAttendanceSummary.fromRecords(
        studentId: 's1',
        studentName: 'Charlie',
        records: records,
      );

      expect(summary.totalClasses, equals(5));
      expect(summary.presentCount, equals(3));
      expect(summary.lateCount, equals(1));
      expect(summary.absentCount, equals(1));
      expect(summary.attendedCount, equals(4));
      expect(summary.attendancePercentage, equals(80.0));
    });

    test('0 total classes returns 100.0% attendance', () {
      final summary = StudentAttendanceSummary.fromRecords(
        studentId: 's1',
        studentName: 'David',
        records: [],
      );
      expect(summary.totalClasses, equals(0));
      expect(summary.attendancePercentage, equals(100.0));
    });

    test('All absent returns 0.0% attendance', () {
      final now = DateTime.now();
      final records = [
        AttendanceRecordModel(
          id: 'id1',
          teacherId: 't1',
          batchId: 'b1',
          batchName: 'Batch',
          studentId: 's1',
          studentName: 'Dave',
          date: now,
          dateKey: '2026-11-01',
          status: AttendanceStatus.absent,
          markedBy: 't1',
          markedByName: 'T',
        ),
      ];
      final summary = StudentAttendanceSummary.fromRecords(
        studentId: 's1',
        studentName: 'Dave',
        records: records,
      );
      expect(summary.attendancePercentage, equals(0.0));
    });
  });

  group('TenantPathResolver Attendance Paths', () {
    test(
      'Resolves organization attendance paths correctly in Institute Mode',
      () {
        final resolver = TenantPathResolver(
          explicitOrgId: 'org_test_123',
          explicitIsInstitute: true,
        );

        expect(
          resolver.attendancePath(),
          equals('organizations/org_test_123/attendance'),
        );
        expect(
          resolver.attendanceDocPath('rec_456'),
          equals('organizations/org_test_123/attendance/rec_456'),
        );
      },
    );

    test(
      'Resolves single teacher attendance paths correctly in Single Teacher Mode',
      () {
        final resolver = TenantPathResolver(
          explicitOrgId: '',
          explicitIsInstitute: false,
        );

        expect(
          resolver.attendancePath('teacher_789'),
          equals('user/teacher_789/attendance'),
        );
        expect(
          resolver.attendanceDocPath('rec_456', 'teacher_789'),
          equals('user/teacher_789/attendance/rec_456'),
        );
      },
    );
  });

  group('BatchAttendanceController In-Memory State & Dirty Guard', () {
    test('Initial controller state is clean and empty', () {
      final controller = BatchAttendanceController();
      expect(controller.batches, isEmpty);
      expect(controller.selectedBatch, isNull);
      expect(controller.students, isEmpty);
      expect(controller.attendanceMap, isEmpty);
      expect(controller.isDirty, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.isSaving, isFalse);
    });

    test('Marking status or remarks flags dirty state', () {
      final controller = BatchAttendanceController();
      expect(controller.isDirty, isFalse);

      controller.markStatus('student_1', AttendanceStatus.present);
      expect(controller.isDirty, isTrue);
      expect(
        controller.attendanceMap['student_1'],
        equals(AttendanceStatus.present),
      );
      expect(controller.presentCount, equals(1));

      controller.markRemarks('student_1', 'Arrived with doctor note');
      expect(
        controller.remarksMap['student_1'],
        equals('Arrived with doctor note'),
      );

      // Discarding changes reverts to saved state
      controller.discardChanges();
      expect(controller.isDirty, isFalse);
      expect(controller.attendanceMap, isEmpty);
      expect(controller.remarksMap, isEmpty);
    });
  });

  group('StudentAttendanceController Filters', () {
    test('Filters records by status correctly', () {
      final controller = StudentAttendanceController();
      final now = DateTime.now();

      final r1 = AttendanceRecordModel(
        id: '1',
        teacherId: 't1',
        batchId: 'b1',
        batchName: 'Batch A',
        studentId: 's1',
        studentName: 'Sam',
        date: now,
        dateKey: '2026-11-01',
        status: AttendanceStatus.present,
        markedBy: 't1',
        markedByName: 'T',
      );
      final r2 = r1.copyWith(id: '2', status: AttendanceStatus.absent);
      final r3 = r1.copyWith(id: '3', status: AttendanceStatus.late);

      // Using private field injection via load simulation
      controller.allRecords.addAll([r1, r2, r3]);

      controller.setStatusFilter(AttendanceStatus.present);
      expect(controller.filteredRecords.length, equals(1));
      expect(controller.filteredRecords.first.status, equals('present'));

      controller.setStatusFilter(AttendanceStatus.absent);
      expect(controller.filteredRecords.length, equals(1));
      expect(controller.filteredRecords.first.status, equals('absent'));

      controller.clearFilters();
      expect(controller.filteredRecords.length, equals(3));
    });
  });
}
