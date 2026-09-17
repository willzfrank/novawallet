import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivity(ConnectivityRef ref) {
  return Connectivity().onConnectivityChanged;
}

@riverpod
bool isOnline(IsOnlineRef ref) {
  final async = ref.watch(connectivityProvider);
  return async.maybeWhen(
    data: (results) =>
        results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none),
    orElse: () => true,
  );
}
