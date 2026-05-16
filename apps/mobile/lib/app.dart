import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/localization/fallback_localizations_delegates.dart';
import 'core/services/light_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/tile_cache_service.dart';
import 'l10n/gen/app_localizations.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'core/utils/messenger_utils.dart';

class PetaliaApp extends ConsumerStatefulWidget {
  const PetaliaApp({super.key});

  @override
  ConsumerState<PetaliaApp> createState() => _PetaliaAppState();
}

class _PetaliaAppState extends ConsumerState<PetaliaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Surface widget errors in a controlled banner instead of crashing the app.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Une erreur est survenue dans l\'interface.\n${details.exceptionAsString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Best-effort cleanup; safe to await as the engine is tearing down.
      TileCacheService.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    final ambientLight = ref.watch(ambientLightProvider).value ?? 0.0;

    // Détermine si on active le mode haute visibilité (Plein Soleil).
    // Priorité au toggle manuel, sinon automatique si activé.
    final bool effectiveHighContrast = settings.highContrast || 
        (settings.autoHighContrast && ambientLight >= LightService.kSunThreshold);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(highContrast: effectiveHighContrast),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('wo'),
        Locale('ff'),
      ],
      // Order matters: Wolof fallbacks must come BEFORE the Global delegates
      // so they are queried first for `Locale('wo')`. The Global delegates
      // handle fr/en, the Wolof delegates borrow the French chrome strings.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        WolofMaterialLocalizationsDelegate(),
        WolofCupertinoLocalizationsDelegate(),
        WolofWidgetsLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(
              AppTheme.textScale(settings.largeText),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
