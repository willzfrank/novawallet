import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:nova_wallet/core/network/connectivity_provider.dart';
import 'package:nova_wallet/core/network/mock_api_service.dart';
import 'package:nova_wallet/core/storage/app_storage.dart';
import 'package:nova_wallet/queue/queue_processor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('submitOrQueue online processes once', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final dir = await Directory.systemTemp.createTemp('nova_q_');
    final storage = AppStorage();
    await storage.init(testPath: dir.path);
    final api = MockApiService(failureRate: 0, delay: Duration.zero);
    final container = ProviderContainer(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
        mockApiProvider.overrideWithValue(api),
        connectivityProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.wifi]),
        ),
        isOnlineProvider.overrideWithValue(true),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await Hive.close();
      await dir.delete(recursive: true);
    });

    final result =
        await container.read(queueProcessorProvider.notifier).submitOrQueue(
              type: 'send',
              payload: {'recipient': 'Ada', 'amountKobo': 150075},
              online: true,
              idempotencyKey: 'test-key-1',
            );

    expect(api.processedKeys.contains('test-key-1'), isTrue);
    expect(storage.queueBox.isEmpty, isTrue);
    expect(result.queuedOffline, isFalse);
  });
}
