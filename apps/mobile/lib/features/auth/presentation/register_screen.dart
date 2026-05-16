import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../core/services/auth_service.dart' show authServiceProvider;
import '../../../l10n/gen/app_localizations.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_colors.dart';
import 'auth_providers.dart';
import 'widgets/brand_shield_icon.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final data = ref.read(registrationDataProvider);
    _phoneCtrl = TextEditingController(text: data.phone.isEmpty ? '' : data.phone.replaceFirst('+221', ''));
    _nameCtrl = TextEditingController(text: data.name);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    // Normaliser le numéro (Sénégal +221)
    final fullPhone = phone.startsWith('+221') ? phone : '+221$phone';

    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await ref.read(authServiceProvider.notifier).requestOtp(fullPhone);

    if (!mounted) return;
    Navigator.pop(context); // Fermer loader

    if (success) {
      ref.read(registrationDataProvider.notifier).update((state) => state.copyWith(
        name: name,
        phone: fullPhone,
      ));
      context.push(Routes.registerOtp);
    } else {
      final error = ref.read(authServiceProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Erreur d\'envoi du code OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
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
              const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: BrandShieldIcon()),
                      const SizedBox(height: 32),
                      const Center(
                        child: Text(
                          'Créer un compte',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Veuillez renseigner vos informations\npour commencer',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 40),

                      const Text(
                        'Nom complet',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Entrez votre nom complet',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          filled: true,
                          fillColor: AppColors.surfaceOf(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.dividerOf(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.dividerOf(context)),
                          ),
                        ),
                        validator: (v) => v != null && v.trim().length < 2 ? l10n.authErrorNameTooShort : null,
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Numéro de téléphone',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      IntlPhoneField(
                        controller: _phoneCtrl,
                        initialCountryCode: 'SN',
                        showCountryFlag: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _next(),
                        decoration: InputDecoration(
                          hintText: '77 123 45 67',
                          hintStyle: TextStyle(color: AppColors.textMutedOf(context), fontSize: 14),
                          filled: true,
                          fillColor: AppColors.surfaceOf(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.dividerOf(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.dividerOf(context)),
                          ),
                        ),
                        onChanged: (phone) {
                          // Numéro complet géré par le contrôleur ou le callback
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Continuer',
                    onPressed: _next,
                    color: AppColors.primary, 
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Vous avez déjà un compte ? ',
                        style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () => context.push(Routes.login),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Se connecter',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
