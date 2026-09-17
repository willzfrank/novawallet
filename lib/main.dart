import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/locale/fallback_localizations.dart';
import 'core/locale/locale_provider.dart';
import 'core/network/connectivity_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/app_storage.dart';
import 'features/wallet/wallet_home_screen.dart';
import 'l10n/app_localizations.dart';
import 'queue/queue_processor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = AppStorage();
  await storage.init();

  final notifications = NotificationService();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const NovaWalletApp(),
    ),
  );
}

class NovaWalletApp extends ConsumerStatefulWidget {
  const NovaWalletApp({super.key});

  @override
  ConsumerState<NovaWalletApp> createState() => _NovaWalletAppState();
}

class _NovaWalletAppState extends ConsumerState<NovaWalletApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Simulator connectivity can lag; flush queue on foreground as fallback.
    // processPending itself no-ops when offline (MockApi is local).
    if (state == AppLifecycleState.resumed &&
        ref.read(isOnlineProvider)) {
      ref.read(queueProcessorProvider.notifier).processPending();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    // Belt-and-suspenders: flush queue when Offline chip flips to Online,
    // even if QueueProcessor rebuild timing misses the transition.
    ref.listen<bool>(isOnlineProvider, (wasOnline, online) {
      if (online && wasOnline == false) {
        ref.read(queueProcessorProvider.notifier).processPending();
      }
    });

    return MaterialApp(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appName ?? 'NovaWallet',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        FallbackWidgetsLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6E4F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const WalletHomeScreen(),
    );
  }
}
