import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivity(ConnectivityRef ref) async* {
  // Seed current link state — onConnectivityChanged alone can lag / miss
  // the first value, which made the app assume online and drain the mock API.
  yield await Connectivity().checkConnectivity();
  yield* Connectivity().onConnectivityChanged;
}

@Riverpod(keepAlive: true)
bool isOnline(IsOnlineRef ref) {
  final async = ref.watch(connectivityProvider);
  return async.maybeWhen(
    data: (results) =>
        results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none),
    // Offline-first: unknown / loading → do not auto-process queue.
    orElse: () => false,
  );
}
