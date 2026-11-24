import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/model/batch_model.dart';

class BatchQrService {
  /// Copies the batch joining code to the clipboard and displays a feedback snackbar.
  static Future<bool> copyJoiningCode(BuildContext context, String code) async {
    final cleanCode = BatchAndJoinCodeService.normalizeCode(code);
    if (cleanCode.isEmpty) {
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'No active joining code to copy.',
          color: Colors.orange,
          ico: Icons.warning_amber_rounded,
        );
      }
      return false;
    }

    try {
      await Clipboard.setData(ClipboardData(text: cleanCode));
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Code $cleanCode copied to clipboard!',
          color: Colors.green,
          ico: Icons.copy_rounded,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Failed to copy to clipboard: $e',
          color: Colors.red,
          ico: Icons.error_outline_rounded,
        );
      }
      return false;
    }
  }

  /// Shares batch joining details via the native platform share dialog.
  static Future<void> shareJoiningCodeText({
    required BuildContext context,
    required String batchName,
    required String joinCode,
  }) async {
    final cleanCode = BatchAndJoinCodeService.normalizeCode(joinCode);
    if (cleanCode.isEmpty) {
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'This batch has no active joining code to share.',
          color: Colors.orange,
          ico: Icons.warning_amber_rounded,
        );
      }
      return;
    }

    final message =
        '''
Test Nest - Batch Invitation
Batch: $batchName
Joining Code: $cleanCode

Instructions:
1. Open the Test Nest app.
2. Go to "Join Batch".
3. Enter code $cleanCode or scan the batch QR code to submit your request to join.
''';

    try {
      await Share.share(message, subject: 'Join $batchName on Test Nest');
    } catch (e) {
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Unable to open share dialog: $e',
          color: Colors.red,
          ico: Icons.error_outline_rounded,
        );
      }
    }
  }

  /// Generates and shares a high-resolution branded QR card image.
  static Future<void> shareQrCodeImage({
    required BuildContext context,
    required BatchModel batch,
    GlobalKey? repaintBoundaryKey,
  }) async {
    final code = BatchAndJoinCodeService.normalizeCode(batch.activeJoinCode);
    if (code.isEmpty) {
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'This batch has no active joining code to generate a QR.',
          color: Colors.orange,
          ico: Icons.warning_amber_rounded,
        );
      }
      return;
    }

    try {
      Uint8List? pngBytes;

      // 1. Try to capture from RepaintBoundary if rendered and attached
      if (repaintBoundaryKey?.currentContext != null) {
        final boundary =
            repaintBoundaryKey!.currentContext!.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 3.0);
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData != null) {
            pngBytes = byteData.buffer.asUint8List();
          }
        }
      }

      // 2. High-quality canvas synthesis fallback if RepaintBoundary was not captured
      if (pngBytes == null) {
        pngBytes = await _renderBrandedQrCard(
          batchName: batch.name,
          joinCode: code,
          subject: batch.subject,
        );
      }

      // 3. Save to temporary storage
      final tempDir = await getTemporaryDirectory();
      _cleanupOldQrImages(tempDir);

      final fileName =
          'testnest_qr_${batch.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);

      // 4. Share via SharePlus
      final box = context.mounted
          ? context.findRenderObject() as RenderBox?
          : null;
      final originRect = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'Join "${batch.name}" on Test Nest with joining code $code',
        sharePositionOrigin: originRect,
      );
    } catch (e) {
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Failed to share QR image: $e',
          color: Colors.red,
          ico: Icons.error_outline_rounded,
        );
      }
    }
  }

  /// Synthesizes a clean, high-resolution QR card image via Canvas.
  static Future<Uint8List> _renderBrandedQrCard({
    required String batchName,
    required String joinCode,
    String? subject,
  }) async {
    const width = 800.0;
    const height = 1050.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // Background
    final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

    // Card Container
    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(40, 40, width - 80, height - 80),
      const Radius.circular(32),
    );
    final cardShadowPaint = Paint()
      ..color = const Color(0x1A0F172A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRRect(cardRect.shift(const Offset(0, 10)), cardShadowPaint);

    final cardPaint = Paint()..color = Colors.white;
    canvas.drawRRect(cardRect, cardPaint);

    // Card border
    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(cardRect, borderPaint);

    // Header gradient banner
    final bannerRect = RRect.fromRectAndCorners(
      const Rect.fromLTWH(40, 40, width - 80, 160),
      topLeft: const Radius.circular(32),
      topRight: const Radius.circular(32),
    );
    final bannerPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(40, 40),
        const Offset(width - 40, 200),
        [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
      );
    canvas.drawRRect(bannerRect, bannerPaint);

    // "Test Nest" Header text
    final appTextPainter = TextPainter(
      text: const TextSpan(
        text: 'TEST NEST',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 4.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 120);
    appTextPainter.paint(
      canvas,
      Offset((width - appTextPainter.width) / 2, 75),
    );

    final subHeaderPainter = TextPainter(
      text: const TextSpan(
        text: 'BATCH JOINING PASS',
        style: TextStyle(
          color: Color(0xFFE0E7FF),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 120);
    subHeaderPainter.paint(
      canvas,
      Offset((width - subHeaderPainter.width) / 2, 130),
    );

    // Batch Name
    final batchTextPainter = TextPainter(
      text: TextSpan(
        text: batchName,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 34,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: width - 140);
    batchTextPainter.paint(
      canvas,
      Offset((width - batchTextPainter.width) / 2, 230),
    );

    // QR Code rendering
    final qrPainter = QrPainter(
      data: joinCode,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF0F172A),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF0F172A),
      ),
    );
    const qrSize = 380.0;
    final qrOffset = Offset((width - qrSize) / 2, 340);

    // QR Frame background
    final qrBoxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        qrOffset.dx - 20,
        qrOffset.dy - 20,
        qrSize + 40,
        qrSize + 40,
      ),
      const Radius.circular(24),
    );
    final qrBoxBorder = Paint()
      ..color = const Color(0xFFEEF2FF)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(qrBoxRect, qrBoxBorder);

    final qrBorder = Paint()
      ..color = const Color(0xFFC7D2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(qrBoxRect, qrBorder);

    canvas.save();
    canvas.translate(qrOffset.dx, qrOffset.dy);
    qrPainter.paint(canvas, const Size(qrSize, qrSize));
    canvas.restore();

    // Joining Code Pill
    final codePillRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(100, 780, width - 200, 80),
      const Radius.circular(20),
    );
    final codePillPaint = Paint()..color = const Color(0xFFEEF2FF);
    canvas.drawRRect(codePillRect, codePillPaint);

    final codePillBorder = Paint()
      ..color = const Color(0xFFC7D2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(codePillRect, codePillBorder);

    final codeTextPainter = TextPainter(
      text: TextSpan(
        text: 'CODE: $joinCode',
        style: const TextStyle(
          color: Color(0xFF4F46E5),
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 4.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    codeTextPainter.paint(
      canvas,
      Offset(
        (width - codeTextPainter.width) / 2,
        780 + (80 - codeTextPainter.height) / 2,
      ),
    );

    // Bottom instructions
    final hintPainter = TextPainter(
      text: const TextSpan(
        text:
            'Scan with Test Nest app or enter code manually to request access',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 120);
    hintPainter.paint(canvas, Offset((width - hintPainter.width) / 2, 890));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Clean up temporary qr image files created during sharing.
  static void _cleanupOldQrImages(Directory tempDir) {
    try {
      final files = tempDir.listSync();
      final now = DateTime.now();
      for (final entity in files) {
        if (entity is File && entity.path.contains('testnest_qr_')) {
          final stat = entity.statSync();
          if (now.difference(stat.modified).inMinutes > 30) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  /// Extracts a joining code from a scanned raw QR string.
  /// Handles raw code, URLs, URI query parameters, and custom schemes.
  static String? extractJoiningCode(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Check if it's a URI with a 'code' query parameter
    try {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.queryParameters.containsKey('code')) {
        final queryCode = uri.queryParameters['code'];
        if (queryCode != null && queryCode.trim().isNotEmpty) {
          return BatchAndJoinCodeService.normalizeCode(queryCode);
        }
      }
    } catch (_) {}

    // Check for standard TN- prefix pattern (e.g. TN-7K9P2 or tn-7k9p2)
    final match = RegExp(
      r'TN-[A-Za-z0-9]{4,10}',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match != null) {
      return BatchAndJoinCodeService.normalizeCode(match.group(0)!);
    }

    // Fall back to normalizing the whole string if it conforms to code alphanumeric rules
    final normalized = BatchAndJoinCodeService.normalizeCode(trimmed);
    if (normalized.length >= 4 && normalized.length <= 64) {
      // Basic sanity check: only letters, digits, underscores and hyphens
      if (RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(trimmed)) {
        return trimmed;
      }
      if (RegExp(r'^[A-Z0-9\-_]+$').hasMatch(normalized)) {
        return normalized;
      }
    }

    return null;
  }
}
