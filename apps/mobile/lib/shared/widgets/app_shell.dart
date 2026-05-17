import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/connectivity_service.dart';
import '../../core/services/alert_engine.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/catalog_service.dart';
import '../../core/utils/haptics.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/parcels/presentation/parcels_providers.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import 'parcel_picker_sheet.dart';
import '../../features/dashboard/presentation/tour_provider.dart';

/// Bottom shell with 5 destinations and a central docked FAB "Capturer".
///
/// Layout:
///   [ Dashboard ] [ Parcelles ]  ⊕ FAB  [ Alertes ] [ Profil ]
///
/// The FAB is the primary CTA of the app: anywhere in the shell, one tap
/// opens the parcel picker sheet to start a field observation. It does not
/// own a route — the picker sheet pushes to `/observation/:parcelId`.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const tabs = <_ShellTab>[
    _ShellTab(Routes.dashboard, Icons.home_rounded, 'Accueil'),
    _ShellTab(Routes.parcels, Icons.grass_rounded, 'Parcelles'),
    _ShellTab(Routes.alerts, Icons.notifications_active_rounded, 'Alertes'),
    _ShellTab(Routes.settings, Icons.person_rounded, 'Profil'),
  ];

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int? _activeIndex(String location) {
    for (int i = 0; i < AppShell.tabs.length; i++) {
      if (location.startsWith(AppShell.tabs[i].route)) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Refresh alerts when parcels change (add/edit/delete).
    ref.listen<List>(parcelsProvider, (_, __) {
      ref.read(alertEngineProvider.notifier).refresh();
    });

    final loc = GoRouterState.of(context).matchedLocation;
    final active = _activeIndex(loc);

    return Scaffold(
      extendBody: false,
      drawer: const _AppDrawer(),
      body: Column(
        children: [
          const _HydrationBanner(),
          const _SyncBanner(),
          const _TourBanner(),
          Expanded(child: widget.child),
        ],
      ),
      floatingActionButton: _CaptureFab(
        onPressed: () {
          Haptics.light();
          final parcels = ref.read(parcelsProvider);
          showParcelPickerSheet(context, parcels);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _ShellBottomBar(
        tabs: AppShell.tabs,
        activeIndex: active,
        onTap: (i) {
          Haptics.selection();
          context.go(AppShell.tabs[i].route);
        },
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value?.user;
    
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'Technicien'),
            accountEmail: Text(user?.phone ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'T',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          ListTile(
            leading: const Icon(Icons.alt_route_rounded),
            title: const Text('Planificateur de tournée'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.routePlanner);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_rounded),
            title: const Text('Producteurs'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.producers);
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_rounded),
            title: const Text('Diagnostics Experts'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.diagnosticHistory);
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded),
            title: const Text('Demandes d\'Avis Expert'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.expertRequests);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_rounded),
            title: const Text('Mes Rapports'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.reports);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded),
            title: const Text('Portefeuille & Crédits'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.wallet);
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: const Text('Catalogue Agronomique'),
            onTap: () {
              Navigator.pop(context);
              context.push(Routes.catalog);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              context.go(Routes.settings);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Aide & Support'),
            onTap: () {
              // TODO: Implement help
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Persistent banner shown only when sync is active, queued, errored, or offline.
/// Silent (zero height) when everything is up-to-date and online.
class _SyncBanner extends ConsumerWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncServiceProvider);
    final net = ref.watch(networkStatusProvider).value ?? NetworkStatus.online;

    final offline = net == NetworkStatus.offline;
    final syncing = sync.state == SyncState.syncing;
    final error = sync.state == SyncState.error;
    final pending = sync.pending > 0;

    if (!offline && !syncing && !error && !pending) {
      return const SizedBox.shrink();
    }

    Color color;
    IconData icon;
    String label;
    if (error) {
      color = AppColors.danger;
      icon = Icons.error_outline_rounded;
      label = 'Erreur de synchronisation — nouvelle tentative au retour du réseau';
    } else if (offline) {
      color = AppColors.warning;
      icon = Icons.cloud_off_rounded;
      label = pending
          ? 'Hors ligne — ${sync.pending} action(s) en attente'
          : 'Hors ligne — vos données seront synchronisées au retour';
    } else if (syncing) {
      color = AppColors.info;
      icon = Icons.sync_rounded;
      label = 'Synchronisation en cours…';
    } else {
      color = AppColors.warning;
      icon = Icons.cloud_queue_rounded;
      label = '${sync.pending} action(s) en attente';
    }

    return Material(
      color: color.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (error)
                TextButton(
                  onPressed: () =>
                      ref.read(syncServiceProvider.notifier).flush(),
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Réessayer'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab(this.route, this.icon, this.label);
  final String route;
  final IconData icon;
  final String label;
}

/// 4 destinations split around a notch. Index 0/1 left, 2/3 right.
class _ShellBottomBar extends StatelessWidget {
  const _ShellBottomBar({
    required this.tabs,
    required this.activeIndex,
    required this.onTap,
  });

  final List<_ShellTab> tabs;
  final int? activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 72,
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(child: _ShellNavItem(
            tab: tabs[0],
            selected: activeIndex == 0,
            onTap: () => onTap(0),
          )),
          Expanded(child: _ShellNavItem(
            tab: tabs[1],
            selected: activeIndex == 1,
            onTap: () => onTap(1),
          )),
          // Spacer reserved for the FAB notch.
          const SizedBox(width: 64),
          Expanded(child: _ShellNavItem(
            tab: tabs[2],
            selected: activeIndex == 2,
            onTap: () => onTap(2),
          )),
          Expanded(child: _ShellNavItem(
            tab: tabs[3],
            selected: activeIndex == 3,
            onTap: () => onTap(3),
          )),
        ],
      ),
    );
  }
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textMutedOf(context);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(tab.icon, size: 24, color: color),
          const SizedBox(height: 2),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          if (selected) ...[
            const SizedBox(height: 2),
            Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CaptureFab extends StatelessWidget {
  const _CaptureFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 60,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: 'Capturer une visite',
        child: const Icon(Icons.add_a_photo_rounded, size: 26),
      ),
    );
  }
}
class _TourBanner extends ConsumerWidget {
  const _TourBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tour = ref.watch(tourProvider);
    if (!tour.isActive) return const SizedBox.shrink();

    final isDone = tour.isCompleted;
    final color = isDone ? AppColors.success : AppColors.primary;

    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: () => context.push(Routes.routePlanner),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone ? Icons.check_circle_rounded : Icons.alt_route_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDone ? 'BRAVO !' : 'TOURNEE ACTIVE',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        isDone 
                          ? 'Toutes les parcelles ont été visitées.' 
                          : 'Progression : ${tour.visited} / ${tour.total} parcelles visitées',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (isDone) {
                      ref.read(tourProvider.notifier).cancel();
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Annuler la tournée ?'),
                        content: const Text('Voulez-vous vraiment arrêter la tournée en cours ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Non'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(tourProvider.notifier).cancel();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Oui, arrêter', style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(isDone ? 'QUITTER' : 'ANNULER', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HydrationBanner extends ConsumerStatefulWidget {
  const _HydrationBanner();

  @override
  ConsumerState<_HydrationBanner> createState() => _HydrationBannerState();
}

class _HydrationBannerState extends ConsumerState<_HydrationBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(catalogServiceProvider.notifier);
      final syncNotifier = ref.read(syncServiceProvider.notifier);
      notifier.hydrate();
      syncNotifier.reconcileAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogServiceProvider);

    if (state.isCompleted || !state.isHydrating) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '1ère connexion : Téléchargement des données hors-ligne...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${(state.progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.statusText,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
