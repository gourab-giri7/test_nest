import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/institute_admin_dashboard_controller.dart';
import 'package:test_nest/model/batch_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 3: Owner Institute Panel - Models & Controller Tests', () {
    test('BatchModel schedule field serialization and copyWith', () {
      final now = DateTime(2026, 10, 24, 12, 0);
      final batch = BatchModel(
        id: 'batch_alpha_01',
        name: 'Mathematics Mastery',
        subject: 'Mathematics',
        schedule: 'Mon, Wed, Fri 10:00 AM - 11:30 AM',
        studentCount: 25,
        activeJoinCode: 'JOIN123',
        teacherId: 'teacher_001',
        createdAt: now,
      );

      final json = batch.toJson();
      expect(json['id'], 'batch_alpha_01');
      expect(json['name'], 'Mathematics Mastery');
      expect(json['schedule'], 'Mon, Wed, Fri 10:00 AM - 11:30 AM');

      final fromJson = BatchModel.fromJson(json, docId: 'batch_alpha_01');
      expect(fromJson.id, 'batch_alpha_01');
      expect(fromJson.name, 'Mathematics Mastery');
      expect(fromJson.schedule, 'Mon, Wed, Fri 10:00 AM - 11:30 AM');

      // Test copyWith
      final updated = fromJson.copyWith(schedule: 'Tue, Thu 2:00 PM - 4:00 PM');
      expect(updated.schedule, 'Tue, Thu 2:00 PM - 4:00 PM');
      expect(updated.name, 'Mathematics Mastery');

      // Missing schedule defaults to null or empty
      final noScheduleJson = Map<String, dynamic>.from(json);
      noScheduleJson.remove('schedule');
      final fromJsonDefault = BatchModel.fromJson(noScheduleJson);
      expect(fromJsonDefault.schedule, isNull);
    });

    test(
      'InstituteAdminDashboardController tab switching and initial state',
      () {
        final controller = InstituteAdminDashboardController(autoListen: false);
        expect(controller.currentTabIndex, 0);

        controller.switchTab(1);
        expect(controller.currentTabIndex, 1);

        controller.switchTab(3);
        expect(controller.currentTabIndex, 3);

        controller.switchTab(0);
        expect(controller.currentTabIndex, 0);

        // Verify initial statistics defaults
        expect(controller.pendingJoinRequests, 0);
        expect(controller.recentJoinRequests, isEmpty);
        expect(controller.todayAttendancePresent, 0);
        expect(controller.todayAttendanceTotal, 0);
        expect(controller.totalStudents, 0);
        expect(controller.totalTeachers, 0);
        expect(controller.totalBatches, 0);
      },
    );

    test(
      'TenantPathResolver resolves correct institute batch and member paths',
      () {
        final pathResolver = TenantPathResolver(
          explicitOrgId: 'org_test_institute',
          explicitIsInstitute: true,
        );

        expect(
          pathResolver.batchesPath(),
          'organizations/org_test_institute/batches',
        );
        expect(
          pathResolver.batchDocPath('batch_123'),
          'organizations/org_test_institute/batches/batch_123',
        );
        expect(
          pathResolver.batchStudentsPath('batch_123'),
          'organizations/org_test_institute/batches/batch_123/students',
        );
        expect(
          pathResolver.joinRequestsPath(),
          'organizations/org_test_institute/joinRequests',
        );
      },
    );

    testWidgets(
      'OutlinedButton and ElevatedButton in horizontal Row do not force infinite width under AppTheme',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ColorTheme.light,
            home: Scaffold(
              body: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Faculty Directory'),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.mail),
                        label: const Text('Invitations'),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Teacher'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Faculty Directory'), findsOneWidget);
        expect(find.text('Invitations'), findsOneWidget);
        expect(find.text('Add Teacher'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
