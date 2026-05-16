// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Petalia Field Pro';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Error';

  @override
  String get noData => 'No data';

  @override
  String get tabDashboard => 'Home';

  @override
  String get tabParcels => 'Parcels';

  @override
  String get tabAlerts => 'Alerts';

  @override
  String get tabSettings => 'Profile';

  @override
  String get greetingMorning => 'Good morning,';

  @override
  String get greetingAfternoon => 'Good afternoon,';

  @override
  String get greetingEvening => 'Good evening,';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusOffline => 'Offline';

  @override
  String statusGpsAccuracy(Object meters) {
    return 'Accuracy ±${meters}m';
  }

  @override
  String get statusGpsWaiting => 'Waiting for GPS';

  @override
  String get dashboardSeeAll => 'See all';

  @override
  String get dashboardViewMyParcels => 'View my parcels';

  @override
  String get dashboardToday => 'Today';

  @override
  String get dashboardCropHealth7d => 'Crop health — last 7 days';

  @override
  String get dashboardDailyActions => 'Today\'s actions';

  @override
  String get dashboardNewVisit => 'New field visit';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardVoiceGuideTitle => 'Voice guide';

  @override
  String get dashboardVoiceGuideDesc => 'Start voice tour';

  @override
  String get weatherLoading => 'Loading weather…';

  @override
  String get weatherLoadingDesc => 'Fetching local conditions';

  @override
  String get weatherError => 'Weather unavailable';

  @override
  String get weatherErrorDesc => 'Retry at next synchronization';

  @override
  String get weatherHumidity => 'Humidity';

  @override
  String get weatherWind => 'Wind';

  @override
  String weatherTtsFull(int temp, String condition, int humidity, int wind) {
    return 'Current weather. $temp degrees, $condition. $humidity percent humidity. Wind $wind kilometers per hour.';
  }

  @override
  String get parcelsTitle => 'My parcels';

  @override
  String get parcelsAddButton => 'Add a parcel';

  @override
  String get parcelsEmptyTitle => 'No parcels yet';

  @override
  String get parcelsEmptyMessage => 'Add your first parcel to start tracking.';

  @override
  String get parcelsSearchHint => 'Search a parcel, farmer, village…';

  @override
  String get parcelsAllCrops => 'All';

  @override
  String get recoTitle => 'Advice & Actions';

  @override
  String get recoNotFound => 'Parcel not found';

  @override
  String get recoNotFoundMessage =>
      'This parcel may have been deleted or not synced yet.';

  @override
  String get recoLoadFailed => 'Could not load advice';

  @override
  String get recoLoadFailedMessage =>
      'Check your connection or try again in a moment.';

  @override
  String get recoBackToHome => 'Back to home';

  @override
  String get recoCreateReport => 'Create my report';

  @override
  String recoSourcePrefix(String source) {
    return 'Source: $source';
  }

  @override
  String get recoUrgencyHigh => 'Urgent';

  @override
  String get recoUrgencyMedium => 'Watch';

  @override
  String get recoUrgencyLow => 'Preventive';

  @override
  String get recoUrgencyHighHint => 'Act within 24-48 h';

  @override
  String get recoUrgencyMediumHint => 'Act within a few days';

  @override
  String get recoUrgencyLowHint => 'Best practices';

  @override
  String get recoListenAction => 'Listen';

  @override
  String get recoStopAction => 'Stop';

  @override
  String get recoFallbackHint => 'Reading in French (voice unavailable).';

  @override
  String get recoExpertCta => 'Ask an agronomist';

  @override
  String get recoExpertCtaAlt => 'This isn\'t my case — ask an agronomist';

  @override
  String get recoExpertSent => 'Request sent! An agronomist will reply.';

  @override
  String get recoNextVisit => 'Next visit';

  @override
  String get obsTitle => 'Field visit';

  @override
  String get obsHowIsCrop => 'Crop health status';

  @override
  String get obsEverythingOk => 'Everything is good';

  @override
  String get obsSomeProblems => 'Some problems';

  @override
  String get obsCritical => 'Critical state';

  @override
  String get obsWhatDoYouSee => 'Identified observations';

  @override
  String get obsHowSerious => 'Severity level';

  @override
  String get obsWhereIsCrop => 'Current growth stage';

  @override
  String get obsMoreDetails => 'More details (optional)';

  @override
  String get obsFieldMeasurements => 'Field measurements (optional)';

  @override
  String get obsAddPhoto => 'Add a photo';

  @override
  String get obsTakePhoto => 'Take a photo';

  @override
  String get obsFromGallery => 'From gallery';

  @override
  String get obsAudioNote => 'Voice note';

  @override
  String get obsEvidenceRequired => 'Photo or voice note required to save.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageChoose => 'Choose language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeChoose => 'Choose theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLargeText => 'Large text';

  @override
  String get settingsLargeTextHint => 'Enlarge all text';

  @override
  String get settingsHighContrast => 'High Visibility Mode (Field)';

  @override
  String get settingsHighContrastHint => 'Boosted contrast for direct sunlight';

  @override
  String get settingsNotifications => 'Push notifications';

  @override
  String get settingsAutoSync => 'Auto-sync';

  @override
  String get settingsOfflineMaps => 'Offline maps';

  @override
  String get settingsClearCache => 'Clear map cache';

  @override
  String get settingsClearCacheConfirm => 'Clear map cache?';

  @override
  String get settingsClearCacheHint => 'Free up storage space.';

  @override
  String get settingsClearCacheDone => 'Map cache cleared';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsLogoutConfirm => 'Sign out?';

  @override
  String get settingsCalculating => 'Calculating…';

  @override
  String get healthNone => 'No parcels';

  @override
  String get healthExcellent => 'Vigorous';

  @override
  String get healthGood => 'Good health';

  @override
  String get healthWarning => 'Attention required';

  @override
  String get healthCritical => 'Critical situation';

  @override
  String get healthAllFine => 'All your parcels are in good shape';

  @override
  String healthNeedAttention(int count) {
    return '$count parcel(s) require(s) your attention';
  }

  @override
  String get severityLight => 'Light';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityHigh => 'Heavy';

  @override
  String get stageSemis => 'Sowing/Planting';

  @override
  String get stageGermination => 'Germination';

  @override
  String get stageVegetative => 'Growth';

  @override
  String get stageFlowering => 'Flowering';

  @override
  String get stageFruiting => 'Fruiting';

  @override
  String get stageMaturation => 'Maturation';

  @override
  String get relativeNow => 'just now';

  @override
  String relativeMinutes(int count) {
    return '$count min ago';
  }

  @override
  String relativeHours(int count) {
    return '$count h ago';
  }

  @override
  String relativeDays(int count) {
    return '$count d ago';
  }

  @override
  String get recentParcels => 'Recent parcels';

  @override
  String get seeAll => 'See all';

  @override
  String get mapLayerStandard => 'Standard';

  @override
  String get mapLayerDark => 'Dark';

  @override
  String get mapLayerSatellite => 'Satellite';

  @override
  String get mapLayerNdvi => 'Health (NDVI) 🥬';

  @override
  String get mapLegendStress => 'Stress';

  @override
  String get mapLegendModerate => 'Moderate';

  @override
  String get mapLegendVigorous => 'Vigorous';

  @override
  String get tooltipListView => 'List view';

  @override
  String get tooltipMapView => 'Map view';

  @override
  String get parcelTabSummary => 'Summary';

  @override
  String get parcelTabDetails => 'Details';

  @override
  String get parcelTabVisits => 'Visits';

  @override
  String get parcelTabPhotos => 'Photos';

  @override
  String get parcelTabNotes => 'Notes';

  @override
  String get parcelKpiSurface => 'SURFACE';

  @override
  String get parcelKpiYield => 'YIELD';

  @override
  String get parcelActionNavigate => 'Navigate';

  @override
  String get parcelActionStop => 'Stop';

  @override
  String get parcelActionLocating => 'Locating GPS...';

  @override
  String get parcelMenuEdit => 'Edit parcel';

  @override
  String get parcelMenuExport => 'Export to PDF';

  @override
  String get parcelMenuDelete => 'Delete';

  @override
  String get parcelDetailTitle => 'Parcel details';

  @override
  String get soilSandyLabel => 'Sandy (Dior)';

  @override
  String get soilSandyDesc => 'Fast drainage, low water retention';

  @override
  String get soilSandyLoamLabel => 'Sandy-loam';

  @override
  String get soilSandyLoamDesc => 'Good balance between drainage and retention';

  @override
  String get soilLoamLabel => 'Loam';

  @override
  String get soilLoamDesc => 'Versatile, medium retention';

  @override
  String get soilClayLoamLabel => 'Clay-loam (Deck)';

  @override
  String get soilClayLoamDesc => 'Good retention, risk of compaction';

  @override
  String get soilClayLabel => 'Clay (Deck-dior)';

  @override
  String get soilClayDesc => 'High retention, slow drainage';

  @override
  String get soilSiltLabel => 'Silt';

  @override
  String get soilSiltDesc => 'Silty, prone to crusting';

  @override
  String get addParcelTitle => 'New parcel';

  @override
  String get editParcelTitle => 'Edit parcel';

  @override
  String get addParcelStepMap => 'Map boundary';

  @override
  String get addParcelStepForm => 'Crop information';

  @override
  String get addParcelHintPoints =>
      'Place at least 3 points to define the parcel.';

  @override
  String get addParcelUndo => 'Undo last point';

  @override
  String get addParcelClear => 'Clear all';

  @override
  String get addParcelSave => 'Save parcel';

  @override
  String get addParcelLabelName => 'Parcel name';

  @override
  String get addParcelLabelOwner => 'Owner / Farmer';

  @override
  String get addParcelLabelVillage => 'Village / Locality';

  @override
  String get addParcelLabelCrop => 'Crop';

  @override
  String get addParcelLabelVariety => 'Variety';

  @override
  String get addParcelLabelSemis => 'Sowing date';

  @override
  String get addParcelLabelSoil => 'Soil type';

  @override
  String get addParcelLabelRegion => 'Region';

  @override
  String get addParcelLabelPrevCrop => 'Previous crop';

  @override
  String get addParcelLabelIrrigation => 'Irrigation mode';

  @override
  String get addParcelLabelGrowth => 'Growth stage';

  @override
  String get addParcelLabelYield => 'Estimated yield (T/ha)';

  @override
  String get addParcelConfirmDiscard => 'Do you want to leave without saving?';

  @override
  String get addParcelDiscardTitle => 'Unsaved changes';

  @override
  String addParcelSuggestionApplied(int das, String stage, String code) {
    return 'D+$das · suggested stage: $stage (BBCH $code)';
  }

  @override
  String addParcelSuggestionCoherent(int das, String stage) {
    return 'D+$das · stage consistent with $stage';
  }

  @override
  String get genericCancel => 'Cancel';

  @override
  String get genericQuit => 'Quit';

  @override
  String get genericApply => 'Apply';

  @override
  String get genericNext => 'Next';

  @override
  String get genericStart => 'Start';

  @override
  String get genericStop => 'Stop';

  @override
  String get genericIdentification => 'Identification';

  @override
  String get genericCulture => 'Crop';

  @override
  String get genericRequiredField => 'This field is required';

  @override
  String get exportTitle => 'Export Data';

  @override
  String get exportPdf => 'Export to PDF (Pro Report)';

  @override
  String get exportExcel => 'Export to Excel (Spreadsheet)';

  @override
  String exportSuccess(String file) {
    return 'Export successful: $file';
  }

  @override
  String get exportError => 'Export failed';

  @override
  String get exportShare => 'Share';

  @override
  String get exportGenerating => 'Generating file...';

  @override
  String get reportHeaderParcel => 'Parcel';

  @override
  String get reportHeaderOwner => 'Owner';

  @override
  String get reportHeaderVillage => 'Village';

  @override
  String get reportHeaderCrop => 'Crop';

  @override
  String get reportHeaderSurface => 'Surface (Ha)';

  @override
  String get reportHeaderDate => 'Visit Date';

  @override
  String get reportHeaderDiagnosis => 'Diagnosis / Observation';

  @override
  String get reportHeaderAction => 'ISRA/ANCAR Recommendations';

  @override
  String get reportFooterNotice =>
      'Document generated by Petalia Field Pro — Rules v3 (ISRA, ANCAR, CSP).';

  @override
  String get authLoginTagline => 'Your intelligent agronomic companion';

  @override
  String get authPhoneLabel => 'Phone number';

  @override
  String get authPhoneHint => '7X XXX XX XX';

  @override
  String get authPinLabel => 'Secret PIN (4 digits)';

  @override
  String get authErrorInvalidPhone => 'Invalid phone number';

  @override
  String get authErrorInvalidCredentials => 'Incorrect credentials';

  @override
  String get authNoAccount => 'No account yet? ';

  @override
  String get authRegisterCta => 'Sign Up';

  @override
  String get authRegisterTitle => 'Sign Up (1/3)';

  @override
  String get authRegisterHeader => 'Your information';

  @override
  String get authRegisterSubHeader =>
      'Identify yourself to secure access to your parcels.';

  @override
  String get authNameLabel => 'Full name';

  @override
  String get authNameHint => 'Ex: Samba Diop';

  @override
  String get authErrorNameTooShort => 'Name too short';

  @override
  String get authErrorInvalidNumber => 'Invalid number';

  @override
  String get authOtpTitle => 'Verification (2/3)';

  @override
  String get authOtpHeader => 'Verify your number';

  @override
  String get authOtpSubHeader => 'A 6-digit code has been sent to';

  @override
  String get authErrorInvalidOtp => 'Incorrect code (Use 123456 for testing)';

  @override
  String get authPinTitle => 'Security (3/3)';

  @override
  String get authPinHeader => 'Secret PIN';

  @override
  String get authPinSubHeader => 'Set a 4-digit PIN to access your account.';

  @override
  String get authPinFinalCta => 'Finish Registration';

  @override
  String get authRegisterSuccess => 'Account created successfully!';
}
