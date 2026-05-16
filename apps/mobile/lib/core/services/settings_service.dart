import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';

/// Supported app languages.
///
/// `ff` (Pulaar/Fula) is included to feed the symptoms catalog
/// (`assets/data/symptoms.json` carries `ff` labels) and the TTS service —
/// even though Flutter's stock `MaterialLocalizations` has no `ff` chrome
/// (handled the same way as `wo`: borrow the French chrome via the fallback
/// delegate, application strings localised through ARB / catalog).
enum AppLanguage { fr, en, wo, ff }

class AppSettings {
  final ThemeMode themeMode;
  final AppLanguage language;
  final int syncFrequencyMinutes;
  final bool notifications;
  final bool largeText;
  final bool highContrast;
  final bool autoHighContrast;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.fr,
    this.syncFrequencyMinutes = 15,
    this.notifications = true,
    this.largeText = false,
    this.highContrast = false,
    this.autoHighContrast = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
    int? syncFrequencyMinutes,
    bool? notifications,
    bool? largeText,
    bool? highContrast,
    bool? autoHighContrast,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
        syncFrequencyMinutes: syncFrequencyMinutes ?? this.syncFrequencyMinutes,
        notifications: notifications ?? this.notifications,
        largeText: largeText ?? this.largeText,
        highContrast: highContrast ?? this.highContrast,
        autoHighContrast: autoHighContrast ?? this.autoHighContrast,
      );

  Locale get locale => switch (language) {
        AppLanguage.fr => const Locale('fr'),
        AppLanguage.en => const Locale('en'),
        AppLanguage.wo => const Locale('wo'),
        AppLanguage.ff => const Locale('ff'),
      };
}

/// Display helpers — single source of truth for the human-readable names of
/// each app language. Used by the onboarding picker and the Settings screen
/// so they stay in sync when a new language is added.
extension AppLanguageDisplay on AppLanguage {
  /// Endonym (the language's name written in itself). Best for a picker
  /// where each option must be readable by a speaker of that language —
  /// even if the rest of the UI is currently in another locale.
  String get endonym => switch (this) {
        AppLanguage.fr => 'Français',
        AppLanguage.en => 'English',
        AppLanguage.wo => 'Wolof',
        AppLanguage.ff => 'Pulaar',
      };

  /// French label — used inside the existing French-language Settings UI
  /// where the rest of the page is already in FR.
  String get labelFr => switch (this) {
        AppLanguage.fr => 'Français',
        AppLanguage.en => 'Anglais',
        AppLanguage.wo => 'Wolof',
        AppLanguage.ff => 'Pulaar',
      };

  /// Compact two-letter flag-style tag for chip / pill rendering.
  String get tag => switch (this) {
        AppLanguage.fr => 'FR',
        AppLanguage.en => 'EN',
        AppLanguage.wo => 'WO',
        AppLanguage.ff => 'FF',
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
    final ahc = _box.get('autoHighContrast', defaultValue: true) as bool;
    
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
      autoHighContrast: ahc,
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

  void setAutoHighContrast(bool v) {
    state = state.copyWith(autoHighContrast: v);
    _box.put('autoHighContrast', v);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (_) => SettingsNotifier(),
);
