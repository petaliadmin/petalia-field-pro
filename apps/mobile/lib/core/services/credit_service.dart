import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../network/dio_provider.dart';
import './sync_service.dart';

/// Gère les crédits agronomiques pour les services payants (NDVI, IA).
class CreditService extends StateNotifier<int> {
  final Ref _ref;
  static const String _kCredits = 'user_credits';

  static const int costNdvi = 1;
  static const int costAiDiagnostic = 2;
  static const int costExpertOpinion = 5;

  CreditService(this._ref) : super(0) {
    _loadLocal();
    refreshBalance();
  }

  Box get _box => Hive.box(AppConstants.boxSettings);

  int get credits => state;

  void _loadLocal() {
    state = _box.get(_kCredits, defaultValue: 50) as int;
  }

  Future<void> refreshBalance() async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get('/wallet/balance');
      final newBalance = response.data['balance'] as int;
      state = newBalance;
      await _box.put(_kCredits, newBalance);
    } catch (e) {
      print('Error refreshing balance: $e');
    }
  }

  Future<void> addCredits(int amount) async {
    // Note: On attend normalement le webhook backend, mais on peut forcer un refresh
    await refreshBalance();
  }

  Future<bool> useCredits(int amount, {String? description}) async {
    if (state >= amount) {
      state -= amount;
      await _box.put(_kCredits, state);

      final txId = const Uuid().v4();
      final desc = description ?? 'Consultation agronomique / IA';

      _ref.read(syncServiceProvider.notifier).enqueue({
        'op': 'wallet_tx',
        'id': txId,
        'amount': amount,
        'description': desc,
      });

      return true;
    }
    return false;
  }

  Future<void> refreshLocal(int newBalance) async {
    state = newBalance;
    await _box.put(_kCredits, newBalance);
  }
}

final creditServiceProvider = StateNotifierProvider<CreditService, int>((ref) => CreditService(ref));
