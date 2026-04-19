library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../constants/app_constants.dart';
import '../../features/parcels/domain/parcel.dart';
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
    _generateAlerts();
  }

  Box get _obsBox => Hive.box(AppConstants.boxObservations);

  Future<void> _generateAlerts() async {
    final alerts = <Alert>[];
    final now = DateTime.now();
    final uuid = DateTime.now().millisecondsSinceEpoch.toString();

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
    }

    // 4. Weather alert (placeholder - would check real API in production)
    alerts.add(
      Alert(
        id: 'weather_alert',
        parcelId: '',
        title: 'Pluie prévue',
        message: 'Pluie prévue dans 48h. Reporter tout épandage pesticides.',
        severity: AlertSeverity.medium,
        category: AlertCategory.weather,
        createdAt: now,
      ),
    );

    // Limit max alerts
    if (alerts.length > 20) {
      alerts.removeRange(20, alerts.length);
    }

    state = alerts;
  }

  Map<String, dynamic>? _getLastObservation(String parcelId) {
    final obsList = _obsBox.values
        .where((o) => o['parcelId'] == parcelId)
        .toList();
    if (obsList.isEmpty) return null;

    obsList.sort((a, b) {
      final aAt = DateTime.tryParse(a['at'] ?? '') ?? DateTime(2000);
      final bAt = DateTime.tryParse(b['at'] ?? '') ?? DateTime(2000);
      return bAt.compareTo(aAt);
    });

    return Map<String, dynamic>.from(obsList.first);
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
