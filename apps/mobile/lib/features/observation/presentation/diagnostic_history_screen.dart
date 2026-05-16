import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/ai_diagnostic_service.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../theme/app_colors.dart';

class DiagnosticHistoryScreen extends ConsumerWidget {
  const DiagnosticHistoryScreen({super.key});

  Future<void> _shareWhatsApp(DiagnosticRequest r) async {
    final phone = r.ownerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final text = Uri.encodeComponent(
      'Bonjour ${r.ownerName}, voici le diagnostic expert pour votre parcelle :\n'
      'Résultat : ${r.aiResult?.label}\n'
      'Conseil : ${r.aiResult?.recommendations}\n'
      'Lien : https://petalia.ag/r/${r.id}'
    );
    final url = 'https://wa.me/$phone?text=$text';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendSms(DiagnosticRequest r) async {
    final phone = r.ownerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final text = 'Petalia : Diagnostic pret pour ${r.ownerName}. Resultat : ${r.aiResult?.label}. Voir : https://petalia.ag/r/${r.id}';
    final url = 'sms:$phone?body=${Uri.encodeComponent(text)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(diagnosticRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics Experts')),
      body: requestsAsync.when(
        data: (requests) => requests.isEmpty
            ? const EmptyState(
                icon: Icons.auto_awesome_rounded,
                title: 'Aucun diagnostic',
                message: 'Les demandes de diagnostic IA s\'afficheront ici.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final r = requests[i];
                  return _DiagnosticRequestCard(
                    request: r,
                    onWhatsApp: () => _shareWhatsApp(r),
                    onSms: () => _sendSms(r),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _DiagnosticRequestCard extends ConsumerWidget {
  const _DiagnosticRequestCard({
    required this.request,
    required this.onWhatsApp,
    required this.onSms,
  });
  final DiagnosticRequest request;
  final VoidCallback onWhatsApp;
  final VoidCallback onSms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAnalyzed = request.status == DiagnosticStatus.analyzed;
    final isValidated = request.status == DiagnosticStatus.validated;

    Color statusColor = Colors.grey;
    String statusLabel = 'En attente';
    if (isAnalyzed) { statusColor = AppColors.info; statusLabel = 'Analysé (Claude)'; }
    if (isValidated) { statusColor = AppColors.success; statusLabel = 'Validé par Expert'; }

    // Résoudre l'URL de l'image (si relative au backend)
    String imageUrl = request.photoUrl;
    if (!imageUrl.startsWith('http')) {
      final baseUrl = ref.read(dioProvider).options.baseUrl;
      imageUrl = '$baseUrl/$imageUrl';
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(height: 50, width: 50, color: Colors.grey.withValues(alpha: 0.1)),
                  errorWidget: (_, __, ___) => Container(height: 50, width: 50, color: Colors.grey.withValues(alpha: 0.2), child: const Icon(Icons.broken_image_rounded, size: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.ownerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Demandé le ${request.createdAt.day}/${request.createdAt.month}',
                      style: TextStyle(fontSize: 12, color: AppColors.textMutedOf(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (request.aiResult != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  request.aiResult!.label,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              request.aiResult!.recommendations,
              style: const TextStyle(fontSize: 13),
            ),
          ],
          if (isValidated) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onWhatsApp,
                    icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSms,
                    icon: const Icon(Icons.sms_rounded, size: 16),
                    label: const Text('SMS'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
