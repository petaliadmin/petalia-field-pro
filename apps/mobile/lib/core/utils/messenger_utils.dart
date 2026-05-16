import 'package:flutter/material.dart';

/// Global key to access ScaffoldMessenger without context.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MessengerUtils {
  static void showSnackBar(String message, {bool isError = false}) {
    scaffoldMessengerKey.currentState?.clearSnackBars();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFC53030) : const Color(0xFF2E5A44),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static void showSuccess(String message) => showSnackBar(message, isError: false);
  static void showError(String message) => showSnackBar(message, isError: true);
  static void showInfo(String message) => showSnackBar(message, isError: false);
}
