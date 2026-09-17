part of 'wallet_provider.dart';

@ProviderFor(Wallet)
final walletProvider =
    AsyncNotifierProvider<Wallet, WalletState>(Wallet.new);

abstract class _$Wallet extends AsyncNotifier<WalletState> {}
