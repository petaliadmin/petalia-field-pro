import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_colors.dart';
import 'widgets/auth_header.dart';

class BiometricSetupScreen extends ConsumerWidget {
  const BiometricSetupScreen({super.key});

  Future<void> _complete(BuildContext context) async {
    final box = Hive.box(AppConstants.boxSettings);
    final seen = box.get(AppConstants.kOnboardingCompleted, defaultValue: false) as bool;
    context.go(seen ? Routes.dashboard : Routes.onboarding);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            AuthHeader(
              icon: Icons.fingerprint_rounded,
              title: 'Activer l\'empreinte\ndigitale ?',
              subtitle: 'Utilisez votre empreinte pour vous connecter rapidement et en toute sécurité.',
              circleColor: AppColors.primary.withValues(alpha: 0.1),
              iconColor: AppColors.primary,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Activer',
                    onPressed: () => _complete(context),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _complete(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Plus tard',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
