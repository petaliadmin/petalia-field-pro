import 'package:flutter/material.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../theme/app_colors.dart';
import '../../../recommendations/domain/agro_rule.dart';

/// Un calculateur interactif pour convertir les doses/ha en doses par pulvérisateur.
/// Design "Bento Grid" premium pour le terrain.
class SprayerCalculator extends StatefulWidget {
  const SprayerCalculator({
    super.key,
    required this.rule,
    required this.parcelArea,
  });

  final AgroRule rule;
  final double parcelArea;

  @override
  State<SprayerCalculator> createState() => _SprayerCalculatorState();
}

class _SprayerCalculatorState extends State<SprayerCalculator> {
  double _volumeHa = 200; // Par défaut 200L/ha
  int _sprayerSize = 15; // Standard 15L

  @override
  Widget build(BuildContext context) {
    final dosePerHa = widget.rule.id.contains('FERTI') ? 50.0 : 1.0; // Mock dose
    // Note: Dans une version réelle, la dose exacte serait extraite des actions de la règle.
    
    final dosePerSprayer = (dosePerHa / _volumeHa) * _sprayerSize;
    final totalSprayers = (widget.parcelArea * _volumeHa / _sprayerSize).ceil();

    return GlassCard(
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Calculateur de Bouillie',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Bento Grid Layout
          Row(
            children: [
              // Case 1: Volume hectare
              Expanded(
                child: _BentoItem(
                  label: 'Volume / ha',
                  value: '${_volumeHa.toInt()} L',
                  icon: Icons.opacity_rounded,
                  onTap: () => _showPicker(
                    'Volume de bouillie par hectare',
                    [200, 300, 400],
                    (v) => setState(() => _volumeHa = v.toDouble()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Case 2: Taille pulvé
              Expanded(
                child: _BentoItem(
                  label: 'Taille Pulvé',
                  value: '$_sprayerSize L',
                  icon: Icons.backpack_rounded,
                  onTap: () => _showPicker(
                    'Capacité de votre pulvérisateur',
                    [12, 15, 16, 20],
                    (v) => setState(() => _sprayerSize = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Result Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dose par machine',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${dosePerSprayer.toStringAsFixed(1)} unités',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$totalSprayers',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Text(
                        'machines',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(String title, List<int> options, Function(int) onSelected) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...options.map((o) => ListTile(
                  title: Text('$o Litres'),
                  onTap: () {
                    onSelected(o);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

class _BentoItem extends StatelessWidget {
  const _BentoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: AppColors.textSecondaryOf(context), fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
