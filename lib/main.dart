import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/dashboard/controller/student_dashboard_controller.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examHistory/controller/exam_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/allStudents/controller/student_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/fileUpload/controller/file_upload_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/reviewPublishExam/controller/publishExamController.dart';
import 'firebase_options.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/login_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/dashboard/students_dashboard_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/controller/create_exam_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/create_exam_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/addStudents/add_students_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/addStudents/controller/add_student_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/allStudents/all_students_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/dashboard/teacher_dashboard_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/fileUpload/file_upload_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoginController()),
        ChangeNotifierProvider(create: (context) => AddStudentController()),
        ChangeNotifierProvider(create: (context) => CreateExamController()),
        ChangeNotifierProvider(create: (context) => StudentController()),
        ChangeNotifierProvider(create: (context) => ExamController()),
        ChangeNotifierProvider(create: (context) => FileUploadController()),
        ChangeNotifierProvider(create: (context) => Publishexamcontroller()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

late final SharedPreferences pref;
LoginController loginController = LoginController();

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    initData();
    // TODO: implement initState
    super.initState();
  }

  Future<void> initData() async {
    pref = await SharedPreferences.getInstance();
    final controller = context.read<LoginController>();
    // pref.remove("isLogined");

    controller.changeLoginState(
      pref.getBool('isLogined') ?? false,
      pref.getString('role') ?? "",
    );
  }

  @override
  Widget build(BuildContext context) {
    // log(loginController.isLogined.toString());
    return Material(
      child: Consumer<LoginController>(
        builder: (context, controller, child) => MaterialApp(
          debugShowCheckedModeBanner: false,

          home: controller.isLogined
              ? controller.role == "teacher"
                    ? TeacherDashboardScreen()
                    : StudentDashboardScreen()
              : LoginScreen(),
          // home: FileUploadScreen(),
        ),
      ),
    );
  }
}
