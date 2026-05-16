// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Fulah (`ff`).
class AppLocalizationsFf extends AppLocalizations {
  AppLocalizationsFf([String locale = 'ff']) : super(locale);

  @override
  String get appTitle => 'Petalia Field Pro';

  @override
  String get save => 'Mooftu';

  @override
  String get cancel => 'Haaytu';

  @override
  String get delete => 'Momtu';

  @override
  String get edit => 'Wattindo';

  @override
  String get add => 'Beydu';

  @override
  String get close => 'Uddu';

  @override
  String get confirm => 'Teeŋtin';

  @override
  String get retry => 'Ƴeewto';

  @override
  String get back => 'Rutto';

  @override
  String get next => 'Jokku';

  @override
  String get done => 'Gasii';

  @override
  String get search => 'Yiilo';

  @override
  String get loading => 'Ina loowee…';

  @override
  String get error => 'Juumre';

  @override
  String get noData => 'Alaa hay batte';

  @override
  String get tabDashboard => 'Galle';

  @override
  String get tabParcels => 'Ngesaaji am';

  @override
  String get tabAlerts => 'Habrudee';

  @override
  String get tabSettings => 'Profiil maa';

  @override
  String get greetingMorning => 'Bonjour,';

  @override
  String get greetingAfternoon => 'Bon après-midi,';

  @override
  String get greetingEvening => 'Bonsoir,';

  @override
  String get statusConnected => 'Connecté';

  @override
  String get statusOffline => 'Hors-ligne';

  @override
  String statusGpsAccuracy(Object meters) {
    return 'Précision ±${meters}m';
  }

  @override
  String get statusGpsWaiting => 'GPS en attente';

  @override
  String get dashboardSeeAll => 'Yiy fof';

  @override
  String get dashboardViewMyParcels => 'Yiy ngesaaji am';

  @override
  String get dashboardToday => 'Hannde';

  @override
  String get dashboardCropHealth7d => 'Cellal gàncax — 7 balɗe gadano';

  @override
  String get dashboardDailyActions => 'Kewuuji hannde';

  @override
  String get dashboardNewVisit => 'Wisit terrain keso';

  @override
  String get dashboardQuickActions => 'Kewuuji yaawɗi';

  @override
  String get dashboardVoiceGuideTitle => 'Ardiije daande';

  @override
  String get dashboardVoiceGuideDesc => 'Fuɗɗu visit vocal oo';

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
  String get parcelsTitle => 'Ngesaaji am';

  @override
  String get parcelsAddButton => 'Beydu ngesa';

  @override
  String get parcelsEmptyTitle => 'Alaa ngesa hay haa jooni';

  @override
  String get parcelsEmptyMessage =>
      'Beydu ngesa maa adii ngam fuɗɗaade tabitinde.';

  @override
  String get parcelsSearchHint => 'Yiilo ngesa';

  @override
  String get parcelsAllCrops => 'Fof';

  @override
  String get recoTitle => 'Wasiyaaji & Golle';

  @override
  String get recoNotFound => 'Ngesa heɓaaka';

  @override
  String get recoNotFoundMessage =>
      'Ngesa nde ina waawi momtaade walla nde sync-aaki tawo.';

  @override
  String get recoLoadFailed => 'Wasiyaaji ɗii loowaaki';

  @override
  String get recoLoadFailedMessage => 'Ƴeewtu konekson maa walla ƴeewto seeɗa.';

  @override
  String get recoBackToHome => 'Rutto galle';

  @override
  String get recoCreateReport => 'Sosu rapoor am';

  @override
  String recoSourcePrefix(String source) {
    return 'Iwdi : $source';
  }

  @override
  String get recoUrgencyHigh => 'Yaawnde';

  @override
  String get recoUrgencyMedium => 'Ndaaree';

  @override
  String get recoUrgencyLow => 'Reentino';

  @override
  String get recoUrgencyHighHint => 'Huutoro nder waktuuji 24-48';

  @override
  String get recoUrgencyMediumHint => 'Huutoro nder balɗe seeɗa';

  @override
  String get recoUrgencyLowHint => 'Golle moƴƴe';

  @override
  String get recoListenAction => 'Heɗo';

  @override
  String get recoStopAction => 'Daro';

  @override
  String get recoFallbackHint => 'Janngugol e Faraysere (sawtu Pulaar alaa).';

  @override
  String get recoExpertCta => 'Lamndo ekspeer ndema';

  @override
  String get recoExpertCtaAlt => 'Ɗum wonaa ko am — lamndo ekspeer ndema';

  @override
  String get recoExpertSent => 'Lamndal nelaama ! Ekspeer ndema maa jaabo ma.';

  @override
  String get recoNextVisit => 'Yiilannde aroore';

  @override
  String get obsTitle => 'Yiilannde ngesa';

  @override
  String get obsHowIsCrop => 'No puɗo maa woni ?';

  @override
  String get obsEverythingOk => 'Fof ina yahra boom';

  @override
  String get obsSomeProblems => 'Caɗeele seeɗa';

  @override
  String get obsCritical => 'Ngonka muusɗo';

  @override
  String get obsWhatDoYouSee => 'Ko yiy-ɗaa ?';

  @override
  String get obsHowSerious => 'Hol no muusi ?';

  @override
  String get obsWhereIsCrop => 'Hol to puɗo maa woni ?';

  @override
  String get obsMoreDetails => 'Ko ɓuri (so jiɗɗaa)';

  @override
  String get obsFieldMeasurements => 'Betɗe ngesa (so jiɗɗaa)';

  @override
  String get obsAddPhoto => 'Beydu nataal';

  @override
  String get obsTakePhoto => 'Ƴetto nataal';

  @override
  String get obsFromGallery => 'Iwdi galeri';

  @override
  String get obsAudioNote => 'Note sawtu';

  @override
  String get obsEvidenceRequired =>
      'Nataal walla note sawtu ina sokli ngam mooftude.';

  @override
  String get settingsTitle => 'Teelte';

  @override
  String get settingsLanguage => 'Ɗemngal';

  @override
  String get settingsLanguageChoose => 'Suɓo ɗemngal';

  @override
  String get settingsTheme => 'Mbaadi';

  @override
  String get settingsThemeChoose => 'Suɓo mbaadi';

  @override
  String get settingsThemeLight => 'Jalbuɗo';

  @override
  String get settingsThemeDark => 'Ɓaleejo';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsLargeText => 'Binndi mawɗi';

  @override
  String get settingsLargeTextHint => 'Mawnin binndi fof';

  @override
  String get settingsHighContrast => 'Mode ngesa';

  @override
  String get settingsHighContrastHint => 'Kontras ɓeydaaɗo ngam naange tiiɗɗo';

  @override
  String get settingsNotifications => 'Habrudee push';

  @override
  String get settingsAutoSync => 'Sync e hoore mum';

  @override
  String get settingsOfflineMaps => 'Kaarte sokle';

  @override
  String get settingsClearCache => 'Momtu kasi kaarte';

  @override
  String get settingsClearCacheConfirm => 'Momtu kasi kaarte ?';

  @override
  String get settingsClearCacheHint => 'Ɓooyna nokku e kaɓirgal.';

  @override
  String get settingsClearCacheDone => 'Kasi kaarte momtaama';

  @override
  String get settingsLogout => 'Yaltu';

  @override
  String get settingsLogoutConfirm => 'Yaltu ?';

  @override
  String get settingsCalculating => 'Ina limee…';

  @override
  String get healthNone => 'Alaa ngesa';

  @override
  String get healthExcellent => 'Ngesa moƴƴo';

  @override
  String get healthGood => 'Ngesa belɗo';

  @override
  String get healthWarning => 'Toppitée seeɗa';

  @override
  String get healthCritical => 'Ngonka muusɗo';

  @override
  String get healthAllFine => 'Ngesaaji maa fof ina mbooli';

  @override
  String healthNeedAttention(int count) {
    return '$count ngesa ina sokli toppitgol';
  }

  @override
  String get severityLight => 'Pamaro';

  @override
  String get severityMedium => 'Hakkundeejo';

  @override
  String get severityHigh => 'Tiiɗɗo';

  @override
  String get stageSemis => 'Aawre/Aawde';

  @override
  String get stageGermination => 'Fuɗde';

  @override
  String get stageVegetative => 'Mawnude';

  @override
  String get stageFlowering => 'Pidugol';

  @override
  String get stageFruiting => 'Dimɗude';

  @override
  String get stageMaturation => 'Ɓenndude';

  @override
  String get relativeNow => 'Jooni jooni';

  @override
  String relativeMinutes(int count) {
    return 'ina woni $count min';
  }

  @override
  String relativeHours(int count) {
    return 'ina woni $count waktu';
  }

  @override
  String relativeDays(int count) {
    return 'ina woni $count balɗe';
  }

  @override
  String get recentParcels => 'Parcelles récentes';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get mapLayerStandard => 'Standard';

  @override
  String get mapLayerDark => 'Ɓaleejo';

  @override
  String get mapLayerSatellite => 'Satellit';

  @override
  String get mapLayerNdvi => 'Cellal (NDVI) 🥬';

  @override
  String get mapLegendStress => 'Stress';

  @override
  String get mapLegendModerate => 'Hakkundeejo';

  @override
  String get mapLegendVigorous => 'Tiiɗɗo';

  @override
  String get tooltipListView => 'Vue liste';

  @override
  String get tooltipMapView => 'Vue carte';

  @override
  String get parcelTabSummary => 'Tënk';

  @override
  String get parcelTabDetails => 'Détailji';

  @override
  String get parcelTabVisits => 'Yiilannde';

  @override
  String get parcelTabPhotos => 'Nataalji';

  @override
  String get parcelTabNotes => 'Noteji';

  @override
  String get parcelKpiSurface => 'SURFACE';

  @override
  String get parcelKpiYield => 'MEÑÑÉEF';

  @override
  String get parcelActionNavigate => 'Laawol';

  @override
  String get parcelActionStop => 'Daro';

  @override
  String get parcelActionLocating => 'Yiilo GPS...';

  @override
  String get parcelMenuEdit => 'Modifier la parcelle';

  @override
  String get parcelMenuExport => 'Exporter en PDF';

  @override
  String get parcelMenuDelete => 'Supprimer';

  @override
  String get parcelDetailTitle => 'Détails de la parcelle';

  @override
  String get soilSandyLabel => 'Dior';

  @override
  String get soilSandyDesc => 'Ndiyam ina yaawi yaltude';

  @override
  String get soilSandyLoamLabel => 'Sablo-limoneux';

  @override
  String get soilSandyLoamDesc => 'Ina moƴƴi e ndiyam';

  @override
  String get soilLoamLabel => 'Limoneux';

  @override
  String get soilLoamDesc => 'Ina moƴƴi e fof';

  @override
  String get soilClayLoamLabel => 'Deck';

  @override
  String get soilClayLoamDesc => 'Ndiyam ina heddoo seeɗa';

  @override
  String get soilClayLabel => 'Deck-dior';

  @override
  String get soilClayDesc => 'Ndiyam ina heddoo no feewi';

  @override
  String get soilSiltLabel => 'Limoneux fin';

  @override
  String get soilSiltDesc => 'Battant, sensible à la croûte';

  @override
  String get addParcelTitle => 'Nouvelle parcelle';

  @override
  String get editParcelTitle => 'Modifier la parcelle';

  @override
  String get addParcelStepMap => 'Délimiter la parcelle';

  @override
  String get addParcelStepForm => 'Informations culture';

  @override
  String get addParcelHintPoints =>
      'Placez au moins 3 points pour définir la parcelle.';

  @override
  String get addParcelUndo => 'Annuler dernier point';

  @override
  String get addParcelClear => 'Tout effacer';

  @override
  String get addParcelSave => 'Enregistrer la parcelle';

  @override
  String get addParcelLabelName => 'Nom de la parcelle';

  @override
  String get addParcelLabelOwner => 'Propriétaire / Agriculteur';

  @override
  String get addParcelLabelVillage => 'Village / Localité';

  @override
  String get addParcelLabelCrop => 'Culture';

  @override
  String get addParcelLabelVariety => 'Variété';

  @override
  String get addParcelLabelSemis => 'Date de semis';

  @override
  String get addParcelLabelSoil => 'Type de sol';

  @override
  String get addParcelLabelRegion => 'Région';

  @override
  String get addParcelLabelPrevCrop => 'Culture précédente';

  @override
  String get addParcelLabelIrrigation => 'Mode d\'irrigation';

  @override
  String get addParcelLabelGrowth => 'Stade de croissance';

  @override
  String get addParcelLabelYield => 'Rendement estimé (T/ha)';

  @override
  String get addParcelConfirmDiscard =>
      'Voulez-vous quitter sans enregistrer ?';

  @override
  String get addParcelDiscardTitle => 'Modifications non enregistrées';

  @override
  String addParcelSuggestionApplied(int das, String stage, String code) {
    return 'J+$das · stade suggéré : $stage (BBCH $code)';
  }

  @override
  String addParcelSuggestionCoherent(int das, String stage) {
    return 'J+$das · stade cohérent avec $stage';
  }

  @override
  String get genericCancel => 'Haaytu';

  @override
  String get genericQuit => 'Yaltu';

  @override
  String get genericApply => 'Huutoro';

  @override
  String get genericNext => 'Jokku';

  @override
  String get genericStart => 'Fuɗɗo';

  @override
  String get genericStop => 'Daro';

  @override
  String get genericIdentification => 'Anndol';

  @override
  String get genericCulture => 'Ndema';

  @override
  String get genericRequiredField => 'Ɗo ina sokli winndude';

  @override
  String get exportTitle => 'Yaltin joxe';

  @override
  String get exportPdf => 'Yaltin e PDF (Rapoort Pro)';

  @override
  String get exportExcel => 'Yaltin e Excel (Tableau)';

  @override
  String exportSuccess(String file) {
    return 'Yaltingol moƴƴi : $file';
  }

  @override
  String get exportError => 'Yaltingol moƴƴaani';

  @override
  String get exportShare => 'Séddoo';

  @override
  String get exportGenerating => 'Fayil oo ina soso...';

  @override
  String get reportHeaderParcel => 'Ngesa';

  @override
  String get reportHeaderOwner => 'Joomum';

  @override
  String get reportHeaderVillage => 'Wuro';

  @override
  String get reportHeaderCrop => 'Ndema';

  @override
  String get reportHeaderSurface => 'Surface (Ha)';

  @override
  String get reportHeaderDate => 'Ñalnde yiilannde';

  @override
  String get reportHeaderDiagnosis => 'Ko yiy-ɗaa';

  @override
  String get reportHeaderAction => 'Wasiyaaji ISRA/ANCAR';

  @override
  String get reportFooterNotice =>
      'Kayit oo ummi ko e Petalia Field Pro — Doosɗe v3 (ISRA, ANCAR, CSP).';

  @override
  String get authLoginTagline => 'Gollitirgal maa gure agronomique';

  @override
  String get authPhoneLabel => 'Limo telefon';

  @override
  String get authPhoneHint => '7X XXX XX XX';

  @override
  String get authPinLabel => 'Kodu sirlu (4 sifr)';

  @override
  String get authErrorInvalidPhone => 'Limo telefon oo woodani';

  @override
  String get authErrorInvalidCredentials => 'Kodu sirlu oo woodani';

  @override
  String get authNoAccount => 'A ala compte tawo? ';

  @override
  String get authRegisterCta => 'Winndito';

  @override
  String get authRegisterTitle => 'Winndito (1/3)';

  @override
  String get authRegisterHeader => 'Habbere maa';

  @override
  String get authRegisterSubHeader => 'Winndito ngir reena gure maa.';

  @override
  String get authNameLabel => 'Innde e jammu';

  @override
  String get authNameHint => 'Miseel: Samba Diop';

  @override
  String get authErrorNameTooShort => 'Innde ndee raɓi no feewi';

  @override
  String get authErrorInvalidNumber => 'Limo oo woodani';

  @override
  String get authOtpTitle => 'Goongɗinal (2/3)';

  @override
  String get authOtpHeader => 'Goongɗin limo maa';

  @override
  String get authOtpSubHeader => 'Kodu 6 sifr nelaama to';

  @override
  String get authErrorInvalidOtp =>
      'Kodu oo woodani (Kuutoro 123456 ngir jarribo)';

  @override
  String get authPinTitle => 'Reenude (3/3)';

  @override
  String get authPinHeader => 'Kodu sirlu';

  @override
  String get authPinSubHeader => 'Winndu kodu 4 sifr ngir naatde e compte maa.';

  @override
  String get authPinFinalCta => 'Timmin winndito';

  @override
  String get authRegisterSuccess => 'Compte maa winndiima e jam!';
}
