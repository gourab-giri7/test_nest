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
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (files.isEmpty) return;

      final PlatformFile file = files.first;
      log('Selected file: ${file.name}');

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (context.mounted) _error(context, 'Unable to read the selected Excel file.');
        return;
      }

      final Excel excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        if (context.mounted) _error(context, 'Excel file does not contain any sheet.');
        return;
      }

      // Use the first sheet that actually contains the template headers
      // (a teacher may have added extra sheets in front of it).
      _Layout? layout;
      Sheet? sheet;
      for (final entry in excel.tables.entries) {
        final candidate = entry.value;
        final found = _findLayout(candidate);
        if (found != null) {
          layout = found;
          sheet = candidate;
          log('Template found on sheet "${entry.key}"');
          break;
        }
      }

      if (layout == null || sheet == null) {
        if (context.mounted) {
          _error(
            context,
            'Template not recognised. Please use the downloaded template '
            '(headers: "Questions", "Options" A–D, "Right option").',
          );
        }
        return;
      }

      // ==========================================================
      // EXTRACT QUESTIONS
      // ==========================================================

      final List<QAModel> tempQuestions = [];

      for (int row = layout.firstDataRow; row < sheet.maxRows; row++) {
        final String question = _getCell(sheet, row, layout.questionCol);
        final String a = _getCell(sheet, row, layout.optionCols[0]);
        final String b = _getCell(sheet, row, layout.optionCols[1]);
        final String c = _getCell(sheet, row, layout.optionCols[2]);
        final String d = _getCell(sheet, row, layout.optionCols[3]);
        final String ans = _getCell(sheet, row, layout.answerCol);

        // Skip completely empty rows (also rows that only have formatting)
        if ([question, a, b, c, d, ans].every((t) => t.isEmpty)) continue;

        final int excelRow = row + 1;

        if (_hasFormula(sheet, row, layout)) {
          if (context.mounted) {
            _error(
              context,
              'Row $excelRow contains a formula. Please paste the cells as '
              'values (text) and upload again.',
            );
          }
          return;
        }

        if (question.isEmpty) {
          if (context.mounted) _error(context, 'Question is empty at row $excelRow.');
          return;
        }

        if (a.isEmpty || b.isEmpty || c.isEmpty || d.isEmpty) {
          if (context.mounted) {
            _error(context, 'All four options are required at row $excelRow.');
          }
          return;
        }

        final String? correct = _parseAnswer(ans, a, b, c, d);
        if (correct == null) {
          if (context.mounted) {
            _error(
              context,
              'Invalid answer "$ans" at row $excelRow. Use A, B, C or D.',
            );
          }
          return;
        }

        tempQuestions.add(
          QAModel(q: question, a: a, b: b, c: c, d: d, ans: correct),
        );
      }

      if (tempQuestions.isEmpty) {
        if (context.mounted) {
          _error(
            context,
            'No questions found. Add them from row ${layout.firstDataRow + 1} '
            'of the template and try again.',
          );
        }
        return;
      }

      slectedFileName = file.name;
      questions = tempQuestions;
      qc?.setFromExcel(tempQuestions, file.name);

      log('Excel import OK: ${file.name}, ${questions.length} questions');

      notifyListeners();

      if (!context.mounted) return;
      customSnackbar(
        context: context,
        message: '${questions.length} questions imported successfully.',
        color: Colors.green,
        ico: Icons.check_circle,
      );
    } catch (e, stackTrace) {
      log('Excel error', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        _error(context, 'Something went wrong while reading the Excel file.');
      }
    }
  }

  void _error(BuildContext context, String message) {
    customSnackbar(
      context: context,
      message: message,
      color: Colors.red,
      ico: Icons.error,
    );
  }

  // ============================================================
  // FIND TEMPLATE LAYOUT
  //
  // The template starts at column G, not A:
  //
  //   G1:L1  "Test Nest" (merged title)
  //   G2:G3  "Questions"   H2:K2 "Options"   L2:L3 "Right option (A,B,C,D)"
  //          row 3 has the letters  H3=A  I3=B  J3=C  K3=D
  //   row 4+ the questions
  //
  // Instead of trusting fixed cell addresses, the headers are searched for,
  // so the sheet still imports if columns or title rows are added or moved.
  // ============================================================

  _Layout? _findLayout(Sheet sheet) {
    final int maxRow = sheet.maxRows < 30 ? sheet.maxRows : 30;
    final int maxCol = sheet.maxColumns < 40 ? sheet.maxColumns : 40;

    for (int row = 0; row < maxRow; row++) {
      int? questionCol;
      int? optionsCol;
      int? answerCol;

      for (int col = 0; col < maxCol; col++) {
        final text = _normalize(_getCell(sheet, row, col));
        if (text.isEmpty) continue;

        if (questionCol == null && text.startsWith('question')) {
          questionCol = col;
        } else if (optionsCol == null && text.startsWith('option')) {
          optionsCol = col;
        } else if (answerCol == null &&
            (text.contains('right') ||
                text.contains('correct') ||
                text.contains('answer'))) {
          answerCol = col;
        }
      }

      if (questionCol == null || optionsCol == null || answerCol == null) {
        continue;
      }

      // Letters A, B, C, D sit in the header row or the one right below it
      for (int letterRow = row; letterRow <= row + 2; letterRow++) {
        final cols = <int>[];
        for (final letter in ['a', 'b', 'c', 'd']) {
          int? found;
          for (int col = optionsCol; col < maxCol; col++) {
            if (_normalize(_getCell(sheet, letterRow, col)) == letter) {
              found = col;
              break;
            }
          }
          if (found == null) break;
          cols.add(found);
        }
        if (cols.length == 4) {
          return _Layout(
            questionCol: questionCol,
            optionCols: cols,
            answerCol: answerCol,
            firstDataRow: letterRow + 1,
          );
        }
      }
    }
    return null;
  }

  // ============================================================
  // ANSWER PARSING  (A / a / "A." / "(B)" / "Option C" / 1-4 / option text)
  // ============================================================

  String? _parseAnswer(String raw, String a, String b, String c, String d) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final upper = text.toUpperCase();

    if (upper.length == 1 && 'ABCD'.contains(upper)) return upper;

    final match = RegExp(r'^\(?\s*(?:OPTION\s*)?([ABCD1-4])\s*[\).:\-]?$')
        .firstMatch(upper);
    if (match != null) {
      const map = {'1': 'A', '2': 'B', '3': 'C', '4': 'D'};
      final key = match.group(1)!;
      return map[key] ?? key;
    }

    final n = _normalize(text);
    final options = {'A': a, 'B': b, 'C': c, 'D': d};
    final hits = options.entries
        .where((e) => _normalize(e.value) == n)
        .map((e) => e.key)
        .toList();
    return hits.length == 1 ? hits.first : null;
  }

  // ============================================================
  // GET CELL VALUE
  // ============================================================

  bool _hasFormula(Sheet sheet, int row, _Layout layout) {
    final cols = [layout.questionCol, ...layout.optionCols, layout.answerCol];
    for (final col in cols) {
      if (row >= sheet.maxRows || col >= sheet.maxColumns) continue;
      final value = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
          .value;
      if (value is FormulaCellValue) return true;
    }
    return false;
  }

  String _getCell(Sheet sheet, int row, int column) {
    if (row < 0 ||
        column < 0 ||
        row >= sheet.maxRows ||
        column >= sheet.maxColumns) {
      return '';
    }

    final CellValue? value = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
        .value;

    if (value == null) return '';

    String text;
    if (value is TextCellValue) {
      text = value.value.toString();
    } else if (value is IntCellValue) {
      text = value.value.toString();
    } else if (value is DoubleCellValue) {
      // 5.0 -> "5" so numeric options look the way the teacher typed them
      final v = value.value;
      text = v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
    } else if (value is BoolCellValue) {
      text = value.value.toString();
    } else if (value is FormulaCellValue) {
      text = value.formula;
    } else if (value is DateTimeCellValue) {
      text = value.asDateTimeLocal().toString();
    } else if (value is TimeCellValue) {
      text = value.asDuration().toString();
    } else {
      text = value.toString();
    }

    return text
        .replaceAll('\uFEFF', '')
        .replaceAll('\u00A0', ' ')
        .trim();
  }

  String _normalize(String text) {
    return text
        .replaceAll('\uFEFF', '')
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
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

/// Where each part of the template sits in the sheet (all indexes 0-based).
class _Layout {
  final int questionCol;
  final List<int> optionCols; // A, B, C, D
  final int answerCol;
  final int firstDataRow;

  const _Layout({
    required this.questionCol,
    required this.optionCols,
    required this.answerCol,
    required this.firstDataRow,
  });
}