import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/dashboard/teacher_dashboard_screen.dart';
import 'package:test_nest/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pref = await SharedPreferences.getInstance();
    teacherData = TeacherData(
      id: 'teacher_123',
      teacherId: 'teacher_123',
      name: 'Dr. Jane Smith',
      email: 'jane@example.com',
      lastStdId: '0',
      lastExamId: '0',
      batch: ['Batch A'],
    );
  });

  testWidgets(
    'TeacherDashboardScreen renders and scrolls without layout or RenderClipRect errors on small screens',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: TeacherDashboardScreen(
            studentsStream: Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
            examsStream: Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
            recentExamsStream:
                Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Fee Records'), findsOneWidget);
      expect(find.text('Good Morning,'), findsOneWidget);

      // Verify scrolling down and up
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'TeacherDashboardScreen renders on large tablet/desktop screen without errors',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: TeacherDashboardScreen(
            studentsStream: Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
            examsStream: Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
            recentExamsStream:
                Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Fee Records'), findsOneWidget);
    },
  );

  testWidgets(
    'Signup navigation flow with customSnackbar and pushAndRemoveUntil reaches TeacherDashboardScreen without assertion crash',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    customSnackbar(
                      context: context,
                      message: 'Account created successfully! Welcome, Jane.',
                      color: Colors.green,
                      ico: Icons.check_circle,
                    );
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => TeacherDashboardScreen(
                          studentsStream:
                              Stream<
                                QuerySnapshot<Map<String, dynamic>>
                              >.empty(),
                          examsStream:
                              Stream<
                                QuerySnapshot<Map<String, dynamic>>
                              >.empty(),
                          recentExamsStream:
                              Stream<
                                QuerySnapshot<Map<String, dynamic>>
                              >.empty(),
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Simulate Signup Complete'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap to simulate the complete signup navigation
      await tester.tap(find.text('Simulate Signup Complete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify TeacherDashboardScreen is successfully mounted and visible
      expect(find.byType(TeacherDashboardScreen), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Students'), findsWidgets);
    },
  );
}
