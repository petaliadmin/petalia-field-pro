import '../data/bbch_stages.dart';
import '../data/crops_catalog.dart';
import '../../features/parcels/domain/parcel.dart';

/// Snapshot of a parcel's phenological state at a given date.
///
/// Computed from [Parcel.semisDate], [Parcel.crop] (resolved through
/// [CropsCatalog]) and the BBCH calendar from [BbchCatalog]. Pure data —
/// no IO, safe to call on every rebuild.
class PhenologySnapshot {
  const PhenologySnapshot({
    required this.cropDef,
    required this.semisDate,
    required this.daysAfterSowing,
    required this.cycleDaysMin,
    required this.cycleDaysMax,
    required this.estimatedHarvestDate,
    required this.daysRemaining,
    required this.progress,
    required this.currentStage,
    required this.allStages,
    required this.isOverdue,
  });

  final CropDefinition cropDef;
  final DateTime semisDate;

  /// Days elapsed since [semisDate] (clamped to >= 0).
  final int daysAfterSowing;

  final int cycleDaysMin;
  final int cycleDaysMax;

  /// Median expected harvest date (semisDate + cycleDaysAverage).
  final DateTime estimatedHarvestDate;

  /// Days remaining to [estimatedHarvestDate] (can be negative if overdue).
  final int daysRemaining;

  /// Cycle progress in [0.0, 1.0] (das / cycleDaysAverage, clamped).
  final double progress;

  /// Current BBCH stage estimated from DAS, or `null` if no BBCH calendar
  /// exists for this crop.
  final BbchStage? currentStage;

  /// All BBCH stages for this crop (empty if none mapped).
  final List<BbchStage> allStages;

  /// True when DAS exceeds [cycleDaysMax] — parcel should have been
  /// harvested already.
  final bool isOverdue;
}

class PhenologyService {
  PhenologyService._();

  /// Computes a [PhenologySnapshot] for [parcel] at [now] (defaults to
  /// `DateTime.now()`). Returns `null` when the parcel has no [Parcel.semisDate]
  /// or its crop is not in [CropsCatalog] (cannot compute a cycle).
  static PhenologySnapshot? snapshot(Parcel parcel, {DateTime? now}) {
    final semis = parcel.semisDate;
    if (semis == null) return null;
    final cropDef = CropsCatalog.byLabelFr(parcel.crop) ??
        CropsCatalog.byId(parcel.crop);
    if (cropDef == null) return null;

    final today = now ?? DateTime.now();
    final das = today.difference(semis).inDays.clamp(0, 100000);
    final avg = cropDef.cycleDaysAverage;
    final harvest = semis.add(Duration(days: avg));
    final remaining = harvest.difference(today).inDays;
    final progress = avg <= 0 ? 0.0 : (das / avg).clamp(0.0, 1.0);
    final stages = BbchCatalog.stagesFor(cropDef.id) ?? const <BbchStage>[];
    final stage =
        BbchCatalog.estimateStage(cropId: cropDef.id, das: das);

    return PhenologySnapshot(
      cropDef: cropDef,
      semisDate: semis,
      daysAfterSowing: das,
      cycleDaysMin: cropDef.cycleDaysMin,
      cycleDaysMax: cropDef.cycleDaysMax,
      estimatedHarvestDate: harvest,
      daysRemaining: remaining,
      progress: progress.toDouble(),
      currentStage: stage,
      allStages: stages,
      isOverdue: das > cropDef.cycleDaysMax,
    );
  }
}
