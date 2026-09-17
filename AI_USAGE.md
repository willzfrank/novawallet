# AI Usage

## Tools used

- **Cursor** (agent IDE) — project scaffold, file edits, running `flutter test` / diagnose hangs
- **Claude** (Composer) — architecture drafts, Riverpod/Hive queue, screens, README, tests

## Example prompts

1. > Build NovaWallet Flutter app with Riverpod, Hive offline queue, int-kobo money, 3-step send flow, NovaSave goals, and integration test for idempotent sync.

2. > Processing loop must reset `processing` → `pending` on app start for crash recovery, and `ref.listen` connectivity to auto-drain the Hive queue.

3. > Widget-test send money step 1→2→3→confirm and NovaSave contribution updating LinearProgressIndicator; money only as int kobo.

4. > Tests hang forever on Send Money confirm — find root cause and fix without weakening the offline-queue guarantees.

## Where AI was wrong (caught & fixed)

### 1. Money as `double`
AI suggested storing money as `double` and using `/100` arithmetic inline — causes floating-point drift in balance summation. Fixed by enforcing **int kobo** end-to-end; convert only in `Money.formatKobo` for display.

### 2. Offline queue re-entrancy
First draft of `processPending()` used `if (_processing) return;` with no rerun flag. Connectivity `ref.listen` could start an empty drain while a new enqueue was in flight → action left `pending` forever until next reconnect. Fixed with `_rerunRequested` so a second call queues another pass instead of dropping work.

### 3. Widget tests “hung” (looked like a slow suite)
AI / initial tests used `Directory.systemTemp.createTemp()`, `await Hive.openBox` / `await box.put`, and Confirm→queue in normal `testWidgets` code. Under Flutter’s **fake-async**, those real IO Futures never complete → 10‑minute timeouts, not slow tests. Fixed with:
- sync temp dirs (`createSync`)
- `tester.runAsync` for Hive init / enqueue
- avoiding Confirm→Hive on the fake-async path in widget tests (unit + integration still cover process/idempotency)

### 4. `riverpod_generator` vs Dart 3.13
AI assumed `dart run build_runner` would emit `.g.dart`. Analyzer/SDK mismatch (`visitDotShorthandPropertyAccess`) broke codegen. Fixed by keeping `@riverpod` / `riverpod_annotation` in source and shipping equivalent hand-written `.g.dart` providers so the app still runs.

### 5. Duplicate / silent double-send risk in mock API
Early mock API sketch only delayed and returned `true` — no idempotency set. A reconnect replay with the same UUID could debit twice if side effects weren’t keyed. Fixed: `MockApiService` tracks processed UUID keys; duplicates return success without re-applying wallet/goal side effects.

### 6. Misleading `processAttempts` comment
`MockApiService` comment said `processAttempts` increments on first success only — code actually increments on every non-duplicate attempt including failures. Caught it by reading the implementation, not the comment. Fixed by clarifying the comment.

### 7. Retry count as boolean
AI suggested storing retry count as a boolean (`hasRetried`) — caught this as it prevents implementing configurable max retry limits; fixed by using `int retryCount` with a threshold constant.

### 8. Biometric stuck / no system prompt
`MainActivity` left as `FlutterActivity`. `local_auth` on Android needs `FlutterFragmentActivity` for the system biometric sheet. Auth failed inside an empty `catch` → returned `false` → snackbar “Authentication required to proceed” with no prompt. Fixed by switching `MainActivity` to `FlutterFragmentActivity`.

### 9. Offline still “succeeds”
`MockApiService` is in-process (no real HTTP). AI drained the queue whenever connectivity said “link up,” defaulted `isOnline` to `true` while loading, and called `processPending()` on app resume / pull-to-refresh without an online gate — so airplane-mode / “offline” sends still completed instantly. Fixed by seeding connectivity with `checkConnectivity()`, defaulting unknown → offline, and no-oping `processPending` (and resume flush) when `isOnline` is false.

### 10. Yoruba locale → red screen
Globe toggles `en` ↔ `yo`. AI set `MaterialApp.locale` to `yo` with only `GlobalMaterialLocalizations` — Flutter has no Material/Cupertino catalog for Yoruba → `No MaterialLocalizations found` on `AppBar`. Fixed with fallback delegates that load English Material/Widgets/Cupertino strings when the locale isn’t supported, while `AppLocalizations` still serves Yoruba UI copy.
