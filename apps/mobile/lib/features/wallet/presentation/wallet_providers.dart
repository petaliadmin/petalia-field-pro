import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/services/credit_service.dart';

class WalletTransaction {
  final String id;
  final String type; // CREDIT, DEBIT
  final String operationType; // TOPUP, RECHARGE, TRANSFER, etc.
  final int amount;
  final String description;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.operationType,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'CREDIT',
      operationType: json['operationType'] as String? ?? 'TOPUP',
      amount: json['amount'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

final showBalanceProvider = StateProvider<bool>((ref) => true);

final walletTransactionsProvider = FutureProvider<List<WalletTransaction>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/wallet/transactions');
    final list = res.data['transactions'] as List? ?? [];
    return list.map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  } catch (e) {
    print('Error loading transactions: $e');
    return [];
  }
});

class WalletController extends StateNotifier<AsyncValue<void>> {
  WalletController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> transferCredits(String recipientPhone, int amount, String description) async {
    state = const AsyncLoading();
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/wallet/transfer', data: {
        'recipientPhone': recipientPhone,
        'amount': amount,
        'description': description,
      });

      // Rafraîchir le solde et l'historique
      await _ref.read(creditServiceProvider.notifier).refreshBalance();
      _ref.invalidate(walletTransactionsProvider);

      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}

final walletControllerProvider = StateNotifierProvider<WalletController, AsyncValue<void>>((ref) {
  return WalletController(ref);
});
