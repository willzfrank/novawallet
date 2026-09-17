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
4. **Loop**: pending → processing → MockApi (1s + 10% fail) → success deletes row / failure increments `retryCount` (dead at ≥3) or resets pending
5. **Idempotency**: MockApi keeps a `Set` of keys; duplicates return `true` without re-applying side effects
6. **Survival**: queue is Hive-only — app kill mid-flight recovers via step 2
7. **Notifications**: successful sync triggers local notification via `NotificationService`

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

## Stretch Goals Implemented

- **Balance validation** — `MoneyValidator` blocks enqueue when amount ≤ 0 or exceeds wallet balance
- **Local notifications** — `flutter_local_notifications` channel `nova_sync` / “Queue Sync” (Android importance High); fires on successful queue sync
- **Biometric confirmation** — `local_auth` stub for sends ≥ **₦10,000** (`1_000_000` kobo)
- **Dead letter queue** — max **3** retries; status `dead` + failure reason; home banner to reset & retry
- **Golden test** — `test/golden/wallet_home_golden_test.dart` → `test/golden/goldens/wallet_home.png`
- **Localization** — English + Yoruba (`en` / `yo`) for Send Money strings; globe toggle on wallet home (Hive `metaBox` key `locale`)
- **Empty / error states** — empty txns & goals; online process failure snackbar

### Biometric threshold

Transfers with `amountKobo >= 1_000_000` (₦10,000) prompt biometrics when the device supports them. Below threshold, or if biometrics unavailable, send proceeds normally.

### Notification channel setup

- Channel id: `nova_sync`
- Channel name: `Queue Sync`
- Android importance: High
- iOS: permission requested in `NotificationService.init()`

### Localization

```bash
flutter gen-l10n
```

Supported locales: `en`, `yo`. ARB sources under `lib/l10n/`.

### Dead letter queue

- On API failure: `retryCount++`
- At `retryCount >= 3`: status → `dead`, `failureReason: Max retries exceeded` (not re-queued as pending)
- Wallet home banner: tap → reset to `pending` / `retryCount: 0` → `processPending()`

