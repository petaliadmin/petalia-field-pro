class AppConstants {
  AppConstants._();

  static const String appName = 'Petalia Field Pro';
  static const String appTagline = 'Smart agronomy in your pocket';

  // Hive boxes
  static const String boxAuth = 'box_auth';
  static const String boxParcels = 'box_parcels';
  static const String boxObservations = 'box_observations';
  static const String boxReports = 'box_reports';
  static const String boxAlerts = 'box_alerts';
  static const String boxSyncQueue = 'box_sync_queue';
  static const String boxSettings = 'box_settings';
  static const String boxExpertRequests = 'box_expert_requests';
  static const String boxAgroRulesCache = 'box_agro_rules_cache';
  static const String boxChecklists = 'box_checklists';
  static const String boxWeather = 'box_weather';

  // ---------------------------------------------------------------------------
  // Remote API — non activé par défaut. Quand `remoteBaseUrl` est non vide,
  // la couche `remote_sources/` bascule vers l'impl HTTP (Dio). Tant qu'elle
  // reste vide, toutes les données proviennent des assets / Hive locaux.
  // ---------------------------------------------------------------------------
  static const String remoteBaseUrl = String.fromEnvironment(
    'PETALIA_REMOTE_BASE_URL',
    defaultValue: '',
  );
  static bool get remoteApiEnabled => remoteBaseUrl.isNotEmpty;

  // Keys
  static const String kThemeMode = 'theme_mode';
  static const String kLanguage = 'language';
  static const String kSyncFreq = 'sync_freq';
  static const String kNotifications = 'notifications';
  static const String kLargeText = 'large_text';
  static const String kHighContrast = 'high_contrast';
  static const String kRememberSession = 'remember_session';
  static const String kCurrentUser = 'current_user';
  static const String kUserPin = 'user_pin';
  static const String kBiometricEnabled = 'biometric_enabled';
  static const String kOnboardingCompleted = 'onboarding_completed';

  // Tile cache
  static const String kTileCacheAutoDownload = 'tile_cache_auto_download';
}
