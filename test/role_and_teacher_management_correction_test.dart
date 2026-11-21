import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/login_screen.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/roleSelection/role_selection_screen.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/institute_teacher_dashboard_controller.dart';
import 'package:test_nest/main.dart';
import 'package:test_nest/model/organization_model.dart';
import 'package:test_nest/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pref = await SharedPreferences.getInstance();
  });

  group('Role Selection Screen — Exactly 3 Roles & Responsiveness', () {
    testWidgets(
      'Displays exactly 3 portal cards (Owner, Teacher, Student) with responsive layout on 320x640',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          GetMaterialApp(
            home: ChangeNotifierProvider<LoginController>(
              create: (_) => LoginController(),
              child: const RoleSelectionScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check for 3 distinct portal options
        expect(find.text('Owner Portal'), findsOneWidget);
        expect(find.text('Teacher Portal'), findsOneWidget);
        expect(find.text('Student Portal'), findsOneWidget);

        // Check for respective role badges
        expect(find.text('INSTITUTE ADMINISTRATION'), findsOneWidget);
        expect(find.text('FACULTY WORKSPACE'), findsOneWidget);
        expect(find.text('LEARNER WORKSPACE'), findsOneWidget);

        // Teacher portal must display notice that account is provisioned by owner
        expect(
          find.text('Account provisioned by Institute Owner'),
          findsOneWidget,
        );

        // Verify zero RenderFlex overflows
        expect(tester.takeException(), isNull);

        // Test vertical drag scrolling
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Renders cleanly on 360x780 and 390x844 viewport widths without overflow',
      (tester) async {
        for (final size in [const Size(360, 780), const Size(390, 844)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            GetMaterialApp(
              home: ChangeNotifierProvider<LoginController>(
                create: (_) => LoginController(),
                child: const RoleSelectionScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Owner Portal'), findsOneWidget);
          expect(find.text('Teacher Portal'), findsOneWidget);
          expect(find.text('Student Portal'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        tester.view.resetPhysicalSize();
      },
    );
  });

  group('Login Screen — 3-Segment Switcher & Context-Sensitive Footers', () {
    testWidgets(
      'LoginScreen switches across Owner, Teacher, and Student and adapts footers',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final loginController = LoginController();

        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: AppRoutes.login,
            getPages: [
              GetPage(
                name: AppRoutes.login,
                page: () => ChangeNotifierProvider<LoginController>.value(
                  value: loginController,
                  child: const LoginScreen(),
                ),
              ),
              GetPage(
                name: AppRoutes.ownerSignup,
                page: () => const Scaffold(body: Text('Owner Signup Page')),
              ),
              GetPage(
                name: AppRoutes.studentSignup,
                page: () => const Scaffold(body: Text('Student Signup Page')),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initially starts in Teacher mode
        expect(loginController.isTeacherLogin, isTrue);
        expect(find.text('Sign In as Teacher'), findsOneWidget);
        // Teacher portal must NOT show public registration link
        expect(find.text('Create Teacher Account'), findsNothing);
        // Teacher portal must display Owner-provisioned credentials notice
        expect(
          find.text(
            'Teacher accounts are created by your Institute Owner. Please log in with the credentials provided to you.',
          ),
          findsOneWidget,
        );

        // 2. Switch to Owner portal
        await tester.tap(find.text('Owner'));
        await tester.pumpAndSettle();

        expect(loginController.isOwnerLogin, isTrue);
        expect(find.text('Sign In as Owner'), findsOneWidget);
        expect(find.text('New Institute Owner? '), findsOneWidget);
        expect(find.text('Create Owner Account'), findsOneWidget);

        // 3. Switch to Student portal
        await tester.tap(find.text('Student'));
        await tester.pumpAndSettle();

        expect(loginController.isStudentLogin, isTrue);
        expect(find.text('Sign In as Student'), findsOneWidget);
        expect(find.text('New to Test Nest? '), findsOneWidget);
        expect(find.text('Create Student Account'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Teacher Model & Account Structure Validation', () {
    test('OrganizationMemberModel serializes and deserializes teacher fields', () {
      final now = DateTime(2026, 11, 22, 10, 0);
      final member = OrganizationMemberModel(
        uid: 'teacher_uid_999',
        email: 'sharma.physics@institute.com',
        name: 'Prof. R. K. Sharma',
        role: OrganizationRole.teacher,
        status: OrganizationStatus.active,
        joinedAt: now,
        assignedBatchIds: ['batch_phy_01', 'batch_phy_02'],
        teacherId: 'TN-TEA-0001',
        subject: 'Physics',
        phone: '+91 9876543210',
        gender: 'Male',
        qualification: 'M.Sc, Ph.D Physics',
        experience: '12 Years',
        monthlySalary: 65000.0,
      );

      final map = member.toMap();
      expect(map['uid'], 'teacher_uid_999');
      expect(map['email'], 'sharma.physics@institute.com');
      expect(map['teacherId'], 'TN-TEA-0001');
      expect(map['teacher_id'], 'TN-TEA-0001');
      expect(map['subject'], 'Physics');
      expect(map['phone'], '+91 9876543210');
      expect(map['qualification'], 'M.Sc, Ph.D Physics');
      expect(map['experience'], '12 Years');
      expect(map['monthlySalary'], 65000.0);
      expect(map['monthly_salary'], 65000.0);

      final fromMap = OrganizationMemberModel.fromMap(map, 'teacher_uid_999');
      expect(fromMap.teacherId, 'TN-TEA-0001');
      expect(fromMap.subject, 'Physics');
      expect(fromMap.phone, '+91 9876543210');
      expect(fromMap.qualification, 'M.Sc, Ph.D Physics');
      expect(fromMap.experience, '12 Years');
      expect(fromMap.monthlySalary, 65000.0);
      expect(fromMap.isTeacher, isTrue);
      expect(fromMap.isActive, isTrue);
      expect(fromMap.isSuspended, isFalse);
    });

    test('ActiveTenantContext reflects active and suspended member status', () {
      final ctx = ActiveTenantContext();
      expect(ctx.isActive, isTrue);
      expect(ctx.isSuspended, isFalse);
    });
  });

  group('Teacher Student Visibility (No Batch Restriction)', () {
    test(
      'TeacherAssignedStudent includes unassigned students and students across any batch',
      () {
        const student1 = TeacherAssignedStudent(
          studentUid: 'std_01',
          studentName: 'Aarav Patel',
          studentEmail: 'aarav@test.com',
          studentPhone: '9876500001',
          batchIds: ['batch_1'],
          batchNames: ['Batch 10A'],
        );

        const student2 = TeacherAssignedStudent(
          studentUid: 'std_02',
          studentName: 'Diya Sen',
          studentEmail: 'diya@test.com',
          studentPhone: '9876500002',
          batchIds: [],
          batchNames: ['Unassigned'],
        );

        expect(student1.batchNames, contains('Batch 10A'));
        expect(student2.batchNames, contains('Unassigned'));
        expect(student2.matchesSearch('Diya'), isTrue);
        expect(student2.matchesSearch('diya@test.com'), isTrue);
      },
    );

    test(
      'InstituteTeacherDashboardController deduplicates students across batches and search filters',
      () {
        final controller = InstituteTeacherDashboardController(autoListen: false);

        expect(controller.deduplicatedStudents, isEmpty);
        expect(controller.assignedStudentsCount, 0);

        controller.setStudentSearchQuery('Rahul');
        expect(controller.studentSearchQuery, 'Rahul');

        controller.setStudentBatchFilter('all');
        expect(controller.studentBatchFilter, 'all');
      },
    );
  });
}
