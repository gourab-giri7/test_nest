import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_nest/model/Q&A_model.dart';

void main() {
  group('Excel Importer Tests', () {
    String getCell(Sheet sheet, {required int row, required int column}) {
      if (row < 0 ||
          column < 0 ||
          row >= sheet.maxRows ||
          column >= sheet.maxColumns) {
        return '';
      }
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
      );
      final value = cell.value;
      if (value == null) return '';
      if (value is TextCellValue) return value.value.toString().trim();
      if (value is IntCellValue) return value.value.toString().trim();
      if (value is DoubleCellValue) return value.value.toString().trim();
      return value.toString().trim();
    }

    bool isSame(String a, String b) {
      final cleanA = a.replaceAll(' ', '').trim().toLowerCase();
      final cleanB = b.replaceAll(' ', '').trim().toLowerCase();
      return cleanA == cleanB;
    }

    test(
      'Sample questions sheet.xlsx template is valid and imports correctly',
      () {
        final file = File('assets/Sample questions sheet.xlsx');
        expect(file.existsSync(), isTrue);

        final bytes = file.readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);

        final sheet = excel.tables[excel.tables.keys.first]!;

        // Headers check
        expect(isSame(getCell(sheet, row: 1, column: 6), 'Questions'), isTrue);
        expect(isSame(getCell(sheet, row: 1, column: 7), 'Options'), isTrue);
        expect(
          isSame(getCell(sheet, row: 1, column: 11), 'Right option (A,B,C,D)'),
          isTrue,
        );

        // Options A, B, C, D row check
        expect(isSame(getCell(sheet, row: 2, column: 7), 'A'), isTrue);
        expect(isSame(getCell(sheet, row: 2, column: 8), 'B'), isTrue);
        expect(isSame(getCell(sheet, row: 2, column: 9), 'C'), isTrue);
        expect(isSame(getCell(sheet, row: 2, column: 10), 'D'), isTrue);

        // Sample questions sheet template structure verified
        expect(sheet.maxRows >= 3, isTrue);
        if (sheet.maxRows > 3) {
          final q = getCell(sheet, row: 3, column: 6);
          expect(q.isNotEmpty, isTrue);
        }
      },
    );

    test('20 questions imported correctly from valid template', () {
      final excel = Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet()!];

      // Set headers
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 1))
          .value = TextCellValue(
        'Questions',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1))
          .value = TextCellValue(
        'Options',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: 1))
          .value = TextCellValue(
        'Right option (A,B,C,D)',
      );

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 2))
          .value = TextCellValue(
        'A',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 2))
          .value = TextCellValue(
        'B',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 2))
          .value = TextCellValue(
        'C',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: 2))
          .value = TextCellValue(
        'D',
      );

      final answers = ['A', 'B', 'C', 'D'];
      for (int i = 0; i < 20; i++) {
        final row = 3 + i;
        final ans = answers[i % 4];
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = TextCellValue(
          'Question ${i + 1}',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = TextCellValue(
          'Option A $i',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
            .value = TextCellValue(
          'Option B $i',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
            .value = TextCellValue(
          'Option C $i',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
            .value = TextCellValue(
          'Option D $i',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row))
            .value = TextCellValue(
          ans,
        );
      }

      final List<QAModel> imported = [];
      for (int row = 3; row < sheet.maxRows; row++) {
        final q = getCell(sheet, row: row, column: 6);
        final a = getCell(sheet, row: row, column: 7);
        final b = getCell(sheet, row: row, column: 8);
        final c = getCell(sheet, row: row, column: 9);
        final d = getCell(sheet, row: row, column: 10);
        final ans = getCell(sheet, row: row, column: 11).toUpperCase();

        if (q.isEmpty &&
            a.isEmpty &&
            b.isEmpty &&
            c.isEmpty &&
            d.isEmpty &&
            ans.isEmpty)
          continue;
        expect(['A', 'B', 'C', 'D'].contains(ans), isTrue);
        imported.add(QAModel(q: q, a: a, b: b, c: c, d: d, ans: ans));
      }

      expect(imported.length, 20);
      expect(imported[0].q, 'Question 1');
      expect(imported[0].ans, 'A');
      expect(imported[19].q, 'Question 20');
      expect(imported[19].ans, 'D');
    });
  });
}
