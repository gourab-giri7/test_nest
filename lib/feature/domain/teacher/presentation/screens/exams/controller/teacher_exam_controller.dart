import 'package:flutter/material.dart';

class TeacherExamController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  String search = '';
  String selectedFilter = 'All';
  String selectedBatch = 'All Batches';

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
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
