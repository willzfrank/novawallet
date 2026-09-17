import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nova_wallet/core/network/connectivity_provider.dart';
import 'package:nova_wallet/core/network/mock_api_service.dart';
import 'package:nova_wallet/core/storage/app_storage.dart';
import 'package:nova_wallet/queue/queue_processor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Offline queue syncs once when connectivity returns (idempotent)',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final tempDir =
          await Directory.systemTemp.createTemp('nova_wallet_int_');
      final storage = AppStorage();
      await storage.init(testPath: tempDir.path);

      final api = MockApiService(
        random: Random(1),
        failureRate: 0,
        delay: Duration.zero,
      );

      final container = ProviderContainer(
        overrides: [
          appStorageProvider.overrideWithValue(storage),
          mockApiProvider.overrideWithValue(api),
          connectivityProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.none]),
          ),
          isOnlineProvider.overrideWithValue(false),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await Hive.close();
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });

      container.read(queueProcessorProvider);

      final action =
          await container.read(queueProcessorProvider.notifier).enqueue(
                type: 'send',
                payload: {
                  'recipient': 'Ada Okafor',
                  'amountKobo': 150075,
                },
              );

      expect(storage.queueBox.length, 1);
      expect(storage.queueBox.get(action.id)?.status, 'pending');
      expect(api.processedKeys.contains(action.id), isFalse);

      // Simulate connectivity return → process queue.
      await container.read(queueProcessorProvider.notifier).processPending();

      expect(api.processedKeys.contains(action.id), isTrue);
      expect(api.processedKeys.length, 1);
      expect(api.processAttempts[action.id], 1);
      expect(storage.queueBox.isEmpty, isTrue);

      final dup = await api.sendMoney(
        {'recipient': 'Ada Okafor', 'amountKobo': 150075},
        action.id,
      );
      expect(dup, isTrue);
      expect(api.processedKeys.length, 1);
    },
  );
}
