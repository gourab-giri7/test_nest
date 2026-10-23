import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pref = await SharedPreferences.getInstance();
    teacherData = null;
    studentData = null;
  });

  group('LoginController & Session Lifecycle Tests', () {
    test('Default constructor starts in logged out state without GlobalKey', () {
      final controller = LoginController();

      expect(controller.isLogined, isFalse);
      expect(controller.role, isEmpty);
      expect(controller.ispressed, isFalse);
      expect(controller.isStudentLogin, isFalse);
      expect(controller.obscurePassword, isTrue);
    });

    test('Custom constructor supports restored session state', () {
      final controller = LoginController(
        initialIsLogined: true,
        initialRole: 'teacher',
      );

      expect(controller.isLogined, isTrue);
      expect(controller.role, equals('teacher'));
    });

    test('Field validation rejects null or empty and accepts valid text', () {
      final controller = LoginController();

      expect(controller.fieldeValidation(null), isNotNull);
      expect(controller.fieldeValidation(''), isNotNull);
      expect(controller.fieldeValidation('valid_id'), isNull);
    });

    test('Switching role clears text controllers and updates state', () {
      final controller = LoginController();
      controller.id.text = 'old_id';
      controller.password.text = 'old_password';

      controller.changeLoginToStudent();

      expect(controller.isStudentLogin, isTrue);
      expect(controller.id.text, isEmpty);
      expect(controller.password.text, isEmpty);

      controller.toggeFields();
      expect(controller.isStudentLogin, isFalse);
    });

    test('Password obscure toggle works as expected', () {
      final controller = LoginController();
      expect(controller.obscurePassword, isTrue);

      controller.toggelObscurePassword();
      expect(controller.obscurePassword, isFalse);

      controller.toggelObscurePassword();
      expect(controller.obscurePassword, isTrue);
    });

    test('loadTeacherData and loadStudentData store session to SharedPreferences', () async {
      await loadTeacherData('T123', 'pass123');

      expect(pref.getString('id'), equals('T123'));
      expect(pref.getString('password'), equals('pass123'));
      expect(pref.getString('role'), equals('teacher'));
      expect(pref.getBool('isLogined'), isTrue);

      await loadStudentData('T123', 'S456', 'pass456');

      expect(pref.getString('teacherId'), equals('T123'));
      expect(pref.getString('id'), equals('S456'));
      expect(pref.getString('password'), equals('pass456'));
      expect(pref.getString('role'), equals('student'));
      expect(pref.getBool('isLogined'), isTrue);
    });

    test('TeacherData.updateTeacherLocalData saves complete session to SharedPreferences', () async {
      teacherData = TeacherData(
        name: 'John Doe',
        password: 'pass',
        id: 'T1',
        teacherId: 'T1',
        lastStdId: '5',
        lastExamId: '3',
        batch: ['Batch A', 'Batch B'],
      );

      await TeacherData.updateTeacherLocalData();

      expect(pref.getBool('isLogined'), isTrue);
      expect(pref.getString('role'), equals('teacher'));
      expect(pref.getString('id'), equals('T1'));
      expect(pref.getString('teacherData'), isNotNull);
      expect(pref.getString('teacherData'), contains('John Doe'));
    });

    test('StudentData.updateStudentLocalData saves complete session to SharedPreferences', () async {
      studentData = StudentData(
        name: 'Jane Student',
        password: 'spass',
        id: 'S1',
        teacherId: 'T1',
        batch: 'Batch A',
        teacherName: 'John Doe',
      );

      await StudentData.updateStudentLocalData();

      expect(pref.getBool('isLogined'), isTrue);
      expect(pref.getString('role'), equals('student'));
      expect(pref.getString('id'), equals('S1'));
      expect(pref.getString('teacherId'), equals('T1'));
      expect(pref.getString('studentData'), isNotNull);
      expect(pref.getString('studentData'), contains('Jane Student'));
    });

    test('StudentData.fromJson resolves ID correctly from id, student_id, or docId', () {
      final s1 = StudentData.fromJson({'id': 'S1', 'name': 'A'});
      expect(s1.id, equals('S1'));

      final s2 = StudentData.fromJson({'student_id': 'S2', 'name': 'B'});
      expect(s2.id, equals('S2'));

      final s3 = StudentData.fromJson({'name': 'C'}, docId: 'DOC_S3');
      expect(s3.id, equals('DOC_S3'));
    });

    test('changeLoginToTeacher and changeLoginToStudent clear inputs and switch modes', () {
      final controller = LoginController();
      controller.id.text = 'my_id';
      controller.password.text = 'secret';
      controller.teacherId.text = 'T_ID';

      controller.changeLoginToStudent();
      expect(controller.isStudentLogin, isTrue);
      expect(controller.id.text, isEmpty);
      expect(controller.password.text, isEmpty);
      expect(controller.teacherId.text, isEmpty);

      controller.id.text = 'new_id';
      controller.password.text = 'new_pass';
      controller.teacherId.text = 'new_t';

      controller.changeLoginToTeacher();
      expect(controller.isStudentLogin, isFalse);
      expect(controller.id.text, isEmpty);
      expect(controller.password.text, isEmpty);
      expect(controller.teacherId.text, isEmpty);
    });
  });
}
