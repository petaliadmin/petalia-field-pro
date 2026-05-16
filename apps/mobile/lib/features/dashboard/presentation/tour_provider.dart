import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';

class TourState {
  final bool isActive;
  final List<String> parcelIds;
  final List<String> visitedIds;
  final DateTime? startTime;

  TourState({
    this.isActive = false,
    this.parcelIds = const [],
    this.visitedIds = const [],
    this.startTime,
  });

  int get total => parcelIds.length;
  int get visited => visitedIds.length;
  double get progress => total == 0 ? 0 : visited / total;
  bool get isCompleted => isActive && total > 0 && visited == total;

  TourState copyWith({
    bool? isActive,
    List<String>? parcelIds,
    List<String>? visitedIds,
    DateTime? startTime,
  }) {
    return TourState(
      isActive: isActive ?? this.isActive,
      parcelIds: parcelIds ?? this.parcelIds,
      visitedIds: visitedIds ?? this.visitedIds,
      startTime: startTime ?? this.startTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'isActive': isActive,
    'parcelIds': parcelIds,
    'visitedIds': visitedIds,
    'startTime': startTime?.toIso8601String(),
  };

  factory TourState.fromJson(Map<String, dynamic> json) => TourState(
    isActive: json['isActive'] ?? false,
    parcelIds: List<String>.from(json['parcelIds'] ?? []),
    visitedIds: List<String>.from(json['visitedIds'] ?? []),
    startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
  );
}

class TourNotifier extends StateNotifier<TourState> {
  TourNotifier() : super(TourState()) {
    _load();
  }

  static const _key = 'active_tour';

  void _load() {
    final box = Hive.box(AppConstants.boxSettings);
    final data = box.get(_key);
    if (data != null) {
      state = TourState.fromJson(Map<String, dynamic>.from(data));
    }
  }

  void _save() {
    final box = Hive.box(AppConstants.boxSettings);
    box.put(_key, state.toJson());
  }

  void start(List<String> parcelIds) {
    state = TourState(
      isActive: true,
      parcelIds: parcelIds,
      visitedIds: [],
      startTime: DateTime.now(),
    );
    _save();
  }

  void markVisited(String parcelId) {
    if (!state.isActive) return;
    if (state.visitedIds.contains(parcelId)) return;
    if (!state.parcelIds.contains(parcelId)) return;

    state = state.copyWith(
      visitedIds: [...state.visitedIds, parcelId],
    );
    _save();
  }

  void cancel() {
    state = TourState();
    _save();
  }
}

final tourProvider = StateNotifierProvider<TourNotifier, TourState>((ref) {
  return TourNotifier();
});
