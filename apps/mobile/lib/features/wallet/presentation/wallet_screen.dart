import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/credit_service.dart';
import '../../../routes/route_names.dart';
import '../../../theme/app_colors.dart';
import 'wallet_providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits = ref.watch(creditServiceProvider);
    final showBalance = ref.watch(showBalanceProvider);
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text(
          'Mon Portefeuille',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () async {
              HapticFeedback.lightImpact();
              await ref.read(creditServiceProvider.notifier).refreshBalance();
              ref.invalidate(walletTransactionsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await ref.read(creditServiceProvider.notifier).refreshBalance();
          ref.invalidate(walletTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // En-tête Premium GlassCard avec dégradé
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Cercles décoratifs en arrière-plan
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SOLDE DISPONIBLE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.8),
                                letterSpacing: 1.2,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                showBalance
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                final current = ref.read(showBalanceProvider);
                                ref.read(showBalanceProvider.notifier).state = !current;
                                if (!current) {
                                  ref.read(creditServiceProvider.notifier).refreshBalance();
                                  ref.invalidate(walletTransactionsProvider);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: AppColors.accent, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                showBalance ? '$credits CRÉDITS' : '•••• CRÉDITS',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Boutons d'action rapide (Recharger / Transférer)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push(Routes.walletRecharge);
                                },
                                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                                label: const Text(
                                  'Recharger',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context.push(Routes.walletTransfer);
                                },
                                icon: const Icon(Icons.send_rounded, color: Colors.white),
                                label: const Text(
                                  'Transférer',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section QR Code & Partage
            const Text(
              'Partage de crédits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.qr_code_rounded,
                    title: 'Mon QR Code',
                    subtitle: 'Recevoir des crédits',
                    color: const Color(0xFF10B981), // Emerald
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(Routes.walletQr, extra: {'tab': 0});
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Scanner',
                    subtitle: 'Transférer via QR',
                    color: const Color(0xFF6366F1), // Indigo
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(Routes.walletQr, extra: {'tab': 1});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Section Historique des transactions
            const Text(
              'Historique des transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            transactionsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Impossible de charger l\'historique',
                        style: TextStyle(color: AppColors.dangerOf(context), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 64, color: AppColors.textMutedOf(context).withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune transaction récente',
                          style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: transactions.map((tx) {
                    final isCredit = tx.type == 'CREDIT';
                    final isTransfer = tx.operationType == 'TRANSFER';
                    final color = isTransfer
                        ? const Color(0xFF6366F1)
                        : (isCredit ? const Color(0xFF10B981) : AppColors.danger);
                    final icon = isTransfer
                        ? (isCredit ? Icons.call_received_rounded : Icons.call_made_rounded)
                        : (isCredit ? Icons.add_rounded : Icons.remove_rounded);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.dividerOf(context)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description.isNotEmpty ? tx.description : tx.operationType,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimaryOf(context),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt),
                                  style: TextStyle(color: AppColors.textMutedOf(context), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${isCredit ? '+' : '-'}${tx.amount}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.dividerOf(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textPrimaryOf(context),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textMutedOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
