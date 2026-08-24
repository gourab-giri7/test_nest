import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';

class FileUploadController extends ChangeNotifier {
  String? slectedFileName;
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
          fileName: 'Template_sheet_${DateTime.timestamp().hour}${DateTime.timestamp().microsecond}.xlsx',
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
      PlatformFile? file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        
      );
      if (file != null) {
        slectedFileName = file.name;
        log(file.name);
        // log(file.length().toString());
      } else {
        // User canceled the picker
      }
    } catch (e) {
      log(e.toString());
    }
    notifyListeners();
  }

  // ---- cancel selected file
  void cancelFile() {
    slectedFileName = null;
    notifyListeners();
  }
  
}
