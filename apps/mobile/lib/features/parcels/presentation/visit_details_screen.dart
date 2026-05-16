import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:petaliacropassist/theme/app_colors.dart';
import 'package:petaliacropassist/shared/widgets/glass_card.dart';
import 'package:petaliacropassist/shared/widgets/health_badge.dart';
import 'package:petaliacropassist/core/utils/formatters.dart';
import 'package:petaliacropassist/core/constants/app_constants.dart';
import '../presentation/parcels_providers.dart';

class VisitDetailsScreen extends ConsumerWidget {
  const VisitDetailsScreen({super.key, required this.visitId});
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupération de la visite réelle depuis Hive
    final box = Hive.box(AppConstants.boxObservations);
    final data = box.get(visitId);

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visite introuvable')),
        body: const Center(child: Text('Les données de cette visite ne sont pas disponibles.')),
      );
    }

    // Récupération de la parcelle pour le contexte (Culture/Propriétaire)
    final parcel = ref.watch(parcelByIdProvider(data['parcelId'] as String));

    final date = DateTime.parse(data['at'] as String);
    final symptoms = (data['symptoms'] as List?)?.cast<String>() ?? [];
    final healthScore = 1.0 - (data['severity'] as double? ?? 0.0);
    final note = data['note'] as String? ?? '';
    final photos = (data['photoPaths'] as List?)?.cast<String>() ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, date, data['stage'] as String? ?? 'Visite', healthScore),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeatherCard(context, data),
                  const SizedBox(height: 16),
                  if (parcel != null)
                    Text(
                      '${parcel.crop} · ${parcel.owner}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  const SizedBox(height: 20),
                  _buildSectionTitle(context, 'Observations Terrain'),
                  const SizedBox(height: 12),
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(note, style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
                    ),
                  if (symptoms.isEmpty && note.isEmpty)
                    _buildObservationItem(context, 'Aucune anomalie détectée.')
                  else
                    ...symptoms.map((s) => _buildObservationItem(context, s)),
                  
                  const SizedBox(height: 24),
                  _buildRecommendationCard(context, 'Poursuivre la surveillance. Appliquer les bonnes pratiques ISRA selon le stade phénologique actuel.'),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Photos de la visite'),
                  const SizedBox(height: 12),
                  _buildPhotoGrid(context, photos),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, DateTime date, String type, double healthScore) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(Fmt.date(date), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.primary),
            Positioned(
              bottom: 60,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  HealthBadge(score: healthScore),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context, Map<dynamic, dynamic> data) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildWeatherStat(context, Icons.thermostat_rounded, '28°C', 'Température'), // À lier à weather service si besoin
          _buildWeatherStat(context, Icons.water_drop_rounded, data['soilMoisture'] ?? 'N/A', 'Sol'),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title.toUpperCase(), 
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.primary));
  }

  Widget _buildObservationItem(BuildContext context, String obs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(child: Text(obs, style: TextStyle(fontSize: 14, height: 1.4, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 20),
              SizedBox(width: 8),
              Text('CONSEIL EXPERT', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9))),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, List<String> photos) {
    if (photos.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text('Aucune photo pour cette visite', 
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final path = photos[index];
        
        Widget image;
        if (kIsWeb) {
          image = Image.network(path, fit: BoxFit.cover);
        } else {
          final file = File(path);
          image = file.existsSync() 
            ? Image.file(file, fit: BoxFit.cover)
            : Icon(Icons.broken_image_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5));
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: image,
          ),
        );
      },
    );
  }
}
