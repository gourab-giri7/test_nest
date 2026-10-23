import 'dart:developer';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/manualQuestions/controller/question_controller.dart';
import 'package:test_nest/model/Q&A_model.dart';

class FileUploadController extends ChangeNotifier {
  String? slectedFileName;
  List<QAModel> questions = [];

  // ============================================================
  // DOWNLOAD EXCEL TEMPLATE
  // ============================================================

  static Future<bool> downloadTemplate() async {
    try {
      const assetPath = 'assets/Sample questions sheet.xlsx';

      final ByteData data = await rootBundle.load(assetPath);

      final Directory tempDir = await getTemporaryDirectory();

      final File file = File('${tempDir.path}/Template_sheet.xlsx');

      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

      final String? savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: file.path,
          fileName:
              'Template_sheet_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        ),
      );

      if (savedPath != null) {
        log('Excel saved at: $savedPath');
        return true;
      }

      log('User cancelled saving');
      return false;
    } catch (e, stackTrace) {
      log('Download error', error: e, stackTrace: stackTrace);

      return false;
    }
  }

  // ============================================================
  // PICK EXCEL FILE
  // ============================================================

  Future<void> pickFile(BuildContext context, [QuestionController? qc]) async {
    try {
      // ----------------------------------------------------------
      // FILE PICKER 12.x API
      // ----------------------------------------------------------

      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (files.isEmpty) {
        return;
      }

      final PlatformFile file = files.first;

      log('Selected file: ${file.name}');

      // ----------------------------------------------------------
      // READ FILE
      // ----------------------------------------------------------

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        if (!context.mounted) return;

        customSnackbar(
          context: context,
          message: 'Unable to read the selected Excel file.',
          color: Colors.red,
          ico: Icons.error,
        );

        return;
      }

      log('Excel file size: ${bytes.length} bytes');

      // ----------------------------------------------------------
      // DECODE EXCEL
      // ----------------------------------------------------------

      final Excel excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        if (!context.mounted) return;

        customSnackbar(
          context: context,
          message: 'Excel file does not contain any sheet.',
          color: Colors.red,
          ico: Icons.error,
        );

        return;
      }

      // ----------------------------------------------------------
      // GET FIRST SHEET
      // ----------------------------------------------------------

      final String sheetName = excel.tables.keys.first;

      final Sheet? sheet = excel.tables[sheetName];

      if (sheet == null) {
        if (!context.mounted) return;

        customSnackbar(
          context: context,
          message: 'Unable to read the Excel sheet.',
          color: Colors.red,
          ico: Icons.error,
        );

        return;
      }

      log('Sheet name: $sheetName');
      log('Rows: ${sheet.maxRows}');
      log('Columns: ${sheet.maxColumns}');

      // ==========================================================
      // HEADER CHECK
      // ==========================================================

      // G2
      final String questionHeader = _getCell(sheet, row: 1, column: 6);

      // H2
      final String optionHeader = _getCell(sheet, row: 1, column: 7);

      // L2
      final String answerHeader = _getCell(sheet, row: 1, column: 11);

      log('Question Header = "$questionHeader"');
      log('Option Header   = "$optionHeader"');
      log('Answer Header   = "$answerHeader"');

      // ----------------------------------------------------------
      // QUESTIONS HEADER
      // ----------------------------------------------------------

      if (!_isSame(questionHeader, 'Questions')) {
        if (!context.mounted) return;

        customSnackbar(
          context: context,
          message: 'Invalid template: "Questions" header is missing.',
          color: Colors.red,
          ico: Icons.error,
        );

        return;
      }

      // ----------------------------------------------------------
      // OPTIONS HEADER
      // ----------------------------------------------------------

      if (!_isSame(optionHeader, 'Options')) {
        if (!context.mounted) return;

        customSnackbar(
          context: context,
          message: 'Invalid template: "Options" header is missing.',
          color: Colors.red,
          ico: Icons.error,
        );

        return;
      }

      // ----------------------------------------------------------
      // ANSWER HEADER
      // ----------------------------------------------------------

      if (!_isSame(answerHeader, 'Right option (A,B,C,D)')) {
        if (!context.mounted) return;

        customSnackbar(
          context: context,
          message:
              'Invalid template: "Right option (A,B,C,D)" header is missing.',
          color: Colors.red,
          ico: Icons.error,
        );

        return;
      }

      // ==========================================================
      // A B C D CHECK
      // ==========================================================

      // H3
      final String optionA = _getCell(sheet, row: 2, column: 7);

      // I3
      final String optionB = _getCell(sheet, row: 2, column: 8);

      // J3
      final String optionC = _getCell(sheet, row: 2, column: 9);

      // K3
      final String optionD = _getCell(sheet, row: 2, column: 10);

      log('Option A = "$optionA"');
      log('Option B = "$optionB"');
      log('Option C = "$optionC"');
      log('Option D = "$optionD"');

      if (!_isSame(optionA, 'A') ||
          !_isSame(optionB, 'B') ||
          !_isSame(optionC, 'C') ||
          !_isSame(optionD, 'D')) {
        if (!context.mounted) return;

        customSnackbar(
          context: context,
          message: 'Invalid template: Options must be A, B, C and D.',
          color: Colors.red,
          ico: Icons.error,
        );

        return;
      }

      // ==========================================================
      // EXTRACT QUESTIONS
      // ==========================================================

      final List<QAModel> tempQuestions = [];

      // Excel row 4 = Dart row index 3
      for (int row = 3; row < sheet.maxRows; row++) {
        // --------------------------------------------------------
        // QUESTION - G
        // --------------------------------------------------------

        final String question = _getCell(sheet, row: row, column: 6);

        // --------------------------------------------------------
        // OPTION A - H
        // --------------------------------------------------------

        final String a = _getCell(sheet, row: row, column: 7);

        // --------------------------------------------------------
        // OPTION B - I
        // --------------------------------------------------------

        final String b = _getCell(sheet, row: row, column: 8);

        // --------------------------------------------------------
        // OPTION C - J
        // --------------------------------------------------------

        final String c = _getCell(sheet, row: row, column: 9);

        // --------------------------------------------------------
        // OPTION D - K
        // --------------------------------------------------------

        final String d = _getCell(sheet, row: row, column: 10);

        // --------------------------------------------------------
        // ANSWER - L
        // --------------------------------------------------------

        final String ans = _getCell(sheet, row: row, column: 11);

        // --------------------------------------------------------
        // IGNORE COMPLETELY EMPTY ROWS
        // --------------------------------------------------------

        if (question.isEmpty &&
            a.isEmpty &&
            b.isEmpty &&
            c.isEmpty &&
            d.isEmpty &&
            ans.isEmpty) {
          continue;
        }

        final int excelRow = row + 1;

        log(
          'Row $excelRow => '
          'Q="$question", '
          'A="$a", '
          'B="$b", '
          'C="$c", '
          'D="$d", '
          'Ans="$ans"',
        );

        // ========================================================
        // QUESTION VALIDATION
        // ========================================================

        if (question.isEmpty) {
          if (!context.mounted) return;

          customSnackbar(
            context: context,
            message: 'Question is empty at row $excelRow.',
            color: Colors.red,
            ico: Icons.error,
          );

          return;
        }

        // ========================================================
        // OPTION VALIDATION
        // ========================================================

        if (a.isEmpty || b.isEmpty || c.isEmpty || d.isEmpty) {
          if (!context.mounted) return;

          customSnackbar(
            context: context,
            message: 'All four options are required at row $excelRow.',
            color: Colors.red,
            ico: Icons.error,
          );

          return;
        }

        // ========================================================
        // ANSWER VALIDATION
        // ========================================================

        final String correctAnswer = ans.trim().toUpperCase();

        if (!['A', 'B', 'C', 'D'].contains(correctAnswer)) {
          if (!context.mounted) return;

          customSnackbar(
            context: context,
            message:
                'Invalid answer at row $excelRow. '
                'Use A, B, C or D.',
            color: Colors.red,
            ico: Icons.error,
          );

          return;
        }

        // ========================================================
        // CREATE Q&A MODEL
        // ========================================================

        tempQuestions.add(
          QAModel(q: question, a: a, b: b, c: c, d: d, ans: correctAnswer),
        );
      }

      // ==========================================================
      // NO QUESTIONS
      // ==========================================================

      if (tempQuestions.isEmpty) {
        if (!context.mounted) return;

        customSnackbar(
          context: context,
          message: 'No valid questions found in the Excel file.',
          color: Colors.red,
          ico: Icons.error,
        );

        return;
      }

      // ==========================================================
      // SAVE QUESTIONS
      // ==========================================================

      slectedFileName = file.name;
      questions = tempQuestions;
      qc?.setFromExcel(tempQuestions, file.name);

      log('==========================================');
      log('Excel format is VALID');
      log('File: ${file.name}');
      log('Total Questions: ${questions.length}');
      log('==========================================');

      for (int i = 0; i < questions.length; i++) {
        final QAModel question = questions[i];

        log('''
Question ${i + 1}: ${question.q}
A: ${question.a}
B: ${question.b}
C: ${question.c}
D: ${question.d}
Answer: ${question.ans}
------------------------------------------
''');
      }

      // ==========================================================
      // PROVIDER UPDATE
      // ==========================================================

      notifyListeners();

      // ==========================================================
      // SUCCESS
      // ==========================================================

      if (!context.mounted) return;

      customSnackbar(
        context: context,
        message: '${questions.length} questions imported successfully.',
        color: Colors.green,
        ico: Icons.check_circle,
      );
    } catch (e, stackTrace) {
      log('Excel error', error: e, stackTrace: stackTrace);

      if (!context.mounted) return;

      customSnackbar(
        context: context,
        message: 'Something went wrong while reading the Excel file.',
        color: Colors.red,
        ico: Icons.error,
      );
    }
  }

  // ============================================================
  // GET CELL VALUE
  // ============================================================

  String _getCell(Sheet sheet, {required int row, required int column}) {
    if (row < 0 ||
        column < 0 ||
        row >= sheet.maxRows ||
        column >= sheet.maxColumns) {
      return '';
    }

    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
    );

    final CellValue? value = cell.value;

    if (value == null) {
      return '';
    }

    // ----------------------------------------------------------
    // TEXT CELL
    // ----------------------------------------------------------

    if (value is TextCellValue) {
      return value.value.toString().trim();
    }

    // ----------------------------------------------------------
    // INTEGER CELL
    // ----------------------------------------------------------

    if (value is IntCellValue) {
      return value.value.toString().trim();
    }

    // ----------------------------------------------------------
    // DOUBLE CELL
    // ----------------------------------------------------------

    if (value is DoubleCellValue) {
      return value.value.toString().trim();
    }

    // ----------------------------------------------------------
    // BOOLEAN CELL
    // ----------------------------------------------------------

    if (value is BoolCellValue) {
      return value.value.toString().trim();
    }

    // ----------------------------------------------------------
    // FORMULA CELL
    // ----------------------------------------------------------

    if (value is FormulaCellValue) {
      return value.formula.toString().trim();
    }

    // ----------------------------------------------------------
    // DATE/TIME CELL
    // ----------------------------------------------------------

    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal().toString().trim();
    }

    // ----------------------------------------------------------
    // TIME CELL
    // ----------------------------------------------------------

    if (value is TimeCellValue) {
      return value.asDuration().toString().trim();
    }

    // ----------------------------------------------------------
    // FALLBACK
    // ----------------------------------------------------------

    return value.toString().trim();
  }

  // ============================================================
  // COMPARE CELL TEXT
  // ============================================================

  bool _isSame(String value, String expected) {
    String normalize(String text) {
      return text
          .replaceAll('\uFEFF', '')
          .replaceAll('\u00A0', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .toLowerCase();
    }

    return normalize(value) == normalize(expected);
  }

  // ============================================================
  // CANCEL SELECTED FILE
  // ============================================================

  void cancelFile() {
    slectedFileName = null;
    questions = [];

    notifyListeners();
  }
}
