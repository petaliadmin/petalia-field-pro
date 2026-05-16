import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart' show authServiceProvider;
import '../../../routes/route_names.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_colors.dart';
import 'auth_providers.dart';
import 'widgets/auth_header.dart';
import 'widgets/numeric_keypad.dart';

class RegisterOtpScreen extends ConsumerStatefulWidget {
  const RegisterOtpScreen({super.key});

  @override
  ConsumerState<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends ConsumerState<RegisterOtpScreen> {
  String _otp = '';
  bool _loading = false;

  void _onDigit(int digit) {
    if (_otp.length >= 6 || _loading) return;
    HapticFeedback.lightImpact();
    setState(() => _otp += digit.toString());
    if (_otp.length == 6) _verify();
  }

  void _onBackspace() {
    if (_otp.isEmpty || _loading) return;
    HapticFeedback.lightImpact();
    setState(() => _otp = _otp.substring(0, _otp.length - 1));
  }

  Future<void> _verify() async {
    final data = ref.read(registrationDataProvider);
    
    setState(() => _loading = true);
    
    final success = await ref.read(authServiceProvider.notifier).verifyOtp(data.phone, _otp);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      context.push(Routes.registerPin);
    } else {
      HapticFeedback.heavyImpact();
      final error = ref.read(authServiceProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Code OTP invalide')),
      );
      setState(() => _otp = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(registrationDataProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    AuthHeader(
                      icon: Icons.sms_outlined,
                      title: 'Vérification du numéro',
                      subtitle: 'Entrez le code à 6 chiffres envoyé au',
                      circleColor: AppColors.primary.withValues(alpha: 0.1),
                      iconColor: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.phone,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // OTP Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        final digit = i < _otp.length ? _otp[i] : '';
                        final active = i == _otp.length;
                        return Container(
                          width: 50,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active ? AppColors.primary : AppColors.dividerOf(context),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              digit,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 48),
                    
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Renvoyer le code dans ',
                          style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 14),
                          children: const [
                            TextSpan(
                              text: '00:28',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Primary Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: 'Vérifier',
                onPressed: _otp.length == 6 ? _verify : null,
                loading: _loading,
                color: AppColors.primary,
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
