import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/payment_model.dart';

void main() {
  group('Fee Record & Payment Models Unit Tests', () {
    test('FeeRecord calculates status correctly based on amountDue and amountPaid', () {
      final now = DateTime.now();
      final futureDue = now.add(const Duration(days: 10));

      final unpaid = FeeRecord(
        id: '2026-10',
        billingMonth: '2026-10',
        studentId: 'ST001',
        studentName: 'John Doe',
        batch: 'Batch A',
        amountDue: 1500,
        amountPaid: 0,
        status: FeeStatus.unpaid,
        dueDate: futureDue,
        createdAt: now,
        updatedAt: now,
      );
      expect(unpaid.balance, 1500);
      expect(unpaid.isFullyPaid, isFalse);
      expect(unpaid.effectiveStatus, FeeStatus.unpaid);

      final partial = unpaid.copyWith(amountPaid: 500);
      expect(partial.balance, 1000);
      expect(partial.isFullyPaid, isFalse);
      expect(partial.effectiveStatus, FeeStatus.partial);

      final fullyPaid = unpaid.copyWith(amountPaid: 1500);
      expect(fullyPaid.balance, 0);
      expect(fullyPaid.isFullyPaid, isTrue);
      expect(fullyPaid.effectiveStatus, FeeStatus.paid);

      final overPaid = unpaid.copyWith(amountPaid: 2000);
      expect(overPaid.balance, 0);
      expect(overPaid.isFullyPaid, isTrue);
      expect(overPaid.effectiveStatus, FeeStatus.paid);
    });

    test('Overdue status is detected when past due date and unpaid', () {
      final now = DateTime.now();
      final pastDue = now.subtract(const Duration(days: 5));

      final overdueRecord = FeeRecord(
        id: '2026-09',
        billingMonth: '2026-09',
        studentId: 'ST002',
        studentName: 'Jane Smith',
        batch: 'Batch B',
        amountDue: 1200,
        amountPaid: 0,
        status: FeeStatus.overdue,
        dueDate: pastDue,
        createdAt: pastDue.subtract(const Duration(days: 15)),
        updatedAt: pastDue,
      );

      expect(overdueRecord.effectiveStatus, FeeStatus.overdue);
    });

    test('Serialization and deserialization of FeeRecord preserves all fields', () {
      final now = DateTime.now();
      final record = FeeRecord(
        id: '2026-10',
        billingMonth: '2026-10',
        studentId: 'ST003',
        studentName: 'Alice',
        batch: 'Morning',
        amountDue: 2000,
        amountPaid: 1000,
        status: FeeStatus.partial,
        dueDate: now,
        createdAt: now,
        updatedAt: now,
        notes: 'Monthly fee installment',
      );

      final json = record.toMap();
      final restored = FeeRecord.fromMap(json, '2026-10');

      expect(restored.id, '2026-10');
      expect(restored.studentId, 'ST003');
      expect(restored.studentName, 'Alice');
      expect(restored.batch, 'Morning');
      expect(restored.amountDue, 2000);
      expect(restored.amountPaid, 1000);
      expect(restored.notes, 'Monthly fee installment');
    });

    test('PaymentModel validates serialization and properties', () {
      final now = DateTime.now();
      final payment = PaymentModel(
        id: 'PAY001',
        amount: 1500,
        paidAt: now,
        method: PaymentMethod.upi,
        recordedBy: 'teacher_123',
        receiptReference: 'UPI-REF-9988',
        note: 'GPay transfer',
      );

      expect(payment.amount, 1500);
      expect(payment.methodString, 'UPI');

      final map = payment.toMap();
      expect(map['amount'], 1500);
      expect(map['method'], 'upi');
      expect(map['receiptReference'], 'UPI-REF-9988');

      final restored = PaymentModel.fromMap(map, 'PAY001');
      expect(restored.id, 'PAY001');
      expect(restored.amount, 1500);
      expect(restored.method, PaymentMethod.upi);
      expect(restored.receiptReference, 'UPI-REF-9988');
    });
  });
}
