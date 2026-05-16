import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Single state-display widget used across the app for empty / loading /
/// error placeholders. Layout: a tinted circular illustration, a bold
/// title, an optional supporting message, and an optional CTA.
///
/// Use the named constructors instead of the generic one — they encode the
/// right defaults (color, icon, indicator) for each state and keep call
/// sites short:
///
/// ```dart
/// AppStateView.empty(icon: Icons.grass, title: 'Aucune parcelle')
/// AppStateView.loading(message: 'Chargement…')
/// AppStateView.error('Impossible de charger', onRetry: () { … })
/// ```
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.accent,
    this.showSpinner = false,
  });

  /// Empty state — no data to show, possibly the user's first run.
  /// Defaults to primary (forest sage) accent.
  factory AppStateView.empty({
    Key? key,
    required IconData icon,
    required String title,
    String? message,
    Widget? action,
  }) {
    return AppStateView(
      key: key,
      icon: icon,
      title: title,
      message: message,
      action: action,
      accent: AppColors.primary,
    );
  }

  /// Loading state — prefer this over a bare [CircularProgressIndicator]
  /// so users get context ("loading what?"). The spinner is shown next to
  /// the icon, both tinted in the info color.
  factory AppStateView.loading({
    Key? key,
    String title = 'Chargement…',
    String? message,
  }) {
    return AppStateView(
      key: key,
      icon: Icons.hourglass_top_rounded,
      title: title,
      message: message,
      accent: AppColors.info,
      showSpinner: true,
    );
  }

  /// Error state — surfaces a problem the user might be able to act on.
  /// `onRetry` is wired to a primary button labelled "Réessayer".
  factory AppStateView.error(
    String title, {
    Key? key,
    String? message,
    VoidCallback? onRetry,
    String retryLabel = 'Réessayer',
  }) {
    return AppStateView(
      key: key,
      icon: Icons.error_outline_rounded,
      title: title,
      message: message,
      accent: AppColors.danger,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
    );
  }

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// Accent color used for the illustration circle and (when relevant)
  /// the loading spinner. Defaults to [AppColors.primary] if null.
  final Color? accent;

  /// Show a small spinner beside the icon (loading variant).
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 88,
              width: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(icon, size: 40, color: color),
                  if (showSpinner)
                    SizedBox(
                      height: 88,
                      width: 88,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(
                          color.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
