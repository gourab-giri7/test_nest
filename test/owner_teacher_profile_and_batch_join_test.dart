import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/core/services/batch_qr_service.dart';
import 'package:test_nest/model/join_code_model.dart';
import 'package:test_nest/model/teacher_salary_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch Join Code & QR Extraction Tests', () {
    test('extractJoiningCode accepts standard TN- format', () {
      final code = BatchQrService.extractJoiningCode('TN-7K9P2');
      expect(code, 'TN-7K9P2');
    });

    test('extractJoiningCode accepts lowercase tn- format and normalizes', () {
      final code = BatchQrService.extractJoiningCode('tn-7k9p2');
      expect(code, 'TN-7K9P2');
    });

    test('extractJoiningCode accepts URL with code parameter', () {
      final code = BatchQrService.extractJoiningCode('https://testnest.app/join?code=TN-ABC12');
      expect(code, 'TN-ABC12');
    });

    test('extractJoiningCode accepts 20-character Firestore batch document ID', () {
      const rawBatchId = 'KltYowHSAshB0tPWcetx';
      final code = BatchQrService.extractJoiningCode(rawBatchId);
      expect(code, rawBatchId);
    });

    test('normalizeCode trims whitespace and converts to uppercase', () {
      expect(BatchAndJoinCodeService.normalizeCode(' tn-7k9p2 '), 'TN-7K9P2');
    });
  });

  group('TeacherSalaryModel & SalaryPaymentEntry Tests', () {
    test('TeacherSalaryModel default calculations & balance', () {
      const model = TeacherSalaryModel(
        id: 'teacher1_2026-11',
        orgId: 'org1',
        teacherUid: 'teacher1',
        teacherName: 'John Doe',
        amount: 25000.0,
        amountPaid: 10000.0,
        month: '2026-11',
      );

      expect(model.baseSalary, 25000.0);
      expect(model.balanceDue, 15000.0);
      expect(model.isPartial, isTrue);
      expect(model.isPaid, isFalse);
      expect(model.displayMonth, '2026-11');
    });

    test('TeacherSalaryModel fully paid status derivation', () {
      const model = TeacherSalaryModel(
        id: 'teacher1_2026-11',
        orgId: 'org1',
        teacherUid: 'teacher1',
        teacherName: 'John Doe',
        amount: 25000.0,
        amountPaid: 25000.0,
        month: '2026-11',
      );

      expect(model.balanceDue, 0.0);
      expect(model.isPaid, isTrue);
      expect(model.isPending, isFalse);
    });

    test('SalaryPaymentEntry model serialization and method alias', () {
      final entry = SalaryPaymentEntry(
        paymentId: 'pay_001',
        amount: 15000.0,
        paymentDate: DateTime(2026, 11, 20),
        paymentMethod: 'Bank Transfer',
        recordedBy: 'Owner',
      );

      expect(entry.method, 'Bank Transfer');
      expect(entry.amount, 15000.0);
    });

    test('JoinCodeModel serialization & isActive check', () {
      final model = JoinCodeModel(
        code: 'TN-7K9P2',
        teacherId: 't1',
        teacherName: 'Teacher 1',
        batchId: 'KltYowHSAshB0tPWcetx',
        batchName: 'Physics Batch',
        orgId: 'org1',
        isActive: true,
      );

      expect(model.isActive, isTrue);
      final json = model.toJson();
      expect(json['code'], 'TN-7K9P2');
      expect(json['batch_id'], 'KltYowHSAshB0tPWcetx');
    });
  });
}
