import 'package:flutter/material.dart';

class CustomSnackbar {
  static void showSuccess({
    required BuildContext context,
    String? title,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title != null ? '$title: $message' : message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showError({
    required BuildContext context,
    String? title,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title != null ? '$title: $message' : message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showInfo({
    required BuildContext context,
    String? title,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title != null ? '$title: $message' : message),
        backgroundColor: const Color(0xFF3B82F6),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
