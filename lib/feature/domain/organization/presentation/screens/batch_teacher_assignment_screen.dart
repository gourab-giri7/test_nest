import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/core/services/batch_assignment_service.dart';
import 'package:test_nest/core/utils/theme/theme.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/organization_model.dart';

class _BatchTeacherAssignmentData extends ChangeNotifier {
  BatchModel currentBatch;
  List<OrganizationMemberModel> allMembers = [];
  bool isLoading = true;
  String searchQuery = '';

  _BatchTeacherAssignmentData(this.currentBatch);

  List<OrganizationMemberModel> get assigned => allMembers
      .where((m) => currentBatch.assignedTeacherIds.contains(m.uid))
      .toList();

  List<OrganizationMemberModel> get unassigned => allMembers
      .where((m) => !currentBatch.assignedTeacherIds.contains(m.uid))
      .where((m) {
        final q = searchQuery.toLowerCase();
        return m.name.toLowerCase().contains(q) ||
            m.email.toLowerCase().contains(q);
      })
      .toList();

  void setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  void setData({
    BatchModel? batch,
    List<OrganizationMemberModel>? members,
  }) {
    if (batch != null) currentBatch = batch;
    if (members != null) allMembers = members;
    isLoading = false;
    notifyListeners();
  }

  void updateBatch(BatchModel batch) {
    currentBatch = batch;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }
}

class BatchTeacherAssignmentScreen extends StatefulWidget {
  final String orgId;
  final BatchModel batch;

  const BatchTeacherAssignmentScreen({
    super.key,
    required this.orgId,
    required this.batch,
  });

  @override
  State<BatchTeacherAssignmentScreen> createState() =>
      _BatchTeacherAssignmentScreenState();
}

class _BatchTeacherAssignmentScreenState
    extends State<BatchTeacherAssignmentScreen> {
  final BatchAssignmentService _assignmentService = BatchAssignmentService();
  final TextEditingController _searchController = TextEditingController();
  late final _BatchTeacherAssignmentData _data;

  BatchModel get _currentBatch => _data.currentBatch;

  @override
  void initState() {
    super.initState();
    _data = _BatchTeacherAssignmentData(widget.batch);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _data.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _data.setLoading(true);
    try {
      final updatedBatch = await _assignmentService.getBatch(
        widget.orgId,
        _currentBatch.id,
      );

      final membersStream = _assignmentService.streamOrganizationTeachers(
        widget.orgId,
      );
      final members = await membersStream.first;
      if (mounted) {
        _data.setData(batch: updatedBatch, members: members);
      }
    } catch (e) {
      if (mounted) {
        _data.setLoading(false);
      }
    }
  }

  Future<void> _assignTeacher(OrganizationMemberModel member) async {
    try {
      await _assignmentService.assignTeacherToBatch(
        orgId: widget.orgId,
        batchId: _currentBatch.id,
        teacherUid: member.uid,
      );

      final updatedIds = List<String>.from(_currentBatch.assignedTeacherIds)
        ..add(member.uid);
      _data.updateBatch(_currentBatch.copyWith(assignedTeacherIds: updatedIds));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} assigned to batch'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign teacher: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmRemoveTeacher(OrganizationMemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Teacher Assignment?'),
        content: Text(
          'Remove ${member.name} from ${_currentBatch.name}? The batch, its students, and historical exams will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _assignmentService.removeTeacherFromBatch(
          orgId: widget.orgId,
          batchId: _currentBatch.id,
          teacherUid: member.uid,
        );

        final updatedIds = List<String>.from(_currentBatch.assignedTeacherIds)
          ..remove(member.uid);
        _data.updateBatch(
          _currentBatch.copyWith(assignedTeacherIds: updatedIds),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.name} removed from batch'),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<_BatchTeacherAssignmentData>.value(
      value: _data,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Selector<_BatchTeacherAssignmentData, String>(
            selector: (_, d) => d.currentBatch.name,
            builder: (_, name, __) => Text(
              'Assign Teachers: $name',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
        ),
        body: Selector<_BatchTeacherAssignmentData, bool>(
          selector: (_, d) => d.isLoading,
          builder: (_, isLoading, __) => isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Batch Information Card
                      Consumer<_BatchTeacherAssignmentData>(
                        builder: (_, d, __) => Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _currentBatch.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Code: ${_currentBatch.activeJoinCode}',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_currentBatch.subject != null &&
                              _currentBatch.subject!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Subject: ${_currentBatch.subject}',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            'Students Enrolled: ${_currentBatch.studentCount}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                  const SizedBox(height: 20),

                  // Section 1: Assigned Teachers
                  Consumer<_BatchTeacherAssignmentData>(
                    builder: (_, d, __) {
                      final assigned = d.assigned;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.supervised_user_circle,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Assigned Teachers (${assigned.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                  const SizedBox(height: 10),

                  if (assigned.isEmpty)
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_off_outlined,
                                size: 36,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No teachers currently assigned to this batch.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...assigned.map((teacher) {
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(
                              0.15,
                            ),
                            child: Text(
                              teacher.name.isNotEmpty
                                  ? teacher.name[0].toUpperCase()
                                  : 'T',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            teacher.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            teacher.email,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: TextButton.icon(
                            onPressed: () => _confirmRemoveTeacher(teacher),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      );
                    }),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Section 2: Available Teachers
                  Row(
                    children: [
                      const Icon(
                        Icons.person_add_outlined,
                        color: Colors.indigo,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Selector<_BatchTeacherAssignmentData, int>(
                        selector: (_, d) => d.unassigned.length,
                        builder: (_, count, __) => Text(
                          'Available Institute Teachers ($count)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search input
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search teacher by name or email...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (val) => _data.setSearchQuery(val),
                  ),
                  const SizedBox(height: 10),

                  Consumer<_BatchTeacherAssignmentData>(
                    builder: (_, d, __) {
                      final unassigned = d.unassigned;
                      if (unassigned.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              d.searchQuery.isEmpty
                                  ? 'All institute teachers are already assigned to this batch.'
                                  : 'No matching teachers found.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: unassigned.map((teacher) {
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            child: Text(
                              teacher.name.isNotEmpty
                                  ? teacher.name[0].toUpperCase()
                                  : 'T',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            teacher.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            teacher.email,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _assignTeacher(teacher),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Assign'),
                          ),
                        ),
                      );
                    }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}
