part of 'connectivity_provider.dart';

typedef ConnectivityRef = Ref;
typedef IsOnlineRef = Ref;

@ProviderFor(connectivity)
final connectivityProvider = StreamProvider<List<ConnectivityResult>>(
  connectivity,
  name: 'connectivityProvider',
);

@ProviderFor(isOnline)
final isOnlineProvider = Provider<bool>(
  isOnline,
  name: 'isOnlineProvider',
);
