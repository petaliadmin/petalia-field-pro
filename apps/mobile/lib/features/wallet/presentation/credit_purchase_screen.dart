import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/credit_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class CreditPurchaseScreen extends ConsumerStatefulWidget {
  const CreditPurchaseScreen({super.key});

  @override
  ConsumerState<CreditPurchaseScreen> createState() => _CreditPurchaseScreenState();
}

class _CreditPurchaseScreenState extends ConsumerState<CreditPurchaseScreen> {
  PaymentMethod? _selectedMethod;
  int? _selectedPackageIndex;

  final List<Map<String, dynamic>> _packages = [
    {'credits': 10, 'price': 2000, 'label': 'Découverte'},
    {'credits': 50, 'price': 5000, 'label': 'Producteur', 'best': true},
    {'credits': 120, 'price': 10000, 'label': 'Expert'},
  ];

  @override
  Widget build(BuildContext context) {
    final credits = ref.watch(creditServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crédits Agronomiques'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser le solde',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actualisation du solde...')),
              );
              await ref.read(creditServiceProvider.notifier).refreshBalance();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Solde actualisé avec succès !')),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(creditServiceProvider.notifier).refreshBalance();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Solde actuel
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Solde actuel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMutedOf(context))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.accent, size: 36),
                      const SizedBox(width: 12),
                      Text('$credits', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.textPrimaryOf(context))),
                    ],
                  ),
                  Text('crédits disponibles'.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.2)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const Text('Choisir un forfait', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            
            // Packages
            ...List.generate(_packages.length, (index) {
              final pkg = _packages[index];
              final isSelected = _selectedPackageIndex == index;
              final isBest = pkg['best'] == true;

              return GestureDetector(
                onTap: () => setState(() => _selectedPackageIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.dividerOf(context),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.textMutedOf(context).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text('${pkg['credits']}', style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimaryOf(context), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pkg['label'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimaryOf(context))),
                            Text('${pkg['price']} FCFA', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      if (isBest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                          child: const Text('RECOMMANDÉ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),
            const Text('Mode de paiement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                _PaymentMethodCard(
                  method: PaymentMethod.wave,
                  label: 'Wave',
                  imageAsset: 'assets/images/wave_logo.jpg',
                  color: const Color(0xFF1B91FF), // Wave Blue
                  isSelected: _selectedMethod == PaymentMethod.wave,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.wave),
                ),
                const SizedBox(width: 12),
                _PaymentMethodCard(
                  method: PaymentMethod.orangeMoney,
                  label: 'Orange',
                  imageAsset: 'assets/images/orange_money_logo.png',
                  color: const Color(0xFFFF6600), // Orange Money
                  isSelected: _selectedMethod == PaymentMethod.orangeMoney,
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.orangeMoney),
                ),
              ],
            ),

            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: (_selectedMethod != null && _selectedPackageIndex != null) ? _processPurchase : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('PAYER MAINTENANT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _processPurchase() async {
    final pkg = _packages[_selectedPackageIndex!];
    final method = _selectedMethod!;

    // 1. Afficher chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 2. Initialiser le paiement sur le backend
    final request = PaymentRequest(
      id: 'TEMP_${DateTime.now().millisecondsSinceEpoch}',
      description: 'Achat de ${pkg['credits']} crédits Petalia',
      amount: pkg['price'],
      credits: pkg['credits'],
      method: method,
    );

    final paymentUrl = await ref.read(paymentServiceProvider).initializePayment(request);

    if (!mounted) return;
    Navigator.pop(context); // Fermer loader

    if (paymentUrl != null) {
      // 3. Ouvrir l'URL de paiement (Wave/OM Simulator)
      await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);

      if (!mounted) return;
      
      // 4. Afficher un dialogue de vérification
      _showVerificationDialog(pkg['credits']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'initialisation du paiement.')),
      );
    }
  }

  void _showVerificationDialog(int credits) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Paiement en cours'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Veuillez finaliser le paiement dans votre application mobile money.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Ici on pourrait rafraîchir le solde
              ref.read(creditServiceProvider.notifier).refreshBalance();
            },
            child: const Text('VÉRIFIER MON SOLDE'),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final String label;
  final String imageAsset;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.method,
    required this.label,
    required this.imageAsset,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : AppColors.dividerOf(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imageAsset,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : AppColors.textPrimaryOf(context))),
            ],
          ),
        ),
      ),
    );
  }
}
