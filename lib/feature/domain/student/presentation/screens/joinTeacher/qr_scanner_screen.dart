import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:test_nest/core/services/batch_qr_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';

class StudentQrScannerScreen extends StatefulWidget {
  const StudentQrScannerScreen({super.key});

  @override
  State<StudentQrScannerScreen> createState() => _StudentQrScannerScreenState();
}

class _StudentQrScannerScreenState extends State<StudentQrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  bool _hasScanned = false;
  bool _isTorchOn = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scannerController.stop();
    } else if (state == AppLifecycleState.resumed && !_hasScanned) {
      _scannerController.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.trim().isEmpty) continue;

      final extractedCode = BatchQrService.extractJoiningCode(rawValue);
      if (extractedCode != null && extractedCode.isNotEmpty) {
        _hasScanned = true;
        _scannerController.stop();

        // Return extracted joining code to JoinTeacherScreen
        Get.back(result: extractedCode);
        return;
      } else {
        // Scanned QR does not contain a recognized Test Nest batch code
        _showInvalidCodeSnackbar(rawValue);
        break;
      }
    }
  }

  void _showInvalidCodeSnackbar(String scannedText) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Invalid QR Code. Does not contain a valid batch joining code.',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      if (mounted) {
        setState(() {
          _isTorchOn = !_isTorchOn;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (!_hasError)
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return _buildErrorState(error.toString());
              },
            ),

          if (_hasError) _buildErrorState(_errorMessage),

          // Scanner Overlay Mask & Reticle
          if (!_hasError) const _ScannerOverlay(),

          // Top Action Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    tooltip: 'Back',
                    onPressed: () => Get.back(),
                  ),

                  const Text(
                    'Scan Batch QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Torch button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: _isTorchOn
                          ? Colors.amber.withOpacity(0.8)
                          : Colors.black.withOpacity(0.5),
                      foregroundColor: _isTorchOn ? Colors.black : Colors.white,
                    ),
                    icon: Icon(
                      _isTorchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      size: 20,
                    ),
                    tooltip: 'Toggle Flashlight',
                    onPressed: _toggleTorch,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls & Manual Fallback
          Positioned(
            left: 20,
            right: 20,
            bottom: 36,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF818CF8),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Align the teacher\'s QR code within the frame to scan automatically',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Manual Entry Fallback Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.keyboard_rounded, size: 20),
                      label: const Text(
                        'Enter Code Manually',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_photography_rounded,
                size: 56,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Unable to access camera. Please grant camera permission in system settings or enter the joining code manually.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.keyboard_rounded, size: 20),
              label: const Text(
                'Enter Code Manually',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom semi-transparent mask with a transparent scanner reticle in the center.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _ScannerOverlayPainter(),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanBoxSize = (size.width * 0.72).clamp(240.0, 320.0);
    final double left = (size.width - scanBoxSize) / 2;
    final double top = (size.height - scanBoxSize) / 2 - 40;
    final rect = Rect.fromLTWH(left, top, scanBoxSize, scanBoxSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // Dark background mask
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Subtle border around cutout
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rrect, borderPaint);

    // Accent corner brackets
    final cornerPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;

    // Top-Left corner
    canvas.drawLine(
      Offset(left + 24, top),
      Offset(left + 24 + cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + 24),
      Offset(left, top + 24 + cornerLength),
      cornerPaint,
    );

    // Top-Right corner
    canvas.drawLine(
      Offset(left + scanBoxSize - 24, top),
      Offset(left + scanBoxSize - 24 - cornerLength, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanBoxSize, top + 24),
      Offset(left + scanBoxSize, top + 24 + cornerLength),
      cornerPaint,
    );

    // Bottom-Left corner
    canvas.drawLine(
      Offset(left + 24, top + scanBoxSize),
      Offset(left + 24 + cornerLength, top + scanBoxSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanBoxSize - 24),
      Offset(left, top + scanBoxSize - 24 - cornerLength),
      cornerPaint,
    );

    // Bottom-Right corner
    canvas.drawLine(
      Offset(left + scanBoxSize - 24, top + scanBoxSize),
      Offset(left + scanBoxSize - 24 - cornerLength, top + scanBoxSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanBoxSize, top + scanBoxSize - 24),
      Offset(left + scanBoxSize, top + scanBoxSize - 24 - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
