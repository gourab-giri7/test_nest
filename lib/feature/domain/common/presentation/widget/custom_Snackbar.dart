import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

void customSnackbar({
  required BuildContext context,
  required String message,
  required Color color,
  required IconData ico,
}) {
  final overlayState =
      Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
  if (overlayState == null) return;

  showTopSnackBar(
    overlayState,
    CustomSnackBar.success(
      message: message,
      backgroundColor: color,
      icon: Icon(ico, color: Colors.black12, size: 100),
    ),
  );
}
