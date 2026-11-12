import 'package:flutter/material.dart';

class BatchManagementController extends ChangeNotifier {
  bool isSelectionMode = false;
  final Set<String> selectedBatchIds = {};
  bool isDeleting = false;

  void toggleSelectionMode() {
    isSelectionMode = !isSelectionMode;
    if (!isSelectionMode) {
      selectedBatchIds.clear();
    }
    notifyListeners();
  }

  void toggleBatchSelection(String batchId) {
    if (selectedBatchIds.contains(batchId)) {
      selectedBatchIds.remove(batchId);
    } else {
      selectedBatchIds.add(batchId);
    }
    notifyListeners();
  }

  void selectAll(List<String> batchIds) {
    selectedBatchIds.addAll(batchIds);
    notifyListeners();
  }

  void clearSelection() {
    selectedBatchIds.clear();
    isSelectionMode = false;
    notifyListeners();
  }

  void setDeleting(bool val) {
    if (isDeleting == val) return;
    isDeleting = val;
    notifyListeners();
  }
}

class CreateBatchController extends ChangeNotifier {
  bool feeTrackingEnabled = true;
  bool isLoading = false;
  dynamic createdBatch;

  void setFeeTracking(bool val) {
    if (feeTrackingEnabled != val) {
      feeTrackingEnabled = val;
      notifyListeners();
    }
  }

  void setLoading(bool val) {
    if (isLoading != val) {
      isLoading = val;
      notifyListeners();
    }
  }

  void setCreatedBatch(dynamic batch) {
    createdBatch = batch;
    notifyListeners();
  }

  void reset() {
    feeTrackingEnabled = true;
    isLoading = false;
    createdBatch = null;
    notifyListeners();
  }
}

class JoinRequestsController extends ChangeNotifier {
  final Set<String> processingIds = {};

  bool isProcessing(String id) => processingIds.contains(id);

  void setProcessing(String id, bool val) {
    if (val) {
      processingIds.add(id);
    } else {
      processingIds.remove(id);
    }
    notifyListeners();
  }
}

class PromoteStudentsController extends ChangeNotifier {
  final Set<String> selectedStudentDocIds = {};
  dynamic targetBatch;
  bool isPromoting = false;

  void toggleAll(List docs) {
    if (selectedStudentDocIds.length == docs.length) {
      selectedStudentDocIds.clear();
    } else {
      selectedStudentDocIds.clear();
      for (final doc in docs) {
        selectedStudentDocIds.add(doc.id as String);
      }
    }
    notifyListeners();
  }

  void toggleStudent(String docId, bool? val) {
    if (val == true) {
      selectedStudentDocIds.add(docId);
    } else {
      selectedStudentDocIds.remove(docId);
    }
    notifyListeners();
  }

  void setTargetBatch(dynamic batch) {
    targetBatch = batch;
    notifyListeners();
  }

  void setPromoting(bool val) {
    if (isPromoting != val) {
      isPromoting = val;
      notifyListeners();
    }
  }

  void clearSelection() {
    selectedStudentDocIds.clear();
    notifyListeners();
  }
}
