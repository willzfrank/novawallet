import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/transaction.dart';
import '../../queue/queue_processor.dart';

part 'wallet_provider.g.dart';

class WalletState {
  const WalletState({
    required this.balanceKobo,
    required this.transactions,
  });

  final int balanceKobo;
  final List<Transaction> transactions;
}

@riverpod
class Wallet extends _$Wallet {
  @override
  Future<WalletState> build() async {
    final storage = ref.watch(appStorageProvider);
    final balance = await storage.getBalanceKobo();
    final txns = storage.txnBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return WalletState(balanceKobo: balance, transactions: txns);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final storage = ref.read(appStorageProvider);
      final balance = await storage.getBalanceKobo();
      final txns = storage.txnBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return WalletState(balanceKobo: balance, transactions: txns);
    });
  }
}
