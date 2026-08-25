import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:test_nest/feature/auth/loginFeatureStudents/student_login_feature.dart';
import 'package:test_nest/feature/auth/loginFeatureTeacher/teacher_login_feature.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/dashboard/students_dashboard_screen.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/dashboard/teacher_dashboard_screen.dart';
import 'package:test_nest/main.dart';

class LoginController extends ChangeNotifier {
  final loginKey = GlobalKey<FormState>();
  TextEditingController teacherId = TextEditingController();
  TextEditingController id = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isStudentLogin = false;
  bool obscurePassword = true;
  bool ispressed = false;
  // ------------- for main
  bool isLogined = false;
  String role = "";
  void changeLoginToStudent() {
    isStudentLogin = true;
    id.clear();
    password.clear();
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
  void login(BuildContext context) async {
    String userId = id.text.trim(), userpassword = password.text.trim();
    if (loginKey.currentState!.validate()) {
      toggelLoginButton();
      if (!isStudentLogin) {
        // teacher's feature
        int result = await TeacherLoginFeature.teacherlogin(
          userId,
          userpassword,
        );
        log(result.toString());
        if (result == 200) {
          loadTeacherData(userId, userpassword);
          customSnackbar(
            context: context,
            message: "Login successfull",
            color: Colors.green,
            ico: Icons.login,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TeacherDashboardScreen()),
          );
        } else if (result == 404) {
          customSnackbar(
            context: context,
            message: "Please enter valid id password",
            color: Colors.red,
            ico: Icons.error,
          );
        } else {
          customSnackbar(
            context: context,
            message: "Somthing wrong please try again later",
            color: Colors.yellow,
            ico: Icons.info,
          );
        }
      } else {
        log("student's feature");
        // student's feature
        String teacherid = teacherId.text.trim();
        int result = await StudentLoginFeature.studentlogin(
          teacherid,
          userId,
          userpassword,
        );
        log(result.toString());
        if (result == 200) {
          loadStudentData(teacherid, userId, userpassword);
          customSnackbar(
            context: context,
            message: "Login successfull",
            color: Colors.green,
            ico: Icons.login,
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => StudentDashboardScreen()),
          );
        } else if (result == 404) {
          customSnackbar(
            context: context,
            message: "Please enter valid id password",
            color: Colors.red,
            ico: Icons.error,
          );
        } else {
          customSnackbar(
            context: context,
            message: "Somthing wrong please try again later",
            color: Colors.yellow,
            ico: Icons.info,
          );
        }
      }
      toggelLoginButton();
    }
  }
}

// ------------- load pref data (teacher)
void loadTeacherData(String userId, String userpassword) {
  pref.setString("id", userId);
  pref.setString("password", userpassword);
  pref.setString("role", "teacher");
  pref.setBool("isLogined", true);
}

// ------------- load pref data (teacher)
void loadStudentData(String teacherId, String userId, String userpassword) {
  pref.setString("teacherId", userId);
  pref.setString("id", userId);
  pref.setString("password", userpassword);
  pref.setString("role", "student");
  pref.setBool("isLogined", true);
}
