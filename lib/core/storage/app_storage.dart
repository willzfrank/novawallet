import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/queued_action.dart';
import '../../models/save_goal.dart';
import '../../models/transaction.dart';

const String kQueueBox = 'queued_actions';
const String kTxnBox = 'transactions';
const String kGoalsBox = 'save_goals';
const String kMetaBox = 'meta';
const String kBalanceKey = 'wallet_balance_kobo';
const String kSeededKey = 'seeded';

class AppStorage {
  AppStorage({FlutterSecureStorage? secureStorage})
      : secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage secureStorage;
  static const _uuid = Uuid();

  /// In-memory secure map for widget/unit tests (no platform channels).
  Map<String, String>? _memorySecure;

  late Box<QueuedAction> queueBox;
  late Box<Transaction> txnBox;
  late Box<SaveGoal> goalsBox;
  late Box metaBox;

  Future<void> init({String? testPath}) async {
    if (testPath != null) {
      Hive.init(testPath);
      _memorySecure = {};
    } else {
      await Hive.initFlutter();
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(QueuedActionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SaveGoalAdapter());
    }

    queueBox = await Hive.openBox<QueuedAction>(kQueueBox);
    txnBox = await Hive.openBox<Transaction>(kTxnBox);
    goalsBox = await Hive.openBox<SaveGoal>(kGoalsBox);
    metaBox = await Hive.openBox(kMetaBox);

    await _seedIfNeeded();
    await recoverStuckActions();
  }

  /// Crash recovery: processing → pending on app start.
  Future<void> recoverStuckActions() async {
    for (final key in queueBox.keys) {
      final action = queueBox.get(key);
      if (action != null && action.status == 'processing') {
        await queueBox.put(key, action.copyWith(status: 'pending'));
      }
    }
  }

  Future<int> getBalanceKobo() async {
    if (_memorySecure != null) {
      return int.tryParse(_memorySecure![kBalanceKey] ?? '0') ?? 0;
    }
    final raw = await secureStorage.read(key: kBalanceKey);
    if (raw == null) return 0;
    return int.tryParse(raw) ?? 0;
  }

  Future<void> setBalanceKobo(int kobo) async {
    if (_memorySecure != null) {
      _memorySecure![kBalanceKey] = kobo.toString();
      return;
    }
    await secureStorage.write(key: kBalanceKey, value: kobo.toString());
  }

  Future<void> _seedIfNeeded() async {
    final seeded = metaBox.get(kSeededKey) == true;
    if (seeded) return;

    await setBalanceKobo(250000000); // ₦2,500,000

    final now = DateTime.now();
    final seeds = <Transaction>[
      Transaction(
        id: _uuid.v4(),
        description: 'Salary — Acme NG',
        amountKobo: 50000000,
        type: 'credit',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: _uuid.v4(),
        description: 'Transfer to Ada',
        amountKobo: 150075,
        type: 'debit',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Transaction(
        id: _uuid.v4(),
        description: 'POS — Shoprite',
        amountKobo: 245050,
        type: 'debit',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Transaction(
        id: _uuid.v4(),
        description: 'Airtime top-up',
        amountKobo: 200000,
        type: 'debit',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Transaction(
        id: _uuid.v4(),
        description: 'Refund — Jumia',
        amountKobo: 890000,
        type: 'credit',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Transaction(
        id: _uuid.v4(),
        description: 'Uber trip',
        amountKobo: 350000,
        type: 'debit',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      Transaction(
        id: _uuid.v4(),
        description: 'Freelance payout',
        amountKobo: 12000000,
        type: 'credit',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Transaction(
        id: _uuid.v4(),
        description: 'Electricity — IKEDC',
        amountKobo: 750000,
        type: 'debit',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      Transaction(
        id: _uuid.v4(),
        description: 'Transfer from Kunle',
        amountKobo: 5000000,
        type: 'credit',
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      Transaction(
        id: _uuid.v4(),
        description: 'Netflix subscription',
        amountKobo: 460000,
        type: 'debit',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];

    for (final txn in seeds) {
      await txnBox.put(txn.id, txn);
    }

    final goal = SaveGoal(
      id: _uuid.v4(),
      name: 'Lagos Trip',
      targetAmountKobo: 100000000, // ₦1,000,000
      savedAmountKobo: 50000000, // 50% funded
      targetDate: now.add(const Duration(days: 90)),
    );
    await goalsBox.put(goal.id, goal);

    await metaBox.put(kSeededKey, true);
  }
}
