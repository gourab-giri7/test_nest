import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomSnackbar {
  static void showSuccess({
    BuildContext? context,
    String? title,
    required String message,
  }) {
    _showSnackBar(
      context: context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFF10B981),
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void showError({
    BuildContext? context,
    String? title,
    required String message,
  }) {
    _showSnackBar(
      context: context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFFEF4444),
      icon: Icons.error_outline_rounded,
    );
  }

  static void showInfo({
    BuildContext? context,
    String? title,
    required String message,
  }) {
    _showSnackBar(
      context: context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFF3B82F6),
      icon: Icons.info_outline_rounded,
    );
  }

  static void _showSnackBar({
    BuildContext? context,
    String? title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    // 1. Try using the provided context if it is mounted and valid
    if (context != null && context.mounted) {
      try {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title != null ? '$title: $message' : message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: backgroundColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      } catch (_) {
        // Fall through to GetX snackbar
      }
    }

    // 2. Try using Get.context if available and mounted
    final getCtx = Get.context;
    if (getCtx != null && getCtx.mounted) {
      try {
        final messenger = ScaffoldMessenger.maybeOf(getCtx);
        if (messenger != null) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title != null ? '$title: $message' : message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: backgroundColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      } catch (_) {}
    }

    // 3. Robust GetX fallback overlay snackbar
    try {
      Get.rawSnackbar(
        titleText: title != null
            ? Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              )
            : null,
        messageText: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        icon: Icon(icon, color: Colors.white, size: 22),
        backgroundColor: backgroundColor,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        duration: const Duration(seconds: 3),
      );
    } catch (_) {}
  }
}
