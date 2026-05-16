import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ff.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_wo.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ff'),
    Locale('fr'),
    Locale('wo'),
  ];

  /// Application title
  ///
  /// In fr, this message translates to:
  /// **'Petalia Field Pro'**
  String get appTitle;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get noData;

  /// No description provided for @tabDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get tabDashboard;

  /// No description provided for @tabParcels.
  ///
  /// In fr, this message translates to:
  /// **'Parcelles'**
  String get tabParcels;

  /// No description provided for @tabAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get tabAlerts;

  /// No description provided for @tabSettings.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get tabSettings;

  /// No description provided for @greetingMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir,'**
  String get greetingEvening;

  /// No description provided for @statusConnected.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get statusConnected;

  /// No description provided for @statusOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors-ligne'**
  String get statusOffline;

  /// No description provided for @statusGpsAccuracy.
  ///
  /// In fr, this message translates to:
  /// **'Précision ±{meters}m'**
  String statusGpsAccuracy(Object meters);

  /// No description provided for @statusGpsWaiting.
  ///
  /// In fr, this message translates to:
  /// **'GPS en attente'**
  String get statusGpsWaiting;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get dashboardSeeAll;

  /// No description provided for @dashboardViewMyParcels.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes parcelles'**
  String get dashboardViewMyParcels;

  /// No description provided for @dashboardToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get dashboardToday;

  /// No description provided for @dashboardCropHealth7d.
  ///
  /// In fr, this message translates to:
  /// **'Suivi de santé — 7 derniers jours'**
  String get dashboardCropHealth7d;

  /// No description provided for @dashboardDailyActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions du jour'**
  String get dashboardDailyActions;

  /// No description provided for @dashboardNewVisit.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle visite de terrain'**
  String get dashboardNewVisit;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardVoiceGuideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Guide vocal de l\'application'**
  String get dashboardVoiceGuideTitle;

  /// No description provided for @dashboardVoiceGuideDesc.
  ///
  /// In fr, this message translates to:
  /// **'Lancer la visite guidée audio'**
  String get dashboardVoiceGuideDesc;

  /// No description provided for @weatherLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement météo…'**
  String get weatherLoading;

  /// No description provided for @weatherLoadingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Récupération des conditions locales'**
  String get weatherLoadingDesc;

  /// No description provided for @weatherError.
  ///
  /// In fr, this message translates to:
  /// **'Météo indisponible'**
  String get weatherError;

  /// No description provided for @weatherErrorDesc.
  ///
  /// In fr, this message translates to:
  /// **'Réessai à la prochaine synchronisation'**
  String get weatherErrorDesc;

  /// No description provided for @weatherHumidity.
  ///
  /// In fr, this message translates to:
  /// **'Humidité'**
  String get weatherHumidity;

  /// No description provided for @weatherWind.
  ///
  /// In fr, this message translates to:
  /// **'Vent'**
  String get weatherWind;

  /// No description provided for @weatherTtsFull.
  ///
  /// In fr, this message translates to:
  /// **'Météo actuelle. {temp} degrés, {condition}. {humidity} pour cent d\'humidité. Vent {wind} kilomètres par heure.'**
  String weatherTtsFull(int temp, String condition, int humidity, int wind);

  /// No description provided for @parcelsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes parcelles'**
  String get parcelsTitle;

  /// No description provided for @parcelsAddButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une parcelle'**
  String get parcelsAddButton;

  /// No description provided for @parcelsEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune parcelle pour l\'instant'**
  String get parcelsEmptyTitle;

  /// No description provided for @parcelsEmptyMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez votre première parcelle pour commencer le suivi.'**
  String get parcelsEmptyMessage;

  /// No description provided for @parcelsSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une parcelle, un agriculteur, un village…'**
  String get parcelsSearchHint;

  /// No description provided for @parcelsAllCrops.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get parcelsAllCrops;

  /// No description provided for @recoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseils & Actions'**
  String get recoTitle;

  /// No description provided for @recoNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Parcelle introuvable'**
  String get recoNotFound;

  /// No description provided for @recoNotFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette parcelle a peut-être été supprimée ou n\'est pas encore synchronisée.'**
  String get recoNotFoundMessage;

  /// No description provided for @recoLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les conseils'**
  String get recoLoadFailed;

  /// No description provided for @recoLoadFailedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion ou réessayez dans un instant.'**
  String get recoLoadFailedMessage;

  /// No description provided for @recoBackToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get recoBackToHome;

  /// No description provided for @recoCreateReport.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon rapport'**
  String get recoCreateReport;

  /// No description provided for @recoSourcePrefix.
  ///
  /// In fr, this message translates to:
  /// **'Source : {source}'**
  String recoSourcePrefix(String source);

  /// No description provided for @recoUrgencyHigh.
  ///
  /// In fr, this message translates to:
  /// **'Urgent'**
  String get recoUrgencyHigh;

  /// No description provided for @recoUrgencyMedium.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller'**
  String get recoUrgencyMedium;

  /// No description provided for @recoUrgencyLow.
  ///
  /// In fr, this message translates to:
  /// **'Préventif'**
  String get recoUrgencyLow;

  /// No description provided for @recoUrgencyHighHint.
  ///
  /// In fr, this message translates to:
  /// **'À traiter sous 24-48 h'**
  String get recoUrgencyHighHint;

  /// No description provided for @recoUrgencyMediumHint.
  ///
  /// In fr, this message translates to:
  /// **'À traiter sous quelques jours'**
  String get recoUrgencyMediumHint;

  /// No description provided for @recoUrgencyLowHint.
  ///
  /// In fr, this message translates to:
  /// **'Bonnes pratiques'**
  String get recoUrgencyLowHint;

  /// No description provided for @recoListenAction.
  ///
  /// In fr, this message translates to:
  /// **'Écouter'**
  String get recoListenAction;

  /// No description provided for @recoStopAction.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get recoStopAction;

  /// No description provided for @recoFallbackHint.
  ///
  /// In fr, this message translates to:
  /// **'Lecture en français (voix non disponible).'**
  String get recoFallbackHint;

  /// No description provided for @recoExpertCta.
  ///
  /// In fr, this message translates to:
  /// **'Demander l\'avis d\'un agronome'**
  String get recoExpertCta;

  /// No description provided for @recoExpertCtaAlt.
  ///
  /// In fr, this message translates to:
  /// **'Ce n\'est pas mon cas — demander à un agronome'**
  String get recoExpertCtaAlt;

  /// No description provided for @recoExpertSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée ! Un agronome vous répondra.'**
  String get recoExpertSent;

  /// No description provided for @recoNextVisit.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine visite'**
  String get recoNextVisit;

  /// No description provided for @obsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Visite de terrain'**
  String get obsTitle;

  /// No description provided for @obsHowIsCrop.
  ///
  /// In fr, this message translates to:
  /// **'État de santé de la culture'**
  String get obsHowIsCrop;

  /// No description provided for @obsEverythingOk.
  ///
  /// In fr, this message translates to:
  /// **'Tout va bien'**
  String get obsEverythingOk;

  /// No description provided for @obsSomeProblems.
  ///
  /// In fr, this message translates to:
  /// **'Quelques problèmes'**
  String get obsSomeProblems;

  /// No description provided for @obsCritical.
  ///
  /// In fr, this message translates to:
  /// **'État critique'**
  String get obsCritical;

  /// No description provided for @obsWhatDoYouSee.
  ///
  /// In fr, this message translates to:
  /// **'Observations identifiées'**
  String get obsWhatDoYouSee;

  /// No description provided for @obsHowSerious.
  ///
  /// In fr, this message translates to:
  /// **'Niveau de sévérité'**
  String get obsHowSerious;

  /// No description provided for @obsWhereIsCrop.
  ///
  /// In fr, this message translates to:
  /// **'Stade de croissance actuel'**
  String get obsWhereIsCrop;

  /// No description provided for @obsMoreDetails.
  ///
  /// In fr, this message translates to:
  /// **'Plus de détails (optionnel)'**
  String get obsMoreDetails;

  /// No description provided for @obsFieldMeasurements.
  ///
  /// In fr, this message translates to:
  /// **'Mesures de terrain (optionnel)'**
  String get obsFieldMeasurements;

  /// No description provided for @obsAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get obsAddPhoto;

  /// No description provided for @obsTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get obsTakePhoto;

  /// No description provided for @obsFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Depuis la galerie'**
  String get obsFromGallery;

  /// No description provided for @obsAudioNote.
  ///
  /// In fr, this message translates to:
  /// **'Note vocale'**
  String get obsAudioNote;

  /// No description provided for @obsEvidenceRequired.
  ///
  /// In fr, this message translates to:
  /// **'Photo ou note vocale requise pour enregistrer.'**
  String get obsEvidenceRequired;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue'**
  String get settingsLanguageChoose;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @settingsThemeChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisir le thème'**
  String get settingsThemeChoose;

  /// No description provided for @settingsThemeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLargeText.
  ///
  /// In fr, this message translates to:
  /// **'Grand texte'**
  String get settingsLargeText;

  /// No description provided for @settingsLargeTextHint.
  ///
  /// In fr, this message translates to:
  /// **'Agrandit tous les textes'**
  String get settingsLargeTextHint;

  /// No description provided for @settingsHighContrast.
  ///
  /// In fr, this message translates to:
  /// **'Mode haute visibilité (terrain)'**
  String get settingsHighContrast;

  /// No description provided for @settingsHighContrastHint.
  ///
  /// In fr, this message translates to:
  /// **'Contraste renforcé pour le plein soleil'**
  String get settingsHighContrastHint;

  /// No description provided for @settingsNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications push'**
  String get settingsNotifications;

  /// No description provided for @settingsAutoSync.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde automatique'**
  String get settingsAutoSync;

  /// No description provided for @settingsOfflineMaps.
  ///
  /// In fr, this message translates to:
  /// **'Cartes hors-ligne'**
  String get settingsOfflineMaps;

  /// No description provided for @settingsClearCache.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le cache carte'**
  String get settingsClearCache;

  /// No description provided for @settingsClearCacheConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le cache carte ?'**
  String get settingsClearCacheConfirm;

  /// No description provided for @settingsClearCacheHint.
  ///
  /// In fr, this message translates to:
  /// **'Libérer de l\'espace de stockage.'**
  String get settingsClearCacheHint;

  /// No description provided for @settingsClearCacheDone.
  ///
  /// In fr, this message translates to:
  /// **'Cache carte supprimé'**
  String get settingsClearCacheDone;

  /// No description provided for @settingsLogout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter ?'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsCalculating.
  ///
  /// In fr, this message translates to:
  /// **'Calcul…'**
  String get settingsCalculating;

  /// No description provided for @healthNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune parcelle'**
  String get healthNone;

  /// No description provided for @healthExcellent.
  ///
  /// In fr, this message translates to:
  /// **'Vigoureuse'**
  String get healthExcellent;

  /// No description provided for @healthGood.
  ///
  /// In fr, this message translates to:
  /// **'Bonne santé'**
  String get healthGood;

  /// No description provided for @healthWarning.
  ///
  /// In fr, this message translates to:
  /// **'Attention requise'**
  String get healthWarning;

  /// No description provided for @healthCritical.
  ///
  /// In fr, this message translates to:
  /// **'Situation critique'**
  String get healthCritical;

  /// No description provided for @healthAllFine.
  ///
  /// In fr, this message translates to:
  /// **'Toutes vos parcelles sont en forme'**
  String get healthAllFine;

  /// No description provided for @healthNeedAttention.
  ///
  /// In fr, this message translates to:
  /// **'{count} parcelle(s) nécessite(nt) votre attention'**
  String healthNeedAttention(int count);

  /// No description provided for @severityLight.
  ///
  /// In fr, this message translates to:
  /// **'Léger'**
  String get severityLight;

  /// No description provided for @severityMedium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get severityMedium;

  /// No description provided for @severityHigh.
  ///
  /// In fr, this message translates to:
  /// **'Grave'**
  String get severityHigh;

  /// No description provided for @stageSemis.
  ///
  /// In fr, this message translates to:
  /// **'Semis/Plantation'**
  String get stageSemis;

  /// No description provided for @stageGermination.
  ///
  /// In fr, this message translates to:
  /// **'Levée'**
  String get stageGermination;

  /// No description provided for @stageVegetative.
  ///
  /// In fr, this message translates to:
  /// **'Croissance'**
  String get stageVegetative;

  /// No description provided for @stageFlowering.
  ///
  /// In fr, this message translates to:
  /// **'Floraison'**
  String get stageFlowering;

  /// No description provided for @stageFruiting.
  ///
  /// In fr, this message translates to:
  /// **'Formation fruits'**
  String get stageFruiting;

  /// No description provided for @stageMaturation.
  ///
  /// In fr, this message translates to:
  /// **'Maturité'**
  String get stageMaturation;

  /// No description provided for @relativeNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get relativeNow;

  /// No description provided for @relativeMinutes.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} min'**
  String relativeMinutes(int count);

  /// No description provided for @relativeHours.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} h'**
  String relativeHours(int count);

  /// No description provided for @relativeDays.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} j'**
  String relativeDays(int count);

  /// No description provided for @recentParcels.
  ///
  /// In fr, this message translates to:
  /// **'Parcelles récentes'**
  String get recentParcels;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get seeAll;

  /// No description provided for @mapLayerStandard.
  ///
  /// In fr, this message translates to:
  /// **'Standard'**
  String get mapLayerStandard;

  /// No description provided for @mapLayerDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get mapLayerDark;

  /// No description provided for @mapLayerSatellite.
  ///
  /// In fr, this message translates to:
  /// **'Satellite'**
  String get mapLayerSatellite;

  /// No description provided for @mapLayerNdvi.
  ///
  /// In fr, this message translates to:
  /// **'Santé (NDVI) 🥬'**
  String get mapLayerNdvi;

  /// No description provided for @mapLegendStress.
  ///
  /// In fr, this message translates to:
  /// **'Stress'**
  String get mapLegendStress;

  /// No description provided for @mapLegendModerate.
  ///
  /// In fr, this message translates to:
  /// **'Modéré'**
  String get mapLegendModerate;

  /// No description provided for @mapLegendVigorous.
  ///
  /// In fr, this message translates to:
  /// **'Vigoureux'**
  String get mapLegendVigorous;

  /// No description provided for @tooltipListView.
  ///
  /// In fr, this message translates to:
  /// **'Vue liste'**
  String get tooltipListView;

  /// No description provided for @tooltipMapView.
  ///
  /// In fr, this message translates to:
  /// **'Vue carte'**
  String get tooltipMapView;

  /// No description provided for @parcelTabSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get parcelTabSummary;

  /// No description provided for @parcelTabDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get parcelTabDetails;

  /// No description provided for @parcelTabVisits.
  ///
  /// In fr, this message translates to:
  /// **'Visites'**
  String get parcelTabVisits;

  /// No description provided for @parcelTabPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get parcelTabPhotos;

  /// No description provided for @parcelTabNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes'**
  String get parcelTabNotes;

  /// No description provided for @parcelKpiSurface.
  ///
  /// In fr, this message translates to:
  /// **'SURFACE'**
  String get parcelKpiSurface;

  /// No description provided for @parcelKpiYield.
  ///
  /// In fr, this message translates to:
  /// **'RENDEMENT'**
  String get parcelKpiYield;

  /// No description provided for @parcelActionNavigate.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get parcelActionNavigate;

  /// No description provided for @parcelActionStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get parcelActionStop;

  /// No description provided for @parcelActionLocating.
  ///
  /// In fr, this message translates to:
  /// **'Recherche GPS...'**
  String get parcelActionLocating;

  /// No description provided for @parcelMenuEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la parcelle'**
  String get parcelMenuEdit;

  /// No description provided for @parcelMenuExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF'**
  String get parcelMenuExport;

  /// No description provided for @parcelMenuDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get parcelMenuDelete;

  /// No description provided for @parcelDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la parcelle'**
  String get parcelDetailTitle;

  /// No description provided for @soilSandyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sableux (Dior)'**
  String get soilSandyLabel;

  /// No description provided for @soilSandyDesc.
  ///
  /// In fr, this message translates to:
  /// **'Drainage rapide, faible rétention d\'eau'**
  String get soilSandyDesc;

  /// No description provided for @soilSandyLoamLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sablo-limoneux'**
  String get soilSandyLoamLabel;

  /// No description provided for @soilSandyLoamDesc.
  ///
  /// In fr, this message translates to:
  /// **'Bon compromis drainage / rétention'**
  String get soilSandyLoamDesc;

  /// No description provided for @soilLoamLabel.
  ///
  /// In fr, this message translates to:
  /// **'Limoneux'**
  String get soilLoamLabel;

  /// No description provided for @soilLoamDesc.
  ///
  /// In fr, this message translates to:
  /// **'Polyvalent, rétention moyenne'**
  String get soilLoamDesc;

  /// No description provided for @soilClayLoamLabel.
  ///
  /// In fr, this message translates to:
  /// **'Argilo-limoneux (Deck)'**
  String get soilClayLoamLabel;

  /// No description provided for @soilClayLoamDesc.
  ///
  /// In fr, this message translates to:
  /// **'Bonne rétention, risque de tassement'**
  String get soilClayLoamDesc;

  /// No description provided for @soilClayLabel.
  ///
  /// In fr, this message translates to:
  /// **'Argileux (Deck-dior)'**
  String get soilClayLabel;

  /// No description provided for @soilClayDesc.
  ///
  /// In fr, this message translates to:
  /// **'Rétention forte, drainage lent'**
  String get soilClayDesc;

  /// No description provided for @soilSiltLabel.
  ///
  /// In fr, this message translates to:
  /// **'Limoneux fin'**
  String get soilSiltLabel;

  /// No description provided for @soilSiltDesc.
  ///
  /// In fr, this message translates to:
  /// **'Battant, sensible à la croûte'**
  String get soilSiltDesc;

  /// No description provided for @addParcelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle parcelle'**
  String get addParcelTitle;

  /// No description provided for @editParcelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la parcelle'**
  String get editParcelTitle;

  /// No description provided for @addParcelStepMap.
  ///
  /// In fr, this message translates to:
  /// **'Délimiter la parcelle'**
  String get addParcelStepMap;

  /// No description provided for @addParcelStepForm.
  ///
  /// In fr, this message translates to:
  /// **'Informations culture'**
  String get addParcelStepForm;

  /// No description provided for @addParcelHintPoints.
  ///
  /// In fr, this message translates to:
  /// **'Placez au moins 3 points pour définir la parcelle.'**
  String get addParcelHintPoints;

  /// No description provided for @addParcelUndo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler dernier point'**
  String get addParcelUndo;

  /// No description provided for @addParcelClear.
  ///
  /// In fr, this message translates to:
  /// **'Tout effacer'**
  String get addParcelClear;

  /// No description provided for @addParcelSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la parcelle'**
  String get addParcelSave;

  /// No description provided for @addParcelLabelName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la parcelle'**
  String get addParcelLabelName;

  /// No description provided for @addParcelLabelOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire / Agriculteur'**
  String get addParcelLabelOwner;

  /// No description provided for @addParcelLabelVillage.
  ///
  /// In fr, this message translates to:
  /// **'Village / Localité'**
  String get addParcelLabelVillage;

  /// No description provided for @addParcelLabelCrop.
  ///
  /// In fr, this message translates to:
  /// **'Culture'**
  String get addParcelLabelCrop;

  /// No description provided for @addParcelLabelVariety.
  ///
  /// In fr, this message translates to:
  /// **'Variété'**
  String get addParcelLabelVariety;

  /// No description provided for @addParcelLabelSemis.
  ///
  /// In fr, this message translates to:
  /// **'Date de semis'**
  String get addParcelLabelSemis;

  /// No description provided for @addParcelLabelSoil.
  ///
  /// In fr, this message translates to:
  /// **'Type de sol'**
  String get addParcelLabelSoil;

  /// No description provided for @addParcelLabelRegion.
  ///
  /// In fr, this message translates to:
  /// **'Région'**
  String get addParcelLabelRegion;

  /// No description provided for @addParcelLabelPrevCrop.
  ///
  /// In fr, this message translates to:
  /// **'Culture précédente'**
  String get addParcelLabelPrevCrop;

  /// No description provided for @addParcelLabelIrrigation.
  ///
  /// In fr, this message translates to:
  /// **'Mode d\'irrigation'**
  String get addParcelLabelIrrigation;

  /// No description provided for @addParcelLabelGrowth.
  ///
  /// In fr, this message translates to:
  /// **'Stade de croissance'**
  String get addParcelLabelGrowth;

  /// No description provided for @addParcelLabelYield.
  ///
  /// In fr, this message translates to:
  /// **'Rendement estimé (T/ha)'**
  String get addParcelLabelYield;

  /// No description provided for @addParcelConfirmDiscard.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous quitter sans enregistrer ?'**
  String get addParcelConfirmDiscard;

  /// No description provided for @addParcelDiscardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifications non enregistrées'**
  String get addParcelDiscardTitle;

  /// No description provided for @addParcelSuggestionApplied.
  ///
  /// In fr, this message translates to:
  /// **'J+{das} · stade suggéré : {stage} (BBCH {code})'**
  String addParcelSuggestionApplied(int das, String stage, String code);

  /// No description provided for @addParcelSuggestionCoherent.
  ///
  /// In fr, this message translates to:
  /// **'J+{das} · stade cohérent avec {stage}'**
  String addParcelSuggestionCoherent(int das, String stage);

  /// No description provided for @genericCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get genericCancel;

  /// No description provided for @genericQuit.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get genericQuit;

  /// No description provided for @genericApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get genericApply;

  /// No description provided for @genericNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get genericNext;

  /// No description provided for @genericStart.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer'**
  String get genericStart;

  /// No description provided for @genericStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get genericStop;

  /// No description provided for @genericIdentification.
  ///
  /// In fr, this message translates to:
  /// **'Identification'**
  String get genericIdentification;

  /// No description provided for @genericCulture.
  ///
  /// In fr, this message translates to:
  /// **'Culture'**
  String get genericCulture;

  /// No description provided for @genericRequiredField.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire'**
  String get genericRequiredField;

  /// No description provided for @exportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Exporter les données'**
  String get exportTitle;

  /// No description provided for @exportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF (Rapport Pro)'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en Excel (Tableau)'**
  String get exportExcel;

  /// No description provided for @exportSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Export réussi : {file}'**
  String exportSuccess(String file);

  /// No description provided for @exportError.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'export'**
  String get exportError;

  /// No description provided for @exportShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get exportShare;

  /// No description provided for @exportGenerating.
  ///
  /// In fr, this message translates to:
  /// **'Génération du fichier...'**
  String get exportGenerating;

  /// No description provided for @reportHeaderParcel.
  ///
  /// In fr, this message translates to:
  /// **'Parcelle'**
  String get reportHeaderParcel;

  /// No description provided for @reportHeaderOwner.
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get reportHeaderOwner;

  /// No description provided for @reportHeaderVillage.
  ///
  /// In fr, this message translates to:
  /// **'Village'**
  String get reportHeaderVillage;

  /// No description provided for @reportHeaderCrop.
  ///
  /// In fr, this message translates to:
  /// **'Culture'**
  String get reportHeaderCrop;

  /// No description provided for @reportHeaderSurface.
  ///
  /// In fr, this message translates to:
  /// **'Surface (Ha)'**
  String get reportHeaderSurface;

  /// No description provided for @reportHeaderDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de visite'**
  String get reportHeaderDate;

  /// No description provided for @reportHeaderDiagnosis.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic / Observation'**
  String get reportHeaderDiagnosis;

  /// No description provided for @reportHeaderAction.
  ///
  /// In fr, this message translates to:
  /// **'Recommandations ISRA/ANCAR'**
  String get reportHeaderAction;

  /// No description provided for @reportFooterNotice.
  ///
  /// In fr, this message translates to:
  /// **'Document généré par Petalia Field Pro — Règles v3 consolidées (ISRA, ANCAR, CSP).'**
  String get reportFooterNotice;

  /// No description provided for @authLoginTagline.
  ///
  /// In fr, this message translates to:
  /// **'Votre compagnon agronomique intelligent'**
  String get authLoginTagline;

  /// No description provided for @authPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In fr, this message translates to:
  /// **'7X XXX XX XX'**
  String get authPhoneHint;

  /// No description provided for @authPinLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code secret (4 chiffres)'**
  String get authPinLabel;

  /// No description provided for @authErrorInvalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide'**
  String get authErrorInvalidPhone;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants incorrects'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? '**
  String get authNoAccount;

  /// No description provided for @authRegisterCta.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get authRegisterCta;

  /// No description provided for @authRegisterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscription (1/3)'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterHeader.
  ///
  /// In fr, this message translates to:
  /// **'Vos informations'**
  String get authRegisterHeader;

  /// No description provided for @authRegisterSubHeader.
  ///
  /// In fr, this message translates to:
  /// **'Identifiez-vous pour sécuriser l\'accès à vos parcelles.'**
  String get authRegisterSubHeader;

  /// No description provided for @authNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get authNameLabel;

  /// No description provided for @authNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Samba Diop'**
  String get authNameHint;

  /// No description provided for @authErrorNameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Nom trop court'**
  String get authErrorNameTooShort;

  /// No description provided for @authErrorInvalidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide'**
  String get authErrorInvalidNumber;

  /// No description provided for @authOtpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification (2/3)'**
  String get authOtpTitle;

  /// No description provided for @authOtpHeader.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre numéro'**
  String get authOtpHeader;

  /// No description provided for @authOtpSubHeader.
  ///
  /// In fr, this message translates to:
  /// **'Un code à 6 chiffres a été envoyé au'**
  String get authOtpSubHeader;

  /// No description provided for @authErrorInvalidOtp.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect (Utilisez 123456 pour le test)'**
  String get authErrorInvalidOtp;

  /// No description provided for @authPinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurisation (3/3)'**
  String get authPinTitle;

  /// No description provided for @authPinHeader.
  ///
  /// In fr, this message translates to:
  /// **'Code Secret'**
  String get authPinHeader;

  /// No description provided for @authPinSubHeader.
  ///
  /// In fr, this message translates to:
  /// **'Définissez un code à 4 chiffres pour accéder à votre compte.'**
  String get authPinSubHeader;

  /// No description provided for @authPinFinalCta.
  ///
  /// In fr, this message translates to:
  /// **'Finaliser l\'inscription'**
  String get authPinFinalCta;

  /// No description provided for @authRegisterSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé avec succès !'**
  String get authRegisterSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ff', 'fr', 'wo'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ff':
      return AppLocalizationsFf();
    case 'fr':
      return AppLocalizationsFr();
    case 'wo':
      return AppLocalizationsWo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
