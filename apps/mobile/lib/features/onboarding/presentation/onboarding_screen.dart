import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/utils/haptics.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_colors.dart';

/// Onboarding flow — shown once after first login (gated by
/// [AppConstants.kOnboardingCompleted] in the settings box).
///
/// Page 0 is a **language picker** (P4.3) so the rest of the onboarding
/// — and the entire app — renders in the user's preferred language from
/// the very first screen they fully control. The picker uses each
/// language's endonym (its own name written in itself), which is the only
/// way a non-French-speaker can self-identify their language in a UI that
/// is currently displayed in French.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Pages 1..N are the existing feature intros. Page 0 is the language
  // picker rendered separately (it needs ref/state).
  static const _featurePages = [
    _OnboardingFeature(
      icon: Icons.add_location_alt_rounded,
      title: 'Ajoutez vos parcelles',
      subtitle:
          'Dessinez vos champs sur la carte ou marchez les limites avec le GPS',
    ),
    _OnboardingFeature(
      icon: Icons.camera_alt_rounded,
      title: 'Observez vos cultures',
      subtitle:
          'Prenez des photos et notez l\'état de santé de vos plantes en quelques taps',
    ),
    _OnboardingFeature(
      icon: Icons.auto_awesome_rounded,
      title: 'Recevez des conseils',
      subtitle:
          'L\'application analyse vos observations et vous propose des actions concrètes',
    ),
    _OnboardingFeature(
      icon: Icons.description_rounded,
      title: 'Générez vos rapports',
      subtitle:
          'Créez des comptes-rendus PDF à partager par WhatsApp ou email',
    ),
  ];

  int get _totalPages => _featurePages.length + 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await Hive.box(AppConstants.boxSettings)
        .put(AppConstants.kOnboardingCompleted, true);
    if (mounted) context.go(Routes.dashboard);
  }

  void _nextPage() {
    Haptics.light();
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                children: [
                  _LanguagePickerPage(
                    selected: settings.language,
                    onSelect: (lang) {
                      Haptics.selection();
                      ref.read(settingsProvider.notifier).setLanguage(lang);
                    },
                  ),
                  for (final page in _featurePages)
                    _FeaturePageView(page: page, theme: theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPage
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  if (_currentPage < _totalPages - 1) ...[
                    PrimaryButton(
                      label: 'Suivant',
                      onPressed: _nextPage,
                    ),
                    const SizedBox(height: 8),
                    // The "Skip" link is hidden on the language page — we
                    // really want the user to pick a language explicitly.
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: const Text('Passer'),
                      ),
                  ] else
                    PrimaryButton(
                      label: 'Commencer',
                      onPressed: _completeOnboarding,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingFeature {
  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _FeaturePageView extends StatelessWidget {
  const _FeaturePageView({required this.page, required this.theme});
  final _OnboardingFeature page;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(31),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LanguagePickerPage extends StatelessWidget {
  const _LanguagePickerPage({
    required this.selected,
    required this.onSelect,
  });

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(31),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.translate_rounded,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 28),
          // Trilingual heading so a Wolof- or Pulaar-only speaker can
          // recognise that this is the language picker even if the rest
          // of the screen is still in French.
          Text(
            'Choisissez votre langue',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Tànn sa làkk · Suɓo ɗemngal maa',
            style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: AppLanguage.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final lang = AppLanguage.values[i];
                final isSelected = lang == selected;
                return _LanguageOptionTile(
                  lang: lang,
                  selected: isSelected,
                  onTap: () => onSelect(lang),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.dividerOf(context),
              width: selected ? 1.6 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  lang.tag,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.endonym,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      lang.labelFr,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.textMutedOf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
