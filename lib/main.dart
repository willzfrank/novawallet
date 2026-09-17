import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/locale/locale_provider.dart';
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
    if (state == AppLifecycleState.resumed) {
      ref.read(queueProcessorProvider.notifier).processPending();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appName ?? 'NovaWallet',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
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
