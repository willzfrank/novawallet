# NovaWallet

Nigerian fintech take-home: wallet, send money, NovaSave, offline queue with idempotency.

## Flutter / Dart version

- Flutter **3.47.4** (stable)
- Dart **3.13.3**

SDK lives at `../tools/flutter` if installed with this workspace; otherwise use your local Flutter stable on `PATH`.

```bash
flutter --version
```

## How to Run

```bash
cd nova_wallet
flutter pub get
flutter run
```

Tests:

```bash
flutter test
flutter test integration_test/queue_sync_test.dart
```

## Architecture

```
lib/
  core/
    money/          # int kobo ↔ display formatting
    storage/        # Hive boxes + flutter_secure_storage (balance)
    network/        # connectivity_plus + MockApiService
  features/
    wallet/         # home, balance, transactions
    send/           # 3-step send flow
    save/           # goals + contribute
  queue/            # offline queue processor
  models/           # QueuedAction, Transaction, SaveGoal (Hive adapters)
  main.dart
```

- **UI** → Riverpod notifiers → Hive / secure storage → MockApiService
- Money never leaves the int-kobo domain until `Money.formatKobo`

## State Management Choice (Riverpod — why)

- **hooks_riverpod** for `HookConsumerWidget` in multi-step forms (send / contribute) without StatefulWidget boilerplate
- **riverpod_annotation** is a declared dependency for the intended codegen style (`@riverpod` Notifiers)
- Providers implemented as equivalent `Notifier` / `AsyncNotifier` / `StreamProvider` APIs (what `riverpod_generator` emits)
  - Full `build_runner` codegen currently hits an analyzer/SDK mismatch on Dart 3.13 (`visitDotShorthandPropertyAccess`); Notifier API keeps the same mental model and runtime behavior

Why Riverpod over Bloc/GetX:

- Compile-safe DI via `ProviderScope` overrides (tests inject Hive + MockApi)
- `ref.listen` on `connectivityProvider` drives queue auto-sync cleanly
- Fine-grained rebuilds for balance / pending badge / goals

## Offline Queue Design

1. **Persist**: every action is a Hive `QueuedAction` with UUID v4 `id` (idempotency key) created once
2. **Crash recovery**: on `AppStorage.init`, any `status == processing` → `pending`
3. **Connectivity**: `connectivityProvider` (`StreamProvider`) watched; `QueueProcessorNotifier` uses `ref.listen` to call `processPending()` when online
4. **Loop**: pending → processing → MockApi (1s + 10% fail) → success deletes row / failure resets pending
5. **Idempotency**: MockApi keeps a `Set` of keys; duplicates return `true` without re-applying side effects
6. **Survival**: queue is Hive-only — app kill mid-flight recovers via step 2

## Kobo Money Handling

- All amounts stored/computed as **`int` kobo**
- `₦1,500.75` = `150075`
- Display only: `Money.formatKobo` → `NumberFormat.currency(locale: 'en_NG', symbol: '₦')` with `kobo / 100`
- Parse Naira input → kobo via string split (no `double` money math)
- Wallet balance in **flutter_secure_storage** (not SharedPreferences)

## Trade-offs & Assumptions

- Mock API is in-process (no real HTTP); failure rate injectable for tests (`failureRate: 0`)
- Side effects (debit balance, write txn, bump goal) apply only after MockApi success
- Online submit still goes through the queue (enqueue then process) so idempotency key + crash recovery stay consistent
- Contacts are mock strings; no bank account validation
- `SliverChildBuilderDelegate` / `ListView.builder` used for lists (lazy)
- macOS/iOS need secure storage entitlements (Flutter plugin defaults)
- Connectivity events on iOS Simulator can lag; app foreground resume (`AppLifecycleState.resumed`) triggers a queue flush as a fallback. Physical device recommended for offline demo.
