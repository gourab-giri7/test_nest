import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/signup/controller/teacher_signup_controller.dart';

void main() {
  group('TeacherSignupController Validation Unit Tests', () {
    late TeacherSignupController controller;

    setUp(() {
      controller = TeacherSignupController();
    });

    test('Initial visibility flags are obscured', () {
      expect(controller.obscure, isTrue);
      expect(controller.obscureConfirm, isTrue);
      expect(controller.loading, isFalse);
    });

    test('Toggling obscure flags notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.toggleObscure();
      expect(controller.obscure, isFalse);
      expect(notified, isTrue);

      notified = false;
      controller.toggleObscureConfirm();
      expect(controller.obscureConfirm, isFalse);
      expect(notified, isTrue);
    });

    test('Required field validator rejects null or empty strings', () {
      expect(controller.requiredField(null), 'This field is required');
      expect(controller.requiredField(''), 'This field is required');
      expect(controller.requiredField('   '), 'This field is required');
      expect(controller.requiredField('Physics Academy'), isNull);
    });

    test('Email validator enforces valid email structure', () {
      expect(controller.emailValidator(null), 'Email is required');
      expect(controller.emailValidator(''), 'Email is required');
      expect(controller.emailValidator('invalidEmail'), 'Enter a valid email');
      expect(controller.emailValidator('teacher@'), 'Enter a valid email');
      expect(
        controller.emailValidator('teacher@example'),
        'Enter a valid email',
      );
      expect(controller.emailValidator('teacher@testnest.com'), isNull);
    });

    test('Password validator requires minimum 6 characters', () {
      expect(controller.passwordValidator(null), 'Password is required');
      expect(controller.passwordValidator(''), 'Password is required');
      expect(
        controller.passwordValidator('12345'),
        'Minimum 6 characters required',
      );
      expect(controller.passwordValidator('123456'), isNull);
      expect(controller.passwordValidator('SecretPass!'), isNull);
    });

    test(
      'Confirm password validator verifies equality with password controller',
      () {
        controller.password.text = 'SuperSecret123';

        expect(
          controller.confirmPasswordValidator('WrongPass'),
          'Passwords do not match',
        );
        expect(
          controller.confirmPasswordValidator(''),
          'Passwords do not match',
        );
        expect(controller.confirmPasswordValidator('SuperSecret123'), isNull);
      },
    );
  });
}
