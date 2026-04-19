# Petalia Field Pro — Audit terrain & Plan d'implémentation 100 %

**Date :** 2026-04-18
**Périmètre :** Application Flutter destinée aux techniciens agronomes en zone rurale (Thiès, Sénégal).
**Objectif de ce document :** (1) Auditer l'écart entre le besoin terrain réel et l'application telle qu'elle est codée. (2) Définir un plan d'implémentation step-by-step pour couvrir 100 % de l'audit.

---

## PARTIE I — AUDIT TERRAIN vs APPLICATION

### 1. Profil utilisateur et contexte terrain

| Dimension | Réalité terrain | Impact app |
|---|---|---|
| Utilisateur principal | Technicien agronome (ANCAR, ISRA, ONG, coopératives privées) visitant 5–15 parcelles/jour | Besoin de rapidité : < 2 min par observation, main-libre autant que possible |
| Utilisateur secondaire | Agriculteur (souvent >45 ans, alphabétisation numérique faible, FR oral, wolof courant, lit mal) | UI : icônes explicites, voix, peu de texte, jargon zéro |
| Cultures dominantes (bassin arachidier / Niayes) | Arachide, mil, sorgho, niébé, maïs, riz irrigué (vallée), maraîchage (tomate, oignon, chou, gombo, piment), mangue, anacarde | Référentiel cultures actuel insuffisant (voir §3.4) |
| Saisonnalité | Hivernage juin–octobre (pluies), contre-saison novembre–mai (maraîchage + irrigation) | Recommandations doivent être saisonnelles — aujourd'hui elles ne le sont pas |
| Contraintes physiques | Soleil intense, poussière, gants, écran bouilli, batterie faible, 4G 2–3 barres puis coupée | Offline-first (bien couvert), contraste (partiel), gestes larges (à renforcer) |
| Connectivité | ~60 % des villages ciblés sans 3G stable ; seules les villes (Thiès, Mbour) ont une couverture fiable | Pas d'API cloud — aucun sync réel aujourd'hui (voir §4.1) |
| Langue | Wolof 80 %, français 20 % en usage réel ; lecture FR aléatoire | Localisation **non fonctionnelle** malgré l'infrastructure (voir §3.12) |
| Maladies/ravageurs fréquents | Cercosporiose arachide, rosette (virus), striga (mil/sorgho), chenilles légionnaires (maïs), mildiou tomate, thrips oignon, mouche blanche, acariens | Dictionnaire IA ne couvre pas ces cas (voir §3.6) |

### 2. Synthèse : l'app répond à quel pourcentage du besoin ?

**Estimation globale : ~65 % du besoin terrain couvert en l'état (après implémentation).**

| Dimension besoin | Couverture | Commentaire |
|---|---|---|
| Cartographier les parcelles | 85 % | Très bon (GPS walk + tap draw, FMTC, surface auto) |
| Documenter une visite | 75 % | ✅ Écran riche, 17 symptômes, BBCH stages |
| Obtenir un diagnostic utile | 60 % | ✅ Moteur 15 règles culture-spécifiques, no urée légumineuses |
| Planifier sa tournée | 45 % | Nearest-neighbor + tours tracking prep (OSRM offline pending) |
| Produire un compte-rendu | 65 % | PDF + signature + recommandations (photos pending) |
| Travailler sans réseau | 75 % | Excellente base offline (sync réelle pending backend) |
| Être utilisable par un agriculteur lambda | 30 % | ✅ ARB FR/EN ready, thème terrain (wolof pending) |
| Alertes & rappels actionables | 60 % | ✅ AlertEngine avec regles visite/stade/sécheresse |
| Historique / capitalisation | 40 % | Checklist persistante (comparateur photo pending) |
| Sécurité des données | 30 % | Hive(boxChecklists added), chiffr. pending |

### 3. Audit détaillé par feature

#### 3.1 Authentification (`lib/features/auth/`)
**Implémenté :** PIN 4 chiffres + biométrie, inscription, session Hive, shake sur erreur, haptique.
**Écarts :** PIN en clair dans Hive (`auth_repository.dart:18-20`), pas de récupération OTP SMS, pas de multi-utilisateur, pas de workflow remplacement agent.
**Priorité :** P1 chiffrement PIN, P2 récupération, P3 multi-profils.

#### 3.2 Dashboard
**Implémenté :** Greeting, météo Open-Meteo (cache 6 h box_weather, fallback offline), santé moyenne, alertes non lues, 3 parcelles récentes, graphique `fl_chart` 7 jours.
✅ **MISE À JOUR:** `WeatherService` (Open-Meteo) remplace `FakeData.weatherToday()` — snapshot temp/humidité/vent/condition géolocalisé, âge affiché si > 1 h.
✅ **MISE À JOUR:** `_HealthChart` (fl_chart) sur dashboard depuis observations Hive, fallback santé parcelles.
**Écarts :** Pas de pluviométrie cumulée 7 j, pas d'ETP Penman-Monteith, KPI santé 0..1 pas encore traduit en message humain, to-do du jour limité aux alertes non lues.
**Priorité :** P1 pluviométrie + ETP, P1 to-do prioritaire hors alertes.

#### 3.3 Carte
**Implémenté :** flutter_map, OSM + Satellite, polygones colorés, markers, GPS, FMTC auto-cache 2 km z10-17.
**Écarts :** Zoom max 17 (z18 utile Niayes), licence ArcGIS risquée, pas de NDVI, pas de clustering, pas de traces GPS passées, dessin sans preview polygone, pas de POI éditables (puits, forage).
**Priorité :** P0 NDVI, P1 clustering, P1 POI, P2 historique visites.

#### 3.4 Parcelles
**Implémenté :** CRUD, GPS walk + tap, catalogue cultures enrichi + variétés, date de semis, région, type de sol, culture précédente, surface shoelace.
✅ **MISE À JOUR:** `CropsCatalog` (arachide, mil, sorgho, niébé, maïs, riz, tomate, oignon, chou, piment, pastèque, gombo, manioc, mangue, anacarde, moringa…) + variétés + `BbchCatalog`.
✅ **MISE À JOUR:** Sol (`SoilTypes` Dior / Deck / argilo-limoneux / sablo-limoneux / limoneux / silt) + culture précédente (catalogue + Jachère + Aucune) sur Parcel domain + formulaire + carte "Contexte agronomique" Vue d'ensemble.
**Écarts :** GPS walk sans HDOP, pas de snap, pas de parcellaire hiérarchique (exploitation).
**Priorité :** P1 précision GPS (HDOP), P2 hiérarchie exploitations.

#### 3.5 Observation — écran critique
**Implémenté :** 1692+ lignes, photos, santé 3 boutons, 17 symptômes, mesures terrain, audio AAC, sévérité, BBCH stages.
✅ **MISE À JOUR:** Symptômes élargis à 17 spécifiques (cercosporiose, rosette, striga, etc.) avec pests_diseases.dart catalog
✅ **MISE À JOUR:** BBCH stages par culture avec _genericStages fallback
**Écarts :** Pas de catalogue photo interactif, pas d'IA vision, pas de géotag EXIF, pas de comparateur avant/après.
**Priorité :** P1 géotag, P1 comparateur, P2 IA photo.

#### 3.6 Recommandations / IA — point le plus faible
**Implémenté :** ✅ Moteur 15 règles culture-spécifiques (ai_recommender.dart) + pests_diseases.dart
✅ **MISE À JOUR:** Plus d'urée sur légumineuses! Règles pour arachide, niebe, mil, mais, riz, tomate
**Écarts :** Pas de dose géolocalisée, pas de coût FCfa, pas encore 200+ règles (15 implémentées).
**Priorité :** P1 règles additionnelles, P2 coûts.

#### 3.7 Checklist
**Implémenté :** ✅ ChecklistTemplate domain (checklist_template.dart) avec persistance Hive
✅ **MISE À JOUR:** Templates par culture (arachide, niebe, mil, mais, riz, tomate, oignon) + GlobalGAP
**Écarts :** Pas liée à observation (still in progress).
**Priorité :** P0 persister liée.

#### 3.8 Rapports PDF
**Implémenté :** PDF A4, share_plus, signature technician.
**Écarts :** Pas de photos dans PDF, pas de signature agriculteur, pas d'en-tête org.
**Priorité :** P0 photos + signature agriculteur.

#### 3.9 Alertes
**Implémenté :** ✅ AlertEngine (alert_engine.dart) avec regles: visite overdue, stade critique, stress hydrique
✅ **MISE À JOUR:** AlertEngine génère alertes depuis données Parcels et Observations
**Écarts :** Pas de push notifications locales.
**Priorité :** P1 notifications locales.

#### 3.10 Planificateur tournée
**Implémenté :** Nearest-neighbor euclidien, polyline.
**Écarts :** Distance vol d'oiseau ≠ routière, pas de temps estimé, pas de créneau, pas de sauvegarde tournée, pas de partage superviseur, pas de tracking.
**Priorité :** P1 OSRM + temps, P1 sauvegarde, P2 tracking.

#### 3.11 Settings
**Implémenté :** Thème, langue (stockée non traduite), grand texte (toggle factice), contraste terrain (toggle factice), fréquence sync, cache stats.
**Écarts :** `highContrast` et `largeText` non appliqués, pas d'UI téléchargement région, pas d'export/import, pas de diagnostic réseau, pas d'infos support.
**Priorité :** P1 brancher thèmes, P1 UI région, P2 export.

#### 3.12 Localisation FR/EN/WO — feature fantôme
**Constat grave :** Aucun `.arb` n'existe. Tous textes FR hardcodés dans widgets. Changer la langue = aucun effet.
**Priorité :** P0 extraction .arb + traduction wolof validée (IFAN/CLAD UCAD), P1 EN bailleurs.

#### 3.13 Onboarding
**Implémenté :** 4 slides, dots, skip, flag persistence.
**Écarts :** Textuel uniquement, pas de vidéo/GIF, pas de parcelle démo, pas de tutoriel guidé.
**Priorité :** P1 parcelle démo, P2 vidéos.

### 4. Services transversaux

#### 4.1 Synchronisation — constat critique
`flush()` = `Future.delayed(150ms)` puis vide la queue. **Aucun endpoint API.** L'app collecte parfaitement mais n'envoie rien nulle part.
Manques : backend, compression photos, priorisation, résolution conflits, retry exponentiel.
**Priorité :** P0 absolu — sans backend, l'app n'existe pas.

#### 4.2 Cache tuiles
**Constat :** FMTC bien intégré, ObjectBox, cacheFirst, TTL 30j. Meilleure partie technique.
Manques : UI sélection région, limite taille auto, purge LRU.
**Priorité :** P1 UI région + limites.

#### 4.3 Sécurité
Hive non chiffré, pas d'auto-lock, pas d'effacement distant, pas de consentement RGPD-like.
**Priorité :** P1 chiffrement, P2 auto-lock.

### 5. Verdict global

MVP technique excellent, produit agronomique immature. Couverture ~45 % du besoin terrain. Les 3 P0 (backend + référentiel agro + wolof) doubleraient cette couverture.

**Dangereux en l'état :** terme "IA" trompeur, "Sync" qui ne synchronise rien, multilingue annoncé mais fantôme.

---

## PARTIE II — PLAN D'IMPLÉMENTATION 100 %

> **Objectif :** Passer de **~45 % à 100 % de couverture** en 6 sprints de 2 semaines (~12 semaines / 3 mois calendaires). Chaque sprint livre une valeur testable terrain.
> **Équipe :** 1 dev mobile Flutter (plein temps), 1 dev back (mi-temps), 1 agronome ISRA/ANCAR (consultant), 1 linguiste wolof (ponctuel), 1 UX testeur (ponctuel).

### 6. Vue d'ensemble des sprints

| Sprint | Focus | Livrable testable | Couverture cumulée |
|---|---|---|---|
| **S1** | Backend + sync réelle | Données remontent vers serveur | 55 % |
| **S2** | Référentiel agro + cultures enrichies | Recos crédibles sur 12 cultures | 70 % |
| **S3** | Diagnostic terrain (taxonomie + catalogue + BBCH) | Diagnostic utilisable par technicien junior | 80 % |
| **S4** | UX agriculteur (wolof + simplification + météo) | Utilisable par agriculteur seul | 88 % |
| **S5** | Alertes + PDF pro + sécurité | Production-ready pour pilote | 95 % |
| **S6** | Différenciateurs (NDVI + IA photo + OSRM) | Avantage concurrentiel | 100 % |

---

### 7. SPRINT 1 — Fondations backend & synchronisation

**But :** L'app cesse d'être une démo locale. Les données atteignent un serveur et reviennent sur d'autres appareils.
**Couvre audit :** §4.1 (sync réelle), §4.3 (sécurité), §3.1 (auth PIN).

#### 7.1 — Setup backend Supabase (3 j-h dev back)
1. Provisionner une instance Supabase self-hosted sur un VPS Dakar (OVH, Scaleway ou Orange Cloud SN) — souveraineté des données
2. Activer extension **PostGIS** (géométries parcelles)
3. Créer les tables : `users`, `organizations`, `parcels` (geometry polygon), `observations`, `reports`, `alerts`, `media_files`, `sync_log`
4. Politiques **RLS** (Row-Level Security) : un technicien ne voit que les parcelles de son organisation
5. Seed data : 1 organisation démo, 3 techniciens, 20 parcelles Thiès
6. Déployer **Storage bucket** pour photos/audio/PDF

**Validation :** `curl` POST observation → retour 201 + JOIN visible dans dashboard Supabase.

#### 7.2 — Auth réelle (2 j-h dev mobile)
1. Remplacer `auth_repository.dart` local par appel Supabase Auth (téléphone + OTP SMS)
2. Intégrer gateway SMS Orange Sénégal (ou Twilio fallback) pour OTP 6 chiffres
3. Conserver PIN 4 chiffres en **cache local post-login** via `flutter_secure_storage` (Keystore Android / Keychain iOS)
4. Migration : utilisateurs existants → écran "Confirmer votre numéro" au premier relancement
5. **Corriger** `auth_repository.dart:18-20` : hash PIN avec bcrypt avant stockage

**Validation :** Login OTP SMS → token JWT Supabase stocké → relogin hors ligne avec PIN OK.

#### 7.3 — SyncService réel avec backoff (3 j-h)
1. Remplacer `Future.delayed(150ms)` de `flush()` par vrai POST Supabase
2. Actions typées : `{op, entity, id, data, at, retries, status, version}`
3. Retry backoff exponentiel : 2 s, 8 s, 30 s, puis `status: failed` + badge UI
4. Sync différentielle : `lastSyncTimestamp` par entité, ne renvoyer que le delta
5. Résolution conflits **last-write-wins** (timestamp serveur fait foi)
6. **Priorisation queue** : observations avant PDF, photos en file séparée

**Validation :** Mode avion → créer 3 observations → rallumer → les 3 remontent avec progression visible.

#### 7.4 — Stockage sécurisé médias (2 j-h)
1. Créer `MediaStorageService` : copie photos/audio dans `getApplicationDocumentsDirectory()` avec UUID
2. **Compression image** avant sauvegarde : qualité 80 %, max 1920 px (`flutter_image_compress`)
3. Upload vers Supabase Storage via sync séparée (résumable upload, reprise automatique)
4. Nettoyage fichiers orphelins au démarrage

**Validation :** 10 photos 4 MB prises → 10 fichiers ~400 KB en local → upload progressif visible.

#### 7.5 — Chiffrement Hive (0.5 j-h)
1. Activer `Hive.openBox(name, encryptionCipher: HiveAesCipher(key))`
2. Clé stockée dans `flutter_secure_storage` (générée au premier lancement)
3. Migration boxes existantes : lire en clair → écrire chiffré → supprimer ancien box

**Validation :** Extraction ADB du box Hive → contenu illisible.

**🎯 Livrable S1 :** App installée sur 3 téléphones → toutes les données convergent vers Supabase → consultables depuis un dashboard web minimal.

---

### 8. SPRINT 2 — Référentiel agronomique & cultures

**But :** Les recommandations deviennent crédibles aux yeux d'un agronome ISRA.
**Couvre audit :** §3.4 (cultures + variétés + semis), §3.6 (moteur de règles), stades BBCH.

#### 8.1 — Enrichir le référentiel cultures (1 j-h)
1. Ajouter dans `lib/core/constants/crops.dart` : **sorgho, niébé, pastèque, gombo, chou, piment, patate douce, manioc, mangue, anacarde, banane, canne à sucre, moringa, haricot vert, aubergine, carotte, laitue, pomme de terre**
2. Pour chaque culture : icône, couleur, saison (hivernage/contre-saison/permanent), durée de cycle (jours)
3. Ajouter champ **variété** dans `Parcel` (ex: arachide → 73-33, GC-8-35, Fleur 11, 55-437)
4. Ajouter champ **date de semis** obligatoire à la création de parcelle
5. Migration parcelles existantes : date de semis = date de création (modifiable)

**Validation :** Créer parcelle "Arachide 73-33 semée le 15/06/2026" → `Parcel.semisDate` non null.

#### 8.2 — Stades phénologiques BBCH par culture (2 j-h)
1. Créer `lib/core/data/bbch_stages.json` : pour chaque culture, liste des stades BBCH avec code, libellé FR + WO, jours après semis (fourchette), photo de référence
2. Calcul **automatique du stade** à partir de `DateTime.now() - parcel.semisDate`
3. Remplacer le `growthStage` libre par un **dropdown filtré par culture**

**Validation :** Parcelle arachide, 45 jours après semis → proposition "R1 Floraison (40–50 jaS)".

#### 8.3 — Moteur de règles agronomiques (5 j-h dev + 20 j-h agronome)
1. Définir le schéma JSON dans `lib/core/data/agro_rules.json` :
   ```json
   {
     "id": "ARA-R1-YELLOW-SAHEL-RAINY",
     "crop": "arachide",
     "stage": ["R1", "R3"],
     "symptom": "yellow_leaves",
     "season": "hivernage",
     "region": ["thies", "fatick", "kaolack"],
     "severity_min": 0.3,
     "diagnosis": "Carence en azote de démarrage (rare sur légumineuse)",
     "recommendation": {
       "title": "Inoculation + démarrage léger",
       "actions": [
         "Vérifier nodulation (arracher 1 plante, couper nodule = rose OK)",
         "Si pas de nodulation : NPK 15-15-15 à 50 kg/ha en démarrage"
       ],
       "cost_fcfa_per_ha": 15000,
       "delay_before_harvest_days": 0,
       "ppe_required": false,
       "followup_days": 7
     },
     "validated_by": "ISRA-CNRA-Bambey-2024"
   }
   ```
2. Remplir **200+ règles** avec l'agronome consultant (10 cultures × 4 stades × 5 symptômes)
3. Refondre `ai_recommender.dart` : moteur de filtrage multi-critères (culture AND stade AND symptôme AND saison AND région)
4. Fallback si 0 match : "Consulter un agronome — cas non catalogué"
5. Câbler le bouton "Changer la date" de prochaine visite (actuellement vide)

**Validation :** Observation "arachide R1, jaunissement, hivernage, Thiès" → reco ciblée, pas de l'urée générique.

#### 8.4 — Géolocalisation des règles (1 j-h)
1. Ajouter `region` dans `Parcel` (auto-détecté via commune la plus proche, modifiable)
2. Filtrer les règles par région : Thiès ≠ Fouta ≠ Casamance
3. Référentiel communes Sénégal embarqué (data INS)

**Validation :** Même symptôme Thiès vs Ziguinchor → 2 recos différentes.

#### 8.5 — Fallback "Demander à un expert" (2 j-h)
1. Bouton sur chaque écran de reco : "Ce n'est pas mon cas → demander à un agronome"
2. Formulaire : photo(s) + contexte libre + envoi async via Supabase (table `expert_requests`)
3. Notification quand un expert répond (via sync)

**Validation :** Envoyer question → visible dans dashboard Supabase "Pending expert requests".

**🎯 Livrable S2 :** Un agronome ISRA test 20 observations → valide au moins 85 % des recommandations.

---

### 9. SPRINT 3 — Diagnostic terrain & observation pro

**But :** Un technicien junior peut identifier une maladie grâce à l'app.
**Couvre audit :** §3.5 (taxonomie + catalogue + accordéon + géotag + comparateur), §3.4 (précision GPS).

#### 9.1 — Taxonomie locale ravageurs/maladies (5 j-h + 10 j-h agronome)
1. Créer `lib/core/data/pests_diseases.json` : **30+ entrées** couvrant Sénégal :
   - Arachide : cercosporiose précoce/tardive, rosette, mottle virus, aphides
   - Mil/sorgho : striga, chenille mineuse, mildiou, ergot
   - Maïs : chenille légionnaire d'automne, helminthosporiose
   - Riz : pyriculariose, RYMV, foreur de tige
   - Tomate : mildiou, TYLCV, mouche blanche, nématode, acariens, BER
   - Oignon : thrips, mildiou, pourriture blanche
   - Maraîchage : jassides, pucerons, chenilles Spodoptera
2. Chaque entrée : nom FR + WO + nom scientifique + 3 photos de référence + symptômes textuels + cultures affectées
3. Assets photos (~90 photos) placés dans `assets/diagnosis/`

#### 9.2 — Catalogue photo interactif (3 j-h)
1. Nouvel écran `lib/features/diagnosis/presentation/catalog_screen.dart`
2. Filtres : culture + partie plante (feuille/tige/racine/fruit) + couleur dominante
3. Grille photos avec zoom + description + bouton "C'est ça dans mon cas"
4. Intégration dans `observation_screen.dart` : bouton "Je ne sais pas ce que c'est → catalogue"
5. Sélection dans le catalogue → pré-remplit `observation.symptom` avec la bonne taxonomie

**Validation :** Technicien junior identifie la cercosporiose sur photo exemple en < 30 s.

#### 9.3 — Refonte écran observation (3 j-h)
1. **Accordéons fermés par défaut** :
   - Niveau 1 (toujours visible) : Photos + "Comment va la culture ?" 3 boutons colorés
   - Niveau 2 (accordéon "Que voyez-vous ?") : catalogue photo + symptômes cards illustrées
   - Niveau 3 (accordéon "Mesures détaillées") : les 7 mesures terrain actuelles
2. **Validation minimum** : au moins 1 photo OU 1 note vocale requise
3. **Santé rapide** : remplacer slider 0..1 par 3 gros boutons avec emoji + couleur + wolof
4. Symptômes : remplacer chips par cards illustrées 120×120 px

**Validation :** Temps moyen observation simple : **< 90 s** (mesuré sur 10 tests).

#### 9.4 — Géotag EXIF photos (0.5 j-h)
1. Injecter GPS dans EXIF au moment de `ImagePicker.pickImage`
2. Utilitaire `lib/core/utils/exif_writer.dart` (package `native_exif`)
3. Lecture EXIF dans rapports PDF pour afficher "Photo prise à [coords]"

**Validation :** Photo → `exiftool` affiche GPSLatitude/GPSLongitude corrects.

#### 9.5 — Comparateur photo avant/après (2 j-h)
1. Dans `parcel_details_screen.dart` onglet "Photos", ajouter mode "Comparer"
2. Sélection de 2 observations de la même parcelle → vue côte à côte (slider horizontal)
3. Date + stade affiché sous chaque photo

**Validation :** 2 observations d'une parcelle à 15 j d'écart → comparaison visuelle fluide.

#### 9.6 — Précision GPS au walk (1 j-h)
1. Afficher HDOP en temps réel pendant GPS walk ("Précision : ±5 m" en vert, ±20 m en rouge)
2. Bloquer la sauvegarde si < 3 points OU HDOP > 15 m (avec override manuel + warning)
3. Signal sonore à chaque point capturé

**Validation :** Marcher une parcelle carrée de 50 m → surface calculée à ±10 % de la vérité terrain.

**🎯 Livrable S3 :** 5 techniciens juniors testent sur 15 parcelles → taux de diagnostic correct > 80 % (vs ~30 % avant).

---

### 10. SPRINT 4 — UX agriculteur & langue wolof

**But :** Un agriculteur wolophone de 50 ans peut ouvrir l'app et l'utiliser seul.
**Couvre audit :** §3.12 (wolof), §3.2 (météo + to-do), §3.13 (onboarding), §3.11 (thème contraste/grand texte).

#### 10.1 — Extraction strings en .arb (2 j-h)
1. Créer `lib/l10n/app_fr.arb`, `app_en.arb`, `app_wo.arb`
2. Extraire **tous les littéraux** français des widgets vers clés .arb
3. Générer `AppLocalizations` via `flutter gen-l10n`
4. Remplacer `Text('Observation')` → `Text(AppLocalizations.of(context)!.observation)`
5. Brancher au provider `language` des settings

**Validation :** Switch langue dans Settings → tous textes changent.

#### 10.2 — Traduction wolof validée (linguiste IFAN/CLAD, ~3 j-h)
1. Mission confiée au CLAD UCAD (Pr. Sall ou équivalent) : traduction des ~400 clés
2. Validation sur terrain : 5 agriculteurs valident la compréhension de 20 messages clés
3. Orthographe : respecter décret 2005-980 (orthographe officielle wolof Sénégal)

**Validation :** Test terrain : 5 agriculteurs / 5 comprennent les 20 messages de base.

#### 10.3 — Traduction EN (0.5 j-h)
1. Traduction DeepL + relecture rapide — usage bailleurs (USAID, FIDA, AfDB)

#### 10.4 — Vraie météo + pluviométrie (3 j-h)
1. Intégration API **OpenWeatherMap** (plan gratuit 1000 appels/j) OU **ANACIM** (Météo Sénégal — contact partenariat)
2. Cache 6 h dans Hive (`box_weather`)
3. Dashboard : T°, humidité, vent, pluie prévue 48 h, pluviométrie cumulée 7 j
4. ETP calculé via formule Penman-Monteith simplifiée (input local : T° + humidité + vent)
5. Si offline : afficher dernière valeur connue avec âge ("il y a 3 h")

**Validation :** Comparer avec ANACIM le même jour → ±2 °C / ±5 mm.

#### 10.5 — Dashboard "Aujourd'hui" (2 j-h)
1. Remplacer KPI santé 0..1 par message humain : "3 parcelles à visiter", "1 alerte urgente", "Pluie dans 6 h"
2. Liste des 3 actions prioritaires du jour (extraits du moteur d'alertes)
3. FAB principal "Nouvelle visite" toujours visible
4. Graphique `fl_chart` santé 7 jours : barres vertes/jaunes/rouges

**Validation :** Agriculteur ouvre l'app → comprend en < 10 s ce qu'il doit faire.

#### 10.6 — Simplification vocabulaire (1 j-h)
1. Remplacer dans les .arb :
   - "Stade phénologique" → "Où en est la culture ?"
   - "Sévérité" → "C'est grave ?"
   - "Synchronisation" → "Envoi des données"
   - "Observation" → "Visite"
2. Ajouter descriptions courtes sous chaque champ
3. Messages d'erreur humains : "Pas de réseau ? Pas de souci, tout est gardé sur le téléphone"

#### 10.7 — Onboarding enrichi (2 j-h)
1. 4 slides avec **GIF animés** (15 s chacun) illustrant : marcher une parcelle, prendre une photo, voir un conseil, partager un PDF
2. Écran final : "Essayer avec une parcelle de démo" → seed 1 parcelle + 2 observations fake
3. Tooltips contextuels au 1er usage de chaque écran clé (`showcaseview` package)

**Validation :** 5 agriculteurs jamais vu l'app → complètent 1 observation sans aide en < 5 min.

#### 10.8 — Mode terrain (contraste + grand texte) réellement appliqué (0.5 j-h)
1. Corriger `app_theme.dart` : lire `highContrast` et `largeText` depuis settings et appliquer :
   - `highContrast: true` → fond blanc pur, texte noir, couleurs saturées (primary #007A1F)
   - `largeText: true` → `textScaler: TextScaler.linear(1.25)` sur tout le MaterialApp
2. Bouton "Mode terrain" dans le FAB de settings pour toggle rapide

**Validation :** Test sous plein soleil (12 h, Thiès) → lisibilité OK vs mode normal flou.

**🎯 Livrable S4 :** Test usabilité 5 agriculteurs wolophones (>45 ans) → tous complètent "ajouter parcelle + observer + voir conseil" sans aide.

---

### 11. SPRINT 5 — Alertes, PDF pro & production-ready

**But :** L'app est déployable en pilote pour une coopérative de 200 agriculteurs.
**Couvre audit :** §3.9 (alertes), §3.8 (PDF + historique + agrégé), §3.7 (checklist persistante), §4.2 (UI cache région), §3.11 (settings complets).

#### 11.1 — Moteur d'alertes local (5 j-h)
1. Créer `lib/core/services/alert_engine.dart` — tourne à chaque démarrage + toutes les 2 h (background)
2. **Règles :**
   - **Météo** : pluie prévue > 20 mm dans 48 h → "Ne pas traiter / reporter l'épandage"
   - **Stade critique** : floraison/remplissage proche + pas de visite depuis 7 j → alerte visite
   - **Irrigation** : humidité sol dernière obs "dry" + pas de pluie + 3 j passés → alerte irrigation
   - **Pression ravageur** : même symptôme détecté sur 2+ parcelles du même village en 7 j → alerte foyer local
   - **Seuil BBCH** : calcul `DAS` (jours après semis) + seuils par culture → alerte "Tallage max dépassé" etc.
3. Génération `Alert` objects stockés dans box `boxAlerts`

#### 11.2 — Notifications locales (1 j-h)
1. Intégrer `flutter_local_notifications`
2. À chaque nouvelle alerte de sévérité high → notification push locale (fonctionne offline)
3. Canal Android "Alertes urgentes" (vibration + son)

**Validation :** Simuler pluie 48 h via fake → notification reçue sur téléphone éteint.

#### 11.3 — PDF rapport pro (2 j-h)
1. Inclure **photos** de la visite dans le PDF (thumbnails 300×300, 2 par ligne)
2. Ajouter page **signature manuscrite** (canvas Flutter `signature` package) — technicien ET agriculteur
3. En-tête organisation paramétrable dans settings (logo coopérative + nom projet + bailleur)
4. Pied de page : coordonnées GPS de la parcelle + timestamp
5. Section "Recommandations" remplie depuis le moteur de règles (pas vide)
6. Traduction PDF selon langue active (FR/EN/WO)

**Validation :** PDF généré contient 4 photos + 2 signatures + reco détaillée + logo coop.

#### 11.4 — Historique rapports + agrégé tournée (3 j-h)
1. Nouveau `ReportRepository` + box `boxReports` persistant
2. Écran "Mes rapports" : liste chronologique, recherche par parcelle/culture/date
3. **Rapport agrégé de tournée** : sélection 2+ parcelles → 1 PDF consolidé avec sommaire
4. **Rapport par village / coopérative** : agrégation depuis les données remontées Supabase (mensuel)

#### 11.5 — Settings production-ready (2 j-h)
1. Section **Cartes hors ligne** complète : sélection zone rectangle sur carte + estimation taille + download avec progression + purge LRU + limites
2. Section **Sauvegarde** : export ZIP chiffré + import + auto-backup 24 h
3. Section **Diagnostic** : bouton "Tester la connexion" (ping Supabase + mesure latence)
4. Section **Support** : WhatsApp helpdesk + version app + ID utilisateur (pour debug)

#### 11.6 — Checklist contextuelle persistante (2 j-h)
1. Créer `ChecklistTemplate` par culture + phase (ex: "Récolte arachide", "Semis maïs")
2. Persistance dans `box_checklists` + lien `observation_id`
3. Items cochés remontent dans le PDF

**Validation :** Checklist "Récolte arachide" → 8 items spécifiques → survie au reboot.

#### 11.7 — Clustering carte (1 j-h)
1. Package `flutter_map_marker_cluster` (compatible flutter_map 7.x)
2. Active automatiquement si > 30 parcelles visibles

**🎯 Livrable S5 :** Coopérative test (30 agriculteurs, 3 techniciens, 150 parcelles) → 2 semaines d'usage sans incident bloquant.

---

### 12. SPRINT 6 — Différenciateurs & innovations

**But :** Atteindre 100 % de couverture avec les features avancées.
**Couvre audit :** §3.3 (NDVI), §3.5 (IA photo + transcription), §3.10 (OSRM + tracking), §3.3 (POI terrain), §3.4 (parcellaire hiérarchique).

#### 12.1 — Couche NDVI Sentinel-2 (4 j-h)
1. Option A : tileserver interne (nginx + GDAL) servant des tuiles NDVI pré-calculées Sentinel-2
2. Option B : SaaS SentinelHub (plan gratuit 30 k requêtes/mois)
3. Ajouter un layer "NDVI" dans le switcher de `map_screen.dart`
4. Légende couleur (rouge stress → vert vigoureux) + date de la scène affichée
5. Pré-cache NDVI par parcelle (mise à jour tous les 5 j)

**Validation :** Parcelle en stress hydrique → NDVI rouge visible.

#### 12.2 — IA photo diagnostic (10 j-h dev + 5 j-h data)
1. Collecter **500 photos étiquetées** Sénégal (partenariat ISRA / photos techniciens anonymisés)
2. Fine-tuner **MobileNetV3** sur dataset PlantVillage + 500 photos locales (10 classes principales)
3. Convertir en **TensorFlow Lite** (~5 MB, embarqué dans l'app)
4. Intégrer `tflite_flutter` → inférence locale < 500 ms
5. Écran : photo → top-3 classes avec confiance → valider / corriger
6. Feedback loop : les corrections utilisateur remontent à Supabase pour futur ré-entraînement

**Validation :** 50 photos test → top-3 contient la bonne réponse dans > 75 % des cas.

#### 12.3 — OSRM offline pour planificateur (5 j-h)
1. Extraire `.osm.pbf` Sénégal (region-osm.com) → générer graphe OSRM `.osrm`
2. Embarquer un mini-OSRM dans l'app via FFI (dart_osrm wrapper) OU service local Docker (pilote)
3. Remplacer nearest-neighbor euclidien par **routing réel** : distances et temps estimés
4. Affichage : "Tournée optimisée : 35 km, 2 h 15 de route, 8 parcelles"
5. Sauvegarde tournée dans `boxTours` + partage PDF vers superviseur

**Validation :** Tournée 8 parcelles → temps estimé à ±15 % du temps réel.

#### 12.4 — Transcription audio offline (5 j-h)
1. Intégrer **whisper.cpp** (modèle tiny ~40 MB, FR + WO rudimentaire)
2. `AudioService.transcribe()` → texte inséré dans `observation.note` + marqué "auto-transcrit"
3. Inclusion dans le PDF : "Note vocale transcrite : [...]"

**Validation :** 10 notes vocales FR → transcription > 80 % correcte.

#### 12.5 — POI terrain éditables (2 j-h)
1. Nouvelle entité `FieldPOI` : puits, forage, magasin intrants, case du chef, pompe
2. Long-press sur la carte → "Ajouter un repère" → type + photo + note
3. Affichage markers personnalisés

#### 12.6 — Parcellaire hiérarchique (3 j-h)
1. Nouvelle entité `Farm` (exploitation) : regroupe N parcelles + 1 agriculteur ou coopérative
2. Migration : chaque `Parcel` existante → créer une `Farm` par propriétaire
3. Écran "Mes exploitations" → liste → drill-down parcelles

#### 12.7 — Tracking tournée + partage superviseur (2 j-h)
1. Enregistrement trace GPS pendant la journée (points toutes les 30 s, background)
2. Affichage tracé sur carte en fin de journée
3. Export PDF "Rapport de tournée du [date]" avec trace + parcelles visitées + kilométrage + temps

#### 12.8 — Polish final (2 j-h)
1. Résolution de tous les TODO et `onPressed: () {}` restants
2. Supprimer toutes mentions "fake_api" dans UI
3. Audit accessibilité TalkBack/VoiceOver
4. Crashlytics (Sentry self-hosted ou Firebase)
5. Analytics événements clés (PostHog self-hosted, anonymisé)

**🎯 Livrable S6 :** App complète, tous les items de l'audit couverts. Version 1.0.0 prête pour déploiement pilote officiel.

---

### 13. Récapitulatif effort par rôle

| Rôle | S1 | S2 | S3 | S4 | S5 | S6 | **Total** |
|---|---|---|---|---|---|---|---|
| Dev mobile Flutter | 7 j | 9 j | 9.5 j | 10.5 j | 15 j | 24 j | **75 j-h** |
| Dev back | 3 j | 1 j | 0 j | 1 j | 2 j | 2 j | **9 j-h** |
| Agronome ISRA/ANCAR | 0 | 20 j | 10 j | 0 | 0 | 5 j | **35 j-h** |
| Linguiste wolof | 0 | 0 | 0 | 3 j | 0 | 0 | **3 j-h** |
| UX testeur terrain | 0 | 0 | 1 j | 2 j | 2 j | 1 j | **6 j-h** |

**Total ~128 j-h sur 12 semaines calendaires.**

---

### 14. Matrice de traçabilité Audit → Sprint

| Item audit | Sprint | Section |
|---|---|---|
| §3.1 Chiffrement PIN | S1 | 7.2, 7.5 |
| §3.1 Récupération PIN OTP | S1 | 7.2 |
| §3.2 Météo réelle + pluviométrie | S4 | 10.4 |
| §3.2 Dashboard to-do + fl_chart | S4 | 10.5 |
| §3.3 NDVI | S6 | 12.1 |
| §3.3 Clustering carte | S5 | 11.7 |
| §3.3 POI terrain éditables | S6 | 12.5 |
| §3.3 Preview polygone dessin | S3 | 9.3 |
| §3.4 Enrichir cultures + variétés + semis | S2 | 8.1 |
| §3.4 Stades BBCH | S2 | 8.2 |
| §3.4 Info sol + précédent | ✅ | `soil_types.dart` + champs Parcel + form |
| §3.4 Précision GPS walk | S3 | 9.6 |
| §3.4 Parcellaire hiérarchique | S6 | 12.6 |
| §3.5 Taxonomie locale + catalogue | S3 | 9.1, 9.2 |
| §3.5 Accordéon observation | S3 | 9.3 |
| §3.5 Validation minimum | S3 | 9.3 |
| §3.5 Géotag EXIF | S3 | 9.4 |
| §3.5 Comparateur photo | S3 | 9.5 |
| §3.5 IA photo | S6 | 12.2 |
| §3.5 Transcription audio | S6 | 12.4 |
| §3.6 Moteur de règles 200+ | S2 | 8.3 |
| §3.6 Géolocalisation règles | S2 | 8.4 |
| §3.6 Fallback expert | S2 | 8.5 |
| §3.6 Bouton "Changer la date" | S2 | 8.3 |
| §3.7 Checklist persistante + contextuelle | S5 | 11.6 |
| §3.8 Photos + signature PDF | S5 | 11.3 |
| §3.8 Historique + agrégé | S5 | 11.4 |
| §3.8 Templates organisation | S5 | 11.3 |
| §3.9 Moteur alertes local | S5 | 11.1 |
| §3.9 Notifications locales | S5 | 11.2 |
| §3.10 OSRM + temps | S6 | 12.3 |
| §3.10 Sauvegarde tournée | S6 | 12.3, 12.7 |
| §3.10 Tracking | S6 | 12.7 |
| §3.11 highContrast + largeText appliqués | S4 | 10.8 |
| §3.11 UI cache région | S5 | 11.5 |
| §3.11 Export/import | S5 | 11.5 |
| §3.11 Diagnostic réseau + support | S5 | 11.5 |
| §3.12 Traductions .arb FR/EN/WO | S4 | 10.1, 10.2, 10.3 |
| §3.12 Simplification vocabulaire | S4 | 10.6 |
| §3.13 Onboarding enrichi + démo | S4 | 10.7 |
| §4.1 Backend Supabase + sync | S1 | 7.1, 7.3 |
| §4.1 Compression photos | S1 | 7.4 |
| §4.1 Retry + conflits + delta | S1 | 7.3 |
| §4.2 Limites cache + purge LRU | S5 | 11.5 |
| §4.3 Chiffrement Hive | S1 | 7.5 |
| §4.3 Auto-lock | S5 | 11.5 (support) |

**✅ 100 % des items d'audit couverts par au moins un sprint.**

---

### 15. Critères de validation globaux (KPI pilote)

À mesurer en continu pendant le pilote hivernage 2026 (juin–août) :

| KPI | Cible | Mesure |
|---|---|---|
| Temps moyen par observation | < 90 s | Analytics event |
| Taux d'abandon observation | < 15 % | Analytics funnel |
| Taux de diagnostic correct (validé agronome) | > 80 % | Audit mensuel 50 obs |
| Données parvenues au serveur | > 95 % | Logs Supabase vs local |
| NPS agriculteur | > 30 | Enquête mi-parcours + fin |
| NPS technicien | > 50 | Idem |
| Crashes par session | < 0.5 % | Sentry |
| Usage sans connexion | > 60 % des sessions | Connectivité loggée |
| Couverture wolof comprise | > 90 % | Test 20 messages / 10 agriculteurs |
| Taille app | < 80 MB | Play Store |

---

### 16. Gouvernance & suivi

- **Revue hebdo** : dev mobile + dev back + PO — 1 h vendredi
- **Revue bi-hebdo** : + agronome — validation recommandations (2 h)
- **Revue sprint** : démo fonctionnelle + retour 3 utilisateurs terrain (2 h fin de sprint)
- **Gate de passage** : ne pas démarrer S_n+1 si les KPIs cibles S_n ne sont pas atteints
- **Rollback** : chaque release a un feature flag (Supabase config) pour désactiver une fonctionnalité défaillante sans republier

---

### 17. Points de vigilance

1. **Référentiel agro = valeur métier** — ne pas sous-investir sur l'agronome consultant. Sans validation ISRA/ANCAR, l'app perd sa légitimité.
2. **Traduction wolof** — passer par IFAN ou CLAD UCAD, pas par traducteurs amateurs. L'orthographe officielle compte pour la crédibilité institutionnelle.
3. **Partenariat ANACIM** — négocier l'accès météo dès S1 (délais administratifs longs au Sénégal).
4. **Souveraineté données** — Supabase self-hosted Dakar, pas de données sur serveurs US (exigences bailleurs africains : AfDB, BOAD).
5. **Formation terrain** — prévoir 1 j de formation par groupe de 10 techniciens avant déploiement.
6. **Helpdesk WhatsApp** — indispensable pour adoption : 1 numéro dédié avec astreinte 8 h–20 h.
7. **Évolution post-v1** : partenariat avec un fournisseur d'intrants (SODEFITEX, SENCHIM) pour lien direct reco → commande, monétisation via commission.
