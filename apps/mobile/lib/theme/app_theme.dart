import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Theme extension carrying terrain/visibility flags so widgets (e.g. GlassCard)
/// can adapt without plumbing the bool through the widget tree.
@immutable
class HighVisibility extends ThemeExtension<HighVisibility> {
  const HighVisibility({required this.enabled});
  final bool enabled;

  static const HighVisibility off = HighVisibility(enabled: false);

  static bool of(BuildContext context) =>
      Theme.of(context).extension<HighVisibility>()?.enabled ?? false;

  @override
  HighVisibility copyWith({bool? enabled}) =>
      HighVisibility(enabled: enabled ?? this.enabled);

  @override
  HighVisibility lerp(ThemeExtension<HighVisibility>? other, double t) {
    if (other is! HighVisibility) return this;
    return t < 0.5 ? this : other;
  }
}

class AppTheme {
  AppTheme._();

  /// Returns 1.0 normally, or 1.2 when large text is enabled.
  static double textScale(bool largeText) => largeText ? 1.2 : 1.0;

  static ThemeData light({bool highContrast = false}) {
    // High Contrast palette = WCAG AAA outdoor (>= 7:1) with NO blur surfaces.
    final primary = highContrast ? const Color(0xFF1B3A2C) : AppColors.primary;
    final background = highContrast ? const Color(0xFFFFFFFF) : AppColors.background;
    final surface = highContrast ? const Color(0xFFFFFFFF) : AppColors.surface;
    final textColor = highContrast ? const Color(0xFF000000) : AppColors.textPrimary;
    final textSecondaryColor =
        highContrast ? const Color(0xFF0D1410) : AppColors.textSecondary;
    final textMuted =
        highContrast ? const Color(0xFF1A1D1A) : AppColors.textMuted;
    final inputFill = highContrast ? const Color(0xFFF2F2F2) : AppColors.secondary;
    final borderSide = highContrast
        ? const BorderSide(color: Color(0xFF000000), width: 1.5)
        : BorderSide.none;
    final focusedBorderWidth = highContrast ? 2.5 : 1.5;
    final dividerColor = highContrast ? const Color(0xFF000000) : AppColors.divider;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: AppColors.accent,
      surface: surface,
      error: AppColors.danger,
      brightness: Brightness.light,
    );

    final textTheme = AppTextStyles.textTheme(color: textColor);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        HighVisibility(enabled: highContrast),
      ],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(60),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(60),
          side: BorderSide(color: primary.withValues(alpha: 0.2), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: textMuted),
        labelStyle: TextStyle(color: textColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: focusedBorderWidth),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        selectedColor: primary.withValues(alpha: 0.15),
        disabledColor: AppColors.secondaryDark,
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        secondaryLabelStyle: TextStyle(color: primary, fontWeight: FontWeight.w600),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: highContrast ? 1.5 : 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 72,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? primary : textSecondaryColor,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 28,
            color: states.contains(WidgetState.selected) ? primary : textSecondaryColor,
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const textColor = Color(0xFFF2F5F3);        // Pure Mist (High visibility)
    const textSecondaryColor = Color(0xFFC5CFC8); // Sage Grey
    const textMutedColor = Color(0xFF8B9B91);     // Moss Grey

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primaryLight,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      onSurface: textColor,
      onSurfaceVariant: textSecondaryColor,
      error: AppColors.danger,
      brightness: Brightness.dark,
    );

    final textTheme = AppTextStyles.textTheme(color: textColor).copyWith(
      bodyLarge: TextStyle(color: textColor),
      bodyMedium: TextStyle(color: textSecondaryColor),
      bodySmall: TextStyle(color: textMutedColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[
        HighVisibility.off,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 8,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: textMutedColor),
        labelStyle: const TextStyle(color: textSecondaryColor),
        prefixIconColor: textMutedColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(60),
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          minimumSize: const Size.fromHeight(60),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceAlt,
        selectedColor: AppColors.primary.withValues(alpha: 0.3),
        disabledColor: AppColors.darkBackground,
        labelStyle: const TextStyle(color: textColor, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
