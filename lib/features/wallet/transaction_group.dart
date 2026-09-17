import 'package:intl/intl.dart';

import '../../models/transaction.dart';

class TransactionGroup {
  TransactionGroup({
    required this.label,
    required this.transactions,
  });

  /// 'Today', 'Yesterday', or 'DD MMM YYYY' (or localized equivalents).
  final String label;
  final List<Transaction> transactions;
}

/// Sort descending by [Transaction.createdAt], group by calendar day.
List<TransactionGroup> groupTransactions(
  List<Transaction> txns, {
  String todayLabel = 'Today',
  String yesterdayLabel = 'Yesterday',
  DateTime? now,
}) {
  if (txns.isEmpty) return [];

  final sorted = List<Transaction>.from(txns)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateFormat = DateFormat('dd MMM yyyy');

  final Map<String, List<Transaction>> buckets = {};
  final List<String> order = [];

  for (final txn in sorted) {
    final day = DateTime(
      txn.createdAt.year,
      txn.createdAt.month,
      txn.createdAt.day,
    );
    final String label;
    if (day == today) {
      label = todayLabel;
    } else if (day == yesterday) {
      label = yesterdayLabel;
    } else {
      label = dateFormat.format(day);
    }
    if (!buckets.containsKey(label)) {
      buckets[label] = [];
      order.add(label);
    }
    buckets[label]!.add(txn);
  }

  return [
    for (final label in order)
      TransactionGroup(label: label, transactions: buckets[label]!),
  ];
}
