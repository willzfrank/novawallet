import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:nova_wallet/core/auth/biometric_service.dart';
import 'package:nova_wallet/core/network/connectivity_provider.dart';
import 'package:nova_wallet/core/network/mock_api_service.dart';
import 'package:nova_wallet/core/notifications/notification_service.dart';
import 'package:nova_wallet/core/storage/app_storage.dart';
import 'package:nova_wallet/features/wallet/wallet_home_screen.dart';
import 'package:nova_wallet/l10n/app_localizations.dart';
import 'package:nova_wallet/models/queued_action.dart';
import 'package:nova_wallet/models/transaction.dart';
import 'package:nova_wallet/queue/queue_processor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('wallet home golden', (tester) async {
    final dir = Directory(
      '${Directory.systemTemp.path}/nova_golden_${DateTime.now().microsecondsSinceEpoch}',
    )..createSync();
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final storage = AppStorage();
    await tester.runAsync(() async {
      await storage.init(testPath: dir.path);
      await storage.setBalanceKobo(250000000);

      // Replace seeded txns with exactly 3 fixed ones for stable goldens.
      await storage.txnBox.clear();
      final fixed = DateTime.utc(2025, 1, 15);
      final txns = [
        Transaction(
          id: 'txn-1',
          description: 'Salary — Acme NG',
          amountKobo: 50000000,
          type: 'credit',
          createdAt: fixed,
        ),
        Transaction(
          id: 'txn-2',
          description: 'Transfer to Ada',
          amountKobo: 150075,
          type: 'debit',
          createdAt: fixed.subtract(const Duration(days: 1)),
        ),
        Transaction(
          id: 'txn-3',
          description: 'POS — Shoprite',
          amountKobo: 245050,
          type: 'debit',
          createdAt: fixed.subtract(const Duration(days: 2)),
        ),
      ];
      for (final t in txns) {
        await storage.txnBox.put(t.id, t);
      }

      await storage.queueBox.put(
        'pending-1',
        QueuedAction(
          id: 'pending-1',
          type: 'send',
          payload: {'recipient': 'Ada Okafor', 'amountKobo': 150075},
          status: 'pending',
          createdAt: fixed,
        ),
      );
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
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
            (ref) => Stream.value([ConnectivityResult.wifi]),
          ),
          isOnlineProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: WalletHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(WalletHomeScreen),
      matchesGoldenFile('goldens/wallet_home.png'),
    );
  });
}
