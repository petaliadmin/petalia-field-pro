import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_colors.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

const _pages = [
  _OnboardingPage(
    icon: Icons.add_location_alt_rounded,
    title: 'Ajoutez vos parcelles',
    subtitle:
        'Dessinez vos champs sur la carte ou marchez les limites avec le GPS',
  ),
  _OnboardingPage(
    icon: Icons.camera_alt_rounded,
    title: 'Observez vos cultures',
    subtitle:
        'Prenez des photos et notez l\'état de santé de vos plantes en quelques taps',
  ),
  _OnboardingPage(
    icon: Icons.auto_awesome_rounded,
    title: 'Recevez des conseils',
    subtitle:
        'L\'application analyse vos observations et vous propose des actions concrètes',
  ),
  _OnboardingPage(
    icon: Icons.description_rounded,
    title: 'Générez vos rapports',
    subtitle:
        'Créez des comptes-rendus PDF à partager par WhatsApp ou email',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
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
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
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
                  if (_currentPage < _pages.length - 1) ...[
                    PrimaryButton(
                      label: 'Suivant',
                      onPressed: () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
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
