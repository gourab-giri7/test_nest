import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/teacher_salary_service.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/owner_finance_controller.dart';
import 'package:test_nest/model/teacher_salary_model.dart';

class OwnerTeacherSalariesScreen extends StatelessWidget {
  const OwnerTeacherSalariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tenantCtx = Provider.of<ActiveTenantContext>(context, listen: false);

    return ChangeNotifierProvider(
      create: (_) => OwnerTeacherSalariesController(tenantContext: tenantCtx),
      child: const _OwnerTeacherSalariesView(),
    );
  }
}

class _OwnerTeacherSalariesView extends StatelessWidget {
  const _OwnerTeacherSalariesView();

  static const Color _primary = Color(0xFF4F46E5);
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate600 = Color(0xFF475569);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _green = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OwnerTeacherSalariesController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Teacher Salary Management',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _slate900,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: _slate600),
            onPressed: controller.isLoading
                ? null
                : () => controller.loadData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadData(),
        child: Column(
          children: [
            _buildMonthNavigator(context, controller),
            _buildSummaryHeader(controller),
            _buildFiltersAndSearch(context, controller),
            Expanded(child: _buildTeacherList(context, controller)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Month Navigator
  // ---------------------------------------------------------------------------
  Widget _buildMonthNavigator(
    BuildContext context,
    OwnerTeacherSalariesController c,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: _slate600),
            onPressed: c.isLoading ? null : c.goToPreviousMonth,
          ),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: _primary,
              ),
              const SizedBox(width: 8),
              Text(
                c.selectedMonthLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _slate900,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: _slate600),
            onPressed: c.isLoading ? null : c.goToNextMonth,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Summary Header
  // ---------------------------------------------------------------------------
  Widget _buildSummaryHeader(OwnerTeacherSalariesController c) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Salary Obligation',
                  value: '₹${c.totalObligation.toStringAsFixed(2)}',
                  color: _slate900,
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildMetricTile(
                  label: 'Total Disbursed',
                  value: '₹${c.totalPaid.toStringAsFixed(2)}',
                  color: _green,
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildMetricTile(
                  label: 'Pending Disbursal',
                  value: '₹${c.totalPending.toStringAsFixed(2)}',
                  color: c.totalPending > 0 ? _amber : _green,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCountBadge('Paid', c.paidCount, _green),
              _buildCountBadge('Partial', c.partialCount, _amber),
              _buildCountBadge('Pending', c.pendingCount, _slate600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _slate400,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Filters & Search
  // ---------------------------------------------------------------------------
  Widget _buildFiltersAndSearch(
    BuildContext context,
    OwnerTeacherSalariesController c,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by teacher name or email...',
              hintStyle: const TextStyle(fontSize: 13, color: _slate400),
              prefixIcon: const Icon(Icons.search, size: 20, color: _slate400),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: _slate100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: c.setSearchQuery,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('All', 'all', c),
                _buildStatusChip('Paid', 'paid', c),
                _buildStatusChip('Partial', 'partial', c),
                _buildStatusChip('Pending', 'pending', c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    String value,
    OwnerTeacherSalariesController c,
  ) {
    final selected = c.statusFilter.toLowerCase() == value.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => c.setStatusFilter(value),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : _slate600,
        ),
        backgroundColor: _slate100,
        selectedColor: _primary,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Teacher List
  // ---------------------------------------------------------------------------
  Widget _buildTeacherList(
    BuildContext context,
    OwnerTeacherSalariesController c,
  ) {
    if (c.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (c.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: _red),
              const SizedBox(height: 12),
              Text(
                c.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _slate600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => c.loadData(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final items = c.filteredItems;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 56,
                color: _slate400,
              ),
              const SizedBox(height: 14),
              const Text(
                'No teacher salary records found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _slate900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try adjusting your search query, status filter, or month selection.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _slate600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _buildTeacherSalaryCard(context, item, c);
      },
    );
  }

  Widget _buildTeacherSalaryCard(
    BuildContext context,
    TeacherSalaryItem item,
    OwnerTeacherSalariesController c,
  ) {
    final statusColor = _statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.teacherName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _slate900,
                      ),
                    ),
                    if (item.teacherEmail.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.teacherEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _slate400,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Base Salary',
                    style: TextStyle(fontSize: 11, color: _slate400),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${item.baseSalary.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _slate900,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Disbursed',
                    style: TextStyle(fontSize: 11, color: _slate400),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${item.amountPaid.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Remaining',
                    style: TextStyle(fontSize: 11, color: _slate400),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${item.remainingAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: item.remainingAmount > 0 ? _amber : _green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.history, size: 16),
                label: const Text('History'),
                style: TextButton.styleFrom(
                  foregroundColor: _slate600,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => _showSalaryHistoryDialog(context, item, c),
              ),
              TextButton.icon(
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Configure'),
                style: TextButton.styleFrom(
                  foregroundColor: _slate600,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => _showConfigureSalaryDialog(context, item, c),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.send, size: 15),
                label: const Text('Disburse'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showDisburseSalaryDialog(context, item, c),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return _green;
      case 'partial':
        return _amber;
      default:
        return _slate600;
    }
  }

  // ---------------------------------------------------------------------------
  // Dialog: Disburse Salary
  // ---------------------------------------------------------------------------
  void _showDisburseSalaryDialog(
    BuildContext context,
    TeacherSalaryItem item,
    OwnerTeacherSalariesController controller,
  ) {
    final amountCtrl = TextEditingController(
      text: item.remainingAmount > 0
          ? item.remainingAmount.toStringAsFixed(2)
          : item.baseSalary.toStringAsFixed(2),
    );
    final refCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    var selectedMethod = 'bank_transfer';
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Disburse Salary — ${item.teacherName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _slate900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _slate400,
                        ),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Month: ${controller.selectedMonthLabel} | Remaining: ₹${item.remainingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: _slate600),
                  ),
                  const Divider(height: 24),
                  // Amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Disbursement Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Payment Method Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Disbursement Method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text('Bank Transfer (NEFT/IMPS)'),
                      ),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null)
                        setModalState(() => selectedMethod = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Reference Number
                  TextField(
                    controller: refCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Reference / UTR Number',
                      hintText: 'e.g. UTR-987654321',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Remarks / Notes (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final parsed =
                            double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        if (parsed <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter a valid disbursement amount greater than 0',
                              ),
                            ),
                          );
                          return;
                        }

                        // Confirmation dialog
                        final confirm = await showDialog<bool>(
                          context: modalCtx,
                          builder: (cCtx) => AlertDialog(
                            title: const Text('Confirm Salary Disbursement'),
                            content: Text(
                              'Disburse ₹${parsed.toStringAsFixed(2)} to ${item.teacherName} via ${selectedMethod.replaceAll('_', ' ').toUpperCase()} for ${controller.selectedMonthLabel}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(cCtx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                ),
                                onPressed: () => Navigator.pop(cCtx, true),
                                child: const Text('Confirm Disbursal'),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        Navigator.pop(modalCtx);
                        final success = await controller.recordSalaryPayment(
                          teacherUid: item.teacherUid,
                          teacherName: item.teacherName,
                          amount: parsed,
                          paymentDate: selectedDate,
                          paymentMethod: selectedMethod,
                          recordedBy: 'Institute Owner',
                          referenceNumber: refCtrl.text.trim().isEmpty
                              ? null
                              : refCtrl.text.trim(),
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                          baseSalary: item.baseSalary,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Disbursed ₹${parsed.toStringAsFixed(2)} to ${item.teacherName}.'
                                    : 'Failed to disburse salary. Please try again.',
                              ),
                              backgroundColor: success ? _green : _red,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Submit Disbursal',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Dialog: Configure Base Salary
  // ---------------------------------------------------------------------------
  void _showConfigureSalaryDialog(
    BuildContext context,
    TeacherSalaryItem item,
    OwnerTeacherSalariesController controller,
  ) {
    final salaryCtrl = TextEditingController(
      text: item.baseSalary.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Configure Salary — ${item.teacherName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sets the ongoing monthly base salary. Changing this setting will NOT alter previously paid historical salary records.',
              style: TextStyle(fontSize: 12, color: _slate600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: salaryCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monthly Base Salary (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            onPressed: () async {
              final newSalary = double.tryParse(salaryCtrl.text.trim()) ?? 0.0;
              Navigator.pop(ctx);
              final success = await controller.configureTeacherDefaultSalary(
                teacherUid: item.teacherUid,
                baseSalary: newSalary,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Monthly base salary set to ₹${newSalary.toStringAsFixed(2)}.'
                          : 'Failed to update salary.',
                    ),
                    backgroundColor: success ? _green : _red,
                  ),
                );
              }
            },
            child: const Text('Save Salary'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialog: Salary History & Payment Ledger
  // ---------------------------------------------------------------------------
  void _showSalaryHistoryDialog(
    BuildContext context,
    TeacherSalaryItem item,
    OwnerTeacherSalariesController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Disbursement History — ${item.teacherName}'),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<SalaryPaymentEntry>>(
              future: TeacherSalaryService.getSalaryPayments(
                orgId: controller.orgId,
                teacherUid: item.teacherUid,
                billingMonth: controller.selectedMonth,
              ),
              builder: (fCtx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final entries = snap.data ?? [];
                if (entries.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No salary disbursements recorded for this month.',
                        style: TextStyle(color: _slate600),
                      ),
                    ),
                  );
                }

                final df = DateFormat('dd MMM yyyy, hh:mm a');
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, idx) {
                    final e = entries[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '₹${e.amount.toStringAsFixed(2)} (${e.paymentMethod.replaceAll('_', ' ').toUpperCase()})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${df.format(e.paymentDate)}\nRecorded by: ${e.recordedBy}${e.referenceNumber != null ? ' | Ref: ${e.referenceNumber}' : ''}',
                        style: const TextStyle(fontSize: 11, color: _slate400),
                      ),
                      trailing: const Icon(
                        Icons.check_circle,
                        color: _green,
                        size: 20,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
