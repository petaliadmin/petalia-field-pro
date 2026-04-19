import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// Shows a success snackbar with haptic feedback.
/// Call before navigating away so the user sees confirmation.
class SuccessFeedback {
  SuccessFeedback._();

  static void show(BuildContext context, {required String message}) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  /// Light haptic for toggles (checkboxes, switches).
  static void tapFeedback() => HapticFeedback.lightImpact();
}
