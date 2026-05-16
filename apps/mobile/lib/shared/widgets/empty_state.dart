import 'package:flutter/material.dart';

import 'app_state_view.dart';

/// Backwards-compatible wrapper around [AppStateView.empty]. Kept so the
/// existing call sites keep compiling. New code should use [AppStateView]
/// directly — its named constructors also cover loading and error states.
///
/// Not annotated `@Deprecated` to avoid noisy warnings across the 8 existing
/// call sites; mass migration is out of scope for P5.1.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppStateView.empty(
      icon: icon,
      title: title,
      message: message,
      action: action,
    );
  }
}
