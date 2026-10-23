import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/auth/loginFeatureStudents/student_login_feature.dart';
import 'package:test_nest/feature/auth/loginFeatureTeacher/teacher_login_feature.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/login_screen.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/dashboard/students_dashboard_screen.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/allStudents/controller/student_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/controller/create_exam_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/dashboard/teacher_dashboard_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/exams/controller/teacher_exam_controller.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';

class LoginController extends ChangeNotifier {
  TextEditingController teacherId = TextEditingController();
  TextEditingController id = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isStudentLogin = false;
  bool obscurePassword = true;
  bool ispressed = false;

  // ------------- for main
  bool isLogined = false;
  String role = "";

  LoginController({bool initialIsLogined = false, String initialRole = ""})
    : isLogined = initialIsLogined,
      role = initialRole;

  void changeLoginToStudent() {
    isStudentLogin = true;
    id.clear();
    password.clear();
    teacherId.clear();
    notifyListeners();
  }

  void changeLoginToTeacher() {
    isStudentLogin = false;
    id.clear();
    password.clear();
    teacherId.clear();
    notifyListeners();
  }

  void changeLoginState(bool isLogin, String rolee) {
    isLogined = isLogin;
    role = rolee;
    notifyListeners();
  }

  // ---------------- toggel show password
  void toggelLoginButton() {
    ispressed = !ispressed;
    notifyListeners();
  }

  // ---------------- toggel show password
  void toggeFields() {
    isStudentLogin = !isStudentLogin;
    notifyListeners();
  }

  // ---------------- toggel show password
  void toggelObscurePassword() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  // ----------- field validation
  String? fieldeValidation(String? value) {
    if (value == null || value.isEmpty) {
      return "Please fill the feild before login";
    } else {
      return null;
    }
  }

  // -------------- login function
  Future<void> login(BuildContext context) async {
    if (ispressed) return;
    ispressed = true;
    notifyListeners();

    try {
      final userId = id.text.trim();
      final userpassword = password.text.trim();

      if (!isStudentLogin) {
        // Teacher login via Firebase Auth
        final result = await TeacherLoginFeature.teacherlogin(
          userId,
          userpassword,
        );
        if (!context.mounted) return;

        if (result == 200) {
          await saveTeacherSession();
          isLogined = true;
          role = "teacher";
          ispressed = false;
          notifyListeners();
          customSnackbar(
            context: context,
            message: "Login successful",
            color: Colors.green,
            ico: Icons.login,
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const TeacherDashboardScreen(),
            ),
            (route) => false,
          );
          return;
        } else if (result == 404) {
          customSnackbar(
            context: context,
            message: "Invalid email or password",
            color: Colors.red,
            ico: Icons.error,
          );
        } else {
          customSnackbar(
            context: context,
            message: "Something went wrong, please try again later",
            color: Colors.orange,
            ico: Icons.info,
          );
        }
      } else {
        // Student login — no password needed
        final teacherid = teacherId.text.trim();
        final result = await StudentLoginFeature.studentlogin(
          teacherid,
          userId,
        );
        if (!context.mounted) return;

        if (result == 200) {
          await saveStudentSession(teacherid, userId);
          isLogined = true;
          role = "student";
          ispressed = false;
          notifyListeners();
          customSnackbar(
            context: context,
            message: "Login successful",
            color: Colors.green,
            ico: Icons.login,
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const StudentDashboardScreen(),
            ),
            (route) => false,
          );
          return;
        } else if (result == 404) {
          customSnackbar(
            context: context,
            message: "Teacher ID or Student ID not found",
            color: Colors.red,
            ico: Icons.error,
          );
        } else {
          customSnackbar(
            context: context,
            message: "Something went wrong, please try again later",
            color: Colors.orange,
            ico: Icons.info,
          );
        }
      }
    } catch (e) {
      log("Login exception: $e");
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: "Something went wrong, please try again later",
          color: Colors.red,
          ico: Icons.error,
        );
      }
    } finally {
      if (ispressed) {
        ispressed = false;
        notifyListeners();
      }
    }
  }

  // -------------- logout function
  Future<void> logout(BuildContext context) async {
    isLogined = false;
    role = "";
    teacherData = null;
    studentData = null;

    id.clear();
    password.clear();
    teacherId.clear();
    isStudentLogin = false;
    ispressed = false;

    // Sign out from Firebase Auth (for teacher accounts)
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    // Reset shared controllers if mounted
    try {
      if (context.mounted) {
        context.read<StudentController>().reset();
        context.read<TeacherExamController>().clearSearch();
        context.read<CreateExamController>().clearAll();
      }
    } catch (_) {}

    await pref.clear();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }

    notifyListeners();
  }
}

// ------------- save session data (teacher) — no password stored
Future<void> saveTeacherSession() async {
  await pref.setString("role", "teacher");
  await pref.setBool("isLogined", true);
  if (teacherData != null) {
    await pref.setString("id", teacherData!.id);
  }
}

// ------------- save session data (student) — no password stored
Future<void> saveStudentSession(String teacherid, String userId) async {
  await pref.setString("teacherId", teacherid);
  await pref.setString("id", userId);
  await pref.setString("role", "student");
  await pref.setBool("isLogined", true);
}
