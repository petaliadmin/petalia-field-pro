// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Wolof (`wo`).
class AppLocalizationsWo extends AppLocalizations {
  AppLocalizationsWo([String locale = 'wo']) : super(locale);

  @override
  String get appTitle => 'Petalia Field Pro';

  @override
  String get save => 'Denc';

  @override
  String get cancel => 'Bayi';

  @override
  String get delete => 'Far';

  @override
  String get edit => 'Soppi';

  @override
  String get add => 'Yokk';

  @override
  String get close => 'Tëj';

  @override
  String get confirm => 'Wóoraate';

  @override
  String get retry => 'Jéem ko ñaareelu yoon';

  @override
  String get back => 'Dellu';

  @override
  String get next => 'Topp';

  @override
  String get done => 'Mu jeex';

  @override
  String get search => 'Seet';

  @override
  String get loading => 'Mu ngi fey…';

  @override
  String get error => 'Njuumte';

  @override
  String get noData => 'Amoul dara';

  @override
  String get tabDashboard => 'Kër';

  @override
  String get tabParcels => 'Tool yi';

  @override
  String get tabAlerts => 'Yëgle yi';

  @override
  String get tabSettings => 'Sa profil';

  @override
  String get greetingMorning => 'Naka suba si,';

  @override
  String get greetingAfternoon => 'Naka bëccëg bi,';

  @override
  String get greetingEvening => 'Naka ngoon si,';

  @override
  String get statusConnected => 'Baax na';

  @override
  String get statusOffline => 'Konekson amul';

  @override
  String statusGpsAccuracy(Object meters) {
    return 'Natt bi ±${meters}m';
  }

  @override
  String get statusGpsWaiting => 'GPS mu ngi xar';

  @override
  String get dashboardSeeAll => 'Gis lépp';

  @override
  String get dashboardViewMyParcels => 'Gis sama tool yi';

  @override
  String get dashboardToday => 'Tey';

  @override
  String get dashboardCropHealth7d => 'Wér-gi-yaramu gàncax yi — 7 fan yu mujj';

  @override
  String get dashboardDailyActions => 'Jëf yu tey';

  @override
  String get dashboardNewVisit => 'Visit terrain bu bees';

  @override
  String get dashboardQuickActions => 'Jëf yu gaaw';

  @override
  String get dashboardVoiceGuideTitle => 'Téere baat';

  @override
  String get dashboardVoiceGuideDesc => 'Dóoral visit vocal bi';

  @override
  String get weatherLoading => 'Chargement météo…';

  @override
  String get weatherLoadingDesc => 'Récupération des conditions locales';

  @override
  String get weatherError => 'Météo indisponible';

  @override
  String get weatherErrorDesc => 'Réessai à la prochaine synchronisation';

  @override
  String get weatherHumidity => 'Humidité';

  @override
  String get weatherWind => 'Vent';

  @override
  String weatherTtsFull(int temp, String condition, int humidity, int wind) {
    return 'Météo actuelle. $temp degrés, $condition. $humidity pour cent d\'humidité. Vent $wind kilomètres par heure.';
  }

  @override
  String get parcelsTitle => 'Sama tool yi';

  @override
  String get parcelsAddButton => 'Yokk benn tool';

  @override
  String get parcelsEmptyTitle => 'Amoo tool ba tey';

  @override
  String get parcelsEmptyMessage =>
      'Yokkal sa tool bu njëkk ngir tàmbali toppatoo.';

  @override
  String get parcelsSearchHint => 'Seet tool, boroom tool...';

  @override
  String get parcelsAllCrops => 'Lépp';

  @override
  String get recoTitle => 'Tegtal & Jëf';

  @override
  String get recoNotFound => 'Tool bi gisuñu ko';

  @override
  String get recoNotFoundMessage =>
      'Xéj na ñu far tool bii walla mu sync gi des ba tey.';

  @override
  String get recoLoadFailed => 'Mënuñu woo tegtal yi';

  @override
  String get recoLoadFailedMessage =>
      'Xoolal sa konekson walla jéem ko ci kanam.';

  @override
  String get recoBackToHome => 'Dellu ca kër ga';

  @override
  String get recoCreateReport => 'Sos sama rapoor';

  @override
  String recoSourcePrefix(String source) {
    return 'Boroom : $source';
  }

  @override
  String get recoUrgencyHigh => 'Gaaw';

  @override
  String get recoUrgencyMedium => 'Toppal';

  @override
  String get recoUrgencyLow => 'Moytu';

  @override
  String get recoUrgencyHighHint => 'Defal ko ci 24-48 waxtu';

  @override
  String get recoUrgencyMediumHint => 'Defal ko ci ay fan';

  @override
  String get recoUrgencyLowHint => 'Jëf yu rafet';

  @override
  String get recoListenAction => 'Déglu';

  @override
  String get recoStopAction => 'Taxaw';

  @override
  String get recoFallbackHint => 'Jàng ci faraan (baat bi amul ci wolof).';

  @override
  String get recoExpertCta => 'Laaj ku xam mbay';

  @override
  String get recoExpertCtaAlt => 'Loolu du sama mbir — laaj ku xam mbay';

  @override
  String get recoExpertSent => 'Ndimbal yónni na ! Ku xam mbay dina la tontu.';

  @override
  String get recoNextVisit => 'Wisit bu topp';

  @override
  String get obsTitle => 'Wisit ci tool bi';

  @override
  String get obsHowIsCrop => 'Naka la sa mbay mel ?';

  @override
  String get obsEverythingOk => 'Lépp baax na';

  @override
  String get obsSomeProblems => 'Ay jafe-jafe';

  @override
  String get obsCritical => 'Mu mettit';

  @override
  String get obsWhatDoYouSee => 'Lan nga gis ?';

  @override
  String get obsHowSerious => 'Lu mu metti ?';

  @override
  String get obsWhereIsCrop => 'Fan la sa mbay nekk ?';

  @override
  String get obsMoreDetails => 'Lu ëpp (su soobee)';

  @override
  String get obsFieldMeasurements => 'Natt yi ci tool (su soobee)';

  @override
  String get obsAddPhoto => 'Yokk nataal';

  @override
  String get obsTakePhoto => 'Jël benn nataal';

  @override
  String get obsFromGallery => 'Bi ci galeri bi';

  @override
  String get obsAudioNote => 'Note baat';

  @override
  String get obsEvidenceRequired => 'Nataal walla note baat laa wér ngir denc.';

  @override
  String get settingsTitle => 'Tëralin yi';

  @override
  String get settingsLanguage => 'Làkk';

  @override
  String get settingsLanguageChoose => 'Tànn làkk';

  @override
  String get settingsTheme => 'Melow bi';

  @override
  String get settingsThemeChoose => 'Tànn melow';

  @override
  String get settingsThemeLight => 'Leeral';

  @override
  String get settingsThemeDark => 'Lëndëm';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsLargeText => 'Bind bu mag';

  @override
  String get settingsLargeTextHint => 'Yokkal lépp bind bi';

  @override
  String get settingsHighContrast => 'Mode tool';

  @override
  String get settingsHighContrastHint => 'Kontras yu yokku ngir naaj wu tàng';

  @override
  String get settingsNotifications => 'Yëgle push';

  @override
  String get settingsAutoSync => 'Sync ci boppam';

  @override
  String get settingsOfflineMaps => 'Karte yu sàkku';

  @override
  String get settingsClearCache => 'Faral kache karte';

  @override
  String get settingsClearCacheConfirm => 'Faral kache karte ?';

  @override
  String get settingsClearCacheHint => 'Ubbi barab ci téléfon bi.';

  @override
  String get settingsClearCacheDone => 'Kache karte fariwoon na';

  @override
  String get settingsLogout => 'Génn';

  @override
  String get settingsLogoutConfirm => 'Génn ?';

  @override
  String get settingsCalculating => 'Mu ngi xayma…';

  @override
  String get healthNone => 'Amoo tool';

  @override
  String get healthExcellent => 'Mbay mu baax';

  @override
  String get healthGood => 'Mbay mu néex';

  @override
  String get healthWarning => 'Toppatoo ko';

  @override
  String get healthCritical => 'Mu mettit lool';

  @override
  String get healthAllFine => 'Sa tool yi lépp baax na';

  @override
  String healthNeedAttention(int count) {
    return '$count tool laa wér nga toppatoo ko';
  }

  @override
  String get severityLight => 'Toftal';

  @override
  String get severityMedium => 'Diggu';

  @override
  String get severityHigh => 'Mettit';

  @override
  String get stageSemis => 'Ji/Sax';

  @override
  String get stageGermination => 'Génn ci suuf';

  @override
  String get stageVegetative => 'Mag';

  @override
  String get stageFlowering => 'Tóor-tóor';

  @override
  String get stageFruiting => 'Meññ';

  @override
  String get stageMaturation => 'Ñor';

  @override
  String get relativeNow => 'Léegi léegi';

  @override
  String relativeMinutes(int count) {
    return 'am na $count min';
  }

  @override
  String relativeHours(int count) {
    return 'am na $count waxtu';
  }

  @override
  String relativeDays(int count) {
    return 'am na $count fan';
  }

  @override
  String get recentParcels => 'Tool yi mujje';

  @override
  String get seeAll => 'Gis lépp';

  @override
  String get mapLayerStandard => 'Standard';

  @override
  String get mapLayerDark => 'Lëndëm';

  @override
  String get mapLayerSatellite => 'Satellit';

  @override
  String get mapLayerNdvi => 'Wér-gi-yaram (NDVI) 🥬';

  @override
  String get mapLegendStress => 'Stress';

  @override
  String get mapLegendModerate => 'Diggu';

  @override
  String get mapLegendVigorous => 'Moytu';

  @override
  String get tooltipListView => 'Gis liste bi';

  @override
  String get tooltipMapView => 'Gis karte bi';

  @override
  String get parcelTabSummary => 'Tënk';

  @override
  String get parcelTabDetails => 'Leeral';

  @override
  String get parcelTabVisits => 'Wisit yi';

  @override
  String get parcelTabPhotos => 'Nataal yi';

  @override
  String get parcelTabNotes => 'Note yi';

  @override
  String get parcelKpiSurface => 'JAARYA';

  @override
  String get parcelKpiYield => 'MEÑÑÉEF';

  @override
  String get parcelActionNavigate => 'Yoon wi';

  @override
  String get parcelActionStop => 'Taxawal';

  @override
  String get parcelActionLocating => 'GPS mu ngi seet...';

  @override
  String get parcelMenuEdit => 'Soppi tool bi';

  @override
  String get parcelMenuExport => 'Génne ko PDF';

  @override
  String get parcelMenuDelete => 'Far';

  @override
  String get parcelDetailTitle => 'Leeralu tool bi';

  @override
  String get soilSandyLabel => 'Suufi suuf (Dior)';

  @override
  String get soilSandyDesc => 'Ndox mi mu ngi gaawé génn';

  @override
  String get soilSandyLoamLabel => 'Suuf ak bakk';

  @override
  String get soilSandyLoamDesc => 'Baax na lool ngir ndox mi';

  @override
  String get soilLoamLabel => 'Bakk';

  @override
  String get soilLoamDesc => 'Baax na ci lépp';

  @override
  String get soilClayLoamLabel => 'Bakk ak nax (Deck)';

  @override
  String get soilClayLoamDesc => 'Ndox mi mu ngi dencu';

  @override
  String get soilClayLabel => 'Suufi nax (Deck-dior)';

  @override
  String get soilClayDesc => 'Ndox mi mu ngi dencu bu baax';

  @override
  String get soilSiltLabel => 'Suuf mu néew';

  @override
  String get soilSiltDesc => 'Mu ngi gaawé dëgër';

  @override
  String get addParcelTitle => 'Tool bu bees';

  @override
  String get editParcelTitle => 'Soppi tool bi';

  @override
  String get addParcelStepMap => 'Natt tool bi';

  @override
  String get addParcelStepForm => 'Leeralu mbay mi';

  @override
  String get addParcelHintPoints => 'Defal 3 poñ ngir xam tool bi.';

  @override
  String get addParcelUndo => 'Dellu gannaw';

  @override
  String get addParcelClear => 'Far lépp';

  @override
  String get addParcelSave => 'Denc tool bi';

  @override
  String get addParcelLabelName => 'Turwu tool bi';

  @override
  String get addParcelLabelOwner => 'Boroom tool bi';

  @override
  String get addParcelLabelVillage => 'Dëkk bi';

  @override
  String get addParcelLabelCrop => 'Mbay mi';

  @override
  String get addParcelLabelVariety => 'Wariete';

  @override
  String get addParcelLabelSemis => 'Bis bu ñu ji';

  @override
  String get addParcelLabelSoil => 'Melo suuf bi';

  @override
  String get addParcelLabelRegion => 'Rejoŋ bi';

  @override
  String get addParcelLabelPrevCrop => 'Mbay mu jiitu';

  @override
  String get addParcelLabelIrrigation => 'Naka la ñuy taware';

  @override
  String get addParcelLabelGrowth => 'Fan la mbay mi toll';

  @override
  String get addParcelLabelYield => 'Meññéef (T/ha)';

  @override
  String get addParcelConfirmDiscard => 'Danga bëgg génn te denculoo ?';

  @override
  String get addParcelDiscardTitle => 'Liggéey bi denculoo ko';

  @override
  String addParcelSuggestionApplied(int das, String stage, String code) {
    return 'F+$das · stade suggéré : $stage (BBCH $code)';
  }

  @override
  String addParcelSuggestionCoherent(int das, String stage) {
    return 'F+$das · stade cohérent avec $stage';
  }

  @override
  String get genericCancel => 'Bàyyi';

  @override
  String get genericQuit => 'Génn';

  @override
  String get genericApply => 'Def ko';

  @override
  String get genericNext => 'Topp';

  @override
  String get genericStart => 'Tàmbali';

  @override
  String get genericStop => 'Taxawal';

  @override
  String get genericIdentification => 'Xam-xam';

  @override
  String get genericCulture => 'Mbay mi';

  @override
  String get genericRequiredField => 'Fi laa wér nga bind ko';

  @override
  String get exportTitle => 'Génne joxe yi';

  @override
  String get exportPdf => 'Génne ko PDF (Rapoort Pro)';

  @override
  String get exportExcel => 'Génne ko Excel (Tablo)';

  @override
  String exportSuccess(String file) {
    return 'Génne gi baax na : $file';
  }

  @override
  String get exportError => 'Génne gi baaxul';

  @override
  String get exportShare => 'Séddoo';

  @override
  String get exportGenerating => 'Fayil bi mu ngi sosu...';

  @override
  String get reportHeaderParcel => 'Tool bi';

  @override
  String get reportHeaderOwner => 'Boroom bi';

  @override
  String get reportHeaderVillage => 'Dëkk bi';

  @override
  String get reportHeaderCrop => 'Mbay mi';

  @override
  String get reportHeaderSurface => 'Jaarya (Ha)';

  @override
  String get reportHeaderDate => 'Bis bu ñu wisit';

  @override
  String get reportHeaderDiagnosis => 'Li ñu gis';

  @override
  String get reportHeaderAction => 'Ndigal yu ISRA/ANCAR';

  @override
  String get reportFooterNotice =>
      'Kayit bi Petalia Field Pro la jóge — Àtte v3 (ISRA, ANCAR, CSP).';

  @override
  String get authLoginTagline => 'Sa dëkkalé agronomique bu am xel';

  @override
  String get authPhoneLabel => 'Nimero telefon';

  @override
  String get authPhoneHint => '7X XXX XX XX';

  @override
  String get authPinLabel => 'Kodu bànk (4 sifr)';

  @override
  String get authErrorInvalidPhone => 'Nimero telefon bi baaxul';

  @override
  String get authErrorInvalidCredentials => 'Kodu bànk bi baaxul';

  @override
  String get authNoAccount => 'Amuló compte ba léégi? ';

  @override
  String get authRegisterCta => 'Bindu';

  @override
  String get authRegisterTitle => 'Bindu (1/3)';

  @override
  String get authRegisterHeader => 'Say mbir';

  @override
  String get authRegisterSubHeader => 'Bindul say mbir ngir aar say parcelles.';

  @override
  String get authNameLabel => 'Sa tur ak sa sant';

  @override
  String get authNameHint => 'Miseel: Samba Diop';

  @override
  String get authErrorNameTooShort => 'Tur bi gatt na lool';

  @override
  String get authErrorInvalidNumber => 'Nimero bi baaxul';

  @override
  String get authOtpTitle => 'Weral (2/3)';

  @override
  String get authOtpHeader => 'Weral sa nimero';

  @override
  String get authOtpSubHeader => 'Kodu 6 sifr yonnee nañu ko ci';

  @override
  String get authErrorInvalidOtp =>
      'Kodu bi baaxul (Jëfandikul 123456 ngir test)';

  @override
  String get authPinTitle => 'Aar (3/3)';

  @override
  String get authPinHeader => 'Kodu bànk';

  @override
  String get authPinSubHeader => 'Bindul kodu 4 sifr ngir duggu ci sa compte.';

  @override
  String get authPinFinalCta => 'Matal sa mbindu';

  @override
  String get authRegisterSuccess => 'Sa compte bindi na ak jàmm!';
}
