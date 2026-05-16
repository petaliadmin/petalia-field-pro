import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../parcels/presentation/parcels_providers.dart';
import '../../../core/constants/app_constants.dart';
import 'tour_provider.dart';

enum TaskPriority { high, medium, low }
final reportCountProvider = Provider<int>((ref) {
  final box = Hive.box(AppConstants.boxReports);
  return box.length;
});

final tourProgressProvider = Provider<String>((ref) {
  final tour = ref.watch(tourProvider);
  if (!tour.isActive) return '0/0';
  return '${tour.visited}/${tour.total}';
});

class DashboardTask {
  final String id;
  final String title;
  final String subtitle;
  final TaskPriority priority;
  final String? parcelId;
  final DateTime? dueDate;

  DashboardTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priority,
    this.parcelId,
    this.dueDate,
  });
}

final dashboardTasksProvider = Provider<List<DashboardTask>>((ref) {
  final parcels = ref.watch(parcelsProvider);
  final tasks = <DashboardTask>[];

  for (final p in parcels) {
    final daysSinceVisit = DateTime.now().difference(p.lastVisit).inDays;
    
    // Règle 1 : Visite en retard (> 7 jours)
    if (daysSinceVisit >= 7) {
      tasks.add(DashboardTask(
        id: 'visit-${p.id}',
        title: 'Visite de contrôle : ${p.name}',
        subtitle: 'Dernière visite il y a $daysSinceVisit jours',
        priority: daysSinceVisit > 10 ? TaskPriority.high : TaskPriority.medium,
        parcelId: p.id,
        dueDate: p.lastVisit.add(const Duration(days: 7)),
      ));
    }
    
    // Règle 2 : Santé faible (< 0.6)
    if (p.healthScore < 0.6) {
      // On évite les doublons si une tâche de visite existe déjà
      final existing = tasks.any((t) => t.id == 'visit-${p.id}');
      if (!existing) {
        tasks.add(DashboardTask(
          id: 'health-${p.id}',
          title: 'Alerte Santé : ${p.name}',
          subtitle: 'Score de santé critique (${(p.healthScore * 100).round()}%)',
          priority: TaskPriority.high,
          parcelId: p.id,
        ));
      }
    }
  }

  // Trier par priorité (High first)
  tasks.sort((a, b) => a.priority.index.compareTo(b.priority.index));
  return tasks;
});
