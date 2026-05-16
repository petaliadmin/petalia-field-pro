import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/in_app_notification.dart';
import 'tts_service.dart';
import 'settings_service.dart';
import '../../routes/app_router.dart';

class InternalNotificationService {
  final Ref _ref;
  OverlayEntry? _currentEntry;
  Timer? _dismissTimer;

  InternalNotificationService(this._ref);

  void notify({
    required String title,
    required String message,
    IconData? icon,
    Color? color,
    bool vocal = true,
  }) {
    // 1. Visual notification
    _showOverlay(title, message, icon, color);

    // 2. Vocal notification
    if (vocal) {
      final lang = _ref.read(settingsProvider).language;
      _ref.read(ttsServiceProvider).speak('$title. $message', lang: lang);
    }
  }

  void _showOverlay(String title, String message, IconData? icon, Color? color) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final context = rootNavigatorKey.currentState?.context;
    if (context == null) return;
    
    final overlayState = Overlay.of(context);
    
    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -100, end: 0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: Opacity(
                opacity: (100 + value) / 100,
                child: child,
              ),
            );
          },
          child: InAppNotification(
            title: title,
            message: message,
            icon: icon,
            color: color,
            onTap: () {
              _dismissTimer?.cancel();
              _currentEntry?.remove();
              _currentEntry = null;
            },
          ),
        ),
      ),
    );

    overlayState.insert(_currentEntry!);

    _dismissTimer = Timer(const Duration(seconds: 5), () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }
}

final internalNotificationProvider = Provider<InternalNotificationService>((ref) {
  return InternalNotificationService(ref);
});
