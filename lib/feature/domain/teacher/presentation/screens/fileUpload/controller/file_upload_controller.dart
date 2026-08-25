import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/data/models/Q&A_model.dart';

class FileUploadController extends ChangeNotifier {
  String? slectedFileName;
  List<QAModel> questions = [];
  static Future<bool> downloadTemplate() async {
    try {
      // Load Excel file from assets
      const assetPath = 'assets/Sample questions sheet.xlsx';

      final ByteData data = await rootBundle.load(assetPath);

      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();

      // Create temporary file
      final File file = File('${tempDir.path}/Template_sheet.xlsx');

      // Write asset bytes
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

      // Open native save dialog
      final String? savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: file.path,
          fileName:
              'Template_sheet_${DateTime.timestamp().hour}${DateTime.timestamp().microsecond}.xlsx',
        ),
      );

      if (savedPath != null) {
        log('Excel saved at: $savedPath');
        return true;
      }

      log('User cancelled saving');
      return false;
    } catch (e) {
      log('Download error', error: e);

      return false;
    }
  }

  Future<void> pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null) return;

      final PlatformFile file = result.first;

      slectedFileName = file.name;

      final bytes = await file.readAsBytes();

      // if (bytes == null) {
      //   customSnackbar(
      //     context: context,
      //     message: 'Unable to read the selected file.',
      //     color: Colors.red,
      //     ico: Icons.error,
      //   );
      //   return;
      // }

      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        customSnackbar(
          context: context,
          message: 'Excel file does not contain any sheet.',
          color: Colors.red,
          ico: Icons.error,
        );
        return;
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        customSnackbar(
          context: context,
          message: 'Unable to read the Excel sheet.',
          color: Colors.red,
          ico: Icons.error,
        );
        return;
      }

      // ---------------- HEADER CHECK ----------------

      final questionHeader = _getCell(sheet, row: 1, column: 6);

      final optionHeader = _getCell(sheet, row: 1, column: 7);

      final answerHeader = _getCell(sheet, row: 1, column: 11);

      if (!_isSame(questionHeader, 'Questions')) {
        customSnackbar(
          context: context,
          message: 'Invalid template: "Questions" header is missing.',
          color: Colors.red,
          ico: Icons.error,
        );
        return;
      }

      if (!_isSame(optionHeader, 'Options')) {
        customSnackbar(
          context: context,
          message: 'Invalid template: "Options" header is missing.',
          color: Colors.red,
          ico: Icons.error,
        );
        return;
      }

      if (!_isSame(answerHeader, 'Right option (A,B,C,D)')) {
        customSnackbar(
          context: context,
          message:
              'Invalid template: "Right option (A,B,C,D)" header is missing.',
          color: Colors.red,
          ico: Icons.error,
        );
        return;
      }

      // ---------------- A B C D CHECK ----------------

      final optionA = _getCell(sheet, row: 2, column: 7);

      final optionB = _getCell(sheet, row: 2, column: 8);

      final optionC = _getCell(sheet, row: 2, column: 9);

      final optionD = _getCell(sheet, row: 2, column: 10);

      if (!_isSame(optionA, 'A') ||
          !_isSame(optionB, 'B') ||
          !_isSame(optionC, 'C') ||
          !_isSame(optionD, 'D')) {
        customSnackbar(
          context: context,
          message: 'Invalid template: Options must be A, B, C and D.',
          color: Colors.red,
          ico: Icons.error,
        );
        return;
      }

      // ---------------- EXTRACT QUESTIONS ----------------

      final List<QAModel> tempQuestions = [];

      for (int row = 3; row < sheet.maxRows; row++) {
        final question = _getCell(
          sheet,
          row: row,
          column: 6, // G
        );

        final a = _getCell(
          sheet,
          row: row,
          column: 7, // H
        );

        final b = _getCell(
          sheet,
          row: row,
          column: 8, // I
        );

        final c = _getCell(
          sheet,
          row: row,
          column: 9, // J
        );

        final d = _getCell(
          sheet,
          row: row,
          column: 10, // K
        );

        final ans = _getCell(
          sheet,
          row: row,
          column: 11, // L
        );

        // Ignore completely empty rows
        if (question.isEmpty &&
            a.isEmpty &&
            b.isEmpty &&
            c.isEmpty &&
            d.isEmpty &&
            ans.isEmpty) {
          continue;
        }

        // ---------------- QUESTION ----------------

        if (question.isEmpty) {
          customSnackbar(
            context: context,
            message: 'Question is empty at row ${row + 1}.',
            color: Colors.red,
            ico: Icons.error,
          );
          return;
        }

        // ---------------- OPTIONS ----------------

        if (a.isEmpty || b.isEmpty || c.isEmpty || d.isEmpty) {
          customSnackbar(
            context: context,
            message: 'All four options are required at row ${row + 1}.',
            color: Colors.red,
            ico: Icons.error,
          );
          return;
        }

        // ---------------- ANSWER ----------------

        final correctAnswer = ans.trim().toUpperCase();

        if (!['A', 'B', 'C', 'D'].contains(correctAnswer)) {
          customSnackbar(
            context: context,
            message: 'Invalid answer at row ${row + 1}. Use A, B, C or D.',
            color: Colors.red,
            ico: Icons.error,
          );
          return;
        }

        // ---------------- CREATE MODEL ----------------

        tempQuestions.add(
          QAModel(q: question, a: a, b: b, c: c, d: d, ans: correctAnswer),
        );
      }

      // ---------------- NO QUESTIONS ----------------

      if (tempQuestions.isEmpty) {
        customSnackbar(
          context: context,
          message: 'No questions found in the Excel file.',
          color: Colors.red,
          ico: Icons.error,
        );
        return;
      }

      // ---------------- SAVE QUESTIONS ----------------

      questions = tempQuestions;

      log('Excel format is valid');
      log('Total Questions: ${questions.length}');

      for (final question in questions) {
        log('''
Question: ${question.q}
A: ${question.a}
B: ${question.b}
C: ${question.c}
D: ${question.d}
Answer: ${question.ans}
----------------------------
''');
      }

      customSnackbar(
        context: context,
        message: '${questions.length} questions imported successfully.',
        color: Colors.green,
        ico: Icons.check_circle,
      );

      notifyListeners();
    } catch (e, stackTrace) {
      log('Excel error', error: e, stackTrace: stackTrace);

      customSnackbar(
        context: context,
        message: 'Something went wrong while reading the Excel file.',
        color: Colors.red,
        ico: Icons.error,
      );
    }
  }

  String _getCell(Sheet sheet, {required int row, required int column}) {
    if (row >= sheet.maxRows) {
      return '';
    }

    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
    );

    return cell.value?.toString().trim() ?? '';
  }

  bool _isSame(String value, String expected) {
    String normalize(String text) {
      return text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    }

    return normalize(value) == normalize(expected);
  }

  // ---- cancel selected file
  void cancelFile() {
    slectedFileName = null;
    questions = [];
    notifyListeners();
  }
}
