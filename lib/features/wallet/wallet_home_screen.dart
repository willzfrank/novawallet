import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/locale/locale_provider.dart';
import '../../core/money/money.dart';
import '../../l10n/app_localizations.dart';
import '../../models/transaction.dart';
import '../../queue/queue_processor.dart';
import '../save/save_goals_screen.dart';
import '../send/send_money_flow.dart';
import 'transaction_group.dart';
import 'wallet_provider.dart';

class WalletHomeScreen extends ConsumerWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final walletAsync = ref.watch(walletProvider);
    final pendingCount = ref.watch(queueProcessorProvider);
    final processor = ref.read(queueProcessorProvider.notifier);
    final deadCount = processor.deadCount();
    final deadReason = processor.firstDeadFailureReason();

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
                    label: deadReason == null || deadReason.isEmpty
                        ? l10n.deadActions(deadCount)
                        : '${l10n.deadActions(deadCount)} — $deadReason',
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
                                  deadReason == null || deadReason.isEmpty
                                      ? '⚠️ ${l10n.deadActions(deadCount)}'
                                      : '⚠️ ${l10n.deadActions(deadCount)} — $deadReason',
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
                _TransactionGroupedSliver(
                  transactions: wallet.transactions,
                  todayLabel: l10n.today,
                  yesterdayLabel: l10n.yesterday,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionGroupedSliver extends StatelessWidget {
  const _TransactionGroupedSliver({
    required this.transactions,
    required this.todayLabel,
    required this.yesterdayLabel,
  });

  final List<Transaction> transactions;
  final String todayLabel;
  final String yesterdayLabel;

  @override
  Widget build(BuildContext context) {
    final groups = groupTransactions(
      transactions,
      todayLabel: todayLabel,
      yesterdayLabel: yesterdayLabel,
    );

    // Flatten groups into header + item rows for lazy SliverList.
    final rows = <_TxnRow>[];
    for (final group in groups) {
      rows.add(_TxnRow.header(group.label));
      for (final txn in group.transactions) {
        rows.add(_TxnRow.item(txn));
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final row = rows[index];
            if (row.isHeader) {
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  row.label!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              );
            }
            final txn = row.txn!;
            final isDebit = txn.type == 'debit';
            final amountLabel =
                '${isDebit ? '-' : '+'}${Money.formatKobo(txn.amountKobo)}';
            return Semantics(
              label: '${txn.description}, $amountLabel, ${txn.type}',
              child: ListTile(
                leading: Icon(
                  isDebit ? Icons.arrow_upward : Icons.arrow_downward,
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
          childCount: rows.length,
        ),
      ),
    );
  }
}

class _TxnRow {
  _TxnRow.header(this.label)
      : txn = null,
        isHeader = true;

  _TxnRow.item(this.txn)
      : label = null,
        isHeader = false;

  final String? label;
  final Transaction? txn;
  final bool isHeader;
}
