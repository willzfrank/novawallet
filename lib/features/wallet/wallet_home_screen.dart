import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/money/money.dart';
import '../../queue/queue_processor.dart';
import '../save/save_goals_screen.dart';
import '../send/send_money_flow.dart';
import 'wallet_provider.dart';

class WalletHomeScreen extends ConsumerWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final pendingCount = ref.watch(queueProcessorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NovaWallet'),
        actions: [
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Semantics(
                label: '$pendingCount pending queue actions',
                hint: 'Pending actions will sync when online',
                child: Chip(
                  avatar: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text('$pendingCount pending'),
                ),
              ),
            ),
        ],
      ),
      body: walletAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (wallet) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(walletProvider.notifier).refresh();
            await ref.read(queueProcessorProvider.notifier).processPending();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available balance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        label: 'Wallet balance ${Money.formatKobo(wallet.balanceKobo)}',
                        child: Text(
                          Money.formatKobo(wallet.balanceKobo),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: 'Send money',
                              hint: 'Double tap to start send money flow',
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const SendMoneyFlow(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.send),
                                label: const Text('Send'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: 'NovaSave goals',
                              hint: 'Double tap to open savings goals',
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const SaveGoalsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.savings_outlined),
                                label: const Text('NovaSave'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Recent transactions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              if (wallet.transactions.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No transactions yet')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final txn = wallet.transactions[index];
                        final isDebit = txn.type == 'debit';
                        final amountLabel =
                            '${isDebit ? '-' : '+'}${Money.formatKobo(txn.amountKobo)}';
                        return Semantics(
                          label:
                              '${txn.description}, $amountLabel, ${txn.type}',
                          child: ListTile(
                            leading: Icon(
                              isDebit
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isDebit ? Colors.red : Colors.green,
                            ),
                            title: Text(txn.description),
                            subtitle: Text(
                              MaterialLocalizations.of(context)
                                  .formatShortDate(txn.createdAt),
                            ),
                            trailing: Text(
                              amountLabel,
                              style: TextStyle(
                                color: isDebit ? Colors.red : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: wallet.transactions.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
