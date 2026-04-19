import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/success_feedback.dart';
import '../../../theme/app_colors.dart';
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _pin = '';
  String _confirmPin = '';
  bool _loading = false;
  _PinField _activePinField = _PinField.create;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez créer un code secret de 4 chiffres')),
      );
      return;
    }
    if (_confirmPin != _pin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les codes ne correspondent pas')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier).register(
            phone: _phoneCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            pin: _pin,
          );
      final state = ref.read(authStateProvider);
      if (!mounted) return;
      if (state.hasValue && state.value!.isAuthenticated) {
        SuccessFeedback.show(context, message: 'Compte créé avec succès !');
        final seen = Hive.box(AppConstants.boxSettings)
            .get(AppConstants.kOnboardingCompleted, defaultValue: false) as bool;
        context.go(seen ? Routes.dashboard : Routes.onboarding);
      } else if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${state.error}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onPinDigit(int digit) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_activePinField == _PinField.create) {
        if (_pin.length < 4) _pin += digit.toString();
        if (_pin.length == 4) _activePinField = _PinField.confirm;
      } else {
        if (_confirmPin.length < 4) _confirmPin += digit.toString();
      }
    });
  }

  void _onPinBackspace() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_activePinField == _PinField.confirm) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _activePinField = _PinField.create;
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  void _onPinClear() {
    setState(() {
      if (_activePinField == _PinField.confirm) {
        _confirmPin = '';
      } else {
        _pin = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final pinsMatch = _pin.length == 4 && _confirmPin.length == 4 && _pin == _confirmPin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad + 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejoignez Petalia Field Pro',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),

              // --- Personal info ---
              const Text('Informations personnelles',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        prefixIcon: Icon(Icons.phone_rounded),
                        hintText: '+221 XX XXX XX XX',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
                      ],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Le numéro est obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Le nom est obligatoire'
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- PIN section ---
              const Text('Code secret',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Choisissez un code de 4 chiffres pour sécuriser votre compte',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Create PIN
              GlassCard(
                child: Column(
                  children: [
                    _PinRow(
                      label: 'Créer le code',
                      length: _pin.length,
                      isActive: _activePinField == _PinField.create,
                      onTap: () =>
                          setState(() => _activePinField = _PinField.create),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    _PinRow(
                      label: 'Confirmer le code',
                      length: _confirmPin.length,
                      isActive: _activePinField == _PinField.confirm,
                      hasError: _confirmPin.length == 4 && _confirmPin != _pin,
                      isValid: pinsMatch,
                      onTap: _pin.length == 4
                          ? () => setState(
                              () => _activePinField = _PinField.confirm)
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Mini numpad
              _MiniNumPad(
                onDigit: _onPinDigit,
                onBackspace: _onPinBackspace,
                onClear: _onPinClear,
              ),

              const SizedBox(height: 28),

              // Submit
              PrimaryButton(
                label: 'S\'inscrire',
                icon: Icons.check_rounded,
                loading: _loading,
                onPressed: _submit,
              ),

              const SizedBox(height: 16),

              // Login link
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text.rich(
                    TextSpan(
                      text: 'Déjà un compte ? ',
                      style: TextStyle(color: AppColors.textSecondary),
                      children: const [
                        TextSpan(
                          text: 'Se connecter',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PinField { create, confirm }

// =============================================================================
// PIN Row (label + 4 dots)
// =============================================================================
class _PinRow extends StatelessWidget {
  const _PinRow({
    required this.label,
    required this.length,
    this.isActive = false,
    this.hasError = false,
    this.isValid = false,
    this.onTap,
  });

  final String label;
  final int length;
  final bool isActive;
  final bool hasError;
  final bool isValid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (i) {
              final filled = i < length;
              Color color;
              if (hasError) {
                color = AppColors.danger;
              } else if (isValid) {
                color = AppColors.success;
              } else if (isActive) {
                color = AppColors.primary;
              } else {
                color = AppColors.divider;
              }
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                height: 14,
                width: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
              );
            }),
          ),
          if (isValid)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Mini Numpad for registration
// =============================================================================
class _MiniNumPad extends StatelessWidget {
  const _MiniNumPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row([1, 2, 3]),
        const SizedBox(height: 8),
        _row([4, 5, 6]),
        const SizedBox(height: 8),
        _row([7, 8, 9]),
        const SizedBox(height: 8),
        Row(
          children: [
            _actionKey(Icons.close_rounded, onClear),
            const SizedBox(width: 8),
            _digitKey(0),
            const SizedBox(width: 8),
            _actionKey(Icons.backspace_rounded, onBackspace),
          ],
        ),
      ],
    );
  }

  Widget _row(List<int> digits) {
    return Row(
      children: digits
          .expand((d) => [
                _digitKey(d),
                if (d != digits.last) const SizedBox(width: 8),
              ])
          .toList(),
    );
  }

  Widget _digitKey(int digit) {
    return Expanded(
      child: Material(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onDigit(digit),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                '$digit',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionKey(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Icon(icon, color: AppColors.textSecondary, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
