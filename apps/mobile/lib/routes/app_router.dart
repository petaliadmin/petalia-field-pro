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
import '../features/auth/presentation/register_otp_screen.dart';
import '../features/auth/presentation/register_pin_screen.dart';
import '../features/auth/presentation/biometric_setup_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/checklist/presentation/checklist_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/map/presentation/map_screen.dart';
import '../features/observation/presentation/observation_screen.dart';
import '../features/parcels/domain/parcel.dart';
import '../features/parcels/presentation/add_parcel_screen.dart';
import '../features/parcels/presentation/parcel_details_screen.dart';
import '../features/parcels/presentation/visit_details_screen.dart';
import '../features/parcels/presentation/parcels_list_screen.dart';
import '../features/observation/presentation/diagnostic_history_screen.dart';
import '../features/producers/presentation/producers_list_screen.dart';
import '../features/producers/presentation/producer_detail_screen.dart';
import '../features/recommendations/presentation/recommendations_screen.dart';
import '../features/reports/presentation/report_preview_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/route_planner/presentation/route_planner_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/wallet/presentation/credit_purchase_screen.dart';
import '../features/wallet/presentation/wallet_screen.dart';
import '../features/wallet/presentation/transfer_screen.dart';
import '../features/wallet/presentation/qr_code_screen.dart';
import '../shared/widgets/app_shell.dart';
import 'route_names.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = AuthRefreshListenable(ref);
  
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final authed = ref.read(authStateProvider).value?.isAuthenticated ?? false;
      final loc = state.matchedLocation;
      final goingToAuth = loc == Routes.splash || 
          loc == Routes.login || 
          loc == Routes.register ||
          loc == Routes.registerOtp ||
          loc == Routes.registerPin ||
          loc == Routes.biometricSetup;
      final goingToOnboarding = loc == Routes.onboarding;
      if (!authed && !goingToAuth && !goingToOnboarding) {
        final registered = ref.read(hasRegisteredUserProvider);
        return registered ? Routes.login : Routes.register;
      }
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
      GoRoute(path: Routes.registerOtp, builder: (_, __) => const RegisterOtpScreen()),
      GoRoute(path: Routes.registerPin, builder: (_, __) => const RegisterPinScreen()),
      GoRoute(path: Routes.biometricSetup, builder: (_, __) => const BiometricSetupScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: Routes.dashboard, pageBuilder: _fade(const DashboardScreen())),
          GoRoute(path: Routes.parcels, pageBuilder: _fade(const ParcelsListScreen())),
          GoRoute(path: Routes.alerts, pageBuilder: _fade(const AlertsScreen())),
          GoRoute(path: Routes.settings, pageBuilder: _fade(const SettingsScreen())),
        ],
      ),
      GoRoute(path: Routes.map, builder: (_, __) => const MapScreen()),
      GoRoute(
        path: Routes.addParcel,
        pageBuilder: _slideUp(const AddParcelScreen()),
      ),
      GoRoute(
        path: Routes.editParcel,
        pageBuilder: (context, state) => _slideUp(
          AddParcelScreen(existing: state.extra as Parcel),
        )(context, state),
      ),
      GoRoute(
        path: '${Routes.parcelDetails}/:id',
        builder: (_, s) => ParcelDetailsScreen(parcelId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.observation}/:parcelId',
        pageBuilder: (context, state) => _slideUp(
          ObservationScreen(parcelId: state.pathParameters['parcelId']!),
        )(context, state),
      ),
      GoRoute(
        path: '${Routes.checklist}/:parcelId',
        pageBuilder: (context, state) => _slideUp(
          ChecklistScreen(parcelId: state.pathParameters['parcelId']!),
        )(context, state),
      ),
      GoRoute(
        path: '${Routes.recommendations}/:parcelId',
        pageBuilder: (context, state) => _slideUp(
          RecommendationsScreen(parcelId: state.pathParameters['parcelId']!),
        )(context, state),
      ),
      GoRoute(path: Routes.reports, builder: (_, __) => const ReportsScreen()),
      GoRoute(
        path: Routes.reportPreview,
        pageBuilder: (context, state) {
          final extra = state.extra as Map?;
          final parcelId = extra?['parcelId'] as String? ?? '';
          final filePath = extra?['filePath'] as String?;
          return _slideUp(ReportPreviewScreen(parcelId: parcelId, filePath: filePath))(context, state);
        },
      ),
      GoRoute(
        path: Routes.routePlanner,
        builder: (context, state) {
          final targetId = state.uri.queryParameters['parcelId'];
          return RoutePlannerScreen(targetParcelId: targetId);
        },
      ),
      GoRoute(
        path: '${Routes.visitDetails}/:id',
        pageBuilder: (context, state) => _slideUp(
          VisitDetailsScreen(visitId: state.pathParameters['id']!),
        )(context, state),
      ),
      GoRoute(
        path: Routes.wallet,
        pageBuilder: _slideUp(const WalletScreen()),
      ),
      GoRoute(
        path: Routes.walletRecharge,
        pageBuilder: _slideUp(const CreditPurchaseScreen()),
      ),
      GoRoute(
        path: Routes.walletTransfer,
        pageBuilder: _slideUp(const TransferScreen()),
      ),
      GoRoute(
        path: Routes.walletQr,
        pageBuilder: _slideUp(const QrCodeScreen()),
      ),
      GoRoute(
        path: Routes.producers,
        builder: (_, __) => const ProducersListScreen(),
      ),
      GoRoute(
        path: '${Routes.producers}/:id',
        builder: (_, s) => ProducerDetailScreen(producerId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.diagnosticHistory,
        builder: (_, __) => const DiagnosticHistoryScreen(),
      ),
    ],
  );
});

/// Tab-style transition: 250ms cross-fade. Used for the bottom-nav
/// destinations inside the [ShellRoute] — feels lateral, no displacement.
Page<dynamic> Function(BuildContext, GoRouterState) _fade(Widget child) {
  return (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, __, c) =>
            FadeTransition(opacity: animation, child: c),
      );
}

/// Modal-style transition: 250ms slide from bottom + fade. Used for
/// task-flow screens pushed on top of the shell (capture, observation,
/// recommendations, report preview…) — the upward motion signals
/// "temporary side trip" in line with the iOS / Material modal idiom.
Page<dynamic> Function(BuildContext, GoRouterState) _slideUp(Widget child) {
  return (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (_, animation, __, c) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: c),
          );
        },
      );
}

/// Listenable that triggers GoRouter refresh when auth state changes.
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
