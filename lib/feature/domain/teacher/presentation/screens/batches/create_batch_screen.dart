import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/model/batch_model.dart';

class CreateBatchScreen extends StatefulWidget {
  const CreateBatchScreen({super.key});

  @override
  State<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends State<CreateBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _yearController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feeController = TextEditingController();

  bool _feeTrackingEnabled = true;
  bool _isLoading = false;
  BatchModel? _createdBatch;

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _yearController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _submitBatch() async {
    final tData = teacherData;
    if (tData == null) {
      customSnackbar(
        context: context,
        message: 'Teacher session not found. Please log in again.',
        color: Colors.red,
        ico: Icons.error,
      );
      return;
    }

    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final monthlyFee = double.tryParse(_feeController.text.trim()) ?? 0.0;
      final batch = await BatchAndJoinCodeService.createBatch(
        teacherId: tData.id,
        teacherName: tData.name,
        name: _nameController.text.trim(),
        classLevel: _classController.text.trim().isNotEmpty
            ? _classController.text.trim()
            : null,
        academicYear: _yearController.text.trim().isNotEmpty
            ? _yearController.text.trim()
            : null,
        subject: _subjectController.text.trim().isNotEmpty
            ? _subjectController.text.trim()
            : null,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        monthlyFee: monthlyFee,
        feeTrackingEnabled: _feeTrackingEnabled,
      );

      setState(() {
        _createdBatch = batch;
      });

      if (!mounted) return;
      customSnackbar(
        context: context,
        message: 'Batch created! Joining code: ${batch.activeJoinCode}',
        color: Colors.green,
        ico: Icons.check_circle,
      );
    } catch (e) {
      if (!mounted) return;
      customSnackbar(
        context: context,
        message: 'Failed to create batch: $e',
        color: Colors.red,
        ico: Icons.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyJoinCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    customSnackbar(
      context: context,
      message: 'Joining code copied to clipboard!',
      color: Colors.green,
      ico: Icons.copy_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Batch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _createdBatch != null
                  ? _buildSuccessView(_createdBatch!)
                  : _buildCreateForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF4F46E5),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Organize students and generate a joining code',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Batch Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Batch Name *',
                  hintText: 'e.g. Class 11 JEE 2026',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a batch name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Class / Level & Academic Year in a Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _classController,
                      decoration: const InputDecoration(
                        labelText: 'Class / Level',
                        hintText: 'e.g. Class 11',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Academic Year',
                        hintText: 'e.g. 2025-2026',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Subject
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject (Optional)',
                  hintText: 'e.g. Physics, Mathematics',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Morning batch, 8:00 AM - 10:00 AM',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 14),

              // Monthly Fee
              TextFormField(
                controller: _feeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Fee (Optional)',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Fee Tracking Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Enable Monthly Fee Tracking',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Record student payments and track monthly dues',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                value: _feeTrackingEnabled,
                activeColor: const Color(0xFF4F46E5),
                onChanged: (val) {
                  setState(() => _feeTrackingEnabled = val);
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : _submitBatch,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Batch & Generate Code',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BatchModel batch) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Batch Created Successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              batch.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 24),

            // Joining Code Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Text(
                    'STUDENT JOINING CODE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    batch.activeJoinCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Joining Code'),
                    onPressed: () => _copyJoinCode(batch.activeJoinCode),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Share this reusable code with your students in WhatsApp or class. Students will enter this code to request to join your batch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Get.back(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
