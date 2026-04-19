import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../routes/route_names.dart';
import '../../../theme/app_colors.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _loading = false;
  String? _error;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(int digit) {
    if (_pin.length >= 4 || _loading) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit.toString();
      _error = null;
    });
    if (_pin.length == 4) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty || _loading) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  void _onClear() {
    if (_loading) return;
    setState(() {
      _pin = '';
      _error = null;
    });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    await ref.read(authStateProvider.notifier).loginWithPin(_pin);
    final state = ref.read(authStateProvider);
    if (!mounted) return;

    if (state.hasValue && state.value!.isAuthenticated) {
      context.go(Routes.dashboard);
    } else {
      _shakeCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _error = 'Code incorrect';
        _loading = false;
      });
    }
  }

  Future<void> _biometric() async {
    final hasUser = ref.read(hasRegisteredUserProvider);
    if (!hasUser) {
      setState(() => _error = 'Aucun compte enregistré');
      return;
    }
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      bool ok = true;
      if (canCheck) {
        ok = await auth.authenticate(
          localizedReason: 'Connexion à Petalia Field Pro',
          options: const AuthenticationOptions(biometricOnly: false),
        );
      }
      if (!ok) return;
    } catch (_) {
      return;
    }
    await ref.read(authStateProvider.notifier).loginWithBiometric();
    if (mounted) context.go(Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final hasUser = ref.watch(hasRegisteredUserProvider);
    final repo = ref.read(authRepositoryProvider);
    final user = repo.currentUser();
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.eco_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 12),
            const Text(
              'Petalia Field Pro',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'L\'agronomie intelligente dans votre poche',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 36),

            // Greeting
            if (hasUser && user != null) ...[
              Text(
                'Bonjour, ${user.name} !',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Entrez votre code secret',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ] else ...[
              const Text(
                'Connexion',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Entrez votre code secret pour continuer',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ],

            const SizedBox(height: 32),

            // PIN dots with shake animation
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final dx = _shakeAnim.value *
                    10 *
                    ((_shakeCtrl.value * 6).toInt().isEven ? 1 : -1);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: _PinDots(
                length: _pin.length,
                hasError: _error != null,
              ),
            ),

            // Error message
            const SizedBox(height: 12),
            SizedBox(
              height: 20,
              child: _error != null
                  ? Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),

            const Spacer(),

            // Numeric keypad
            if (hasUser)
              _NumPad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onClear: _onClear,
                loading: _loading,
              ),

            if (hasUser) ...[
              const SizedBox(height: 16),
              // Fingerprint button
              TextButton.icon(
                onPressed: _loading ? null : _biometric,
                icon: const Icon(Icons.fingerprint_rounded, size: 24),
                label: const Text('Empreinte digitale'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            if (!hasUser) ...[
              const Spacer(),
              const Icon(Icons.person_add_rounded,
                  size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text(
                'Aucun compte enregistré',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Créez un compte pour commencer',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: FilledButton.icon(
                  onPressed: () => context.push(Routes.register),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Créer un compte'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],

            const SizedBox(height: 8),
            // Register / Login link
            if (hasUser)
              Padding(
                padding: EdgeInsets.only(bottom: bottomPad + 12),
                child: TextButton(
                  onPressed: () => context.push(Routes.register),
                  child: Text.rich(
                    TextSpan(
                      text: 'Pas de compte ? ',
                      style: TextStyle(color: AppColors.textSecondary),
                      children: const [
                        TextSpan(
                          text: 'S\'inscrire',
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
            if (!hasUser)
              Padding(
                padding: EdgeInsets.only(bottom: bottomPad + 12),
                child: TextButton(
                  onPressed: null,
                  child: Text(
                    'Petalia Field Pro v1.0',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PIN Dots
// =============================================================================
class _PinDots extends StatelessWidget {
  const _PinDots({required this.length, this.hasError = false});
  final int length;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          height: 18,
          width: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? (hasError ? AppColors.danger : AppColors.primary)
                : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppColors.danger
                  : (filled ? AppColors.primary : AppColors.divider),
              width: 2.5,
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// Numeric Keypad
// =============================================================================
class _NumPad extends StatelessWidget {
  const _NumPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    this.loading = false,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _row([1, 2, 3]),
          const SizedBox(height: 12),
          _row([4, 5, 6]),
          const SizedBox(height: 12),
          _row([7, 8, 9]),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionKey(
                icon: Icons.close_rounded,
                onTap: loading ? null : onClear,
              ),
              const SizedBox(width: 12),
              _digitKey(0),
              const SizedBox(width: 12),
              _actionKey(
                icon: Icons.backspace_rounded,
                onTap: loading ? null : onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<int> digits) {
    return Row(
      children: digits
          .expand((d) => [
                _digitKey(d),
                if (d != digits.last) const SizedBox(width: 12),
              ])
          .toList(),
    );
  }

  Widget _digitKey(int digit) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Material(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: loading ? null : () => onDigit(digit),
            child: Center(
              child: Text(
                '$digit',
                style: const TextStyle(
                  fontSize: 24,
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

  Widget _actionKey({required IconData icon, VoidCallback? onTap}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: Icon(icon, color: AppColors.textSecondary, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
