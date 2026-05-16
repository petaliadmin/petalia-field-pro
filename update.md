# Petalia Field Pro — Plan d'Amélioration Step-by-Step (Elite Framework)

**Date :** 2026-05-04
**Périmètre :** Évolution de l'application mobile pour les techniciens agronomes (Sénégal).
**Objectif :** Passer d'un "Système Expert Statique" à un "Hub d'Assistance IA Dynamique & Prédictif" (Standard FAO / Elite).

---

## 🚀 Phase 1 : Dynamisation des Données & Gestion des Risques (Semaines 1-2)
**Objectif :** Éliminer les données codées en dur (prix) et prévenir le risque majeur de résistance aux pesticides (Maintien de l'efficacité agronomique).

### Step 1.1 : Traçabilité & Alternance IRAC/FRAC [x]
- **Problème :** L'app recommande des matières actives statiques (ex: Spinosad). Risque de créer des souches résistantes si répété.
- **Action :** 
  - [x] Modifier le modèle de données de la parcelle pour enregistrer l'historique des pulvérisations.
  - [x] Ajouter un validateur dans `alert_engine.dart` qui vérifie la classe IRAC (insecticides) ou FRAC (fongicides) de la dernière application.
  - [x] Forcer la recommandation d'un mode d'action alternatif si la classe a déjà été utilisée dans les 21 derniers jours.

### Step 1.2 : "Dynamic Pricing" des Intrants [x]
- **Problème :** `costFcfaPerHa: 12000` est statique. Les prix fluctuent avec les subventions étatiques et les saisons.
- **Action :** 
  - [x] Supprimer les coûts statiques de `agro_rules.json` (via abstraction PricingService).
  - [x] Connecter l'application à une API (via Hive cache et PricingService) qui met en cache les prix du marché local (SIM).
  - [x] Calcul du coût total de traitement au moment de la génération de l'alerte.

### Step 1.3 : Calculateur de Bouillie (Sprayer Calibration) [x]
- **Problème :** Les doses en `kg/ha` ou `L/ha` sont inapplicables directement par un paysan avec un pulvérisateur de 15L.
- **Action :** 
  - [x] Développer un widget interactif (UI "Bento Grid" premium) : *« Volume du pulvérisateur ? »* -> *« Dose par machine »*.
  - [x] Calcul mathématique en fonction de la quantité de bouillie prévue à l'hectare (souvent 200L à 400L/ha au Sénégal).

---

## 🧠 Phase 2 : Évolution vers l'Edge AI & Prédictif (Semaines 3-4) [x]
**Objectif :** Augmenter la fiabilité du diagnostic avec des capteurs objectifs (Caméra) et anticiper les chocs climatiques.

### Step 2.1 : Intégration Computer Vision (Edge AI) [x]
- **Problème :** Le diagnostic repose à 100% sur l'œil du technicien (qui peut se tromper entre carence en azote et virus de la rosette).
- **Action :** 
  - [x] Intégrer un modèle TensorFlow Lite (`tflite_flutter`) entraîné sur les maladies foliaires d'Afrique de l'Ouest (Arachide, Mil, Tomate).
  - [x] UX : Le technicien prend une photo, le modèle donne un score de probabilité (ex: *Pyriculariose à 85%*), puis le moteur `agro_rules.json` prend le relais pour affiner selon le stade BBCH.

### Step 2.2 : Couplage Météorologique & Anti-Lessivage [x]
- **Problème :** Traiter un champ juste avant une pluie battante annule l'effet du produit et pollue les nappes.
- **Action :** 
  - [x] Interfacer le système de recommandation avec `weather_service.dart`.
  - [x] Règle de blocage : *Si Précipitations > 5mm prévues dans les 6 heures -> Bloquer la recommandation de pulvérisation foliaire.*
  - [x] Proposer des fenêtres de tir optimales (ex: *« Traitez demain matin entre 6h et 9h »*).

---

## ☁️ Phase 3 : Backoffice & CMS Agronomique (Semaines 5-6)
**Objectif :** Rendre l'application évolutive sans dépendre des cycles de release du Play Store.

### Step 3.1 : Migration de `agro_rules.json` vers le Cloud (OTA) [x]
- **Problème :** Ajouter une nouvelle culture (ex: Coton, Manioc) nécessite une mise à jour de l'APK.
- **Action :** 
  - [x] Placer la "Source de Vérité" des règles agronomiques sur un backend/API.
  - [x] Au lancement (ou en background via `sync_service.dart`), l'application télécharge la dernière version des règles et la stocke dans Hive.
  - [x] L'application reste `Offline-First` mais devient dynamiquement mettable à jour.

### Step 3.2 : Base de Données des Spécialités Commerciales [x]
- **Problème :** L'app recommande des matières actives (ex: "Acétamipride"). Le paysan cherche un nom commercial au magasin.
- **Action :** 
  - [x] Créer une table de correspondance entre matières actives et produits homologués au Sénégal (Index DPV).
  - [x] Afficher les marques locales (ex: *Mospilan, K-Optimal*) dans la fiche de recommandation et éviter les contrefaçons.

---

## 🌍 Phase 4 : Inclusion Totale (Semaines 7-8) [x]
**Objectif :** Franchise totale de la barrière linguistique et de l'analphabétisme.

### Step 4.1 : Traduction Complète & TTS Local [x]
- **Problème :** Seuls les symptômes sont traduits en Wolof/Pulaar, pas les recommandations d'action.
- **Action :** 
  - [x] Traduire l'ensemble des `actions` du JSON en langues nationales (Logic support implémenté).
  - [x] Générer des fichiers audio de haute qualité (ou via un modèle TTS localisé) pour chaque recommandation. Le paysan clique sur "Écouter le traitement".

### Step 4.2 : Intégration Mobile Money (Paiement des intrants) [x]
- **Problème :** Le technicien prescrit, mais l'accès au financement ou à l'assurance agricole freine l'exécution.
- **Action :** 
  - [x] Préparer l'architecture de paiement (Wave, Orange Money) via `PaymentService`.
  - [x] Lier la recommandation à la possibilité de pré-commander l'intrant recommandé chez le fournisseur local via `nearby_places_service.dart`.
