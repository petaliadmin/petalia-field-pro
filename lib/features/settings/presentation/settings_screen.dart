import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/settings_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/tile_cache_service.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authStateProvider).value?.user;
    final sync = ref.watch(syncServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      (user?.name.isNotEmpty ?? false)
                          ? user!.name[0].toUpperCase()
                          : 'T',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'Technicien',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(user?.phone ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Appearance section
            _SectionLabel(label: 'Apparence'),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _ChoiceTile(
                    icon: Icons.brightness_6_rounded,
                    title: 'Thème',
                    value: switch (settings.themeMode) {
                      ThemeMode.light => 'Clair',
                      ThemeMode.dark => 'Sombre',
                      _ => 'Système',
                    },
                    onTap: () => _showThemePicker(context, ref, settings),
                  ),
                  const Divider(height: 1, indent: 56),
                  _ChoiceTile(
                    icon: Icons.translate_rounded,
                    title: 'Langue',
                    value: switch (settings.language) {
                      AppLanguage.fr => 'Français',
                      AppLanguage.en => 'Anglais',
                      AppLanguage.wo => 'Wolof',
                    },
                    onTap: () => _showLanguagePicker(context, ref, settings),
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.text_fields_rounded, size: 20, color: AppColors.primary),
                    ),
                    title: const Text('Grand texte', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Agrandit tous les textes', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    value: settings.largeText,
                    activeTrackColor: AppColors.primary,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setLargeText(v),
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.wb_sunny_rounded, size: 20, color: AppColors.primary),
                    ),
                    title: const Text('Mode terrain', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Contraste renforcé pour le plein soleil', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    value: settings.highContrast,
                    activeTrackColor: AppColors.primary,
                    onChanged: (v) => ref.read(settingsProvider.notifier).setHighContrast(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sync & data
            _SectionLabel(label: 'Sauvegarde et données'),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _ChoiceTile(
                    icon: Icons.sync_rounded,
                    title: 'Sauvegarde automatique',
                    value: '${settings.syncFrequencyMinutes} min',
                    onTap: () => _showSyncFreqPicker(context, ref, settings),
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.cloud_queue_rounded,
                    title: 'En attente de sauvegarde',
                    value: '${sync.pending} élément${sync.pending > 1 ? 's' : ''}',
                  ),
                  if (sync.lastSync != null) ...[
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.access_time_rounded,
                      title: 'Dernière sauvegarde',
                      value: _formatLastSync(sync.lastSync!),
                    ),
                  ],
                  const Divider(height: 1, indent: 56),
                  _TileCacheSection(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notifications
            _SectionLabel(label: 'Notifications'),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      size: 20, color: AppColors.primary),
                ),
                title: const Text('Notifications push',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                value: settings.notifications,
                activeTrackColor: AppColors.primary,
                onChanged: (v) =>
                    ref.read(settingsProvider.notifier).setNotifications(v),
              ),
            ),
            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Se déconnecter ?'),
                      content: const Text(
                          'Les éléments en attente de synchronisation seront conservés et envoyés à votre prochaine connexion.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler')),
                        FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Se déconnecter')),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go(Routes.login);
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                label: const Text('Se déconnecter',
                    style: TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Petalia Field Pro v1.0.0',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------- Pickers ---------------

  void _showThemePicker(
      BuildContext context, WidgetRef ref, AppSettings current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Choisir le thème',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(
                  mode == current.themeMode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: mode == current.themeMode
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(switch (mode) {
                  ThemeMode.system => 'Réglage du système',
                  ThemeMode.light => 'Clair',
                  ThemeMode.dark => 'Sombre',
                }),
                onTap: () {
                  ref.read(settingsProvider.notifier).setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(
      BuildContext context, WidgetRef ref, AppSettings current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Choisir la langue',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final lang in AppLanguage.values)
              ListTile(
                leading: Icon(
                  lang == current.language
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: lang == current.language
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(switch (lang) {
                  AppLanguage.fr => 'Français',
                  AppLanguage.en => 'Anglais',
                  AppLanguage.wo => 'Wolof',
                }),
                onTap: () {
                  ref.read(settingsProvider.notifier).setLanguage(lang);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSyncFreqPicker(
      BuildContext context, WidgetRef ref, AppSettings current) {
    final options = [5, 10, 15, 30, 60];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sauvegarde automatique',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final m in options)
              ListTile(
                leading: Icon(
                  m == current.syncFrequencyMinutes
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: m == current.syncFrequencyMinutes
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(m < 60 ? 'Toutes les $m minutes' : 'Toutes les heures'),
                onTap: () {
                  ref.read(settingsProvider.notifier).setSyncFrequency(m);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _formatLastSync(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    return 'Il y a ${diff.inHours} h';
  }
}

// ---------------------------------------------------------------------------
// Helper tiles
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: Text(value,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14)),
    );
  }
}

class _TileCacheSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheSize = ref.watch(tileCacheSizeMbProvider);
    final cacheStats = ref.watch(tileCacheStatsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.map_rounded, size: 20, color: AppColors.primary),
          ),
          title: const Text('Cartes hors-ligne',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: cacheSize.when(
            data: (mb) => Text(
              mb < 1 ? 'Moins de 1 Mo' : '${mb.toStringAsFixed(1)} Mo',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            loading: () => const Text('Calcul…',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            error: (_, __) => const Text('—',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          trailing: cacheStats.when(
            data: (stats) {
              final total = stats.values.fold<int>(0, (a, b) => a + b);
              return Text(
                '$total tuiles',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        const Divider(height: 1, indent: 56),
        ListTile(
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Supprimer le cache carte ?'),
                content: const Text(
                  'Les tuiles seront re-téléchargées automatiquement lors de votre prochaine navigation sur la carte.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await TileCacheService.clearAllCaches();
              ref.invalidate(tileCacheSizeMbProvider);
              ref.invalidate(tileCacheStatsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache carte supprimé')),
                );
              }
            }
          },
          leading: Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                size: 20, color: AppColors.danger),
          ),
          title: const Text('Supprimer le cache carte',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: const Text('Libérer de l\'espace sur votre téléphone',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
