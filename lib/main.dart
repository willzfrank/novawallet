import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/storage/app_storage.dart';
import 'features/wallet/wallet_home_screen.dart';
import 'queue/queue_processor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = AppStorage();
  await storage.init();

  runApp(
    ProviderScope(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
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
    return MaterialApp(
      title: 'NovaWallet',
      debugShowCheckedModeBanner: false,
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
