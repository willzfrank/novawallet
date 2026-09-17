import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:nova_wallet/core/money/money_validator.dart';
import 'package:nova_wallet/core/network/connectivity_provider.dart';
import 'package:nova_wallet/core/network/mock_api_service.dart';
import 'package:nova_wallet/core/network/retry_policy.dart';
import 'package:nova_wallet/core/notifications/notification_service.dart';
import 'package:nova_wallet/core/storage/app_storage.dart';
import 'package:nova_wallet/models/queued_action.dart';
import 'package:nova_wallet/queue/queue_processor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late AppStorage storage;
  late ProviderContainer container;

  Future<void> setUpEnv({
    required MockApiService api,
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('nova_retry_');
    storage = AppStorage();
    await storage.init(testPath: dir.path);
    container = ProviderContainer(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
        mockApiProvider.overrideWithValue(api),
        notificationServiceProvider.overrideWithValue(
          NoOpNotificationService(),
        ),
        connectivityProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.wifi]),
        ),
        isOnlineProvider.overrideWithValue(true),
      ],
    );
    container.read(queueProcessorProvider.notifier).retryDelayOverride =
        (_) => Duration.zero;
  }

  tearDown(() async {
    container.dispose();
    await Hive.close();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('retries with backoff up to kMaxRetries then marks dead', () async {
    final api = MockApiService(failureRate: 1.0, delay: Duration.zero);
    await setUpEnv(api: api);

    final action =
        await container.read(queueProcessorProvider.notifier).enqueue(
              type: 'send',
              payload: {'recipient': 'Ada', 'amountKobo': 100},
            );

    await container.read(queueProcessorProvider.notifier).processPending();

    final dead = storage.queueBox.get(action.id);
    expect(dead, isNotNull);
    expect(dead!.status, 'dead');
    expect(dead.retryCount, kMaxRetries);
    expect(dead.failureReason, 'Max retries exceeded');
  });

  test('business error goes dead immediately, no retries', () async {
    final api = MockApiService(failureRate: 0, delay: Duration.zero);
    await setUpEnv(api: api);

    final action =
        await container.read(queueProcessorProvider.notifier).enqueue(
              type: 'send',
              payload: {
                'recipient': 'Ada',
                'amountKobo': 100,
                'forceBusinessError': true,
              },
            );

    await container.read(queueProcessorProvider.notifier).processPending();

    final dead = storage.queueBox.get(action.id);
    expect(dead, isNotNull);
    expect(dead!.status, 'dead');
    expect(dead.retryCount, 0);
    expect(dead.failureReason, 'INSUFFICIENT_FUNDS');
    expect(api.processAttempts[action.id], 1);
  });

  test('balance validation blocks enqueue', () async {
    final api = MockApiService(failureRate: 0, delay: Duration.zero);
    await setUpEnv(api: api);
    await storage.setBalanceKobo(100);

    expect(
      await MoneyValidator.validate(200, storage),
      'Insufficient balance',
    );
    expect(await MoneyValidator.validate(50, storage), isNull);
  });

  test('dead action after kMaxRetries, manual retry resets and succeeds',
      () async {
    final api = MockApiService(failureRate: 0, delay: Duration.zero);
    await setUpEnv(api: api);

    const id = 'dead-then-retry';
    await storage.queueBox.put(
      id,
      QueuedAction(
        id: id,
        type: 'send',
        payload: {'recipient': 'Ada', 'amountKobo': 100},
        status: 'dead',
        createdAt: DateTime.now(),
        retryCount: kMaxRetries,
        failureReason: 'Max retries exceeded',
      ),
    );

    await container.read(queueProcessorProvider.notifier).retryDeadActions();

    expect(storage.queueBox.isEmpty, isTrue);
    expect(api.processedKeys.contains(id), isTrue);
  });
}
