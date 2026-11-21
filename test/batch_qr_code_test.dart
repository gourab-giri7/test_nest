import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/core/services/batch_qr_service.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/joinTeacher/qr_scanner_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/widgets/batch_qr_code_dialog.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/join_code_model.dart';

void main() {
  group('BatchQrService Extraction & Normalization Tests', () {
    test('extractJoiningCode parses direct standard TN codes', () {
      expect(BatchQrService.extractJoiningCode('TN-7K9P2'), 'TN-7K9P2');
      expect(BatchQrService.extractJoiningCode('tn-7k9p2'), 'TN-7K9P2');
      expect(BatchQrService.extractJoiningCode('  TN-ABCDE  '), 'TN-ABCDE');
    });

    test('extractJoiningCode parses URL query parameters', () {
      expect(
        BatchQrService.extractJoiningCode(
          'https://testnest.app/join?code=TN-8X1Y3',
        ),
        'TN-8X1Y3',
      );
      expect(
        BatchQrService.extractJoiningCode('testnest://join?code=TN-9Z2A4'),
        'TN-9Z2A4',
      );
      expect(
        BatchQrService.extractJoiningCode(
          'https://example.com/batch?code=tn-4k8p1&ref=qr',
        ),
        'TN-4K8P1',
      );
    });

    test('extractJoiningCode finds embedded TN pattern in text', () {
      expect(
        BatchQrService.extractJoiningCode(
          'Join our Physics batch: TN-5R2W9 now!',
        ),
        'TN-5R2W9',
      );
    });

    test('extractJoiningCode rejects invalid or empty payloads', () {
      expect(BatchQrService.extractJoiningCode(null), isNull);
      expect(BatchQrService.extractJoiningCode(''), isNull);
      expect(BatchQrService.extractJoiningCode('   '), isNull);
      expect(BatchQrService.extractJoiningCode('???###!!!'), isNull);
      expect(BatchQrService.extractJoiningCode('ab'), isNull); // Too short
    });

    test(
      'BatchAndJoinCodeService.normalizeCode trims and uppercases properly',
      () {
        expect(
          BatchAndJoinCodeService.normalizeCode(' tn-7k 9p2 '),
          'TN-7K9P2',
        );
      },
    );
  });

  group('BatchQrCodeDialog UI Widget Tests', () {
    final testBatch = BatchModel(
      id: 'batch_test_1',
      name: 'Class 10 Physics',
      activeJoinCode: 'TN-7K9P2',
      teacherId: 'teacher_123',
      subject: 'Physics',
      classLevel: 'Class 10',
      academicYear: '2026-2027',
    );

    testWidgets('Renders batch details, QR image view, and action buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(body: BatchQrCodeDialog(batch: testBatch)),
        ),
      );
      await tester.pumpAndSettle();

      // Verify batch info
      expect(find.text('Class 10 Physics'), findsWidgets);
      expect(find.text('TN-7K9P2'), findsWidgets);
      expect(find.text('ACTIVE JOINING CODE'), findsOneWidget);

      // Verify scannable QR code exists
      expect(find.byType(QrImageView), findsOneWidget);

      // Verify action buttons
      expect(find.text('Copy Code'), findsOneWidget);
      expect(find.text('Share Code'), findsOneWidget);
      expect(find.text('Share QR Image'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Renders friendly fallback when activeJoinCode is empty', (
      tester,
    ) async {
      final emptyCodeBatch = BatchModel(
        id: 'batch_empty',
        name: 'Class 12 Chemistry',
        activeJoinCode: '',
        teacherId: 'teacher_123',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(body: BatchQrCodeDialog(batch: emptyCodeBatch)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Active Joining Code'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('StudentQrScannerScreen UI & Fallback Tests', () {
    testWidgets(
      'Renders scanner overlay, flashlight, back, and manual entry buttons',
      (tester) async {
        await tester.pumpWidget(
          const GetMaterialApp(home: StudentQrScannerScreen()),
        );
        await tester.pump();

        // Title & instruction elements
        expect(find.text('Scan Batch QR'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_rounded), findsWidgets);
        expect(find.text('Enter Code Manually'), findsWidgets);
      },
    );
  });

  group('Join Code Security & Validation Logic Tests', () {
    test('JoinCodeModel handles serialization and active status correctly', () {
      final model = JoinCodeModel(
        code: 'TN-7K9P2',
        teacherId: 'teacher_1',
        teacherName: 'Dr. Bose',
        batchId: 'batch_1',
        batchName: 'Physics Alpha',
        isActive: true,
      );

      expect(model.isActive, isTrue);
      expect(model.code, 'TN-7K9P2');

      final json = model.toJson();
      expect(json['code'], 'TN-7K9P2');
      expect(json['is_active'], isTrue);

      final restored = JoinCodeModel.fromJson(json);
      expect(restored.code, 'TN-7K9P2');
      expect(restored.batchName, 'Physics Alpha');
      expect(restored.isActive, isTrue);
    });

    test('Inactive or revoked join codes are recognized as inactive', () {
      final inactiveJson = {
        'code': 'TN-REVOKED',
        'teacher_id': 'teacher_1',
        'teacher_name': 'Dr. Bose',
        'batch_id': 'batch_1',
        'batch_name': 'Physics Alpha',
        'is_active': false,
      };

      final inactiveModel = JoinCodeModel.fromJson(inactiveJson);
      expect(inactiveModel.isActive, isFalse);
    });

    test('Different batches hold different independent join codes', () {
      final batch1 = BatchModel(
        id: 'b1',
        name: 'Maths 101',
        activeJoinCode: 'TN-MATH1',
        teacherId: 't1',
      );
      final batch2 = BatchModel(
        id: 'b2',
        name: 'Physics 202',
        activeJoinCode: 'TN-PHYS2',
        teacherId: 't1',
      );

      expect(batch1.activeJoinCode, isNot(equals(batch2.activeJoinCode)));
      expect(
        BatchQrService.extractJoiningCode(batch1.activeJoinCode),
        'TN-MATH1',
      );
      expect(
        BatchQrService.extractJoiningCode(batch2.activeJoinCode),
        'TN-PHYS2',
      );
    });

    test('Copy joining code returns false for empty code', () async {
      final result = await BatchQrService.copyJoiningCode(
        // ignore: avoid_redundant_argument_values
        MockBuildContext(),
        '',
      );
      expect(result, isFalse);
    });
  });
}

class MockBuildContext extends Fake implements BuildContext {
  @override
  bool get mounted => false;
}
