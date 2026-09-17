import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/locale/locale_provider.dart';
import '../../core/money/money.dart';
import '../../l10n/app_localizations.dart';
import '../../queue/queue_processor.dart';
import '../save/save_goals_screen.dart';
import '../send/send_money_flow.dart';
import 'wallet_provider.dart';

class WalletHomeScreen extends ConsumerWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final walletAsync = ref.watch(walletProvider);
    final pendingCount = ref.watch(queueProcessorProvider);
    final deadCount = ref.read(queueProcessorProvider.notifier).deadCount();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.walletHome),
        actions: [
          Semantics(
            button: true,
            label: 'Toggle language',
            hint: 'Double tap to switch between English and Yoruba',
            child: IconButton(
              key: const Key('locale_toggle'),
              icon: const Icon(Icons.language),
              onPressed: () => ref.read(localeProvider.notifier).toggle(),
            ),
          ),
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Semantics(
                label: l10n.pendingActions(pendingCount),
                hint: l10n.pullToRefresh,
                child: Chip(
                  avatar: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(l10n.pendingActions(pendingCount)),
                ),
              ),
            ),
        ],
      ),
      body: walletAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (wallet) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(walletProvider.notifier).refresh();
            await ref.read(queueProcessorProvider.notifier).processPending();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (deadCount > 0)
                SliverToBoxAdapter(
                  child: Semantics(
                    button: true,
                    label: l10n.deadActions(deadCount),
                    hint: l10n.retry,
                    child: Material(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: InkWell(
                        onTap: () {
                          ref
                              .read(queueProcessorProvider.notifier)
                              .retryDeadActions();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '⚠️ ${l10n.deadActions(deadCount)}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(queueProcessorProvider.notifier)
                                      .retryDeadActions();
                                },
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.balance,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        label:
                            '${l10n.balance} ${Money.formatKobo(wallet.balanceKobo)}',
                        child: Text(
                          Money.formatKobo(wallet.balanceKobo),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
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
                              label: l10n.sendMoneyTitle,
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
                                label: Text(l10n.send),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: l10n.novaSave,
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
                                label: Text(l10n.novaSave),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.recentTransactions,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              if (wallet.transactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(l10n.noTransactions)),
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
