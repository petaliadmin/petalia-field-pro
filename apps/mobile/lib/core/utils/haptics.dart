import 'package:flutter/services.dart';

/// Centralised haptic feedback. Four levels mapped to user intent so that
/// the same gesture always feels the same across the app:
///
/// - [selection] — discrete picker change (chip toggle, segmented control,
///   day-marker on a timeline). Sub-perceptual click.
/// - [light]     — confirms a simple tap landed (button press, list row
///   tap, sheet open).
/// - [medium]    — non-trivial state mutation (save, mark-as-done,
///   capture). Tells the hand the work was committed.
/// - [heavy]     — destructive or error path (delete, validation failure,
///   PIN wrong). Should feel different from success.
///
/// On platforms without taptic support (most desktops, web) all calls are
/// no-ops — `HapticFeedback` already swallows them silently.
class Haptics {
  Haptics._();

  /// Discrete picker click — chip select, day toggle, segmented switch.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Standard button / row tap acknowledgement.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// Confirms a successful state mutation (save, capture, mark-as-done).
  static Future<void> medium() => HapticFeedback.mediumImpact();

  /// Error or destructive action — should feel distinct from success.
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  // -------------------------------------------------------------------------
  // Semantic aliases — prefer these at call sites for self-documenting code.
  // -------------------------------------------------------------------------

  /// Alias for [medium] — use when the trigger is a successful save / submit.
  static Future<void> success() => medium();

  /// Alias for [light] — use for non-critical warnings (snackbar surface).
  static Future<void> warning() => light();

  /// Alias for [heavy] — use when surfacing a validation or runtime error.
  static Future<void> error() => heavy();
}
