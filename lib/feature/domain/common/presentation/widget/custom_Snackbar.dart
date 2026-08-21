import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

void customSnackbar({
  required BuildContext context,
  required String message,
  required Color color,
  required IconData ico,
}) {
  showTopSnackBar(
    Overlay.of(context),
    CustomSnackBar.success(
      message: message,
      backgroundColor: color,
      icon: Icon(ico, color: Colors.black12, size: 100),
    ),
  );
}
