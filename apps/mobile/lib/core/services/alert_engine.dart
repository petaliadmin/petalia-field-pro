library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../../features/parcels/presentation/parcels_providers.dart';

enum AlertSeverity { low, medium, high, urgent }

enum AlertCategory {
  weather,
  irrigation,
  pest,
  disease,
  visit,
  growthStage,
  other,
}

class Alert {
  final String id;
  final String parcelId;
  final String title;
  final String message;
  final AlertSeverity severity;
  final AlertCategory category;
  final DateTime createdAt;
  final bool isRead;

  const Alert({
    required this.id,
    required this.parcelId,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.createdAt,
    this.isRead = false,
  });

  Alert copyWith({bool? isRead}) => Alert(
    id: id,
    parcelId: parcelId,
    title: title,
    message: message,
    severity: severity,
    category: category,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}

class AlertEngine extends StateNotifier<List<Alert>> {
  final Ref _ref;

  AlertEngine(this._ref) : super([]) {
    // Defer side effect to a microtask so the notifier is fully constructed
    // before any downstream provider is read.
    Future.microtask(refresh);
  }

  Box get _obsBox => Hive.box(AppConstants.boxObservations);

  /// Public entry point so screens can force regeneration after a sync.
  Future<void> refresh() => _generateAlerts();

  Future<void> _generateAlerts() async {
    final alerts = <Alert>[];
    final now = DateTime.now();

    // Get all parcels
    final parcels = _ref.read(parcelsProvider);

    for (final parcel in parcels) {
      // 1. Visit overdue (no visit in 14 days)
      final daysSince = now.difference(parcel.lastVisit).inDays;
      if (daysSince > 14) {
        alerts.add(
          Alert(
            id: '${parcel.id}_visit',
            parcelId: parcel.id,
            title: 'Visite oubliée',
            message: 'Pas de visite depuis 14 jours sur ${parcel.name}.',
            severity: AlertSeverity.medium,
            category: AlertCategory.visit,
            createdAt: now,
          ),
        );
      }

      // 2. Critical growth stage without recent visit
      final criticalStages = ['flowering', 'fruiting', 'ripening'];
      if (criticalStages.contains(parcel.growthStage) && daysSince > 7) {
        alerts.add(
          Alert(
            id: '${parcel.id}_stage',
            parcelId: parcel.id,
            title: 'Stade critique',
            message:
                '${parcel.name} est à ${parcel.growthStage} sans visite récente.',
            severity: AlertSeverity.high,
            category: AlertCategory.growthStage,
            createdAt: now,
          ),
        );
      }

      // 3. Check last observation for drought stress
      final lastObs = _getLastObservation(parcel.id);
      if (lastObs != null) {
        final soilMoisture = lastObs['soilMoisture'] as String?;
        if (soilMoisture == 'dry') {
          alerts.add(
            Alert(
              id: '${parcel.id}_drought',
              parcelId: parcel.id,
              title: 'Stress hydrique',
              message: 'Dernière observation: sol sec sur ${parcel.name}.',
              severity: AlertSeverity.high,
              category: AlertCategory.irrigation,
              createdAt: now,
            ),
          );
        }
      }

      // 4. Resistance risk check (Step 1.1)
      if (parcel.treatmentHistory.isNotEmpty) {
        final recentTreatments = parcel.treatmentHistory
            .where((t) =>
                now.difference(t.date).inDays <= 21 && t.resistanceCode != null)
            .toList();

        if (recentTreatments.isNotEmpty) {
          // Use a simple map to count occurrences of resistance codes
          final counts = <String, int>{};
          for (final t in recentTreatments) {
            final code = t.resistanceCode!;
            counts[code] = (counts[code] ?? 0) + 1;
          }

          for (final entry in counts.entries) {
            if (entry.value >= 2) {
              alerts.add(
                Alert(
                  id: '${parcel.id}_resistance_${entry.key}',
                  parcelId: parcel.id,
                  title: 'Risque de résistance',
                  message:
                      'Attention : le code ${entry.key} utilisé ${entry.value} fois en 21j sur ${parcel.name}. Changez de molécule !',
                  severity: AlertSeverity.urgent,
                  category: AlertCategory.pest,
                  createdAt: now,
                ),
              );
            }
          }
        }
      }
    }

    // 4. Weather alert (API required for real production alerts)

    // Limit max alerts
    if (alerts.length > 20) {
      alerts.removeRange(20, alerts.length);
    }

    state = alerts;
  }

  Map<String, dynamic>? _getLastObservation(String parcelId) {
    try {
      final obsList = _obsBox.values
          .where((o) => o is Map && o['parcelId'] == parcelId)
          .toList();
      if (obsList.isEmpty) return null;

      obsList.sort((a, b) {
        final aAt = DateTime.tryParse(a['at']?.toString() ?? '') ??
            DateTime(2000);
        final bAt = DateTime.tryParse(b['at']?.toString() ?? '') ??
            DateTime(2000);
        return bAt.compareTo(aAt);
      });

      return Map<String, dynamic>.from(obsList.first as Map);
    } catch (e, st) {
      debugPrint('AlertEngine: failed reading observations: $e\n$st');
      return null;
    }
  }

  Future<void> markAsRead(String alertId) async {
    final index = state.indexWhere((a) => a.id == alertId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        state[index].copyWith(isRead: true),
        ...state.sublist(index + 1),
      ];
    }
  }


  int get unreadCount => state.where((a) => !a.isRead).length;
}

final alertEngineProvider = StateNotifierProvider<AlertEngine, List<Alert>>(
  (ref) => AlertEngine(ref),
);

final unreadAlertCountProvider = Provider<int>((ref) {
  final alerts = ref.watch(alertEngineProvider);
  return alerts.where((a) => !a.isRead).length;
});
