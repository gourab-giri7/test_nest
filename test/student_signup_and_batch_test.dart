import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/signup/controller/student_signup_controller.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/join_code_model.dart';
import 'package:test_nest/model/join_request_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pref = await SharedPreferences.getInstance();
  });

  group('StudentSignupController Validation Tests', () {
    late StudentSignupController controller;

    setUp(() {
      controller = StudentSignupController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial obscure flags are true', () {
      expect(controller.obscure, isTrue);
      expect(controller.obscureConfirm, isTrue);
    });

    test('Toggling obscure flags changes state and notifies listeners', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.toggleObscure();
      expect(controller.obscure, isFalse);
      expect(notifyCount, 1);

      controller.toggleObscureConfirm();
      expect(controller.obscureConfirm, isFalse);
      expect(notifyCount, 2);
    });

    test('Required field validator rejects null and empty values', () {
      expect(controller.requiredField(null), 'This field is required');
      expect(controller.requiredField('   '), 'This field is required');
      expect(controller.requiredField('A'), isNull);
      expect(controller.requiredField('Alex Kumar'), isNull);
    });

    test('Email validator enforces valid email structure', () {
      expect(controller.emailValidator(null), 'Email is required');
      expect(controller.emailValidator(''), 'Email is required');
      expect(controller.emailValidator('notanemail'), 'Enter a valid email');
      expect(controller.emailValidator('test@'), 'Enter a valid email');
      expect(controller.emailValidator('test@example'), 'Enter a valid email');
      expect(controller.emailValidator('student@example.com'), isNull);
      expect(controller.emailValidator('  alex@school.edu  '), isNull);
    });

    test('Password validator requires at least 6 characters', () {
      expect(controller.passwordValidator(null), 'Password is required');
      expect(controller.passwordValidator(''), 'Password is required');
      expect(
        controller.passwordValidator('12345'),
        'Minimum 6 characters required',
      );
      expect(controller.passwordValidator('123456'), isNull);
      expect(controller.passwordValidator('strongPass#1'), isNull);
    });

    test('Confirm password validator verifies equality with password', () {
      controller.password.text = 'secret123';
      expect(
        controller.confirmPasswordValidator('different'),
        'Passwords do not match',
      );
      expect(controller.confirmPasswordValidator('secret123'), isNull);
    });
  });

  group('BatchModel & JoinCode & JoinRequest Models Tests', () {
    test('BatchModel parses JSON and defaults correctly', () {
      final json = {
        'id': 'batch_123',
        'name': 'Class 11 JEE 2026',
        'class_level': 'Class 11',
        'academic_year': '2025-2026',
        'subject': 'Physics',
        'monthly_fee': 1500,
        'fee_tracking_enabled': true,
        'active_join_code': 'TN-8M4K2',
        'student_count': 35,
        'pending_request_count': 2,
        'teacher_id': 'teacher_001',
      };

      final batch = BatchModel.fromJson(json, docId: 'batch_123');
      expect(batch.id, 'batch_123');
      expect(batch.name, 'Class 11 JEE 2026');
      expect(batch.classLevel, 'Class 11');
      expect(batch.academicYear, '2025-2026');
      expect(batch.subject, 'Physics');
      expect(batch.monthlyFee, 1500.0);
      expect(batch.feeTrackingEnabled, isTrue);
      expect(batch.activeJoinCode, 'TN-8M4K2');
      expect(batch.studentCount, 35);
      expect(batch.pendingRequestCount, 2);
      expect(batch.isArchived, isFalse);

      final outJson = batch.toJson();
      expect(outJson['name'], 'Class 11 JEE 2026');
      expect(outJson['active_join_code'], 'TN-8M4K2');
    });

    test('JoinCodeModel normalizes and serializes properly', () {
      final json = {
        'code': 'tn-7k9p2',
        'teacher_id': 'teach_1',
        'teacher_name': 'Dr. Rao',
        'batch_id': 'batch_99',
        'batch_name': 'NEET Batch',
        'is_active': true,
      };

      final code = JoinCodeModel.fromJson(json);
      expect(code.code, 'TN-7K9P2');
      expect(code.teacherId, 'teach_1');
      expect(code.isActive, isTrue);

      final out = code.toJson();
      expect(out['code'], 'TN-7K9P2');
      expect(out['is_active'], isTrue);
    });

    test('JoinRequestModel status defaults and transitions correctly', () {
      final json = {
        'id': 'req_001',
        'student_uid': 'student_abc',
        'student_name': 'Alex Kumar',
        'student_email': 'alex@example.com',
        'student_phone': '+91 9999999999',
        'teacher_id': 'teach_1',
        'teacher_name': 'Dr. Rao',
        'batch_id': 'batch_99',
        'batch_name': 'NEET Batch',
        'status': 'PENDING',
      };

      final req = JoinRequestModel.fromJson(json);
      expect(req.status, 'pending');
      expect(req.studentUid, 'student_abc');
      expect(req.studentName, 'Alex Kumar');

      final approved = req.copyWith(status: 'approved');
      expect(approved.status, 'approved');
      expect(approved.id, req.id);
    });
  });

  group('BatchAndJoinCodeService Utility Tests', () {
    test(
      'generateJoiningCode produces unpredictable code with TN- prefix and 8 chars',
      () {
        final code1 = BatchAndJoinCodeService.generateJoiningCode();
        final code2 = BatchAndJoinCodeService.generateJoiningCode();

        expect(code1.startsWith('TN-'), isTrue);
        expect(code1.length, 8); // 'TN-' (3) + 5 chars = 8
        expect(code2.startsWith('TN-'), isTrue);
        expect(code1, isNot(equals(code2))); // Unpredictable / random
      },
    );

    test('normalizeCode removes whitespace and converts to uppercase', () {
      expect(BatchAndJoinCodeService.normalizeCode('  tn-7k9p2  '), 'TN-7K9P2');
      expect(BatchAndJoinCodeService.normalizeCode('tn - 7k 9p2'), 'TN-7K9P2');
      expect(BatchAndJoinCodeService.normalizeCode('Tn-8m4k2'), 'TN-8M4K2');
    });
  });

  group('Teacher Fee Tracking Preference Tests', () {
    test('TeacherData handles feeTrackingEnabled setting properly', () {
      final jsonWithFee = {
        'id': 't1',
        'name': 'Teacher 1',
        'email': 't1@example.com',
        'batch': <String>[],
        'fee_tracking_enabled': true,
      };
      final tWithFee = TeacherData.fromJson(jsonWithFee);
      expect(tWithFee.feeTrackingEnabled, isTrue);

      final jsonWithoutFee = {
        'id': 't2',
        'name': 'Teacher 2',
        'email': 't2@example.com',
        'batch': <String>[],
        'fee_tracking_enabled': false,
      };
      final tWithoutFee = TeacherData.fromJson(jsonWithoutFee);
      expect(tWithoutFee.feeTrackingEnabled, isFalse);

      final outJson = TeacherData.toJson(tWithoutFee);
      expect(outJson['fee_tracking_enabled'], isFalse);
    });
  });
}
