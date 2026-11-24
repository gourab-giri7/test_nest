import 'dart:developer';
import 'dart:io';
import 'package:excel_plus/excel_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/manualQuestions/controller/question_controller.dart';
import 'package:test_nest/model/Q&A_model.dart';

class FileUploadController extends ChangeNotifier {
  String? slectedFileName;
  List<QAModel> questions = [];

  // ============================================================
  // DOWNLOAD & SHARE EXCEL TEMPLATE
  // ============================================================

  static Future<File> getOrExtractTemplateFile() async {
    const assetPath = 'assets/Sample questions sheet.xlsx';
    final ByteData data = await rootBundle.load(assetPath);
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/Sample_Question_Template.xlsx');
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file;
  }

  /// Downloads and saves the Excel template via system file picker.
  /// Returns `true` if saved, `false` if cancelled by user, `null` if error occurred.
  static Future<bool?> downloadTemplate() async {
    try {
      final file = await getOrExtractTemplateFile();

      final String? savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: file.path,
          fileName: 'Sample_Question_Template.xlsx',
          mimeTypesFilter: const [
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'application/vnd.ms-excel',
          ],
        ),
      );

      if (savedPath != null) {
        log('Excel saved at: $savedPath');
        return true;
      }

      log('User cancelled saving in file picker');
      return false;
    } catch (e, stackTrace) {
      log('Download error', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Directly shares or opens the template with Excel, Google Sheets, Drive, etc.
  static Future<bool> shareTemplate({Rect? sharePositionOrigin}) async {
    try {
      final file = await getOrExtractTemplateFile();
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'Sample_Question_Template.xlsx',
          ),
        ],
        text: 'Test Nest - Sample Questions Excel Template',
        sharePositionOrigin: sharePositionOrigin,
      );
      return true;
    } catch (e, stackTrace) {
      log('Share template error', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  // ============================================================
  // PICK EXCEL FILE
  // ============================================================

  Future<void> pickFile(BuildContext context, [QuestionController? qc]) async {
    try {
      // file_picker v12+ / v13 API: pickFile() returns PlatformFile?
      // No FilePicker.platform, FilePickerResult, withData, or allowMultiple.
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      // The picker returns null when the user cancels.
      if (file == null) return;

      log('Selected file: ${file.name}');

      // Read the selected file using the current PlatformFile API.
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (context.mounted)
          _error(context, 'Unable to read the selected Excel file.');
        return;
      }

      final Excel excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        if (context.mounted)
          _error(context, 'Excel file does not contain any sheet.');
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

        if (question.isEmpty) {
          if (context.mounted)
            _error(context, 'Question is empty at row $excelRow.');
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
      // Print the full exception and stack trace to the IDE debug console.
      // This helps identify the exact line if a null-check error occurs.
      debugPrint('========== EXCEL IMPORT ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('Stack trace:\n$stackTrace');
      debugPrint('========================================');
      log('Excel error', error: e, stackTrace: stackTrace);

      if (context.mounted) {
        _error(context, 'Excel import failed. Check debug console.');
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
    // Simple text-only validation for the Test Nest template.
    // Columns G-L; headers are on row 2, option labels on row 3.
    final questionHeader = _normalize(_getCell(sheet, 1, 6));
    final optionsHeader = _normalize(_getCell(sheet, 1, 7));
    final answerHeader = _normalize(_getCell(sheet, 1, 11));

    final optionA = _normalize(_getCell(sheet, 2, 7));
    final optionB = _normalize(_getCell(sheet, 2, 8));
    final optionC = _normalize(_getCell(sheet, 2, 9));
    final optionD = _normalize(_getCell(sheet, 2, 10));

    final validQuestionHeader =
        questionHeader == 'questions' || questionHeader == 'question';
    final validOptionsHeader =
        optionsHeader == 'options' || optionsHeader == 'option';
    final validAnswerHeader =
        answerHeader.contains('right option') ||
        answerHeader.contains('correct answer') ||
        answerHeader == 'answer' ||
        answerHeader.contains('right answer');

    if (!validQuestionHeader ||
        !validOptionsHeader ||
        !validAnswerHeader ||
        optionA != 'a' ||
        optionB != 'b' ||
        optionC != 'c' ||
        optionD != 'd') {
      return null;
    }

    return const _Layout(
      questionCol: 6, // G
      optionCols: [7, 8, 9, 10], // H, I, J, K
      answerCol: 11, // L
      firstDataRow: 3, // Excel row 4
    );
  }

  // ============================================================
  // ANSWER PARSING  (A / a / "A." / "(B)" / "Option C" / 1-4 / option text)
  // ============================================================

  String? _parseAnswer(String raw, String a, String b, String c, String d) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final upper = text.toUpperCase();

    if (upper.length == 1 && 'ABCD'.contains(upper)) return upper;

    final match = RegExp(
      r'^\(?\s*(?:OPTION\s*)?([ABCD1-4])\s*[\).:\-]?$',
    ).firstMatch(upper);
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

    return text.replaceAll('\uFEFF', '').replaceAll('\u00A0', ' ').trim();
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
