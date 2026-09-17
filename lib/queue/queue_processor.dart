import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../core/network/connectivity_provider.dart';
import '../core/network/mock_api_service.dart';
import '../core/storage/app_storage.dart';
import '../features/save/save_provider.dart';
import '../features/wallet/wallet_provider.dart';
import '../models/queued_action.dart';
import '../models/transaction.dart';

part 'queue_processor.g.dart';

@Riverpod(keepAlive: true)
AppStorage appStorage(AppStorageRef ref) {
  throw UnimplementedError('Override appStorageProvider in main');
}

@Riverpod(keepAlive: true)
MockApiService mockApi(MockApiRef ref) => MockApiService();

@Riverpod(keepAlive: true)
class QueueProcessor extends _$QueueProcessor {
  static const _uuid = Uuid();
  bool _processing = false;
  bool _rerunRequested = false;

  @override
  int build() {
    // Spec: ref.listen connectivityProvider → auto-process when back online.
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityProvider,
      (prev, next) {
        next.whenData((results) {
          final online = results.isNotEmpty &&
              !results.every((r) => r == ConnectivityResult.none);
          final wasOffline = prev?.asData?.value.every(
                (r) => r == ConnectivityResult.none,
              ) ??
              false;
          if (online && (wasOffline || prev == null)) {
            processPending();
          }
        });
      },
    );

    final storage = ref.watch(appStorageProvider);
    return _pendingCount(storage);
  }

  int _pendingCount(AppStorage storage) {
    return storage.queueBox.values
        .where((a) => a.status == 'pending' || a.status == 'processing')
        .length;
  }

  void refreshCount() {
    state = _pendingCount(ref.read(appStorageProvider));
  }

  Future<QueuedAction> enqueue({
    required String type,
    required Map<String, dynamic> payload,
    String? id,
  }) async {
    final storage = ref.read(appStorageProvider);
    final action = QueuedAction(
      id: id ?? _uuid.v4(),
      type: type,
      payload: payload,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await storage.queueBox.put(action.id, action);
    refreshCount();
    return action;
  }

  Future<({QueuedAction action, bool queuedOffline})> submitOrQueue({
    required String type,
    required Map<String, dynamic> payload,
    required bool online,
    String? idempotencyKey,
  }) async {
    final action = await enqueue(
      type: type,
      payload: payload,
      id: idempotencyKey,
    );
    if (online) {
      await processPending();
      final stillThere =
          ref.read(appStorageProvider).queueBox.containsKey(action.id);
      return (action: action, queuedOffline: stillThere);
    }
    return (action: action, queuedOffline: true);
  }

  Future<void> processPending() async {
    if (_processing) {
      _rerunRequested = true;
      return;
    }
    _processing = true;
    try {
      do {
        _rerunRequested = false;
        final storage = ref.read(appStorageProvider);
        final api = ref.read(mockApiProvider);

        final pending = storage.queueBox.values
            .where((a) => a.status == 'pending')
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        for (final action in pending) {
          // Hive local puts are applied synchronously; avoid awaiting Futures
          // that can stall under Flutter test fake-async.
          storage.queueBox.put(
            action.id,
            action.copyWith(status: 'processing'),
          );
          refreshCount();

          final bool ok;
          if (action.type == 'send') {
            ok = await api.sendMoney(action.payload, action.id);
          } else if (action.type == 'contribute') {
            ok = await api.contribute(action.payload, action.id);
          } else {
            ok = false;
          }

          if (ok) {
            await _applySideEffects(action);
            storage.queueBox.delete(action.id);
          } else {
            storage.queueBox.put(
              action.id,
              action.copyWith(status: 'pending'),
            );
          }
          refreshCount();
        }
      } while (_rerunRequested);
    } finally {
      _processing = false;
      refreshCount();
    }
  }

  Future<void> _applySideEffects(QueuedAction action) async {
    final storage = ref.read(appStorageProvider);
    final amountKobo = action.payload['amountKobo'] as int;

    if (action.type == 'send') {
      final recipient = action.payload['recipient'] as String? ?? 'Unknown';
      final balance = await storage.getBalanceKobo();
      await storage.setBalanceKobo(balance - amountKobo);
      final txn = Transaction(
        id: action.id,
        description: 'Send to $recipient',
        amountKobo: amountKobo,
        type: 'debit',
        createdAt: DateTime.now(),
      );
      storage.txnBox.put(txn.id, txn);
      ref.invalidate(walletProvider);
    } else if (action.type == 'contribute') {
      final goalId = action.payload['goalId'] as String;
      final goal = storage.goalsBox.get(goalId);
      if (goal != null) {
        final updated = goal.copyWith(
          savedAmountKobo: goal.savedAmountKobo + amountKobo,
        );
        storage.goalsBox.put(goalId, updated);
      }
      final balance = await storage.getBalanceKobo();
      await storage.setBalanceKobo(balance - amountKobo);
      final txn = Transaction(
        id: action.id,
        description: 'NovaSave: ${goal?.name ?? 'Goal'}',
        amountKobo: amountKobo,
        type: 'debit',
        createdAt: DateTime.now(),
      );
      storage.txnBox.put(txn.id, txn);
      ref.invalidate(walletProvider);
      ref.invalidate(saveGoalsProvider);
    }
  }
}
