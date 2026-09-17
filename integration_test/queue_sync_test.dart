import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nova_wallet/core/network/api_result.dart';
import 'package:nova_wallet/core/network/connectivity_provider.dart';
import 'package:nova_wallet/core/network/mock_api_service.dart';
import 'package:nova_wallet/core/notifications/notification_service.dart';
import 'package:nova_wallet/core/storage/app_storage.dart';
import 'package:nova_wallet/models/queued_action.dart';
import 'package:nova_wallet/queue/queue_processor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Offline queue syncs once via ref.listen on reconnect (idempotent)',
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

      final connectivityCtrl =
          StreamController<List<ConnectivityResult>>();

      final container = ProviderContainer(
        overrides: [
          appStorageProvider.overrideWithValue(storage),
          mockApiProvider.overrideWithValue(api),
          notificationServiceProvider.overrideWithValue(
            NoOpNotificationService(),
          ),
          connectivityProvider.overrideWith(
            (ref) => connectivityCtrl.stream,
          ),
        ],
      );
      addTearDown(() async {
        await connectivityCtrl.close();
        container.dispose();
        await Hive.close();
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });

      // Wire ref.listen before emitting — late events are not buffered.
      container.read(queueProcessorProvider);

      connectivityCtrl.add([ConnectivityResult.none]);
      await tester.pump();

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

      // Reconnect → ref.listen should auto-fire processPending.
      connectivityCtrl.add([ConnectivityResult.wifi]);
      await tester.pumpAndSettle();

      expect(api.processedKeys.contains(action.id), isTrue);
      expect(api.processedKeys.length, 1);
      expect(api.processAttempts[action.id], 1);
      expect(storage.queueBox.isEmpty, isTrue);

      final dup = await api.sendMoney(
        {'recipient': 'Ada Okafor', 'amountKobo': 150075},
        action.id,
      );
      expect(dup, isA<ApiSuccess>());
      expect(api.processedKeys.length, 1);
    },
  );

  testWidgets(
    'Crash recovery: processing → pending, then syncs exactly once',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final tempDir =
          await Directory.systemTemp.createTemp('nova_wallet_crash_');
      final storage = AppStorage();
      await storage.init(testPath: tempDir.path);

      final api = MockApiService(
        random: Random(1),
        failureRate: 0,
        delay: Duration.zero,
      );

      const actionId = 'crash-recovery-key';
      final stuck = QueuedAction(
        id: actionId,
        type: 'send',
        payload: {
          'recipient': 'Ada Okafor',
          'amountKobo': 150075,
        },
        status: 'processing',
        createdAt: DateTime.now(),
      );
      await storage.queueBox.put(actionId, stuck);
      expect(storage.queueBox.get(actionId)?.status, 'processing');

      await storage.recoverStuckActions();
      expect(storage.queueBox.get(actionId)?.status, 'pending');

      final connectivityCtrl =
          StreamController<List<ConnectivityResult>>();

      final container = ProviderContainer(
        overrides: [
          appStorageProvider.overrideWithValue(storage),
          mockApiProvider.overrideWithValue(api),
          notificationServiceProvider.overrideWithValue(
            NoOpNotificationService(),
          ),
          connectivityProvider.overrideWith(
            (ref) => connectivityCtrl.stream,
          ),
        ],
      );
      addTearDown(() async {
        await connectivityCtrl.close();
        container.dispose();
        await Hive.close();
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });

      container.read(queueProcessorProvider);
      connectivityCtrl.add([ConnectivityResult.none]);
      await tester.pump();

      connectivityCtrl.add([ConnectivityResult.wifi]);
      await tester.pumpAndSettle();

      expect(api.processedKeys.contains(actionId), isTrue);
      expect(api.processAttempts[actionId], 1);
      expect(storage.queueBox.isEmpty, isTrue);
    },
  );
}
