import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/success_feedback.dart';
import '../../../theme/app_colors.dart';
import '../../parcels/presentation/parcels_providers.dart';
import '../domain/checklist_template.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key, required this.parcelId});
  final String parcelId;

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  late List<ChecklistTemplate> _templates;
  String _selectedPhase = 'vegetation';
  final Map<String, bool> _items = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    final parcel = ref.read(parcelByIdProvider(widget.parcelId));
    final cropId = parcel?.crop ?? 'arachide';

    _templates = getTemplatesForCrop(cropId);

    final box = Hive.box(AppConstants.boxChecklists);
    final savedKey = '${widget.parcelId}_$_selectedPhase';
    final saved = box.get(savedKey);

    if (saved != null) {
      final Map<dynamic, dynamic> savedItems = saved['checked'] ?? {};
      for (final item in savedItems.entries) {
        _items[item.key.toString()] = item.value as bool;
      }
    } else {
      final template = _templates.firstWhere(
        (t) => t.phase == _selectedPhase,
        orElse: () => _templates.first,
      );
      for (final item in template.items) {
        _items[item.id] = false;
      }
    }

    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _saveToHive() async {
    final box = Hive.box(AppConstants.boxChecklists);
    final key = '${widget.parcelId}_$_selectedPhase';
    await box.put(key, {
      'checked': _items,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  void _selectPhase(String phase) {
    setState(() {
      _selectedPhase = phase;
      _items.clear();
    });
    _loadFromHive();
  }

  String _phaseLabel(String phase) {
    switch (phase) {
      case 'semis':
        return 'Semis';
      case 'vegetation':
        return 'Croissance';
      case 'flowering':
        return 'Floraison';
      case 'fruiting':
        return 'Fructification';
      case 'harvest':
        return 'Récolte';
      case 'all':
        return 'GlobalGAP';
      default:
        return phase;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parcel = ref.watch(parcelByIdProvider(widget.parcelId));
    final cropLabel = parcel?.crop ?? 'arachide';

    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentTemplate = _templates.firstWhere(
      (t) => t.phase == _selectedPhase,
      orElse: () => _templates.first,
    );

    final progress = _items.isEmpty
        ? 0.0
        : _items.values.where((v) => v).length / _items.length;

    final phases = _templates.map((t) => t.phase).toSet().toList();
    final globalGapTemplate = cropChecklistTemplates.firstWhere(
      (t) => t.id == 'GLOBALGAP',
      orElse: () => cropChecklistTemplates.first,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Vérification $cropLabel')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phase culturale :',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: phases.map((phase) {
                    final isSelected = phase == _selectedPhase;
                    return ChoiceChip(
                      label: Text(_phaseLabel(phase)),
                      selected: isSelected,
                      onSelected: (_) => _selectPhase(phase),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'des vérifications terminées',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 10,
                      backgroundColor: AppColors.secondary,
                      valueColor: AlwaysStoppedAnimation(
                        progress >= 1.0 ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...currentTemplate.items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: () {
                      SuccessFeedback.tapFeedback();
                      setState(
                        () => _items[item.id] = !(_items[item.id] ?? false),
                      );
                      _saveToHive();
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: _items[item.id] == true
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: _items[item.id] == true
                                  ? AppColors.primary
                                  : AppColors.divider,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _items[item.id] == true
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.labelFr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _items[item.id] == true
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: _items[item.id] == true
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          const SizedBox(height: 8),
          const Text(
            'Vérifications générales (GlobalGAP)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...globalGapTemplate.items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    onTap: () {
                      SuccessFeedback.tapFeedback();
                      setState(
                        () => _items[item.id] = !(_items[item.id] ?? false),
                      );
                      _saveToHive();
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: _items[item.id] == true
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: _items[item.id] == true
                                  ? AppColors.primary
                                  : AppColors.divider,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _items[item.id] == true
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.labelFr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _items[item.id] == true
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: _items[item.id] == true
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          const SizedBox(height: 12),
          PrimaryButton(
            label: progress >= 1.0 ? 'Terminé !' : 'Terminer la visite',
            icon: Icons.check_circle_rounded,
            onPressed: () {
              SuccessFeedback.show(
                context,
                message: progress >= 1.0
                    ? 'Toutes vérifications terminées !'
                    : 'Visite terminée !',
              );
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}
