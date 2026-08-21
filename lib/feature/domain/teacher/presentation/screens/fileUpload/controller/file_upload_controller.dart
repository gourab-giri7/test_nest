import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

class FileUploadController extends ChangeNotifier {
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
          fileName: 'Template_sheet.xlsx',
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

  void pickFile() async {
    try {
         FilePickerResult? result=await FilePicker.platform.pickFiles(
      type: FileType.any, 
      allowMultiple: false, 
    );
    } catch (e) {
      log(e.toString());
    }
  }
}
