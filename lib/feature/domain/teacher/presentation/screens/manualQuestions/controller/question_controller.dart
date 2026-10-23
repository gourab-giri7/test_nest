import 'package:flutter/material.dart';
import 'package:test_nest/model/Q&A_model.dart';

enum QuestionSource { excel, manual }

class QuestionController extends ChangeNotifier {
  final List<QAModel> _questions = [];
  QuestionSource _source = QuestionSource.manual;
  String? _excelFileName;

  // Form controllers for manual question entry
  final TextEditingController questionInputController = TextEditingController();
  final TextEditingController optionAController = TextEditingController();
  final TextEditingController optionBController = TextEditingController();
  final TextEditingController optionCController = TextEditingController();
  final TextEditingController optionDController = TextEditingController();
  String selectedAnswer = 'A';
  int? editingIndex;

  // Getters
  List<QAModel> get questions => List.unmodifiable(_questions);
  int get questionCount => _questions.length;
  QuestionSource get source => _source;
  String? get excelFileName => _excelFileName;
  bool get isEditing => editingIndex != null;

  void setSource(QuestionSource newSource) {
    if (_source != newSource) {
      _source = newSource;
      notifyListeners();
    }
  }

  void setSelectedAnswer(String ans) {
    final clean = ans.trim().toUpperCase();
    if (['A', 'B', 'C', 'D'].contains(clean)) {
      selectedAnswer = clean;
      notifyListeners();
    }
  }

  /// Sets questions imported from Excel
  void setFromExcel(List<QAModel> imported, String fileName) {
    _questions.clear();
    for (var i = 0; i < imported.length; i++) {
      final q = imported[i];
      if (q.id.trim().isEmpty) {
        q.id = 'q_${i + 1}';
      }
      _questions.add(q);
    }
    _source = QuestionSource.excel;
    _excelFileName = fileName;
    notifyListeners();
  }

  /// Validates the current manual question input
  String? validateDraft() {
    if (questionInputController.text.trim().isEmpty) {
      return 'Please enter the question text.';
    }
    if (optionAController.text.trim().isEmpty) {
      return 'Please enter Option A.';
    }
    if (optionBController.text.trim().isEmpty) {
      return 'Please enter Option B.';
    }
    if (optionCController.text.trim().isEmpty) {
      return 'Please enter Option C.';
    }
    if (optionDController.text.trim().isEmpty) {
      return 'Please enter Option D.';
    }
    if (!['A', 'B', 'C', 'D'].contains(selectedAnswer.trim().toUpperCase())) {
      return 'Please select a valid correct answer (A, B, C, or D).';
    }
    return null;
  }

  /// Adds a new manual question or updates the currently edited question
  bool addOrUpdateQuestion() {
    final error = validateDraft();
    if (error != null) {
      return false;
    }

    final newModel = QAModel(
      id:
          (editingIndex != null &&
              editingIndex! >= 0 &&
              editingIndex! < _questions.length &&
              _questions[editingIndex!].id.isNotEmpty)
          ? _questions[editingIndex!].id
          : 'q_${DateTime.now().millisecondsSinceEpoch}_${_questions.length + 1}',
      q: questionInputController.text.trim(),
      a: optionAController.text.trim(),
      b: optionBController.text.trim(),
      c: optionCController.text.trim(),
      d: optionDController.text.trim(),
      ans: selectedAnswer.trim().toUpperCase(),
    );

    if (editingIndex != null &&
        editingIndex! >= 0 &&
        editingIndex! < _questions.length) {
      _questions[editingIndex!] = newModel;
      editingIndex = null;
    } else {
      _questions.add(newModel);
    }

    _source = QuestionSource.manual;
    _clearDraft();
    notifyListeners();
    return true;
  }

  /// Starts editing an existing question
  void startEdit(int index) {
    if (index >= 0 && index < _questions.length) {
      final q = _questions[index];
      questionInputController.text = q.q;
      optionAController.text = q.a;
      optionBController.text = q.b;
      optionCController.text = q.c;
      optionDController.text = q.d;
      selectedAnswer = q.ans.trim().toUpperCase();
      if (!['A', 'B', 'C', 'D'].contains(selectedAnswer)) {
        selectedAnswer = 'A';
      }
      editingIndex = index;
      notifyListeners();
    }
  }

  /// Cancels editing mode and clears the form
  void cancelEdit() {
    editingIndex = null;
    _clearDraft();
    notifyListeners();
  }

  /// Deletes a question at index
  void deleteQuestion(int index) {
    if (index >= 0 && index < _questions.length) {
      if (editingIndex == index) {
        cancelEdit();
      } else if (editingIndex != null && editingIndex! > index) {
        editingIndex = editingIndex! - 1;
      }
      _questions.removeAt(index);
      notifyListeners();
    }
  }

  /// Reorders questions
  void reorderQuestions(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _questions.length) return;
    if (newIndex < 0 || newIndex > _questions.length) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _questions.removeAt(oldIndex);
    _questions.insert(newIndex, item);
    editingIndex = null;
    notifyListeners();
  }

  void _clearDraft() {
    questionInputController.clear();
    optionAController.clear();
    optionBController.clear();
    optionCController.clear();
    optionDController.clear();
    selectedAnswer = 'A';
  }

  /// Resets all questions and inputs
  void clearAll() {
    _questions.clear();
    _source = QuestionSource.manual;
    _excelFileName = null;
    editingIndex = null;
    _clearDraft();
    notifyListeners();
  }

  @override
  void dispose() {
    questionInputController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
    super.dispose();
  }
}
