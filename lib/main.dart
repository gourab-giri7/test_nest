import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_nest/firebase_options.dart';

import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/utils/theme/theme.dart';

import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';

import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/dashboard/controller/student_dashboard_controller.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examHistory/controller/exam_controller.dart';

import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/controller/create_exam_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/addStudents/controller/add_student_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/allStudents/controller/student_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/dashboard/controller/dasboard_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/exams/controller/teacher_exam_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/fileUpload/controller/file_upload_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/reviewPublishExam/controller/publishExamController.dart';

import 'package:get/get.dart';
import 'package:test_nest/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  pref = await SharedPreferences.getInstance();

  final isLoggedIn = pref.getBool('isLogined') ?? false;
  final savedRole = pref.getString('role') ?? '';

  bool validLoggedIn = false;
  String restoredRole = '';

  if (isLoggedIn && (savedRole == 'teacher' || savedRole == 'owner')) {
    // 1. Immediately restore cached session from SharedPreferences for fast, non-blocking startup
    final teacherString = pref.getString('teacherData');
    if (teacherString != null && teacherString.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(teacherString);
        if (decoded is Map<String, dynamic>) {
          teacherData = TeacherData.fromJson(decoded);
          validLoggedIn = true;
          restoredRole = savedRole;
        }
      } catch (e) {
        log('Failed to decode teacherData from prefs: $e');
      }
    }

    // 2. Verify with FirebaseAuth.currentUser and optionally refresh with a short timeout
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('user')
            .doc(currentUser.uid)
            .get()
            .timeout(const Duration(milliseconds: 1500));

        if (doc.exists && doc.data() != null) {
          teacherData = TeacherData.fromJson(
            doc.data()!,
            docId: currentUser.uid,
          );
          validLoggedIn = true;
          restoredRole = savedRole.isNotEmpty ? savedRole : 'teacher';
        } else if (!validLoggedIn) {
          await _clearLoginSession();
        }
      } catch (e) {
        log('Firestore session refresh skipped/timed out: $e');
        // Keep validLoggedIn if prefs were successfully loaded
      }
    } else if (!validLoggedIn) {
      // No Firebase Auth session and no valid local data
      await _clearLoginSession();
    }
  } else if (isLoggedIn && savedRole == 'student') {
    final studentString = pref.getString('studentData');

    if (studentString != null && studentString.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(studentString);

        if (decoded is Map<String, dynamic>) {
          studentData = StudentData.fromJson(decoded);

          validLoggedIn = true;
          restoredRole = 'student';
        }
      } catch (e, stackTrace) {
        log('Failed to decode studentData: $e', stackTrace: stackTrace);

        studentData = null;
        await _clearLoginSession();
      }
    } else {
      await _clearLoginSession();
    }
  }

  final activeTenantContext = ActiveTenantContext();
  if (validLoggedIn) {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ??
        ((restoredRole == 'teacher' || restoredRole == 'owner')
            ? teacherData?.id
            : studentData?.id);
    if (uid != null && uid.isNotEmpty) {
      try {
        await activeTenantContext
            .init(
              uid,
              fallbackName:
                  (restoredRole == 'teacher' || restoredRole == 'owner')
                      ? teacherData?.name
                      : studentData?.name,
              fallbackEmail:
                  (restoredRole == 'teacher' || restoredRole == 'owner')
                      ? teacherData?.email
                      : FirebaseAuth.instance.currentUser?.email,
            )
            .timeout(const Duration(milliseconds: 2000));
      } catch (e) {
        log('ActiveTenantContext init non-blocking timeout: $e');
      }
    }
  }

  final loginController = LoginController(
    initialIsLogined: validLoggedIn,
    initialRole: restoredRole,
  );
  Get.put<LoginController>(loginController, permanent: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ActiveTenantContext>.value(
          value: activeTenantContext,
        ),
        ChangeNotifierProvider<LoginController>.value(
          value: loginController,
        ),

        ChangeNotifierProvider<AddStudentController>(
          create: (_) => AddStudentController(),
        ),

        ChangeNotifierProvider<CreateExamController>(
          create: (_) => CreateExamController(),
        ),

        ChangeNotifierProvider<TeacherExamController>(
          create: (_) => TeacherExamController(),
        ),

        ChangeNotifierProvider<DasboardController>(
          create: (_) => DasboardController(),
        ),

        ChangeNotifierProvider<StudentController>(
          create: (_) => StudentController(),
        ),

        ChangeNotifierProvider<StudentDashboardController>(
          create: (_) => StudentDashboardController(),
        ),

        ChangeNotifierProvider<ExamController>(create: (_) => ExamController()),

        ChangeNotifierProvider<FileUploadController>(
          create: (_) => FileUploadController(),
        ),

        ChangeNotifierProvider<Publishexamcontroller>(
          create: (_) => Publishexamcontroller(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _clearLoginSession() async {
  teacherData = null;
  studentData = null;

  await pref.remove('isLogined');
  await pref.remove('role');
  await pref.remove('teacherData');
  await pref.remove('studentData');
}

late SharedPreferences pref;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Test Nest',
      theme: ColorTheme.light,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
