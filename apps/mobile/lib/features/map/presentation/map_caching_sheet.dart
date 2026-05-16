import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/tile_cache_service.dart';
import '../../../theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

class MapCachingSheet extends ConsumerStatefulWidget {
  const MapCachingSheet({
    super.key,
    required this.bounds,
    required this.currentStore,
  });

  final LatLngBounds bounds;
  final String currentStore;

  static void show(BuildContext context, LatLngBounds bounds, String store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MapCachingSheet(bounds: bounds, currentStore: store),
    );
  }

  @override
  ConsumerState<MapCachingSheet> createState() => _MapCachingSheetState();
}

class _MapCachingSheetState extends ConsumerState<MapCachingSheet> {
  int _minZoom = 12;
  int _maxZoom = 17;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(tileDownloadProgressProvider).valueOrNull;

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerOf(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.download_for_offline_rounded, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Sauvegarder la zone',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Télécharge les tuiles de la zone visible pour un usage hors-ligne.',
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
          const SizedBox(height: 24),
          
          if (progress != null) ...[
             LinearProgressIndicator(
               value: progress.percentageProgress / 100,
               backgroundColor: AppColors.surfaceAltOf(context),
               borderRadius: BorderRadius.circular(8),
               minHeight: 12,
             ),
             const SizedBox(height: 12),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Téléchargement... ${progress.percentageProgress.toInt()}%'),
                 Text('${progress.cachedTiles} / ${progress.maxTiles} tuiles'),
               ],
             ),
             const SizedBox(height: 24),
             SizedBox(
               width: double.infinity,
               child: OutlinedButton(
                 onPressed: () => TileCacheService.cancelAllDownloads(),
                 child: const Text('Annuler'),
               ),
             ),
          ] else ...[
            _buildZoomLevelPicker(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _startDownload,
                icon: const Icon(Icons.cloud_download_rounded),
                label: const Text('Démarrer le téléchargement'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZoomLevelPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Précision (Zoom)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ZoomCard(
                label: 'Standard',
                description: 'Zoom 12-16',
                selected: _maxZoom == 16,
                onTap: () => setState(() => _maxZoom = 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ZoomCard(
                label: 'Détaillé',
                description: 'Zoom 12-18',
                selected: _maxZoom == 18,
                onTap: () => setState(() => _maxZoom = 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _startDownload() {
    final url = TileCacheService.tileUrlFor(widget.currentStore);
    TileCacheService.downloadRegion(
      bounds: widget.bounds,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      storeName: widget.currentStore,
      urlTemplate: url,
    );
  }
}

class _ZoomCard extends StatelessWidget {
  const _ZoomCard({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceAltOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 12, color: AppColors.textSecondaryOf(context))),
          ],
        ),
      ),
    );
  }
}
