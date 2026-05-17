export const DEFAULT_SYMPTOMS = {
  version: 1,
  description: "Catalog of field symptoms for observation. Localized FR/EN/WO/FF. Material icon names from `Icons.*`.",
  symptoms: [
    {
      id: "yellow_leaves",
      icon: "eco_rounded",
      labels: {
        fr: "Feuilles jaunes",
        en: "Yellow leaves",
        wo: "Xob yu mbokh",
        ff: "Haako jaalde"
      }
    },
    {
      id: "pests",
      icon: "bug_report_rounded",
      labels: {
        fr: "Nuisibles",
        en: "Pests",
        wo: "Mbaam yi",
        ff: "Belɗe"
      }
    },
    {
      id: "drought",
      icon: "wb_sunny_rounded",
      labels: {
        fr: "Sécheresse",
        en: "Drought",
        wo: "Naaj wi",
        ff: "Yoor-yoorɗo"
      }
    },
    {
      id: "weeds",
      icon: "grass_rounded",
      labels: {
        fr: "Mauvaises herbes",
        en: "Weeds",
        wo: "Ñax bu bon",
        ff: "Huɗo bonɗo"
      }
    },
    {
      id: "spots",
      icon: "blur_on_rounded",
      labels: {
        fr: "Taches de maladie",
        en: "Disease spots",
        wo: "Tukki feebar",
        ff: "Tofe ñaw"
      }
    },
    {
      id: "taches_brunes",
      icon: "circle_rounded",
      labels: {
        fr: "Taches brunes",
        en: "Brown spots",
        wo: "Tukki yu xonk-melax",
        ff: "Tofe boɗeeje"
      }
    },
    {
      id: "taches_noires",
      icon: "circle_outlined",
      labels: {
        fr: "Taches noires",
        en: "Black spots",
        wo: "Tukki yu ñuul",
        ff: "Tofe ɓaleeje"
      }
    },
    {
      id: "defoliation",
      icon: "grass_rounded",
      labels: {
        fr: "Feuilles mangées",
        en: "Eaten leaves",
        wo: "Xob lekk",
        ff: "Haako ñaamaaɗo"
      }
    },
    {
      id: "feuille_blanche",
      icon: "colorize_rounded",
      labels: {
        fr: "Feuille blanche anormale",
        en: "Abnormal white leaf",
        wo: "Xob bu weex bu rafet",
        ff: "Haako rawnudo"
      }
    },
    {
      id: "mosaique",
      icon: "palette_rounded",
      labels: {
        fr: "Mosaïque jaune",
        en: "Yellow mosaic",
        wo: "Mosayig bu mboot",
        ff: "Mosayiku oolo"
      }
    },
    {
      id: "nanisme",
      icon: "height_rounded",
      labels: {
        fr: "Plante trop petite",
        en: "Stunted plant",
        wo: "Garab gu ndaw lool",
        ff: "Puɗɗi famɗuɗo"
      }
    },
    {
      id: "fletrissement",
      icon: "water_drop_outlined",
      labels: {
        fr: "Flétrissement",
        en: "Wilting",
        wo: "Garab gu wow",
        ff: "Puɗɗi yoorɗo"
      }
    },
    {
      id: "galles",
      icon: "bubble_chart_rounded",
      labels: {
        fr: "Galles / Bosses",
        en: "Galls / Bumps",
        wo: "Bopp yu jeex",
        ff: "Bumpiraagal"
      }
    },
    {
      id: "miellat",
      icon: "water_rounded",
      labels: {
        fr: "Liquide collant (miellat)",
        en: "Sticky liquid (honeydew)",
        wo: "Ndox mu tef",
        ff: "Ndiyam takkiɗo"
      }
    },
    {
      id: "mauvaise_levee",
      icon: "warning_rounded",
      labels: {
        fr: "Mauvaise levée",
        en: "Poor germination",
        wo: "Saxal bu bon",
        ff: "Fuɗɗannde bonnde"
      }
    },
    {
      id: "pas_grain",
      icon: "sell_rounded",
      labels: {
        fr: "Épi / Gousse vide",
        en: "Empty ear / pod",
        wo: "Mbatt mu amul",
        ff: "Caaboru meere"
      }
    },
    {
      id: "fruit_pourri",
      icon: "sick_rounded",
      labels: {
        fr: "Fruit pourri",
        en: "Rotten fruit",
        wo: "Doom bu yàqu",
        ff: "Ɓiɓɓe yi̇ggii"
      }
    }
  ]
};

export const DEFAULT_AGRO_RULES = {
  schemaVersion: 3,
  updatedAt: "2026-05-07",
  source: "Petalia Field Pro — règles v3 multi-sources. Sources primaires exploitées : ISRA.sn, CERAAS, ANCAR, CDH/Niayes, SAED, DPV-Sénégal, ICRISAT, COLEACP, FAO/IITA, IRD/CIRAD (Agritrop), INSAH/CILSS (Liste CSP juillet 2023 + février 2025), ANACIM, UCAD-FST, ResearchGate (thèses), HAL-INRAE, OMS (mycotoxines), Springer/Phytoparasitica, AJOL, TEL-Thèses.",
  changelog: [
    "v3 2026-05-07 : Enrichissement multi-sources (PDFs institutionnels, journaux peer-reviewed, liste CSP officielle juillet 2023 + session extraordinaire février 2025). Ajout des N° d'autorisation CSP sur produits-clés. Données rendements chiffrées sur niébé (AJOL 2013). Nouvelles données HAL-INRAE 2025 sur aflatoxines arachide Sénégal. Intégration biofongicide AFLASAFE SN 01 (CSP homologué). Ajout bio-insecticide MaviNPV niébé. Ajout variétés ISRA 2024 homologuées. Données ANACIM/agromét pour stades phénologiques. Correction Bio-fongicide Aflatoxine CSP confirmé.",
    "v2 2026-05-07 : Corrections techniques majeures, ajout 4 nouvelles règles",
    "v1 2026-04-18 : Version initiale"
  ],
  cspReference: {
    lastVersion: "Juillet 2023 + Session Extraordinaire 10e (février 2025) + Session Extraordinaire 11e (octobre 2025)",
    source: "INSAH/CILSS — insah.cilss.int",
    url: "https://insah.cilss.int/du-csp-au-coahp/",
    note: "607 produits homologués en 2025 (+11% vs 2023). Vérifier expiration de chaque autorisation avant usage terrain."
  },
  notes: [
    "Chaque règle filtrée sur `crop`, `stages`, `symptom`, `season`, `regions`, `severityMin`.",
    "`ppeRequired=true` : bandeau EPI obligatoire dans l'UI.",
    "`delayBeforeHarvestDays` = DAR (Délai Avant Récolte) du produit le plus contraignant.",
    "`followupDays` : injecté dans le bouton 'Prochaine visite'.",
    "OBLIGATION LÉGALE : vérifier homologation CSP active sur insah.cilss.int avant tout conseil phytosanitaire.",
    "Carbofuran : retiré de toutes les règles (phaseout FAO/OMS, toxicité classe Ia OMS).",
    "Biofongicide AFLASAFE SN 01 (Aspergillus flavus non-aflatoxinogène) : homologué CSP au Sénégal (réf. 0920-H0/Bi.Fo/10-22/HOM-SAHEL, expire oct 2027). Usage : arachide + maïs, contrôle aflatoxines."
  ],
  rules: [
    {
      id: "ARA-VEG-YELLOW-RAINY",
      crop: "arachide",
      stages: ["vegetative", "flowering"],
      symptom: "yellow_leaves",
      season: "hivernage",
      regions: ["thies", "diourbel", "fatick", "kaolack", "kaffrine"],
      severityMin: 0.3,
      scientificContext: "Arachis hypogaea L. — légumineuse fixatrice N₂ via Bradyrhizobium spp. Un jaunissement foliaire indique une nodulation défaillante ou carence en soufre. L'urée est contre-productive (inhibe fixation symbiotique). Source : ISRA-CNRA-Bambey fiches techniques + IFDC itinéraire technique arachide (Sénégal vulgarise NPK 6-20-10 bassin arachidier Sud — IFDC 2019).",
      diagnosis: "Jaunissement sur arachide — nodulation défaillante ou carence en soufre (S). NE PAS confondre avec carence azotée traitée à l'urée : contre-productif sur légumineuse.",
      recommendation: {
        title: "Diagnostiquer la nodulation avant tout apport",
        actions: [
          "Arracher 2–3 plantes au hasard, couper un nodule racinaire : rose/rouge = fixation N₂ active ; blanc/vert/brun = défaillante.",
          "Si nodulation fonctionnelle et jaunissement persistant (carence soufre) : sulfate d'ammoniaque (21-0-0-24S) à 50 kg/ha. Formule NPK 6-20-10 disponible en bassin arachidier (IFDC).",
          "Si nodulation absente : inoculation Bradyrhizobium sur semences campagne suivante (Nitragin® ou équivalent homologué CSP). Aucun apport urée.",
          "Vérifier pH sol : < 5,5 inhibe la nodulation → chaulage à la dolomite si nécessaire.",
          "Variétés homologuées ISRA 2024 à fort potentiel de nodulation : Essamaye, Amoul Morom, Yakaar (cycle court adapté changement climatique)."
        ],
        costFcfaPerHa: 12000,
        delayBeforeHarvestDays: 0,
        ppeRequired: false,
        followupDays: 7
      },
      sources: [
        "ISRA-CNRA-Bambey-fiche-technique-arachide-2022",
        "IFDC-itinéraire-technique-arachide-Sénégal-2019 (ifdc.org)",
        "ISRA.sn-résultats-recherche-variétés-homologuées-2024"
      ]
    },
    {
      id: "ARA-VEG-SPOTS-CERCO",
      crop: "arachide",
      stages: ["vegetative", "flowering", "fruiting"],
      symptom: "spots",
      season: "hivernage",
      regions: ["thies", "diourbel", "fatick", "kaolack", "kaffrine", "kolda", "sedhiou"],
      severityMin: 0.2,
      scientificContext: "Cercospora arachidicola (cercosporiose précoce) et Phaeoisariopsis personata (cercosporiose tardive). Forte présence zones centre-sud et sud du Sénégal (données CERAAS/IAVAO 2017). Variété CH-119-20 sensible à la cercosporiose (intranet.isra.sn). Cycle épidémique : humidité > 80%, T° 25–30°C.",
      diagnosis: "Cercosporioses (précoce/tardive) — taches brun-rougeâtre cercospora arachidicola face supérieure OU brun foncé face inférieure phaeoisariopsis, halo jaune. Défoliation précoce possible (-20% rendement).",
      recommendation: {
        title: "Fongicide cuivre préventif + variétés tolérantes",
        actions: [
          "PRÉVENTIF (dès fermeture des rangs) : oxychlorure de cuivre 50% WP à 2 kg/ha, 400–600 L eau/ha. Homologué CSP cultures oléagineuses.",
          "CURATIF : mancozèbe 80% WP à 2 kg/ha OU hydroxyde de cuivre 77% WP à 1,5 kg/ha. Renouveler à 10–14 j sous pluies fréquentes ou après 20 mm.",
          "FONGICIDE SYSTÉMIQUE (si pression forte) : Systane 240 EC (tébuconazole) OU Ortiva 250 SC (azoxystrobine) — validés IFDC pour traitement foliaire cercosporiose arachide.",
          "VARIÉTÉS TOLÉRANTES homologuées : 55-437 (tolérant), GC8-35, ICGV 14857 (réseau IAVAO). Variété 69-101 (résistante rosette + tolérante cercosporiose, ISRA-Bambey).",
          "Rotation céréale/arachide 2 ans minimum. Détruire résidus après récolte."
        ],
        costFcfaPerHa: 9000,
        delayBeforeHarvestDays: 21,
        ppeRequired: true,
        followupDays: 10
      },
      sources: [
        "ISRA-CERAAS-2021",
        "IAVAO-sélection-arachide-2017 (iavao.org — biologie cercosporiose)",
        "IFDC-fiche-semence-arachide-2019 (traitements foliaires validés)",
        "intranet.isra.sn — variétés sensibles/tolérantes"
      ]
    },
    {
      id: "ARA-VEG-ROSETTE",
      crop: "arachide",
      stages: ["germination", "vegetative"],
      symptom: "yellow_leaves",
      season: "hivernage",
      regions: ["louga", "thies", "diourbel", "kaffrine"],
      severityMin: 0.5,
      scientificContext: "Groundnut Rosette Virus (GRV) — complex viral (sat-RNA + umbravirus). Vecteur Aphis craccivora Koch, transmission persistante en < 5 min. Variété 69-101 (ISRA-Bambey) sélectionnée spécifiquement pour résistance rosette dans zones forte pluviométrie (intranet.isra.sn). Semis précoce = mesure préventive n°1 (ISRA-Bambey).",
      diagnosis: "Rosette virale (GRV) — plantes rabougries, feuillage chlorotique jaune-vert en bouquet dense ('chlorotic rosette') ou feuilles déformées vert foncé ('green rosette'). Aucun traitement curatif connu.",
      recommendation: {
        title: "Arrachage foyers + contrôle vecteur + semis précoce obligatoire",
        actions: [
          "Arracher et brûler IMMÉDIATEMENT tous plants atteints (foyers primaires virus + pucerons virulents).",
          "Traiter foyers pucerons environnants : acétamipride 20% SP (référence IFDC pour pucerons arachide) à 20 g/ha en traitement localisé. Traiter hors activité pollinisateurs.",
          "NE PAS replanter de semences non traitées dans la parcelle contaminée.",
          "PRÉVENTION PRIMAIRE : semer avant le 15 juillet (réduction exposition 70%, ISRA-Bambey). Variétés résistantes GRV : Fleur 11, 69-101, 78-936, ICGV-IS.",
          "Prochaine campagne : enrobage semences imidaclopride 600 FS à 5 mL/kg semences pour protection précoce 0–30 JAS contre pucerons vecteurs."
        ],
        costFcfaPerHa: 6000,
        delayBeforeHarvestDays: 14,
        ppeRequired: true,
        followupDays: 5
      },
      sources: [
        "ISRA-CNRA-Bambey",
        "intranet.isra.sn — variété 69-101 résistance rosette",
        "CERAAS-programme-arachide-diffusion-variétés-2021"
      ]
    },
    {
      id: "ARA-VEG-PESTS-APHIDS",
      crop: "arachide",
      stages: ["vegetative", "flowering"],
      symptom: "pests",
      season: "hivernage",
      regions: ["thies", "diourbel", "fatick", "kaolack", "kaffrine", "louga"],
      severityMin: 0.3,
      scientificContext: "Aphis craccivora Koch — puceron noir de l'arachide. Populations explosent en début hivernage (conditions sèches avant installation pluies). Vecteur GRV. L'acétamipride (15 g/L + lambda-cyhalothrine 10 g/L) est homologué CSP contre pucerons sur tomate (réf. 1015-J10/In/10-22/HOM-SAHEL) — proximité d'usage.",
      diagnosis: "Pucerons noirs (A. craccivora) — colonies denses sur pousses apicales, miellat collant, feuilles enroulées. Risque vecteur GRV si plants < 30 JAS.",
      recommendation: {
        title: "Traitement localisé foyers pucerons — préserver auxiliaires",
        actions: [
          "Traitement localisé (foyers uniquement, pas toute la parcelle) : acétamipride 20% SP à 20 g/ha OU pirimicarbe 50% WP à 250 g/ha (sélectif, préserve coccinelles et parasitoïdes).",
          "Éviter pyréthrinoïdes en début de saison (élimination ennemis naturels, risque acariens).",
          "Préserver Coccinella septempunctata, Chrysoperla carnea, Lysiphlebus spp. — prédateurs naturels efficaces en champ non traité.",
          "Si infestation avant 30 JAS et risque rosette élevé : traitement plus agressif justifié (imidaclopride 70% WS, dose foliaire réduite)."
        ],
        costFcfaPerHa: 5000,
        delayBeforeHarvestDays: 14,
        ppeRequired: true,
        followupDays: 5
      },
      sources: [
        "ANCAR-fiche-puceron-2023",
        "IFDC-fiche-semence-arachide-2019 (acétamipride validé pucerons arachide)",
        "Liste-CSP-juillet-2023 (produits acétamipride homologués)"
      ]
    },
    {
      id: "ARA-HARVEST-AFLATOXIN",
      crop: "arachide",
      stages: ["fruiting", "ripening", "maturation"],
      symptom: "drought",
      season: "hivernage",
      regions: ["louga", "thies", "diourbel", "fatick", "kaolack", "kaffrine"],
      severityMin: 0.4,
      scientificContext: "NOUVELLE DONNÉE v3. Étude HAL-INRAE 2025 (Sénégal, ANSD 2023) : technique séchage 'gousses en l'air sur table' → teneur B1 5,67 ppb vs pratique paysanne 9,13 ppb. Seuil UE : 4 ppb B1. AFLASAFE SN 01 (Aspergillus flavus non-aflatoxinogène) homologué CSP Sénégal réf. 0920-H0/Bi.Fo/10-22/HOM-SAHEL, expire octobre 2027 — biofongicide applicable avant récolte. Filière arachide génère > 22 milliards FCFA (ANSD 2023).",
      diagnosis: "Stress hydrique en fin de cycle (stade gousse–maturation) — risque contamination aflatoxines (Aspergillus flavus). Indicateurs : feuilles basales sèches, sol craquelé, arrêt gonflement gousses.",
      recommendation: {
        title: "Prévention aflatoxines — arrachage anticipé + technique séchage optimisée",
        actions: [
          "BIOFONGICIDE PRÉVENTIF (avant récolte) : AFLASAFE SN 01 homologué CSP Sénégal (réf. 0920-H0/Bi.Fo/10-22/HOM-SAHEL) — Aspergillus flavus non-aflatoxinogène, compétiteur biologique d'A. flavus toxinogène. Disponible via IITA-Sénégal.",
          "Arracher dès 70–80% gousses avec intérieur coque brun/noir (test ISRA-Bambey).",
          "TECHNIQUE DE SÉCHAGE VALIDÉE (HAL-INRAE 2025) : 'gousses en l'air sur table' → B1 = 5,67 ppb (vs pratique paysanne 9,13 ppb). Éviter contact sol humide > 48h.",
          "Stocker en magasin ventilé, humidité gousses < 8%. Éviter l'humidité et les insectes des stocks.",
          "Faire tester un échantillon avant commercialisation : seuil UE 4 ppb B1 (norme export), seuil CEDEAO 10 ppb. Contact : ISRA/CNIA pour analyse."
        ],
        costFcfaPerHa: 3000,
        delayBeforeHarvestDays: 0,
        ppeRequired: false,
        followupDays: 3
      },
      sources: [
        "HAL-INRAE-hal-04927121v1-2025 (effet technique séchage sur aflatoxine B1, Sénégal)",
        "ISRA-CERAAS-aflatoxines-2020",
        "Liste-CSP-juillet-2023 réf. 0920 AFLASAFE SN 01",
        "OMS-mycotoxines-fiche-2023 (who.int)",
        "ANSD-2023 cité par HAL-INRAE-2025 (filière arachide Sénégal)"
      ]
    },
    {
      id: "ARA-SEED-TREAT",
      crop: "arachide",
      stages: ["germination"],
      symptom: "pests",
      season: "hivernage",
      regions: ["thies", "diourbel", "fatick", "kaolack", "kaffrine", "louga", "tambacounda"],
      severityMin: 0.1,
      scientificContext: "Iules (Diplopoda) et charançons des semences — pertes peuplement 15–30% début campagne. Traitement semences validé IFDC 2019 (lambda-cyhalothrine 15 g/L + acétamipride 10 g/L m.a. homologué Sénégal). Incompatibilité inoculant/insecticide : appliquer séparément.",
      diagnosis: "Mauvaise levée — dégâts iules ou charançons sur graines en germination. Plants manquants, gaines coupées, graines rongées visibles à l'arrachage.",
      recommendation: {
        title: "Enrobage insecticide des semences avant semis",
        actions: [
          "Enrober les semences avec lambda-cyhalothrine 15 g/L + acétamipride 10 g/L (IFDC validé au Sénégal) à 5–10 mL/10 kg semences.",
          "Semer dans les 24h. Ne pas stocker semences traitées > 48h.",
          "Si inoculation Bradyrhizobium prévue : appliquer insecticide J-1, inoculant au moment du semis (incompatibilité biochimique).",
          "EPI obligatoire : gants nitrile, masque FFP2, lunettes. Ne jamais consommer semences traitées."
        ],
        costFcfaPerHa: 3500,
        delayBeforeHarvestDays: 0,
        ppeRequired: true,
        followupDays: 10
      },
      sources: [
        "IFDC-fiche-semence-arachide-2019 (protocole traitement semences lambda-cyhalothrine + acétamipride)"
      ]
    },
    {
      id: "MIL-VEG-STRIGA",
      crop: "mil",
      stages: ["vegetative", "stem_elongation"],
      symptom: "weeds",
      season: "hivernage",
      regions: ["diourbel", "louga", "kaffrine", "thies", "fatick"],
      severityMin: 0.3,
      scientificContext: "Striga hermonthica (Delile) Benth. (Orobanchaceae) — parasite racinaire obligatoire. Graines germent via strigolactones exsudées par racines hôtes. Production : 50 000–200 000 graines viables > 20 ans. Souna 3 (90 j) et Thialack 2 (75 j) sont les variétés tolérantes vulgarisées ISRA. Données ISRA : variétés mil disponibles via RESOPP et ANCAR (isra.sn/résultats-2024).",
      diagnosis: "Striga hermonthica — tiges dressées fleurs rose-violacé (5–60 cm), parasitant racines mil. Symptômes avant émergence : pieds chétifs, jaunissement, retard de croissance (4–6 semaines d'effet souterrain avant émergence).",
      recommendation: {
        title: "Lutte intégrée Striga — priorité rotation + variétés tolérantes",
        actions: [
          "ACTION IMMÉDIATE : arracher striga AVANT floraison (avant fleurs rose-violacé), brûler sur place.",
          "FERTILISATION : fumier composté 3–5 t/ha (réduit exsudats strigolactones, confirme PROPAS/IITA).",
          "ROTATION OBLIGATOIRE : niébé, arachide ou sésame la campagne suivante (réduction stock graines de 40% selon IITA).",
          "VARIÉTÉS TOLÉRANTES ISRA (homologuées) : Souna 3 (90 j, zones Centre-Nord), Thialack 2 (75 j, zones sèches). Disponibles RESOPP + ANCAR.",
          "OPTION AVANCÉE (projets ICRISAT) : herbicide imazapyr 0,5% sur semences IR (variétés imazapyr-résistantes — ISMAM). Demander disponibilité auprès de la DPV."
        ],
        costFcfaPerHa: 3000,
        delayBeforeHarvestDays: 0,
        ppeRequired: false,
        followupDays: 14
      },
      sources: [
        "ICRISAT-ISRA-striga-2019",
        "IITA-PROPAS-gestion-striga",
        "isra.sn/résultats-2024 (variétés mil homologuées)",
        "UCAD-FST-thèse-adventices-mil-arachide (dynamique Striga Sahel)"
      ]
    },
    {
      id: "MIL-FLO-PESTS-MINEUSE",
      crop: "mil",
      stages: ["flowering", "fruiting"],
      symptom: "pests",
      season: "hivernage",
      regions: ["louga", "diourbel", "kaffrine", "thies"],
      severityMin: 0.3,
      scientificContext: "Heliocheilus albipunctella De Joannis (Noctuidae) — mineuse de l'épi du mil. Pertes 10–30% en zone Sahélienne (ISRA-DPV 2022). Habrobracon hebetor (parasitoïde larvaire) et azadirachtine (neem) sont les 2 options de biocontrôle disponibles au Sénégal. Bulletins ANACIM : surveillance épiaison par décade agrométéorologique.",
      diagnosis: "Chenille mineuse de l'épi (H. albipunctella) — perforations irrégulières sur épis, excréments noirs, papillons beige clair actifs au crépuscule.",
      recommendation: {
        title: "Biocontrôle prioritaire — intervention dans les 72h post-épiaison",
        actions: [
          "SURVEILLANCE : 3 passages/semaine dès gonflement épis. Utiliser bulletins agrométéorologiques décadaires ANACIM pour anticiper stade épiaison.",
          "BIOCONTRÔLE (prioritaire) : Habrobracon hebetor — 3 lâchers à 7 jours d'intervalle, 5 000–10 000 ind./ha. Disponible ISRA-DPV + Songhaï Sénégal.",
          "BIOPESTICIDE : azadirachtine (neem) 3,2 g/L à 2,5 L/ha en soirée (18h–20h), 3 applications à 5 jours.",
          "CHIMIQUE (pression forte, > 20% épis atteints) : émamectine benzoate 1,9% EC à 250 mL/ha, jet dirigé épis. DAR 7 jours.",
          "Ne pas traiter par temps de pluie ou vent > 15 km/h."
        ],
        costFcfaPerHa: 8000,
        delayBeforeHarvestDays: 7,
        ppeRequired: true,
        followupDays: 7
      },
      sources: [
        "ISRA-DPV-2022",
        "PROPAS-IITA-lutte-biologique-mil",
        "ANACIM-bulletin-agromét-décadaire (stades phénologiques mil)"
      ]
    },
    {
      id: "SOR-VEG-STRIGA",
      crop: "sorgho",
      stages: ["vegetative", "stem_elongation"],
      symptom: "weeds",
      season: "hivernage",
      regions: ["tambacounda", "kaffrine", "kolda", "sedhiou"],
      severityMin: 0.3,
      scientificContext: "S. hermonthica sur sorgho (Sorghum bicolor). Variétés tolérantes homologuées ISRA 2024 : Faourou, Nguinthe, Nganda, Gologé, Payenne, Darou (isra.sn/résultats). Le sorgho est plus sensible que le mil. Pertes 20–80% selon infestation.",
      diagnosis: "Striga hermonthica sur sorgho — émergence plants parasites, pieds chétifs. Le sorgho est plus sensible que le mil — infestation modérée peut causer pertes sévères.",
      recommendation: {
        title: "Rotation + variétés tolérantes homologuées ISRA",
        actions: [
          "Arracher striga AVANT floraison, brûler sur place (ne pas composter).",
          "ROTATION OBLIGATOIRE : légumineuse (niébé Pakau, Lisard, Léona — variétés ISRA homologuées 2024) ou sésame la campagne suivante.",
          "VARIÉTÉS TOLÉRANTES (homologuées ISRA 2024) : Faourou (105 j), Nguinthe (110 j, Casamance), Nganda, Gologé, Darou. Via RESOPP + ANCAR.",
          "Apport fumier 3–5 t/ha pour enrichir sol et réduire exsudats strigolactones.",
          "Infestation sévère (> 5 pieds/m²) : envisager jachère travaillée 1 campagne."
        ],
        costFcfaPerHa: 3500,
        delayBeforeHarvestDays: 0,
        ppeRequired: false,
        followupDays: 14
      },
      sources: [
        "ICRISAT-striga-sorgho-2021",
        "isra.sn/résultats-2024 (nouvelles variétés sorgho homologuées : Darou, Faourou, Nguinthe, Nganda, Gologé, Payenne)"
      ]
    },
    {
      id: "MAIS-VEG-CHENILLE-FAW",
      crop: "mais",
      stages: ["germination", "vegetative", "stem_elongation"],
      symptom: "pests",
      season: "hivernage",
      regions: ["thies", "fatick", "kaolack", "kaffrine", "tambacounda", "kolda", "sedhiou", "ziguinchor"],
      severityMin: 0.2,
      scientificContext: "Spodoptera frugiperda (J.E. Smith) — introduit Afrique de l'Ouest 2016 (IITA/Goergen et al., PLOS ONE 2016). Étude terrain Sénégal 2018–2019 nord-ouest (Springer Phytoparasitica 2023) : sans traitement = 1–25% dégâts foliaires, 3–44% dégâts épis. Bt kurstaki et neem (4,5 L/ha) efficaces sur L1-L3. Deltaméthrine moins efficace que lambda-cyhalothrine + acétamipride (étude terrain Sénégal). Variétés ISRA maïs recommandées ANACIM : Noor 96, Swan, Obatampa.",
      diagnosis: "Chenille légionnaire d'automne (S. frugiperda) — trous irréguliers stades L1-L2, dégâts cornet stades L3-L5 avec excréments noirs, larves avec Y inversé sur capsule céphalique noire.",
      recommendation: {
        title: "Lutte intégrée FAW — seuil 20% + biocontrôle en premier",
        actions: [
          "SURVEILLANCE : inspection 2x/semaine dès stade 2 feuilles, 20 plants/0,5 ha.",
          "SEUIL D'INTERVENTION : ≥ 20% plants avec larves dans le cornet → traiter immédiatement.",
          "BIOCONTRÔLE (premier choix) : Bacillus thuringiensis kurstaki 0,5–1 kg/ha DANS LE CORNET, en soirée. Efficacité validée terrain Sénégal (Phytoparasitica 2023).",
          "NEEM : azadirachtine 4,5 L/ha, efficacité validée terrain Sénégal (mêmes essais).",
          "CHIMIQUE (L4-L5, pression forte) : émamectine benzoate 1,9% EC à 250 mL/ha, jet dirigé cornet. Éviter deltaméthrine seule (résistances documentées). Lambda-cyhalothrine + acétamipride : option validée sur terrain Sénégal.",
          "Variétés ISRA recommandées ANACIM : Noor 96, Swan, Obatampa (meilleure vigueur juvénile = moins vulnérable)."
        ],
        costFcfaPerHa: 11000,
        delayBeforeHarvestDays: 14,
        ppeRequired: true,
        followupDays: 5
      },
      sources: [
        "Springer-Phytoparasitica-FAW-Senegal-2023 (essais 2018–2019 NW Sénégal)",
        "DPV-Senegal-FAW-2023",
        "IITA-PROPAS-FAW",
        "Goergen-et-al-PLOSONE-2016 (1er signalement Afrique de l'Ouest)",
        "ANACIM-bulletin-agromét-variétés-maïs"
      ]
    },
    {
      id: "MAIS-VEG-FAW-BIO",
      crop: "mais",
      stages: ["germination", "vegetative"],
      symptom: "pests",
      season: "hivernage",
      regions: ["thies", "fatick", "kaolack", "kaffrine", "tambacounda", "kolda", "sedhiou", "ziguinchor"],
      severityMin: 0.1,
      scientificContext: "Intervention précoce FAW (< seuil 20%) — approche IPM recommandée FAO et DPV pour limiter résistances. FortenzaTM Duo (imidaclopride + tébuconazole) en enrobage semences : protection systémique 0–30 JAS (IITA-PROPAS).",
      diagnosis: "Début d'infestation FAW (< 20% plants atteints) — larves L1-L2 sur quelques plantes, trous en fenêtres. Stade optimal pour biocontrôle.",
      recommendation: {
        title: "Biocontrôle préventif — stade précoce FAW",
        actions: [
          "Confirmer identification : larve avec Y inversé sur capsule céphalique noire, excréments noirs dans le cornet.",
          "Bt kurstaki 1 kg/ha dans le cornet en soirée, plants atteints + 2 rangs autour.",
          "Option semences prochaine campagne : FortenzaTM Duo (imidaclopride + tébuconazole) enrobage — protection systémique 0–30 JAS.",
          "Favoriser parasitoïdes naturels (Cotesia marginiventris, Telenomus remus) — éviter traitements préventifs sans justification."
        ],
        costFcfaPerHa: 5000,
        delayBeforeHarvestDays: 0,
        ppeRequired: false,
        followupDays: 5
      },
      sources: [
        "FAO-IPM-FAW-guidelines",
        "IITA-PROPAS-FAW-FortenzaDuo",
        "Phytoparasitica-FAW-Senegal-2023"
      ]
    },
    {
      id: "MAIS-VEG-YELLOW",
      crop: "mais",
      stages: ["vegetative", "stem_elongation"],
      symptom: "yellow_leaves",
      season: "hivernage",
      regions: ["thies", "fatick", "kaolack", "kaffrine", "tambacounda", "kolda"],
      severityMin: 0.3,
      scientificContext: "Carence N sur maïs — symptôme classique en V (jaunissement pointe feuilles basses). Bulletin ANACIM décadaire recommande : variétés ISRA Noor 96, Swan, Obatampa + désherbage, amendements organiques et enrobage semences insecticides. Pertes volatilisation urée en surface > 35°C : 50%.",
      diagnosis: "Carence azotée probable — jaunissement en V inversé depuis feuilles basses. Distinguer de Maize Streak Virus (stries irrégulières) et symptômes FAW.",
      recommendation: {
        title: "Apport urée fractionné — méthode anti-pertes",
        actions: [
          "1er apport urée 46% à 50 kg/ha au stade 6–8 feuilles (20–25 JAS). Incorporer légèrement ou avant pluie prévue.",
          "2ème apport 50 kg/ha à initiation paniculaire (35–40 JAS). Tôt le matin ou soirée uniquement.",
          "NE PAS appliquer urée en surface par temps chaud-sec T° > 35°C (pertes NH₃ > 50% — ANACIM).",
          "Si pas d'amélioration en 10 jours : envisager carence Zn (taches internervaires) ou S → sulfate de zinc 25 kg/ha ou sulfate d'ammoniaque.",
          "Associer amendement organique (fumier 3 t/ha) pour améliorer efficacité engrais (recommandation ANACIM bulletin décadaire juin 2024)."
        ],
        costFcfaPerHa: 18000,
        delayBeforeHarvestDays: 0,
        ppeRequired: false,
        followupDays: 10
      },
      sources: [
        "ANCAR-fiche-mais-2022",
        "ANACIM-bulletin-agromét-décadaire-juin-2024 (recommandations maïs)"
      ]
    },
    {
      id: "MAIS-FLO-DROUGHT",
      crop: "mais",
      stages: ["flowering", "fruiting"],
      symptom: "drought",
      season: "hivernage",
      regions: ["thies", "fatick", "kaolack", "kaffrine", "diourbel"],
      severityMin: 0.4,
      scientificContext: "Stress hydrique floraison maïs — 5 jours de déficit = -25 à -50% rendement (ISRA-CERAAS). Fenêtre critique ±7 j autour émission soies. ANACIM : NDVI values relativement plus faibles en 2024 vs 2023 à la même période indique risque stress hydrique accru.",
      diagnosis: "Stress hydrique critique à la floraison — soies desséchées, feuilles enroulées, apex stérile potentiel. Fenêtre critique : émission soies ±7 jours.",
      recommendation: {
        title: "Irrigation de sauvetage — priorité absolue floraison",
        actions: [
          "Irriguer 25–30 mm dans les 24–48h (aspersion soirée ou goutte-à-goutte).",
          "Si pas d'irrigation : paillage épais (coques arachide, paille mil 5–8 cm) sur toute la parcelle.",
          "INTERDIT sous stress hydrique : tout traitement phytosanitaire foliaire (phytotoxicité sur stomates ouverts).",
          "Surveiller reprise pollinisation en 48h. Si soies > 10 jours sans pollinisation : rendement cette parcelle fortement compromis.",
          "Consulter bulletins ANACIM pour prévisions pluies 10 jours — anticiper l'irrigation."
        ],
        costFcfaPerHa: 4000,
        delayBeforeHarvestDays: 0,
        ppeRequired: false,
        followupDays: 3
      },
      sources: [
        "ISRA-CERAAS-stress-mais",
        "ANACIM-bulletin-NDVI-juin-2024 (valeurs NDVI 2024 vs 2023)",
        "FAO-climate-smart-maize-WA"
      ]
    },
    {
      id: "RIZ-VEG-PYRIC",
      crop: "riz",
      stages: ["vegetative", "stem_elongation", "flowering"],
      symptom: "spots",
      season: "hivernage",
      regions: ["saint_louis", "matam", "ziguinchor", "sedhiou"],
      severityMin: 0.3,
      scientificContext: "Magnaporthe oryzae (Cavara) Sacc. — ascomycète. Tricyclazole : inhibiteur biosynthèse mélanine, matière active de référence mondiale (données Academia.edu-Gharb 2024). Variétés ISRA pour Vallée du Fleuve : riz NERICA de bas-fond, Sahel 108 (SAED). Gestion eau : drainage 24h réduit humidité canopée et brise le cycle épidémique.",
      diagnosis: "Pyriculariose — lésions losangiques gris-brun feuilles, col panicule noirci possible (blast du col = perte totale panicule). Conditions : nuits fraîches < 24°C, humidité > 90%.",
      recommendation: {
        title: "Fongicide systémique + réduction azote + variétés résistantes",
        actions: [
          "CURATIF au premier symptôme : tricyclazole 75% WP à 300 g/ha en 400 L eau/ha. DAR 28 jours.",
          "Répéter à 10 jours si pression forte.",
          "ALTERNATIVE si tricyclazole non disponible : propiconazole 250 EC à 500 mL/ha (validé Academia.edu 2024). DAR 28 jours.",
          "RÉDUIRE IMMÉDIATEMENT les apports azote (favorise sporulation M. oryzae).",
          "Drainer la rizière 24–48h si possible (brise le cycle humide).",
          "VARIÉTÉS RÉSISTANTES (campagne suivante) : NERICA de bas-fond (ISRA), Sahel 108 (SAED, adapté Vallée Fleuve Sénégal), Orylux 6."
        ],
        costFcfaPerHa: 15000,
        delayBeforeHarvestDays: 28,
        ppeRequired: true,
        followupDays: 7
      },
      sources: [
        "SAED-ADRAO-pyriculariose-2020",
        "Academia.edu-pyriculariose-Gharb-2024 (tricyclazole + propiconazole efficacité)",
        "isra.sn/résultats-2024 (variétés riz NERICA Vallée Fleuve)"
      ]
    },
    {
      id: "RIZ-PANICLE-BLAST",
      crop: "riz",
      stages: ["flowering", "ripening"],
      symptom: "spots",
      season: "hivernage",
      regions: ["saint_louis", "matam"],
      severityMin: 0.4,
      scientificContext: "Blast du col (neck blast) — forme la plus dévastatrice. Col de la panicule noirci = 60–100% perte en conditions épidémiques. Traitement préventif OBLIGATOIRE si blast foliaire observé dans les 2 semaines précédant l'épiaison.",
      diagnosis: "Blast du col — col panicule noirci ou brun foncé, panicule stérile ou vide ('whiteheads'), affaissement de l'épi. Différencier de caries ou toxicité métallique.",
      recommendation: {
        title: "Fongicide préventif au stade épiaison — urgence maximale",
        actions: [
          "PRÉVENTIF OBLIGATOIRE si blast foliaire observé ≤ 14 jours avant épiaison : tricyclazole 75% WP à 400 g/ha au 50% épiaison. DAR 28 jours.",
          "Répéter 10–14 jours après si conditions humides persistent.",
          "Si blast du col déjà installé : traitement curatif peu efficace. Documenter la perte, alerter SAED/ANCAR.",
          "Alerter le conseiller SAED — blast du col souvent épidémique sur casier entier (coordination inter-parcelles)."
        ],
        costFcfaPerHa: 18000,
        delayBeforeHarvestDays: 28,
        ppeRequired: true,
        followupDays: 5
      },
      sources: ["SAED-ADRAO-pyriculariose-2020", "FAO-rice-blast-management"]
    },
    {
      id: "RIZ-VEG-FOREUR",
      crop: "riz",
      stages: ["vegetative", "stem_elongation"],
      symptom: "pests",
      season: "hivernage",
      regions: ["saint_louis", "matam"],
      severityMin: 0.3,
      scientificContext: "Chilo zacconius (Blesz.) et Maliarpha separatella (Rag.) — foreurs de tige riz. Carbofuran RETIRÉ : phaseout FAO/OMS (classe Ia OMS — toxicité aiguë humaine et faune aquatique). Trichogramma chilonis disponible via biocontrôle. Chlorpyrifos-ethyl : vérifier homologation CSP active.",
      diagnosis: "Foreurs de tige — talles centrales séchées ('cœur mort') ou 'panicules blanches' au stade épiaison. Orifices d'entrée visibles à la base des talles.",
      recommendation: {
        title: "Biocontrôle Trichogramma + gestion post-récolte",
        actions: [
          "BIOCONTRÔLE (premier choix) : Trichogramma chilonis à 100 000 individus/ha, 2 lâchers à 7 jours. Disponible via ISRA-DPV.",
          "CHIMIQUE (si biocontrôle non disponible) : chlorpyrifos-ethyl 5% GR à 20 kg/ha en rizière submergée. EPI strict. Vérifier homologation CSP active sur insah.cilss.int.",
          "CARBOFURAN INTERDIT : retiré des recommandations (phaseout FAO/OMS — toxicité class Ia).",
          "PROPHYLAXIE : récolter au ras du sol, broyer ou brûler chaumes immédiatement.",
          "ROTATION : jachère sèche 1 campagne tous les 3 ans sur parcelles fortement infestées."
        ],
        costFcfaPerHa: 14000,
        delayBeforeHarvestDays: 21,
        ppeRequired: true,
        followupDays: 7
      },
      sources: [
        "SAED-fiche-foreur-riz",
        "FAO-carbofuran-phaseout",
        "PROPAS-IITA-biocontrôle",
        "Liste-CSP-juillet-2023 (chlorpyrifos-ethyl — vérifier expiration)"
      ]
    },
    {
      id: "NIEBE-FLO-PESTS",
      crop: "niebe",
      stages: ["flowering", "fruiting"],
      symptom: "pests",
      season: "hivernage",
      regions: ["louga", "diourbel", "thies", "kaffrine", "tambacounda"],
      severityMin: 0.3,
      scientificContext: "Maruca vitrata (Geyer) [Crambidae] — perceur gousse. Perte jusqu'à 80% rendement niébé non traité (thèse TEL-Thèses 2019, Djibril Souna, WorldVeg/IITA). Mega lurothrips sjostedti — thrips floraux dominant en population (607 ind. vs 15 Maruca sur TN5-78, AJOL 2013/Niger). Parasitoïde potentiel Therophilus javanus (WorldVeg/IITA) identifié pour lutte biologique AOC. Variétés ISRA 2024 niébé homologuées : Pakau, Lisard, Léona, Thieye, Kelle, Sam.",
      diagnosis: "Complexe Maruca-thrips-pucerons sur niébé — fleurs percées tombées (Maruca), fleurs déformées (thrips), colonies noires pédoncules (pucerons). Peut causer 80% perte gousses si non traité.",
      recommendation: {
        title: "Programme traitement floraison 2–3 passages + biocontrôle",
        actions: [
          "1er traitement au stade 10% floraison : émamectine benzoate 1,9% EC à 250 mL/ha OU lambda-cyhalothrine 5% CS à 300 mL/ha. EN SOIRÉE obligatoirement (protéger abeilles pollinisatrices).",
          "2ème traitement à J+10 (50% floraison — stade critique) : deltaméthrine 12,5 g/ha OU chlorpyrifos-ethyl 480 EC à 800 mL/ha.",
          "BIOCONTRÔLE COMPLÉMENTAIRE (programme IITA/WorldVeg) : MaviNPV (baculovirus de M. vitrata) — efficacité validée terrain Niger (AJOL 2013) sur réduction population Maruca. Disponibilité : contacter IITA-Sénégal.",
          "ALTERNATIVE BIO 3 passages à 7 j : azadirachtine (neem) 10 g/L à 2,5 L/ha (préserve pollinisateurs).",
          "VARIÉTÉS TOLÉRANTES Maruca : IT97K-499-35, Mouride (ISRA). Nouvelles variétés ISRA 2024 : Pakau, Lisard, Léona — à tester selon zone."
        ],
        costFcfaPerHa: 10000,
        delayBeforeHarvestDays: 14,
        ppeRequired: true,
        followupDays: 7
      },
      sources: [
        "ISRA-fiche-niebe-2022",
        "TEL-Thèses-2019 (Djibril Souna — Maruca vitrata 80% perte + Therophilus javanus biocontrôle)",
        "AJOL-IJBCS-2013 (lutte intégrée Maruca + thrips Niger — données population + rendements)",
        "isra.sn/résultats-2024 (variétés niébé homologuées : Pakau, Lisard, Léona, Thieye, Kelle, Sam)"
      ]
    },
    {
      id: "NIEBE-ROOT-ROT",
      crop: "niebe",
      stages: ["germination", "vegetative"],
      symptom: "spots",
      season: "hivernage",
      regions: ["diourbel", "louga", "kaffrine", "thies", "fatick"],
      severityMin: 0.3,
      scientificContext: "Macrophomina phaseolina (Tassi) Goid. (charcoal rot) et Fusarium solani — champignons telluriques majeurs du niébé en zone Sahélienne. Favorisés par stress hydrique alternant avec humidité. Pertes 10–30% courantes mais rarement diagnostiquées en champ.",
      diagnosis: "Fonte de semis ou pourriture racinaire — germination irrégulière, plants flétrissant soudainement, racines brun-noirâtres ou grises (M. phaseolina = microclères noirs), collet brun creux.",
      recommendation: {
        title: "Traitement semences fongicide + rotation",
        actions: [
          "Traiter semences : thirame 75% WS à 3 g/kg OU metalaxyl-M + thirame (Apron Star 42 WS) à 3 g/kg.",
          "Semer sur sol bien ressuyé (éviter semis dans les 3 jours après forte pluie).",
          "ROTATION stricte : pas de niébé 2 années consécutives sur même parcelle.",
          "Apport matière organique compostée 3–5 t/ha (stimule microflore antagoniste Macrophomina).",
          "Symptômes présents : arracher et éliminer plants atteints, ne pas composter."
        ],
        costFcfaPerHa: 4000,
        delayBeforeHarvestDays: 0,
        ppeRequired: true,
        followupDays: 14
      },
      sources: ["ISRA-fiche-niebe-2022", "IITA-cowpea-diseases", "FAO-IPM-cowpea"]
    },
    {
      id: "TOM-FLO-MILDIOU",
      crop: "tomate",
      stages: ["flowering", "fruiting", "ripening"],
      symptom: "spots",
      season: "contreSaison",
      regions: ["dakar", "thies", "saint_louis"],
      severityMin: 0.2,
      scientificContext: "Phytophthora infestans (Mont.) de Bary (Oomycète). Atelier CERAAS/USAID 2022 : réactualisation fiches CDH — variétés tolérantes pour les Niayes. Métalaxyl-M + mancozèbe homologué CSP pour tomate (liste CSP juillet 2023).",
      diagnosis: "Mildiou tomate (P. infestans) — taches brunes huileuses reflets violacés, feutrage blanc-grisâtre revers feuilles, pourrissement tiges, odeur terre mouillée.",
      recommendation: {
        title: "Programme fongicide préventif-curatif alterné + pratiques culturales",
        actions: [
          "PRÉVENTIF (rosée matinale persistante) : oxychlorure de cuivre 50% WP à 2 kg/ha tous les 7 jours.",
          "CURATIF (premiers symptômes) : métalaxyl-M + mancozèbe (Ridomil Gold MZ ou équivalent CSP homologué) à 2,5 kg/ha. Action systémique. Alterner avec cuivre (résistance métalaxyl documentée). DAR 14 jours.",
          "PRATIQUES : tuteurage serré, suppression feuilles basses (0–30 cm), aucun arrosage foliaire après 16h.",
          "VARIÉTÉS TOLÉRANTES (atelier CERAAS-USAID 2022) : Mara F1, Ndiambour (ISRA-CDH), Padma F1.",
          "DAR métalaxyl-M + mancozèbe : 14 jours. Respecter strictement."
        ],
        costFcfaPerHa: 22000,
        delayBeforeHarvestDays: 14,
        ppeRequired: true,
        followupDays: 5
      },
      sources: [
        "CDH-Niayes-2021",
        "ISRA-USAID-atelier-CERAAS-fiches-maraichères-2022 (isra.sn)",
        "Liste-CSP-juillet-2023 (métalaxyl-M + mancozèbe homologué tomate)"
      ]
    },
    {
      id: "TOM-VEG-TYLCV",
      crop: "tomate",
      stages: ["vegetative", "flowering"],
      symptom: "yellow_leaves",
      season: "contreSaison",
      regions: ["dakar", "thies", "saint_louis", "louga"],
      severityMin: 0.4,
      scientificContext: "TYLCV (Begomovirus) transmis par Bemisia tabaci biotype B. Spiromésifène homologué CSP contre mouche blanche tomate (liste CSP juil 2023, réf. 0924-A1/In/05-22/APV-SAHEL — ACUXASR 36 EC, expire mai 2025). Acétamipride + lambda-cyhalothrine homologué contre B. tabaci sur tomate (réf. 0936/ACERO 83 EC — expire nov 2023 : VÉRIFIER RENOUVELLEMENT CSP).",
      diagnosis: "TYLCV — feuilles terminales enroulées en cuillère vers le haut, chlorose internervaire, nanisme, absence fructification. Distinguer de carence magnésium.",
      recommendation: {
        title: "Gestion vecteur + arrachage foyers + variétés résistantes Ty",
        actions: [
          "Arracher et détruire IMMÉDIATEMENT plants fortement atteints (> 50% feuilles enroulées).",
          "Traitement B. tabaci (plants voisins) : spiromésifène 240 SC à 400 mL/ha (CSP homologué, vérifier expiration) OU acétamipride 20% SP à 100 g/ha. Alterner.",
          "Plaques jaunes engluées à 40/ha pour monitoring vols B. tabaci.",
          "Filets anti-insectes 50 mesh en pépinière (stade le plus vulnérable : 0–30 JAS).",
          "VARIÉTÉS TY-RÉSISTANTES (gènes Ty-1/Ty-3) : Mongal F1, Lindo F1, Tanya F1. Disponibles distributeurs semences Dakar/Saint-Louis."
        ],
        costFcfaPerHa: 18000,
        delayBeforeHarvestDays: 14,
        ppeRequired: true,
        followupDays: 5
      },
      sources: [
        "CDH-Niayes-2022",
        "Liste-CSP-juillet-2023 (spiromésifène homologué mouche blanche)",
        "AVRDC-tomato-disease-guide"
      ]
    }
  ]
};

export const DEFAULT_CROPS = {
  version: 2,
  updatedAt: "2026-05-17",
  crops: [
    {
      id: "mais",
      labelFr: "Maïs",
      labelWo: "Mboq",
      season: "hivernage",
      scientificName: "Zea mays L.",
      cycle: "90 à 120 jours selon variété",
      zones: ["Thies", "Fatick", "Kaolack", "Kaffrine", "Tambacounda", "Kolda", "Sedhiou", "Ziguinchor"],
      diseases: ["Chenille légionnaire (FAW)", "Carence Azote/Zinc", "Maize Streak Virus"],
      stresses: ["Sécheresse en floraison", "Chaleur extrême > 35°C"],
      symptoms: ["Trous dans le cornet", "Feuilles jaunes en V", "Soies desséchées"],
      causes: ["Spodoptera frugiperda", "Volatilisation urée", "Déficit hydrique"],
      recommendations: ["Appliquer Bt kurstaki en soirée", "Fractionner l'urée 46%", "Irrigation de sauvetage 25mm"],
      goodPractices: "Semis précoce, paillage avec résidus, utilisation de variétés à haute vigueur juvénile (Noor 96, Obatampa)."
    },
    {
      id: "mil",
      labelFr: "Mil",
      labelWo: "Dugub",
      season: "hivernage",
      scientificName: "Pennisetum glaucum (L.) R. Br.",
      cycle: "75 à 90 jours (Souna 3, Thialack 2)",
      zones: ["Diourbel", "Louga", "Kaffrine", "Thies", "Fatick"],
      diseases: ["Striga hermonthica", "Mineuse de l'épi (Heliocheilus albipunctella)", "Mildiou du mil"],
      stresses: ["Sols pauvres dégradés", "Irrégularité des pluies"],
      symptoms: ["Pieds chétifs parasités", "Perforations sur épis", "Feutrage blanc sur feuilles"],
      causes: ["Graines de Striga en dormance", "Larves de noctuelles", "Sclerospora graminicola"],
      recommendations: ["Arrachage manuel avant floraison", "Lâchers de parasitoïdes Habrobracon hebetor", "Traitement semences Apron Star"],
      goodPractices: "Rotation stricte avec niébé ou arachide, apport de fumier composté (3 t/ha) pour réduire l'exsudation de strigolactones."
    },
    {
      id: "sorgho",
      labelFr: "Sorgho",
      labelWo: "Basi",
      season: "hivernage",
      scientificName: "Sorghum bicolor (L.) Moench",
      cycle: "105 à 120 jours (Faourou, Nguinthe)",
      zones: ["Tambacounda", "Kaffrine", "Kolda", "Sedhiou"],
      diseases: ["Striga hermonthica", "Charbon du sorgho", "Cécidomyie"],
      stresses: ["Stress hydrique tardif", "Sols argileux lourds"],
      symptoms: ["Nanisme", "Épis transformés en poudre noire", "Grains vides"],
      causes: ["Parasitisme racinaire", "Sporisorium sorghi", "Contarinia sorghicola"],
      recommendations: ["Rotation légumineuses", "Traitement de semences au thirame", "Pulvérisation d'azadirachtine (Neem)"],
      goodPractices: "Utilisation des variétés homologuées ISRA 2024 (Darou, Faourou), semis en lignes perpendiculaires à la pente."
    },
    {
      id: "riz",
      labelFr: "Riz",
      labelWo: "Ceeb",
      season: "hivernage",
      scientificName: "Oryza sativa L.",
      cycle: "110 à 130 jours (Sahel 108, NERICA)",
      zones: ["Saint-Louis", "Matam", "Ziguinchor", "Sedhiou"],
      diseases: ["Pyriculariose (Magnaporthe oryzae)", "Foreurs de tige (Chilo zacconius)", "Toxicité ferreuse"],
      stresses: ["Salinisation des sols", "Nuits fraîches en floraison"],
      symptoms: ["Lésions losangiques", "Cœur mort / Panicules blanches", "Feuilles bronzées"],
      causes: ["Excès d'azote et humidité", "Larves endophytes", "Excès de fer soluble (bas-fonds)"],
      recommendations: ["Fongicide tricyclazole 75% WP", "Lâchers de Trichogramma chilonis", "Drainage et apport de potasse"],
      goodPractices: "Respect du calendrier cultural SAED, nettoyage strict des diguettes et brûlage des chaumes après récolte."
    },
    {
      id: "arachide",
      labelFr: "Arachide",
      labelWo: "Gerte",
      season: "hivernage",
      scientificName: "Arachis hypogaea L.",
      cycle: "90 à 110 jours (55-437, Fleur 11)",
      zones: ["Thies", "Diourbel", "Fatick", "Kaolack", "Kaffrine", "Louga", "Kolda"],
      diseases: ["Rosette virale", "Cercosporiose (précoce/tardive)", "Contamination Aflatoxine"],
      stresses: ["Déficit pluviométrique en formation de gousses", "Sols lessivés acides"],
      symptoms: ["Plantes rabougries en bouquet", "Taches brunes avec halo jaune", "Gousses noircies/moisies"],
      causes: ["Pucerons Aphis craccivora", "Cercospora arachidicola", "Champignon Aspergillus flavus"],
      recommendations: ["Semis précoce avant le 15 juillet", "Fongicide cuivre ou chlorothalonil", "Application biofongicide AFLASAFE SN 01"],
      goodPractices: "Séchage sur table 'gousses en l'air' (recommandation HAL-INRAE 2025), vérification de la nodulation racinaire."
    },
    {
      id: "niebe",
      labelFr: "Niébé",
      labelWo: "Niebe",
      season: "hivernage",
      scientificName: "Vigna unguiculata (L.) Walp.",
      cycle: "60 à 75 jours (Pakau, Lisard, Léona)",
      zones: ["Louga", "Diourbel", "Thies", "Kaffrine", "Tambacounda"],
      diseases: ["Perceur de gousses (Maruca vitrata)", "Thrips floraux", "Pourriture charbonneuse"],
      stresses: ["Attaques d'insectes au stade floral", "Stress hydrique de début de cycle"],
      symptoms: ["Fleurs perforées tombées", "Déformation des gousses", "Collet noir et flétrissement"],
      causes: ["Larves de Maruca vitrata", "Megalurothrips sjostedti", "Macrophomina phaseolina"],
      recommendations: ["Application d'émamectine en soirée", "Biocontrôle MaviNPV", "Traitement semences Apron Star"],
      goodPractices: "Culture en association ou rotation avec le mil/sorgho, respect d'un programme de 2 à 3 pulvérisations ciblées à la floraison."
    },
    {
      id: "tomate",
      labelFr: "Tomate",
      labelWo: "Tamaate",
      season: "contreSaison",
      scientificName: "Solanum lycopersicum L.",
      cycle: "110 à 130 jours (Mara F1, Mongal F1)",
      zones: ["Dakar", "Thies", "Saint-Louis"],
      diseases: ["TYLCV (Mouche blanche)", "Mildiou (Phytophthora infestans)", "Nématodes à galles"],
      stresses: ["Chaleur excessive provoquant la coulure des fleurs", "Sols fatigués des Niayes"],
      symptoms: ["Feuilles en cuillère", "Taches d'huile violacées", "Galles sur racines"],
      causes: ["Bemisia tabaci biotype B", "Humidité matinale persistante", "Meloidogyne spp."],
      recommendations: ["Spiromésifène ou filets 50 mesh", "Ridomil Gold MZ (Métalaxyl)", "Rotation avec cultures nématicides (Crotalaire)"],
      goodPractices: "Tuteurage systématique, effeuillage basal pour aérer le collet, irrigation goutte-à-goutte stricte."
    },
    { id: "haricot_vert", labelFr: "Haricot vert", labelWo: "Ñebbe bu wert", season: "contreSaison", scientificName: "Phaseolus vulgaris L.", cycle: "60 jours", zones: ["Niayes"] },
    { id: "oignon", labelFr: "Oignon", labelWo: "Soble", season: "contreSaison", scientificName: "Allium cepa L.", cycle: "110 jours", zones: ["Vallée du Fleuve", "Niayes"] },
    { id: "chou", labelFr: "Chou", labelWo: "Suu", season: "contreSaison", scientificName: "Brassica oleracea L.", cycle: "90 jours", zones: ["Niayes"] },
    { id: "piment", labelFr: "Piment", labelWo: "Kaani", season: "contreSaison", scientificName: "Capsicum frutescens L.", cycle: "120 jours", zones: ["Niayes", "Casamance"] },
    { id: "gombo", labelFr: "Gombo", labelWo: "Kañja", season: "hivernage", scientificName: "Abelmoschus esculentus L.", cycle: "70 jours", zones: ["Toutes zones"] },
    { id: "aubergine", labelFr: "Aubergine", labelWo: "Jaxatu", season: "contreSaison", scientificName: "Solanum aethiopicum L.", cycle: "90 jours", zones: ["Niayes"] },
    { id: "carotte", labelFr: "Carotte", labelWo: "Karot", season: "contreSaison", scientificName: "Daucus carota L.", cycle: "90 jours", zones: ["Niayes"] },
    { id: "laitue", labelFr: "Laitue", labelWo: "Salaat", season: "contreSaison", scientificName: "Lactuca sativa L.", cycle: "45 jours", zones: ["Niayes"] },
    { id: "pasteque", labelFr: "Pastèque", labelWo: "Xaal", season: "contreSaison", scientificName: "Citrullus lanatus", cycle: "85 jours", zones: ["Bassin Arachidier"] },
    { id: "patate_douce", labelFr: "Patate douce", labelWo: "Patasa", season: "contreSaison", scientificName: "Ipomoea batatas", cycle: "120 jours", zones: ["Niayes"] },
    { id: "pomme_de_terre", labelFr: "Pomme de terre", labelWo: "Pompiteer", season: "contreSaison", scientificName: "Solanum tuberosum", cycle: "90 jours", zones: ["Niayes"] },
    { id: "manioc", labelFr: "Manioc", labelWo: "Ñambi", season: "permanent", scientificName: "Manihot esculenta", cycle: "12 mois", zones: ["Toutes zones"] },
    { id: "mangue", labelFr: "Mangue", labelWo: "Mango", season: "permanent", scientificName: "Mangifera indica", cycle: "Annuel", zones: ["Casamance", "Niayes"] },
    { id: "anacarde", labelFr: "Anacarde", labelWo: "Darkase", season: "permanent", scientificName: "Anacardium occidentale", cycle: "Annuel", zones: ["Casamance", "Fatick"] },
    { id: "banane", labelFr: "Banane", labelWo: "Banaana", season: "permanent", scientificName: "Musa spp.", cycle: "Annuel", zones: ["Tambacounda", "Casamance"] },
    { id: "canne_a_sucre", labelFr: "Canne à sucre", labelWo: "Kan", season: "permanent", scientificName: "Saccharum officinarum", cycle: "Annuel", zones: ["Richard Toll"] },
    { id: "moringa", labelFr: "Moringa", labelWo: "Nébédaay", season: "permanent", scientificName: "Moringa oleifera", cycle: "Permanent", zones: ["Toutes zones"] }
  ]
};

export const DEFAULT_SUPPLIERS = [
  {
    id: "sup-1",
    name: "SEN-AGRO DISTRIBUTION",
    type: "Intrants & Semences",
    zone: "Niayes / Dakar",
    phone: "+221 77 123 45 67",
    address: "Km 11 Route de Rufisque, Dakar",
    lat: 14.7333,
    lng: -17.3333,
    products: ["Semences maraîchères certifiées", "Engrais NPK 10-10-20", "Produits phytosanitaires CSP"]
  },
  {
    id: "sup-2",
    name: "COPEOL SÉNÉGAL",
    type: "Intrants Oléagineux",
    zone: "Bassin Arachidier (Kaolack/Fatick)",
    phone: "+221 77 234 56 78",
    address: "Quartier Escale, Kaolack",
    lat: 14.1500,
    lng: -16.2500,
    products: ["Semences arachide 55-437", "Fongicides traitement de semence", "Engrais 6-20-10"]
  },
  {
    id: "sup-3",
    name: "CASAMANCE AGRO-TECH",
    type: "Matériel & Intrants",
    zone: "Casamance (Ziguinchor/Kolda)",
    phone: "+221 77 345 67 89",
    address: "Boulevard 54, Ziguinchor",
    lat: 12.5833,
    lng: -16.2667,
    products: ["Kits d'irrigation goutte-à-goutte", "Semences riz NERICA", "Bio-pesticides Neem"]
  },
  {
    id: "sup-4",
    name: "SAED INTRANTS VALLÉE",
    type: "Semences Riz & Engrais",
    zone: "Vallée du Fleuve (Saint-Louis/Matam)",
    phone: "+221 77 456 78 90",
    address: "Route de Khor, Saint-Louis",
    lat: 16.0333,
    lng: -16.4833,
    products: ["Semences riz Sahel 108", "Urée 46%", "Tricyclazole 75% WP"]
  }
];

export const DEFAULT_EQUIPMENTS = [
  {
    id: "eq-1",
    name: "Kit d'irrigation goutte-à-goutte (500m²)",
    category: "Irrigation",
    zone: "Toutes zones",
    supplier: "SEN-AGRO DISTRIBUTION",
    priceFcfa: 150000,
    rentalAvailable: false,
    description: "Kit complet avec gaines, goutteurs intégrés, filtre et raccords. Optimisation hydrique sous stress sahélien."
  },
  {
    id: "eq-2",
    name: "Motoculteur 12 CV avec fraise",
    category: "Mécanisation",
    zone: "Vallée du Fleuve / Niayes",
    supplier: "SAED INTRANTS VALLÉE",
    priceFcfa: 1200000,
    rentalAvailable: true,
    rentalPriceFcfaPerDay: 25000,
    description: "Idéal pour la préparation des sols lourds et rizières. Faible consommation de carburant."
  },
  {
    id: "eq-3",
    name: "Pompe solaire immergée 500W",
    category: "Pompage Solaire",
    zone: "Bassin Arachidier / Tambacounda",
    supplier: "CASAMANCE AGRO-TECH",
    priceFcfa: 350000,
    rentalAvailable: false,
    description: "Pompe hybride solaire/secteur pour puits ou forage jusqu'à 30m. Débit 3m³/h."
  },
  {
    id: "eq-4",
    name: "Semoir manuel de précision mono-rang",
    category: "Semis",
    zone: "Bassin Arachidier",
    supplier: "COPEOL SÉNÉGAL",
    priceFcfa: 45000,
    rentalAvailable: true,
    rentalPriceFcfaPerDay: 5000,
    description: "Permet un semis régulier du mil, sorgho et maïs, avec trémie de fertilisation couplée."
  }
];

export const DEFAULT_INSTITUTIONS = [
  {
    id: "inst-1",
    name: "ISRA (Institut Sénégalais de Recherches Agricoles)",
    role: "Recherche & Semences homologuées",
    contactPerson: "Dr. Diop (CNRA Bambey)",
    phone: "+221 33 859 17 00",
    email: "contact@isra.sn",
    zone: "National / Bambey / Saint-Louis",
    description: "Développement de variétés à cycle court et tolérantes à la sécheresse (arachide, mil, riz, sorgho, niébé)."
  },
  {
    id: "inst-2",
    name: "DPV (Direction de la Protection des Végétaux)",
    role: "Homologation CSP & Surveillance phytosanitaire",
    contactPerson: "Division Biocontrôle",
    phone: "+221 33 836 13 14",
    email: "dpv@agriculture.gouv.sn",
    zone: "National / Dakar",
    description: "Surveillance des ravageurs de quarantaine (FAW, mouches des fruits), lâchers de parasitoïdes (Habrobracon hebetor)."
  },
  {
    id: "inst-3",
    name: "ANCAR (Agence Nationale de Conseil Agricole et Rural)",
    role: "Vulgarisation & Encadrement paysan",
    contactPerson: "Coordination Bassin Arachidier",
    phone: "+221 33 827 50 10",
    email: "ancar@ancar.sn",
    zone: "Toutes régions",
    description: "Mise en relation des smallholders avec les technologies agricoles et diffusion des bonnes pratiques."
  },
  {
    id: "inst-4",
    name: "SAED",
    role: "Aménagement & Développement Vallée du Fleuve",
    contactPerson: "Direction Technique Saint-Louis",
    phone: "+221 33 961 10 70",
    email: "saed@saed.sn",
    zone: "Vallée du Fleuve Sénégal",
    description: "Gestion des périmètres irrigués, encadrement de la filière rizicole et distribution d'intrants."
  }
];
