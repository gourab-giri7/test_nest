import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/context/active_tenant_context.dart';
import 'package:test_nest/core/services/tenant_path_resolver.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/feature/domain/organization/presentation/controllers/notice_editor_controller.dart';
import 'package:test_nest/model/notice_model.dart';

class NoticeEditorScreen extends StatefulWidget {
  final NoticeModel? notice;
  final String? fallbackTeacherId;

  const NoticeEditorScreen({super.key, this.notice, this.fallbackTeacherId});

  @override
  State<NoticeEditorScreen> createState() => _NoticeEditorScreenState();
}

class _NoticeEditorScreenState extends State<NoticeEditorScreen> {
  late final NoticeEditorController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = NoticeEditorController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _initData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  TenantPathResolver _getResolver() {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.read<ActiveTenantContext>();
    } catch (_) {}
    return TenantPathResolver(tenantContext: tenantCtx);
  }

  Future<void> _initData() async {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.read<ActiveTenantContext>();
    } catch (_) {}

    final resolver = _getResolver();
    final user = FirebaseAuth.instance.currentUser;
    final teacherUid = user?.uid ?? widget.fallbackTeacherId ?? '';
    final isTeacherInInstitute =
        tenantCtx != null && tenantCtx.isInstitute && tenantCtx.isTeacher;

    final passedNotice =
        widget.notice ??
        (Get.arguments is NoticeModel ? Get.arguments as NoticeModel : null);

    await _controller.initialize(
      resolver: resolver,
      existingNotice: passedNotice,
      teacherUid: teacherUid,
      isTeacherInInstitute: isTeacherInInstitute,
      fallbackTeacherId: widget.fallbackTeacherId ?? teacherUid,
    );

    _titleController.text = _controller.title;
    _bodyController.text = _controller.body;

    _titleController.addListener(() {
      _controller.setTitle(_titleController.text);
    });
    _bodyController.addListener(() {
      _controller.setBody(_bodyController.text);
    });
  }

  Future<bool> _handlePop() async {
    if (!_controller.isDirty) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes to this notice. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (discard == true) {
      _controller.discardChanges();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ActiveTenantContext? tenantCtx;
    try {
      tenantCtx = context.watch<ActiveTenantContext>();
    } catch (_) {}

    final isInstitute = tenantCtx?.isInstitute ?? false;
    final isAdmin = tenantCtx?.isAdmin ?? true;

    return ChangeNotifierProvider<NoticeEditorController>.value(
      value: _controller,
      child: Consumer<NoticeEditorController>(
        builder: (context, controller, child) {
          return PopScope(
            canPop: !controller.isDirty,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final shouldPop = await _handlePop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(
                  controller.isEditing ? 'Edit Notice' : 'Create Notice',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.text,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    final shouldPop = await _handlePop();
                    if (shouldPop && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              body: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (controller.errorMessage != null) ...[
                            _buildErrorBanner(controller.errorMessage!),
                            const SizedBox(height: 14),
                          ],
                          _buildContentCard(controller),
                          const SizedBox(height: 16),
                          _buildAudienceCard(controller, isInstitute, isAdmin),
                        ],
                      ),
                    ),
              bottomNavigationBar: _buildBottomActions(controller),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(NoticeEditorController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notice Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Notice Title *',
              hintText: 'e.g. Schedule Revision for Physics Batch',
              prefixIcon: const Icon(
                Icons.title,
                size: 20,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: NoticeCategory.all.map((cat) {
                final isSelected = controller.category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(NoticeCategory.displayName(cat)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) controller.setCategory(cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bodyController,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Message Body *',
              hintText: 'Write the complete announcement details here...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceCard(
    NoticeEditorController controller,
    bool isInstitute,
    bool isAdmin,
  ) {
    final allowAll = !isInstitute || isAdmin;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Audience',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose who can see this announcement.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (allowAll)
            RadioListTile<String>(
              value: NoticeAudienceType.all,
              groupValue: controller.audienceType,
              title: Text(
                isInstitute ? 'All Students in Institute' : 'All My Students',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: const Text(
                'Visible to every student enrolled in this workspace.',
                style: TextStyle(fontSize: 12),
              ),
              onChanged: (val) => controller.setAudienceType(val!),
              contentPadding: EdgeInsets.zero,
            ),
          RadioListTile<String>(
            value: NoticeAudienceType.batches,
            groupValue: controller.audienceType,
            title: const Text(
              'Selected Batches',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text(
              'Target specific batch rosters only.',
              style: TextStyle(fontSize: 12),
            ),
            onChanged: (val) => controller.setAudienceType(val!),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: NoticeAudienceType.students,
            groupValue: controller.audienceType,
            title: const Text(
              'Specific Individual Students',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text(
              'Target selected individual students.',
              style: TextStyle(fontSize: 12),
            ),
            onChanged: (val) => controller.setAudienceType(val!),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 20),
          if (controller.audienceType == NoticeAudienceType.batches)
            _buildBatchSelector(controller),
          if (controller.audienceType == NoticeAudienceType.students)
            _buildStudentSelector(controller),
        ],
        ),
      ),
    );
  }

  Widget _buildBatchSelector(NoticeEditorController controller) {
    if (controller.availableBatches.isEmpty) {
      return const Text(
        'No batches available to target.',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Batches (${controller.selectedBatchIds.length}/${controller.availableBatches.length})',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: controller.selectAllBatches,
                  child: const Text(
                    'Select All',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                TextButton(
                  onPressed: controller.deselectAllBatches,
                  child: const Text('Clear', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.availableBatches.map((batch) {
            final isSelected = controller.selectedBatchIds.contains(batch.id);
            return FilterChip(
              label: Text(batch.name),
              selected: isSelected,
              selectedColor: AppColors.primarySoft,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (_) => controller.toggleBatch(
                batch.id,
                resolver: _getResolver(),
                fallbackTeacherId: widget.fallbackTeacherId,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStudentSelector(NoticeEditorController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBatchSelector(controller),
        const SizedBox(height: 14),
        if (controller.selectedBatchIds.isEmpty)
          const Text(
            'Select at least one batch above to choose students.',
            style: TextStyle(color: AppColors.warning, fontSize: 12),
          )
        else if (controller.availableStudents.isEmpty)
          const Text(
            'No students found in the selected batch(es).',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Students (${controller.selectedStudentIds.length}/${controller.availableStudents.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: controller.selectAllStudents,
                    child: const Text(
                      'Select All',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.deselectAllStudents,
                    child: const Text('Clear', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.availableStudents.map((student) {
              final key = student.authUid.isNotEmpty
                  ? student.authUid
                  : student.id;
              final isSelected = controller.selectedStudentIds.contains(key);
              return FilterChip(
                label: Text('${student.name} (${student.batch})'),
                selected: isSelected,
                selectedColor: AppColors.primarySoft,
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (_) => controller.toggleStudent(key),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomActions(NoticeEditorController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: controller.isSaving
                    ? null
                    : () async {
                        final user = FirebaseAuth.instance.currentUser;
                        final uid = user?.uid ?? widget.fallbackTeacherId ?? '';
                        final name = user?.displayName ?? 'Staff';

                        final saved = await controller.saveNotice(
                          resolver: _getResolver(),
                          publish: false,
                          userUid: uid,
                          userName: name,
                          fallbackTeacherId: widget.fallbackTeacherId,
                        );

                        if (saved != null && mounted) {
                          Get.back(result: saved);
                        }
                      },
                child: const Text(
                  'Save as Draft',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: controller.isSaving
                    ? null
                    : () async {
                        final user = FirebaseAuth.instance.currentUser;
                        final uid = user?.uid ?? widget.fallbackTeacherId ?? '';
                        final name = user?.displayName ?? 'Staff';

                        final saved = await controller.saveNotice(
                          resolver: _getResolver(),
                          publish: true,
                          userUid: uid,
                          userName: name,
                          fallbackTeacherId: widget.fallbackTeacherId,
                        );

                        if (saved != null && mounted) {
                          Get.back(result: saved);
                        }
                      },
                child: controller.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Publish Notice',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
