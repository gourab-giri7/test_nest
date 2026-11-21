import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/login_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/signup/controller/student_signup_controller.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/signup/student_signup_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/signup/controller/teacher_signup_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/signup/teacher_signup_screen.dart';
import 'package:test_nest/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pref = await SharedPreferences.getInstance();
  });

  group('Step 7 — LoginScreen Responsive Layout & UI Polish Tests', () {
    testWidgets(
      'LoginScreen renders cleanly on 320x640 screen without RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          GetMaterialApp(
            home: ChangeNotifierProvider<LoginController>(
              create: (_) => LoginController(),
              child: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Welcome Back'), findsOneWidget);
        expect(find.text('Teacher'), findsOneWidget);
        expect(find.text('Student'), findsOneWidget);
        expect(find.text('Sign In as Teacher'), findsOneWidget);
        expect(find.byType(Wrap), findsWidgets);

        // Verify no RenderFlex overflow error occurred during render or interaction
        expect(tester.takeException(), isNull);

        // Test scroll drag down and up
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -150),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'LoginScreen switches to Student mode and renders cleanly on 390x844 screen',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final loginController = LoginController();

        await tester.pumpWidget(
          GetMaterialApp(
            home: ChangeNotifierProvider<LoginController>.value(
              value: loginController,
              child: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap student tab
        await tester.tap(find.text('Student'));
        await tester.pumpAndSettle();

        expect(loginController.isStudentLogin, isTrue);
        expect(
          find.text('Sign in to your Student Learning Portal'),
          findsOneWidget,
        );
        expect(find.text('Create Student Account'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Step 7 — Teacher & Student Signup Screen Responsive Tests', () {
    testWidgets(
      'TeacherSignupScreen renders on 320x640 small screen without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          GetMaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<LoginController>(
                  create: (_) => LoginController(),
                ),
                ChangeNotifierProvider<TeacherSignupController>(
                  create: (_) => TeacherSignupController(),
                ),
              ],
              child: const TeacherSignupScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Educator Registration'), findsOneWidget);
        expect(find.text('Already have an account?'), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Scroll form
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'StudentSignupScreen renders on 320x640 small screen without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          GetMaterialApp(
            home: MultiProvider(
              providers: [
                ChangeNotifierProvider<StudentSignupController>(
                  create: (_) => StudentSignupController(),
                ),
              ],
              child: const StudentSignupScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Student Registration'), findsOneWidget);
        expect(find.text('Already registered? '), findsOneWidget);
        expect(find.text('Sign In Here'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Scroll form
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Step 7 — Responsive Metric Cards & Action Buttons Wrap Verification', () {
    testWidgets(
      'Wrap layout wraps payment action buttons gracefully on narrow 280px container',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 260, // Mimicking narrow card body on small device
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('History'),
                        onPressed: () {},
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_note, size: 16),
                        label: const Text('Edit Due'),
                        onPressed: () {},
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payment, size: 15),
                        label: const Text('Collect Fee'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('History'), findsOneWidget);
        expect(find.text('Edit Due'), findsOneWidget);
        expect(find.text('Collect Fee'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Owner salary action buttons wrap gracefully on narrow 260px container',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 260,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.history, size: 16),
                        label: const Text('History'),
                        onPressed: () {},
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: const Text('Configure'),
                        onPressed: () {},
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send, size: 15),
                        label: const Text('Disburse'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('History'), findsOneWidget);
        expect(find.text('Configure'), findsOneWidget);
        expect(find.text('Disburse'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Owner 6-metric summary grid renders cleanly on 320px screen width',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        Widget buildStatCard(
          String title,
          String value,
          String? subtitle,
          IconData icon,
        ) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(icon, size: 16, color: Colors.blue),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
                  final aspectRatio = constraints.maxWidth < 360 ? 1.35 : 1.5;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: aspectRatio,
                    children: [
                      buildStatCard(
                        'Total Students',
                        '42',
                        null,
                        Icons.school_outlined,
                      ),
                      buildStatCard(
                        'Total Teachers',
                        '6',
                        null,
                        Icons.people_outline,
                      ),
                      buildStatCard(
                        'Total Batches',
                        '8',
                        null,
                        Icons.class_outlined,
                      ),
                      buildStatCard(
                        'Active Exams',
                        '3',
                        null,
                        Icons.assignment_outlined,
                      ),
                      buildStatCard(
                        'Pending Requests',
                        '5',
                        null,
                        Icons.person_add_outlined,
                      ),
                      buildStatCard(
                        'Today Attendance',
                        '38/42',
                        'marked today',
                        Icons.fact_check_outlined,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Total Students'), findsOneWidget);
        expect(find.text('Today Attendance'), findsOneWidget);
        expect(find.text('38/42'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Teacher & Student 4-card metric grid renders cleanly on 320px screen width',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        Widget buildTeacherMetricCard(
          String title,
          String count,
          IconData icon,
        ) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(icon, color: Colors.blue, size: 16),
                  ],
                ),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final aspectRatio = constraints.maxWidth < 360 ? 1.35 : 1.55;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: aspectRatio,
                    children: [
                      buildTeacherMetricCard(
                        'Assigned Batches',
                        '3',
                        Icons.class_outlined,
                      ),
                      buildTeacherMetricCard(
                        'Assigned Students',
                        '85',
                        Icons.people_outline,
                      ),
                      buildTeacherMetricCard(
                        'Active Exams',
                        '2',
                        Icons.assignment_outlined,
                      ),
                      buildTeacherMetricCard(
                        'Scheduled Classes',
                        '4',
                        Icons.event_note_outlined,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Assigned Batches'), findsOneWidget);
        expect(find.text('Scheduled Classes'), findsOneWidget);
        expect(find.text('85'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
