import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/services/fee_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/feeManagement/controller/fee_management_controller.dart';
import 'package:test_nest/model/fee_record_model.dart';
import 'package:test_nest/model/payment_model.dart';

class FeeManagementScreen extends StatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FeeManagementController>().loadFeeData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeeManagementController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            title: const Text(
              'Fee Management',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => controller.loadFeeData(),
            child: Column(
              children: [
                _buildMonthNavigator(controller),
                _buildSummaryCard(controller),
                _buildFilters(controller),
                Expanded(child: _buildStudentList(context, controller)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Month navigator
  // ---------------------------------------------------------------------------
  Widget _buildMonthNavigator(FeeManagementController c) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: c.isLoading ? null : c.goToPreviousMonth,
          ),
          Text(
            c.selectedMonthLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: c.isLoading ? null : c.goToNextMonth,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary card
  // ---------------------------------------------------------------------------
  Widget _buildSummaryCard(FeeManagementController c) {
    if (c.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryItem(
                '₹${_fmt(c.totalCollected)}',
                'Collected',
                AppColors.success,
              ),
              _summaryItem(
                '₹${_fmt(c.totalDue)}',
                'Total Due',
                AppColors.primary,
              ),
              _summaryItem(
                '₹${_fmt(c.totalDue - c.totalCollected)}',
                'Outstanding',
                AppColors.danger,
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _countBadge('${c.paidCount}', 'Paid', AppColors.success),
              _countBadge('${c.partialCount}', 'Partial', AppColors.warning),
              _countBadge(
                '${c.unpaidCount}',
                'Unpaid',
                AppColors.textSecondary,
              ),
              _countBadge('${c.overdueCount}', 'Overdue', AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countBadge(String count, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------
  Widget _buildFilters(FeeManagementController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or ID…',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: c.setSearch,
            ),
          ),
          if (c.availableBatches.isNotEmpty) ...[
            const SizedBox(width: 8),
            DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: c.selectedBatch,
                hint: const Text('All Batches', style: TextStyle(fontSize: 13)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Batches', style: TextStyle(fontSize: 13)),
                  ),
                  ...c.availableBatches.map(
                    (b) => DropdownMenuItem<String?>(
                      value: b,
                      child: Text(b, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                onChanged: c.setBatch,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Student list
  // ---------------------------------------------------------------------------
  Widget _buildStudentList(
    BuildContext context,
    FeeManagementController controller,
  ) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
            const SizedBox(height: 10),
            Text(controller.error!, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: controller.loadFeeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final list = controller.filteredStatuses;

    if (list.isEmpty) {
      return const Center(
        child: Text(
          'No students found.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _StudentFeeCard(
          status: list[index],
          onTap: () => _showStudentFeeDialog(context, controller, list[index]),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Fee detail dialog
  // ---------------------------------------------------------------------------
  void _showStudentFeeDialog(
    BuildContext context,
    FeeManagementController controller,
    StudentFeeStatus status,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _StudentFeeBottomSheet(
        status: status,
        controller: controller,
        onPaymentRecorded: () {
          Get.back();
          if (context.mounted) {
            customSnackbar(
              context: context,
              message: 'Payment recorded successfully',
              color: AppColors.success,
              ico: Icons.check_circle,
            );
          }
        },
        onError: (msg) {
          if (context.mounted) {
            customSnackbar(
              context: context,
              message: msg,
              color: AppColors.danger,
              ico: Icons.error,
            );
          }
        },
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

// =============================================================================
// Student fee card
// =============================================================================
class _StudentFeeCard extends StatelessWidget {
  final StudentFeeStatus status;
  final VoidCallback onTap;

  const _StudentFeeCard({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = status.status;
    final Color statusColor;
    switch (s) {
      case 'paid':
        statusColor = AppColors.success;
        break;
      case 'partial':
        statusColor = AppColors.warning;
        break;
      case 'overdue':
        statusColor = AppColors.danger;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  status.student.name.isNotEmpty
                      ? status.student.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + ID + batch
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.student.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${status.student.id} • ${status.student.batch.isEmpty ? "No batch" : status.student.batch}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: status.amountDue > 0
                          ? (status.amountPaid / status.amountDue).clamp(
                              0.0,
                              1.0,
                            )
                          : 0.0,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Amount + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s[0].toUpperCase() + s.substring(1),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_fmt(status.amountPaid)} / ₹${_fmt(status.amountDue)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  if (status.balance > 0)
                    Text(
                      'Due: ₹${_fmt(status.balance)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

// =============================================================================
// Student fee detail bottom sheet
// =============================================================================
class _StudentFeeBottomSheet extends StatefulWidget {
  final StudentFeeStatus status;
  final FeeManagementController controller;
  final VoidCallback onPaymentRecorded;
  final void Function(String) onError;

  const _StudentFeeBottomSheet({
    required this.status,
    required this.controller,
    required this.onPaymentRecorded,
    required this.onError,
  });

  @override
  State<_StudentFeeBottomSheet> createState() => _StudentFeeBottomSheetState();
}

class _StudentFeeBottomSheetState extends State<_StudentFeeBottomSheet> {
  List<PaymentEntry> _payments = [];
  bool _loadingPayments = true;
  bool _showPaymentForm = false;
  bool _isSubmitting = false;

  // Payment form controllers
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _receiptController = TextEditingController();
  String _selectedMethod = 'cash';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _loadingPayments = true);
    _payments = await widget.controller.loadPaymentsForStudent(
      widget.status.student.id,
    );
    if (mounted) setState(() => _loadingPayments = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, sc) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildFeeOverview(),
                    const SizedBox(height: 16),
                    if (_showPaymentForm) _buildPaymentForm(),
                    if (!_showPaymentForm)
                      ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _showPaymentForm = true),
                        icon: const Icon(Icons.add),
                        label: const Text('Record Payment'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Payment History',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentHistory(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final s = widget.status.student;
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primarySoft,
          child: Text(
            s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              Text(
                '${s.id} • ${s.batch.isEmpty ? "No batch" : s.batch}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeOverview() {
    final status = widget.status;
    final s = status.status;
    final Color statusColor;
    switch (s) {
      case 'paid':
        statusColor = AppColors.success;
        break;
      case 'partial':
        statusColor = AppColors.warning;
        break;
      case 'overdue':
        statusColor = AppColors.danger;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _feeRow('Amount Due', '₹${_fmt(status.amountDue)}'),
              _feeRow('Paid', '₹${_fmt(status.amountPaid)}'),
              _feeRow('Balance', '₹${_fmt(status.balance)}'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                s[0].toUpperCase() + s.substring(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Record Payment',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),

          // Amount
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              prefixIcon: Icon(Icons.currency_rupee, size: 18),
            ),
          ),
          const SizedBox(height: 10),

          // Date
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Payment Date',
                prefixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Method
          DropdownButtonFormField<String>(
            value: _selectedMethod,
            decoration: const InputDecoration(labelText: 'Payment Method'),
            items: PaymentEntry.methodOptions
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(PaymentEntry.methodLabel(m)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedMethod = v);
            },
          ),
          const SizedBox(height: 10),

          // Note (optional)
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              prefixIcon: Icon(Icons.notes, size: 18),
            ),
          ),
          const SizedBox(height: 10),

          // Receipt ref (optional)
          TextField(
            controller: _receiptController,
            decoration: const InputDecoration(
              labelText: 'Receipt Reference (optional)',
              prefixIcon: Icon(Icons.receipt, size: 18),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _showPaymentForm = false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPayment,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Payment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayment() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      widget.onError('Please enter a valid payment amount');
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.controller.recordPayment(
      studentId: widget.status.student.id,
      studentName: widget.status.student.name,
      amount: amount,
      paidAt: _selectedDate,
      method: _selectedMethod,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      receiptRef: _receiptController.text.trim().isNotEmpty
          ? _receiptController.text.trim()
          : null,
      amountDue: widget.status.amountDue,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      widget.onPaymentRecorded();
    } else {
      widget.onError('Failed to record payment. Please try again.');
    }
  }

  Widget _buildPaymentHistory() {
    if (_loadingPayments) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_payments.isEmpty) {
      return const Center(
        child: Text(
          'No payments recorded for this month.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: _payments.map((p) => _PaymentEntryCard(payment: p)).toList(),
    );
  }

  String _fmt(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

// =============================================================================
// Payment entry card
// =============================================================================
class _PaymentEntryCard extends StatelessWidget {
  final PaymentEntry payment;

  const _PaymentEntryCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isReversal = payment.amount < 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isReversal ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReversal ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isReversal ? Icons.remove_circle : Icons.check_circle,
            color: isReversal ? AppColors.danger : AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isReversal ? "-" : "+"}₹${payment.amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isReversal ? AppColors.danger : AppColors.success,
                  ),
                ),
                Text(
                  '${PaymentEntry.methodLabel(payment.method)} • ${_fmtDate(payment.paidAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (payment.note != null && payment.note!.isNotEmpty)
                  Text(
                    payment.note!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (payment.receiptRef != null && payment.receiptRef!.isNotEmpty)
            const Icon(Icons.receipt, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
