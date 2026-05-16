// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Petalia Field Pro';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get close => 'Fermer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get retry => 'Réessayer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get done => 'Terminé';

  @override
  String get search => 'Rechercher';

  @override
  String get loading => 'Chargement…';

  @override
  String get error => 'Erreur';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get tabDashboard => 'Accueil';

  @override
  String get tabParcels => 'Parcelles';

  @override
  String get tabAlerts => 'Alertes';

  @override
  String get tabSettings => 'Profil';

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
  String get dashboardSeeAll => 'Tout voir';

  @override
  String get dashboardViewMyParcels => 'Voir mes parcelles';

  @override
  String get dashboardToday => 'Aujourd\'hui';

  @override
  String get dashboardCropHealth7d => 'Suivi de santé — 7 derniers jours';

  @override
  String get dashboardDailyActions => 'Actions du jour';

  @override
  String get dashboardNewVisit => 'Nouvelle visite de terrain';

  @override
  String get dashboardQuickActions => 'Actions rapides';

  @override
  String get dashboardVoiceGuideTitle => 'Guide vocal de l\'application';

  @override
  String get dashboardVoiceGuideDesc => 'Lancer la visite guidée audio';

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
  String get parcelsTitle => 'Mes parcelles';

  @override
  String get parcelsAddButton => 'Ajouter une parcelle';

  @override
  String get parcelsEmptyTitle => 'Aucune parcelle pour l\'instant';

  @override
  String get parcelsEmptyMessage =>
      'Ajoutez votre première parcelle pour commencer le suivi.';

  @override
  String get parcelsSearchHint =>
      'Rechercher une parcelle, un agriculteur, un village…';

  @override
  String get parcelsAllCrops => 'Toutes';

  @override
  String get recoTitle => 'Conseils & Actions';

  @override
  String get recoNotFound => 'Parcelle introuvable';

  @override
  String get recoNotFoundMessage =>
      'Cette parcelle a peut-être été supprimée ou n\'est pas encore synchronisée.';

  @override
  String get recoLoadFailed => 'Impossible de charger les conseils';

  @override
  String get recoLoadFailedMessage =>
      'Vérifiez votre connexion ou réessayez dans un instant.';

  @override
  String get recoBackToHome => 'Retour à l\'accueil';

  @override
  String get recoCreateReport => 'Créer mon rapport';

  @override
  String recoSourcePrefix(String source) {
    return 'Source : $source';
  }

  @override
  String get recoUrgencyHigh => 'Urgent';

  @override
  String get recoUrgencyMedium => 'À surveiller';

  @override
  String get recoUrgencyLow => 'Préventif';

  @override
  String get recoUrgencyHighHint => 'À traiter sous 24-48 h';

  @override
  String get recoUrgencyMediumHint => 'À traiter sous quelques jours';

  @override
  String get recoUrgencyLowHint => 'Bonnes pratiques';

  @override
  String get recoListenAction => 'Écouter';

  @override
  String get recoStopAction => 'Arrêter';

  @override
  String get recoFallbackHint => 'Lecture en français (voix non disponible).';

  @override
  String get recoExpertCta => 'Demander l\'avis d\'un agronome';

  @override
  String get recoExpertCtaAlt =>
      'Ce n\'est pas mon cas — demander à un agronome';

  @override
  String get recoExpertSent => 'Demande envoyée ! Un agronome vous répondra.';

  @override
  String get recoNextVisit => 'Prochaine visite';

  @override
  String get obsTitle => 'Visite de terrain';

  @override
  String get obsHowIsCrop => 'État de santé de la culture';

  @override
  String get obsEverythingOk => 'Tout va bien';

  @override
  String get obsSomeProblems => 'Quelques problèmes';

  @override
  String get obsCritical => 'État critique';

  @override
  String get obsWhatDoYouSee => 'Observations identifiées';

  @override
  String get obsHowSerious => 'Niveau de sévérité';

  @override
  String get obsWhereIsCrop => 'Stade de croissance actuel';

  @override
  String get obsMoreDetails => 'Plus de détails (optionnel)';

  @override
  String get obsFieldMeasurements => 'Mesures de terrain (optionnel)';

  @override
  String get obsAddPhoto => 'Ajouter une photo';

  @override
  String get obsTakePhoto => 'Prendre une photo';

  @override
  String get obsFromGallery => 'Depuis la galerie';

  @override
  String get obsAudioNote => 'Note vocale';

  @override
  String get obsEvidenceRequired =>
      'Photo ou note vocale requise pour enregistrer.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageChoose => 'Choisir la langue';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeChoose => 'Choisir le thème';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsLargeText => 'Grand texte';

  @override
  String get settingsLargeTextHint => 'Agrandit tous les textes';

  @override
  String get settingsHighContrast => 'Mode haute visibilité (terrain)';

  @override
  String get settingsHighContrastHint =>
      'Contraste renforcé pour le plein soleil';

  @override
  String get settingsNotifications => 'Notifications push';

  @override
  String get settingsAutoSync => 'Sauvegarde automatique';

  @override
  String get settingsOfflineMaps => 'Cartes hors-ligne';

  @override
  String get settingsClearCache => 'Supprimer le cache carte';

  @override
  String get settingsClearCacheConfirm => 'Supprimer le cache carte ?';

  @override
  String get settingsClearCacheHint => 'Libérer de l\'espace de stockage.';

  @override
  String get settingsClearCacheDone => 'Cache carte supprimé';

  @override
  String get settingsLogout => 'Se déconnecter';

  @override
  String get settingsLogoutConfirm => 'Se déconnecter ?';

  @override
  String get settingsCalculating => 'Calcul…';

  @override
  String get healthNone => 'Aucune parcelle';

  @override
  String get healthExcellent => 'Vigoureuse';

  @override
  String get healthGood => 'Bonne santé';

  @override
  String get healthWarning => 'Attention requise';

  @override
  String get healthCritical => 'Situation critique';

  @override
  String get healthAllFine => 'Toutes vos parcelles sont en forme';

  @override
  String healthNeedAttention(int count) {
    return '$count parcelle(s) nécessite(nt) votre attention';
  }

  @override
  String get severityLight => 'Léger';

  @override
  String get severityMedium => 'Moyen';

  @override
  String get severityHigh => 'Grave';

  @override
  String get stageSemis => 'Semis/Plantation';

  @override
  String get stageGermination => 'Levée';

  @override
  String get stageVegetative => 'Croissance';

  @override
  String get stageFlowering => 'Floraison';

  @override
  String get stageFruiting => 'Formation fruits';

  @override
  String get stageMaturation => 'Maturité';

  @override
  String get relativeNow => 'à l\'instant';

  @override
  String relativeMinutes(int count) {
    return 'il y a $count min';
  }

  @override
  String relativeHours(int count) {
    return 'il y a $count h';
  }

  @override
  String relativeDays(int count) {
    return 'il y a $count j';
  }

  @override
  String get recentParcels => 'Parcelles récentes';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get mapLayerStandard => 'Standard';

  @override
  String get mapLayerDark => 'Sombre';

  @override
  String get mapLayerSatellite => 'Satellite';

  @override
  String get mapLayerNdvi => 'Santé (NDVI) 🥬';

  @override
  String get mapLegendStress => 'Stress';

  @override
  String get mapLegendModerate => 'Modéré';

  @override
  String get mapLegendVigorous => 'Vigoureux';

  @override
  String get tooltipListView => 'Vue liste';

  @override
  String get tooltipMapView => 'Vue carte';

  @override
  String get parcelTabSummary => 'Résumé';

  @override
  String get parcelTabDetails => 'Détails';

  @override
  String get parcelTabVisits => 'Visites';

  @override
  String get parcelTabPhotos => 'Photos';

  @override
  String get parcelTabNotes => 'Notes';

  @override
  String get parcelKpiSurface => 'SURFACE';

  @override
  String get parcelKpiYield => 'RENDEMENT';

  @override
  String get parcelActionNavigate => 'Itinéraire';

  @override
  String get parcelActionStop => 'Arrêter';

  @override
  String get parcelActionLocating => 'Recherche GPS...';

  @override
  String get parcelMenuEdit => 'Modifier la parcelle';

  @override
  String get parcelMenuExport => 'Exporter en PDF';

  @override
  String get parcelMenuDelete => 'Supprimer';

  @override
  String get parcelDetailTitle => 'Détails de la parcelle';

  @override
  String get soilSandyLabel => 'Sableux (Dior)';

  @override
  String get soilSandyDesc => 'Drainage rapide, faible rétention d\'eau';

  @override
  String get soilSandyLoamLabel => 'Sablo-limoneux';

  @override
  String get soilSandyLoamDesc => 'Bon compromis drainage / rétention';

  @override
  String get soilLoamLabel => 'Limoneux';

  @override
  String get soilLoamDesc => 'Polyvalent, rétention moyenne';

  @override
  String get soilClayLoamLabel => 'Argilo-limoneux (Deck)';

  @override
  String get soilClayLoamDesc => 'Bonne rétention, risque de tassement';

  @override
  String get soilClayLabel => 'Argileux (Deck-dior)';

  @override
  String get soilClayDesc => 'Rétention forte, drainage lent';

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
  String get genericCancel => 'Annuler';

  @override
  String get genericQuit => 'Quitter';

  @override
  String get genericApply => 'Appliquer';

  @override
  String get genericNext => 'Suivant';

  @override
  String get genericStart => 'Démarrer';

  @override
  String get genericStop => 'Arrêter';

  @override
  String get genericIdentification => 'Identification';

  @override
  String get genericCulture => 'Culture';

  @override
  String get genericRequiredField => 'Ce champ est obligatoire';

  @override
  String get exportTitle => 'Exporter les données';

  @override
  String get exportPdf => 'Exporter en PDF (Rapport Pro)';

  @override
  String get exportExcel => 'Exporter en Excel (Tableau)';

  @override
  String exportSuccess(String file) {
    return 'Export réussi : $file';
  }

  @override
  String get exportError => 'Échec de l\'export';

  @override
  String get exportShare => 'Partager';

  @override
  String get exportGenerating => 'Génération du fichier...';

  @override
  String get reportHeaderParcel => 'Parcelle';

  @override
  String get reportHeaderOwner => 'Propriétaire';

  @override
  String get reportHeaderVillage => 'Village';

  @override
  String get reportHeaderCrop => 'Culture';

  @override
  String get reportHeaderSurface => 'Surface (Ha)';

  @override
  String get reportHeaderDate => 'Date de visite';

  @override
  String get reportHeaderDiagnosis => 'Diagnostic / Observation';

  @override
  String get reportHeaderAction => 'Recommandations ISRA/ANCAR';

  @override
  String get reportFooterNotice =>
      'Document généré par Petalia Field Pro — Règles v3 consolidées (ISRA, ANCAR, CSP).';

  @override
  String get authLoginTagline => 'Votre compagnon agronomique intelligent';

  @override
  String get authPhoneLabel => 'Numéro de téléphone';

  @override
  String get authPhoneHint => '7X XXX XX XX';

  @override
  String get authPinLabel => 'Code secret (4 chiffres)';

  @override
  String get authErrorInvalidPhone => 'Numéro de téléphone invalide';

  @override
  String get authErrorInvalidCredentials => 'Identifiants incorrects';

  @override
  String get authNoAccount => 'Pas encore de compte ? ';

  @override
  String get authRegisterCta => 'S\'inscrire';

  @override
  String get authRegisterTitle => 'Inscription (1/3)';

  @override
  String get authRegisterHeader => 'Vos informations';

  @override
  String get authRegisterSubHeader =>
      'Identifiez-vous pour sécuriser l\'accès à vos parcelles.';

  @override
  String get authNameLabel => 'Nom complet';

  @override
  String get authNameHint => 'Ex: Samba Diop';

  @override
  String get authErrorNameTooShort => 'Nom trop court';

  @override
  String get authErrorInvalidNumber => 'Numéro invalide';

  @override
  String get authOtpTitle => 'Vérification (2/3)';

  @override
  String get authOtpHeader => 'Vérifiez votre numéro';

  @override
  String get authOtpSubHeader => 'Un code à 6 chiffres a été envoyé au';

  @override
  String get authErrorInvalidOtp =>
      'Code incorrect (Utilisez 123456 pour le test)';

  @override
  String get authPinTitle => 'Sécurisation (3/3)';

  @override
  String get authPinHeader => 'Code Secret';

  @override
  String get authPinSubHeader =>
      'Définissez un code à 4 chiffres pour accéder à votre compte.';

  @override
  String get authPinFinalCta => 'Finaliser l\'inscription';

  @override
  String get authRegisterSuccess => 'Compte créé avec succès !';
}
