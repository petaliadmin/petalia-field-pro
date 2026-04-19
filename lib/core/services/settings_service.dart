import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';

enum AppLanguage { fr, en, wo }

class AppSettings {
  final ThemeMode themeMode;
  final AppLanguage language;
  final int syncFrequencyMinutes;
  final bool notifications;
  final bool largeText;
  final bool highContrast;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.fr,
    this.syncFrequencyMinutes = 15,
    this.notifications = true,
    this.largeText = false,
    this.highContrast = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    int? syncFrequencyMinutes,
    bool? notifications,
    bool? largeText,
    bool? highContrast,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
        syncFrequencyMinutes: syncFrequencyMinutes ?? this.syncFrequencyMinutes,
        notifications: notifications ?? this.notifications,
        largeText: largeText ?? this.largeText,
        highContrast: highContrast ?? this.highContrast,
      );

  Locale get locale => switch (language) {
        AppLanguage.fr => const Locale('fr'),
        AppLanguage.en => const Locale('en'),
        AppLanguage.wo => const Locale('wo'),
      };
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Box get _box => Hive.box(AppConstants.boxSettings);

  void _load() {
    final mode = _box.get(AppConstants.kThemeMode, defaultValue: 'system') as String;
    final lang = _box.get(AppConstants.kLanguage, defaultValue: 'fr') as String;
    final freq = _box.get(AppConstants.kSyncFreq, defaultValue: 15) as int;
    final notif = _box.get(AppConstants.kNotifications, defaultValue: true) as bool;
    final bigText = _box.get(AppConstants.kLargeText, defaultValue: false) as bool;
    final hc = _box.get(AppConstants.kHighContrast, defaultValue: false) as bool;
    state = AppSettings(
      themeMode: switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      language: AppLanguage.values.firstWhere(
        (l) => l.name == lang,
        orElse: () => AppLanguage.fr,
      ),
      syncFrequencyMinutes: freq,
      notifications: notif,
      largeText: bigText,
      highContrast: hc,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _box.put(AppConstants.kThemeMode, mode.name);
  }

  void setLanguage(AppLanguage lang) {
    state = state.copyWith(language: lang);
    _box.put(AppConstants.kLanguage, lang.name);
  }

  void setSyncFrequency(int minutes) {
    state = state.copyWith(syncFrequencyMinutes: minutes);
    _box.put(AppConstants.kSyncFreq, minutes);
  }

  void setNotifications(bool v) {
    state = state.copyWith(notifications: v);
    _box.put(AppConstants.kNotifications, v);
  }

  void setLargeText(bool v) {
    state = state.copyWith(largeText: v);
    _box.put(AppConstants.kLargeText, v);
  }

  void setHighContrast(bool v) {
    state = state.copyWith(highContrast: v);
    _box.put(AppConstants.kHighContrast, v);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (_) => SettingsNotifier(),
);
