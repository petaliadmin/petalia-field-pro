import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../core/services/credit_service.dart';
import '../../../theme/app_colors.dart';
import 'wallet_providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  final String? initialPhone;

  const TransferScreen({super.key, this.initialPhone});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _phoneNumber = '';
  bool _isValidPhone = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      _phoneNumber = widget.initialPhone!;
      _isValidPhone = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitTransfer() async {
    if (!_formKey.currentState!.validate() || !_isValidPhone) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez remplir correctement tous les champs obligatoires'),
          backgroundColor: AppColors.dangerOf(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = int.tryParse(_amountController.text) ?? 0;
    final currentCredits = ref.read(creditServiceProvider);

    if (amount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Le montant doit être supérieur à zéro'),
          backgroundColor: AppColors.dangerOf(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (amount > currentCredits) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solde insuffisant (Solde actuel: $currentCredits)'),
          backgroundColor: AppColors.dangerOf(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surfaceOf(context),
        title: const Text('Confirmer le transfert', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Voulez-vous vraiment transférer $amount crédits au producteur $_phoneNumber ?',
          style: TextStyle(color: AppColors.textPrimaryOf(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: AppColors.textMutedOf(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    HapticFeedback.mediumImpact();
    final success = await ref.read(walletControllerProvider.notifier).transferCredits(
      _phoneNumber,
      amount,
      _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfert effectué avec succès !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFF10B981), // Emerald
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      HapticFeedback.heavyImpact();
      final err = ref.read(walletControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec du transfert : ${err ?? "Erreur inconnue"}'),
          backgroundColor: AppColors.dangerOf(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletControllerProvider);
    final isLoading = walletState.isLoading;
    final currentCredits = ref.watch(creditServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text(
          'Transférer des crédits',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Solde actuel affiché de manière élégante
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 36),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solde disponible',
                          style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentCredits CRÉDITS',
                          style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              const Text(
                'Destinataire',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              IntlPhoneField(
                initialCountryCode: 'SN',
                initialValue: widget.initialPhone?.replaceAll('+221', ''),
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: '77 123 45 67',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceOf(context),
                ),
                onChanged: (phone) {
                  _phoneNumber = phone.completeNumber;
                  _isValidPhone = phone.isValidNumber();
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Montant à transférer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Nombre de crédits',
                  hintText: 'Ex: 10',
                  prefixIcon: const Icon(Icons.stars_rounded, color: AppColors.accent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceOf(context),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Veuillez saisir un montant';
                  final n = int.tryParse(val);
                  if (n == null || n <= 0) return 'Montant invalide';
                  if (n > currentCredits) return 'Solde insuffisant';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Note / Motif (Facultatif)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'Ex: Achat d\'intrants ou partage amical',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceOf(context),
                ),
              ),
              const SizedBox(height: 48),

              // Bouton Valider
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          'Transférer les crédits',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
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
