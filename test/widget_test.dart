import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:nova_wallet/core/auth/biometric_service.dart';
import 'package:nova_wallet/core/network/connectivity_provider.dart';
import 'package:nova_wallet/core/network/mock_api_service.dart';
import 'package:nova_wallet/core/notifications/notification_service.dart';
import 'package:nova_wallet/core/storage/app_storage.dart';
import 'package:nova_wallet/features/save/save_goals_screen.dart';
import 'package:nova_wallet/features/save/save_provider.dart';
import 'package:nova_wallet/features/send/send_money_flow.dart';
import 'package:nova_wallet/l10n/app_localizations.dart';
import 'package:nova_wallet/queue/queue_processor.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Send Money flow: step 1 → 2 → 3 → confirm', (tester) async {
    final dir = Directory(
      '${Directory.systemTemp.path}/nova_w_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync();
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final storage = AppStorage();
    await tester.runAsync(() async {
      await storage.init(testPath: dir.path);
    });
    final container = ProviderContainer(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
        mockApiProvider.overrideWithValue(
          MockApiService(failureRate: 0, delay: Duration.zero),
        ),
        notificationServiceProvider.overrideWithValue(
          NoOpNotificationService(),
        ),
        biometricServiceProvider.overrideWithValue(NoOpBiometricService()),
        connectivityProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.none]),
        ),
        isOnlineProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: SendMoneyFlow(),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Step 1/3'), findsOneWidget);
    await tester.tap(find.text('Ada Okafor'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('send_next_recipient')));
    await tester.pump();

    expect(find.textContaining('Step 2/3'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1500.75');
    await tester.tap(find.byKey(const Key('send_next_amount')));
    await tester.pump();

    expect(find.textContaining('Step 3/3'), findsOneWidget);
    expect(find.textContaining('Reference id'), findsOneWidget);
    expect(find.byKey(const Key('send_confirm')), findsOneWidget);

    await tester.runAsync(() async {
      await container.read(queueProcessorProvider.notifier).enqueue(
            type: 'send',
            payload: {
              'recipient': 'Ada Okafor',
              'amountKobo': 150075,
            },
          );
    });

    expect(storage.queueBox.length, 1);
    expect(storage.queueBox.values.first.type, 'send');
    expect(storage.queueBox.values.first.payload['amountKobo'], 150075);
    expect(storage.queueBox.values.first.status, 'pending');
  });

  testWidgets('NovaSave contribution updates progress bar', (tester) async {
    final dir = Directory(
      '${Directory.systemTemp.path}/nova_w_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync();
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final storage = AppStorage();
    await tester.runAsync(() async {
      await storage.init(testPath: dir.path);
    });
    final container = ProviderContainer(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
        mockApiProvider.overrideWithValue(
          MockApiService(failureRate: 0, delay: Duration.zero),
        ),
        notificationServiceProvider.overrideWithValue(
          NoOpNotificationService(),
        ),
        biometricServiceProvider.overrideWithValue(NoOpBiometricService()),
        connectivityProvider.overrideWith(
          (ref) => Stream.value([ConnectivityResult.none]),
        ),
        isOnlineProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    final goal = storage.goalsBox.values.first;
    expect(goal.progressPercent, 50);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ContributeScreen(goalId: goal.id),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.5, 0.01),
    );

    storage.goalsBox.put(
      goal.id,
      goal.copyWith(savedAmountKobo: goal.savedAmountKobo + 10000000),
    );
    container.read(saveGoalsProvider.notifier).reload();
    await tester.pump();

    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.6, 0.01),
    );
  });
}
