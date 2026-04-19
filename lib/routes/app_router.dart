import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../core/constants/app_constants.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';

import '../features/alerts/presentation/alerts_screen.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/checklist/presentation/checklist_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/observation/presentation/observation_screen.dart';
import '../features/parcels/domain/parcel.dart';
import '../features/parcels/presentation/add_parcel_screen.dart';
import '../features/parcels/presentation/parcel_details_screen.dart';
import '../features/parcels/presentation/parcels_list_screen.dart';
import '../features/recommendations/presentation/recommendations_screen.dart';
import '../features/reports/presentation/report_preview_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/route_planner/presentation/route_planner_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../shared/widgets/app_shell.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authed = ref.read(authStateProvider).value?.isAuthenticated ?? false;
      final loc = state.matchedLocation;
      final goingToAuth = loc == Routes.splash || loc == Routes.login || loc == Routes.register;
      final goingToOnboarding = loc == Routes.onboarding;
      if (!authed && !goingToAuth && !goingToOnboarding) return Routes.login;
      if (authed && loc == Routes.login) {
        final seen = Hive.box(AppConstants.boxSettings).get(AppConstants.kOnboardingCompleted, defaultValue: false) as bool;
        return seen ? Routes.dashboard : Routes.onboarding;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: Routes.dashboard, pageBuilder: _fade(const DashboardScreen())),
          GoRoute(path: Routes.parcels, pageBuilder: _fade(const ParcelsListScreen())),
          GoRoute(path: Routes.settings, pageBuilder: _fade(const SettingsScreen())),
        ],
      ),
      GoRoute(path: Routes.map, builder: (_, __) => const MapScreen()),
      GoRoute(path: Routes.alerts, builder: (_, __) => const AlertsScreen()),
      GoRoute(path: Routes.addParcel, builder: (_, __) => const AddParcelScreen()),
      GoRoute(path: Routes.editParcel, builder: (_, s) {
        final parcel = s.extra as Parcel;
        return AddParcelScreen(existing: parcel);
      }),
      GoRoute(
        path: '${Routes.parcelDetails}/:id',
        builder: (_, s) => ParcelDetailsScreen(parcelId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.observation}/:parcelId',
        builder: (_, s) => ObservationScreen(parcelId: s.pathParameters['parcelId']!),
      ),
      GoRoute(
        path: '${Routes.checklist}/:parcelId',
        builder: (_, s) => ChecklistScreen(parcelId: s.pathParameters['parcelId']!),
      ),
      GoRoute(
        path: '${Routes.recommendations}/:parcelId',
        builder: (_, s) => RecommendationsScreen(parcelId: s.pathParameters['parcelId']!),
      ),
      GoRoute(path: Routes.reports, builder: (_, __) => const ReportsScreen()),
      GoRoute(path: Routes.reportPreview, builder: (_, s) {
        final parcelId = (s.extra as Map?)?['parcelId'] as String? ?? '';
        return ReportPreviewScreen(parcelId: parcelId);
      }),
      GoRoute(path: Routes.routePlanner, builder: (_, __) => const RoutePlannerScreen()),
    ],
  );
});

Page<dynamic> Function(BuildContext, GoRouterState) _fade(Widget child) {
  return (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (_, animation, __, c) =>
            FadeTransition(opacity: animation, child: c),
      );
}
