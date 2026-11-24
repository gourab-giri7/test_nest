import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/core/services/batch_qr_service.dart';
import 'package:test_nest/model/batch_model.dart';

class BatchQrCodeDialog extends StatefulWidget {
  final BatchModel batch;

  const BatchQrCodeDialog({super.key, required this.batch});

  static Future<void> show(BuildContext context, BatchModel batch) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BatchQrCodeDialog(batch: batch),
    );
  }

  @override
  State<BatchQrCodeDialog> createState() => _BatchQrCodeDialogState();
}

class _BatchQrCodeDialogState extends State<BatchQrCodeDialog> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isSharingQr = false;
  late String _currentCode;
  bool _isGeneratingCode = false;

  @override
  void initState() {
    super.initState();
    _currentCode = widget.batch.activeJoinCode.trim();
    if (_currentCode.isEmpty) {
      _autoGenerateCode();
    }
  }

  Future<void> _autoGenerateCode() async {
    setState(() => _isGeneratingCode = true);
    try {
      final newCode = BatchAndJoinCodeService.generateJoiningCode();
      final batchId = widget.batch.id.trim();
      final teacherId = widget.batch.teacherId.trim();

      // Update in Firestore
      final db = FirebaseFirestore.instance;
      final joinData = {
        'code': newCode,
        'teacher_id': teacherId,
        'batch_id': batchId,
        'batch_name': widget.batch.name,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      };

      await db.collection('joinCodes').doc(newCode).set(joinData, SetOptions(merge: true));
      await db.collection('joinCodes').doc(batchId).set(joinData, SetOptions(merge: true));

      // Attempt to persist on teacher or org batch
      try {
        if (teacherId.isNotEmpty) {
          await db
              .collection('user')
              .doc(teacherId)
              .collection('batches')
              .doc(batchId)
              .set({'active_join_code': newCode}, SetOptions(merge: true));
        }
      } catch (_) {}

      try {
        final orgsSnap = await db.collection('organizations').limit(20).get();
        for (final o in orgsSnap.docs) {
          final bDoc = await o.reference.collection('batches').doc(batchId).get();
          if (bDoc.exists) {
            await bDoc.reference.set({'active_join_code': newCode}, SetOptions(merge: true));
            break;
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _currentCode = newCode;
          _isGeneratingCode = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isGeneratingCode = false);
      }
    }
  }

  Future<void> _handleShareQr() async {
    if (_isSharingQr) return;
    setState(() => _isSharingQr = true);
    try {
      final effectiveBatch = widget.batch.copyWith(activeJoinCode: _currentCode);
      await BatchQrService.shareQrCodeImage(
        context: context,
        batch: effectiveBatch,
        repaintBoundaryKey: _repaintBoundaryKey,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharingQr = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final joinCode = _currentCode;
    final hasActiveCode = joinCode.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 16,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.qr_code_rounded,
                        color: Color(0xFF4F46E5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                                  if (batch.classLevel != null &&
                                      batch.classLevel!.isNotEmpty)
                                    batch.classLevel!,
                                  if (batch.subject != null &&
                                      batch.subject!.isNotEmpty)
                                    batch.subject!,
                                  if (batch.academicYear != null &&
                                      batch.academicYear!.isNotEmpty)
                                    batch.academicYear!,
                                ].isEmpty
                                ? 'Batch Joining Pass'
                                : [
                                    if (batch.classLevel != null &&
                                        batch.classLevel!.isNotEmpty)
                                      batch.classLevel!,
                                    if (batch.subject != null &&
                                        batch.subject!.isNotEmpty)
                                      batch.subject!,
                                    if (batch.academicYear != null &&
                                        batch.academicYear!.isNotEmpty)
                                      batch.academicYear!,
                                  ].join(' • '),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                      tooltip: 'Close',
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),

              // Body Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: hasActiveCode
                    ? Column(
                        children: [
                          // Scannable QR Code wrapped in RepaintBoundary for high-res capture
                          RepaintBoundary(
                            key: _repaintBoundaryKey,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  QrImageView(
                                    data: joinCode,
                                    version: QrVersions.auto,
                                    size: 210,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFF0F172A),
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    batch.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Code: $joinCode',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Large joining code display pill
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFC7D2FE),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.vpn_key_rounded,
                                  color: Color(0xFF4F46E5),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ACTIVE JOINING CODE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        joinCode,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2.0,
                                          color: Color(0xFF1E1B4B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    color: Color(0xFF4F46E5),
                                    size: 20,
                                  ),
                                  tooltip: 'Copy Code',
                                  onPressed: () =>
                                      BatchQrService.copyJoiningCode(
                                        context,
                                        joinCode,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Students can scan this QR code or enter the code manually in the Test Nest app to request access.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              // Copy Code Button
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFC7D2FE),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    foregroundColor: const Color(0xFF4F46E5),
                                  ),
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Copy Code',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () =>
                                      BatchQrService.copyJoiningCode(
                                        context,
                                        joinCode,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Share Code Button
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFC7D2FE),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    foregroundColor: const Color(0xFF4F46E5),
                                  ),
                                  icon: const Icon(
                                    Icons.share_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Share Code',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () =>
                                      BatchQrService.shareJoiningCodeText(
                                        context: context,
                                        batchName: batch.name,
                                        joinCode: joinCode,
                                      ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Share QR Image Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              icon: _isSharingQr
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                _isSharingQr
                                    ? 'Generating QR...'
                                    : 'Share QR Image',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _isSharingQr ? null : _handleShareQr,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Close Button
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              onPressed: () => Get.back(),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 48,
                            color: Colors.amber,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Active Joining Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This batch currently does not have an active joining code. You can generate or rotate a code from batch settings.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Get.back(),
                              child: const Text('Close'),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
