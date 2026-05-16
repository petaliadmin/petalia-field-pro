import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/route_names.dart';
import '../../../shared/widgets/success_feedback.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../theme/app_colors.dart';
import 'auth_providers.dart';
import 'widgets/auth_header.dart';
import 'widgets/numeric_keypad.dart';
import 'widgets/pin_indicator.dart';

class RegisterPinScreen extends ConsumerStatefulWidget {
  const RegisterPinScreen({super.key});

  @override
  ConsumerState<RegisterPinScreen> createState() => _RegisterPinScreenState();
}

class _RegisterPinScreenState extends ConsumerState<RegisterPinScreen> {
  String _pin = '';
  String _firstPin = '';
  bool _confirming = false;
  bool _loading = false;
  bool _isError = false;

  void _onDigit(int digit) {
    if (_pin.length >= 4 || _loading) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit.toString();
      _isError = false;
    });

    if (_pin.length == 4) {
      if (!_confirming) {
        // First PIN entered, move to confirmation
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _firstPin = _pin;
              _pin = '';
              _confirming = true;
            });
          }
        });
      } else {
        // Confirming PIN
        if (_pin == _firstPin) {
          _submit();
        } else {
          // PINs don't match
          HapticFeedback.heavyImpact();
          setState(() {
            _isError = true;
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _pin = '';
                _isError = false;
              });
            }
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty || _loading) return;
    HapticFeedback.lightImpact();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    final data = ref.read(registrationDataProvider);
    
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).register(
            phone: data.phone,
            name: data.name,
            pin: _pin,
          );
      
      final state = ref.read(authStateProvider);
      if (!mounted) return;

      if (state.hasValue && state.value!.isAuthenticated) {
        SuccessFeedback.show(context, message: AppLocalizations.of(context).authRegisterSuccess);
        context.go(Routes.biometricSetup);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                onPressed: () {
                  if (_confirming) {
                    setState(() {
                      _confirming = false;
                      _pin = '';
                      _firstPin = '';
                    });
                  } else {
                    context.pop();
                  }
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    AuthHeader(
                      icon: Icons.lock_rounded,
                      title: _confirming ? 'Confirmer votre code' : 'Créer votre code secret',
                      subtitle: _confirming
                          ? 'Entrez à nouveau votre code secret'
                          : 'Choisissez un code à 4 chiffres pour sécuriser votre compte',
                      circleColor: AppColors.primary.withValues(alpha: 0.1),
                      iconColor: AppColors.primary,
                    ),
                    const SizedBox(height: 60),
                    
                    PinIndicator(
                      length: 4,
                      currentLength: _pin.length,
                      isError: _isError,
                    ),
                  ],
                ),
              ),
            ),
            
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),

            // Numpad
            NumericKeypad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
