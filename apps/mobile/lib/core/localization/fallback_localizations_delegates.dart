import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter ne fournit pas de [MaterialLocalizations] / [CupertinoLocalizations]
/// pour le **wolof** (`wo`) ni le **pulaar/fula** (`ff`). Sans ces delegates,
/// tous les widgets Material (Scaffold, TextField, DatePicker, etc.) crashent
/// avec une assertion `_MaterialLocalizationsScope` dès que la locale active
/// est `wo` ou `ff`.
///
/// Stratégie : pour les locales non supportées par Flutter, on **emprunte
/// les chaînes françaises** comme fallback de chrome système. C'est
/// culturellement correct au Sénégal et dans toute l'Afrique francophone
/// (le français est la langue administrative) et préserve les strings
/// applicatives en wolof / pulaar (gérées par l'app via ARB et le catalog
/// `assets/data/symptoms.json`).
///
/// Refactor 2026-05-02 : ajout du support `ff` (Pulaar). Toutes les
/// locales sans support natif Flutter passent par le même fallback `fr`.
const _fallbackLanguageCodes = {'wo', 'ff'};

bool _isFallback(Locale locale) =>
    _fallbackLanguageCodes.contains(locale.languageCode);

class WolofMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const WolofMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isFallback(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return GlobalMaterialLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(WolofMaterialLocalizationsDelegate old) => false;
}

class WolofCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const WolofCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isFallback(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return GlobalCupertinoLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(WolofCupertinoLocalizationsDelegate old) => false;
}

class WolofWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const WolofWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => _isFallback(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    return GlobalWidgetsLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(WolofWidgetsLocalizationsDelegate old) => false;
}
