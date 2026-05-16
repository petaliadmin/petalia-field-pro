import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../network/dio_provider.dart';

/// Gère les crédits agronomiques pour les services payants (NDVI, IA).
class CreditService extends StateNotifier<int> {
  final Ref _ref;
  static const String _kCredits = 'user_credits';

  static const int costNdvi = 1;
  static const int costAiDiagnostic = 1;
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

  Future<bool> useCredits(int amount) async {
    if (state >= amount) {
      // Dans un vrai système, on ferait un POST /wallet/debit
      state -= amount;
      await _box.put(_kCredits, state);
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
