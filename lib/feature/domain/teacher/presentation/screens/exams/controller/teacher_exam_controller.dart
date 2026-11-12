import 'package:flutter/material.dart';

class TeacherExamController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  String search = '';
  String selectedFilter = 'All';
  String selectedBatch = 'All Batches';

  bool isSelectionMode = false;
  final Set<String> selectedExamIds = {};
  bool isDeleting = false;

  void setDeleting(bool val) {
    if (isDeleting == val) return;
    isDeleting = val;
    notifyListeners();
  }

  void toggleSelectionMode() {
    isSelectionMode = !isSelectionMode;
    if (!isSelectionMode) {
      selectedExamIds.clear();
    }
    notifyListeners();
  }

  void toggleExamSelection(String examId) {
    if (selectedExamIds.contains(examId)) {
      selectedExamIds.remove(examId);
    } else {
      selectedExamIds.add(examId);
    }
    notifyListeners();
  }

  void selectAllExams(List<String> examIds) {
    selectedExamIds.addAll(examIds);
    notifyListeners();
  }

  void clearSelection() {
    selectedExamIds.clear();
    isSelectionMode = false;
    notifyListeners();
  }

  void setSearch(String value) {
    final newValue = value.trim();

    if (search == newValue) return;

    search = newValue;
    notifyListeners();
  }

  void clearSearch() {
    if (search.isEmpty && searchController.text.isEmpty) {
      return;
    }

    search = '';
    searchController.clear();
    notifyListeners();
  }

  void setFilter(String value) {
    if (selectedFilter == value) return;

    selectedFilter = value;
    notifyListeners();
  }

  void setBatch(String value) {
    if (selectedBatch == value) return;

    selectedBatch = value;
    notifyListeners();
  }

  void normalizeBatch(List<String> batches) {
    final validBatches = {
      'All Batches',
      ...batches.map((e) => e.trim()).where((e) => e.isNotEmpty),
    };

    if (!validBatches.contains(selectedBatch)) {
      selectedBatch = 'All Batches';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
