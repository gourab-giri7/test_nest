import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/payment_model.dart';

void main() {
  group('Fee Record & Payment Models Unit Tests', () {
    test(
      'FeeRecord calculates status correctly based on amountDue and amountPaid',
      () {
        final now = DateTime.now();
        final futureDue = now.add(const Duration(days: 10));

        final unpaid = FeeRecord(
          billingMonth: '2026-10',
          studentId: 'ST001',
          studentName: 'John Doe',
          amountDue: 1500,
          amountPaid: 0,
          dueDate: futureDue,
          createdAt: now,
          updatedAt: now,
        );
        expect(unpaid.balance, 1500);
        expect(unpaid.status, 'unpaid');

        final partial = unpaid.copyWith(amountPaid: 500);
        expect(partial.balance, 1000);
        expect(partial.status, 'partial');

        final fullyPaid = unpaid.copyWith(amountPaid: 1500);
        expect(fullyPaid.balance, 0);
        expect(fullyPaid.status, 'paid');

        final overPaid = unpaid.copyWith(amountPaid: 2000);
        expect(overPaid.balance, 0);
        expect(overPaid.status, 'paid');
      },
    );

    test('Overdue status is detected when past due date and unpaid', () {
      final now = DateTime.now();
      final pastDue = now.subtract(const Duration(days: 5));

      final overdueRecord = FeeRecord(
        billingMonth: '2026-09',
        studentId: 'ST002',
        studentName: 'Jane Smith',
        amountDue: 1200,
        amountPaid: 0,
        dueDate: pastDue,
        createdAt: pastDue.subtract(const Duration(days: 15)),
        updatedAt: pastDue,
      );

      expect(overdueRecord.status, 'overdue');
    });

    test('Serialization and deserialization of FeeRecord preserves fields', () {
      final now = DateTime.now();
      final record = FeeRecord(
        billingMonth: '2026-10',
        studentId: 'ST003',
        studentName: 'Alice',
        amountDue: 2000,
        amountPaid: 1000,
        dueDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final json = record.toJson();
      final restored = FeeRecord.fromJson(json, docId: '2026-10');

      expect(restored.billingMonth, '2026-10');
      expect(restored.studentId, 'ST003');
      expect(restored.studentName, 'Alice');
      expect(restored.amountDue, 2000);
      expect(restored.amountPaid, 1000);
    });

    test('PaymentEntry validates serialization and properties', () {
      final now = DateTime.now();
      final payment = PaymentEntry(
        paymentId: 'PAY001',
        amount: 1500,
        paidAt: now,
        method: 'upi',
        recordedBy: 'teacher_123',
        receiptRef: 'UPI-REF-9988',
        note: 'GPay transfer',
      );

      expect(payment.amount, 1500);
      expect(PaymentEntry.methodLabel(payment.method), 'UPI');
      expect(payment.isReversal, isFalse);

      final map = payment.toJson();
      expect(map['amount'], 1500);
      expect(map['method'], 'upi');
      expect(map['receipt_ref'], 'UPI-REF-9988');

      final restored = PaymentEntry.fromJson(map, docId: 'PAY001');
      expect(restored.paymentId, 'PAY001');
      expect(restored.amount, 1500);
      expect(restored.method, 'upi');
      expect(restored.receiptRef, 'UPI-REF-9988');

      final reversal = PaymentEntry(
        paymentId: 'REV001',
        amount: -500,
        paidAt: now,
        method: 'upi',
        recordedBy: 'teacher_123',
      );
      expect(reversal.isReversal, isTrue);
    });
  });
}
