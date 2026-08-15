# Personal Expense & Life Tracker (Flutter)

A single, offline, all-in-one personal tracker built in Flutter: expenses &
income, mood check-ins, tasks, notes, goals, a shared calendar, reminders, a
monthly review, and a profile/settings area. All data is stored locally on
the device via `shared_preferences` (JSON) — no backend, no account.

**Reliability note:** this project intentionally uses only well-established,
permission-free Flutter packages. There is no SMS-inbox reading, no OS push
notifications, and no runtime permission prompts — those required native
Android/iOS plugins that are a common source of Gradle build failures and
version-mismatch issues across different machines, and they aren't worth
that risk for a personal project. Everything the app does is achieved with
pure Dart/Flutter plus four small, extremely stable packages (see "Key
packages" below), so `flutter pub get` + `flutter run` should just work.

## What's implemented

- **Ask AI** — a full chat screen (message bubbles, history, error handling)
  wired to the OpenAI Chat Completions API via the `http` package (pure
  Dart, zero native code). Ask it anything — not just app-related questions.
  **Requires your own OpenAI API key**, pasted into Settings -> AI Assistant
  — there's no built-in key, since API access is tied to a paid/free
  account only you can create. Your key is stored on-device only and sent
  directly to OpenAI, never through any server of ours.
- **Birthday & Age** — set your birthday in Profile; your age is computed
  automatically and shown next to your name.

- **Home** — welcome message, date, total balance, today's/month's expense,
  today's mood, pending tasks, Quick Add sheet (expense, income, task, note,
  goal), daily motivational quote, logging streak (hidden until you have
  one), month-over-month spending trend, over-budget warning.
- **Expenses** — add income/expense, custom + default categories, payment
  method (Cash/Card/UPI/Bank/Other), recurring transactions (weekly/monthly
  — auto-logs the next occurrence each time you open the app), search,
  filter by type/date, swipe-to-delete with Undo, monthly summary.
- **Reports** — income vs expense, category-wise spending, highest spending
  category, weekly spending, month switcher, spending trend insight.
- **Budgets** — set a monthly limit per expense category; a progress bar
  turns red with the over-budget amount once you exceed it.
- **Mood Tracker** — daily check-in using Material icons (no emoji), tap any
  day on the month calendar to log or edit that day's mood so your month
  stays fully logged, a banner shows how many days still need one, monthly
  mood summary.
- **Tasks** — title, description, due date + specific time, category tag,
  priority (Low/Medium/High), repeat (Daily/Weekly/Monthly — completing a
  repeating task auto-creates the next one), swipe-to-delete with Undo,
  today/overdue/upcoming sections.
- **Notes** — quick notes, pin important ones, search, swipe-to-delete with
  Undo.
- **Goals** — title, target date with a "days left / overdue" indicator,
  progress % slider, mark completed, swipe-to-delete with Undo.
- **Calendar** — pick any day to see that day's expenses, tasks, mood, goals
  due, and notes created, all in one place.
- **Reminders** — in-app list covering *every* task: overdue, upcoming
  (30-day window), and even tasks with no due date set (so nothing is ever
  silently missed), plus upcoming goals and recurring transactions. The
  bell icon in the app bar shows a live badge count of overdue + due-today
  tasks.
- **Welcome-Back Summary** — an optional popup shown once per app open (only
  if something needs attention: overdue tasks, today's tasks, mood not
  logged, over-budget categories). Toggle it off anytime in Settings. This
  is the in-app, permission-free alternative to OS push notifications.
- **Add from SMS** — paste a bank/UPI SMS you've copied from your messages
  app, and it detects the amount and whether it's a debit or credit so you
  can add it as a transaction in one tap. (See "Why paste instead of
  reading SMS directly?" below.)
- **Monthly Review** — total spent/income, top mood, tasks completed, goals
  achieved, most productive day, month switcher.
- **Profile** — name, monthly savings goal with progress bar, app
  statistics (counts across all data types).
- **Settings** — dark mode, currency picker, CSV export (includes payment
  method), full JSON Backup & Restore (copy/paste based — works across
  devices with no cloud account), Welcome-Back Summary toggle, PIN app
  lock, erase all data.
- **Bonus** — global search across transactions/tasks/notes/goals, custom
  categories, weekly spending summary, daily logging streak, daily
  motivational quote.

### Why paste instead of reading SMS directly?

Reading the SMS inbox directly requires the Android `READ_SMS` permission,
a native plugin, and manifest/build configuration that varies by Flutter/
Gradle/Kotlin version — exactly the kind of thing that causes builds to fail
in ways that are hard to diagnose remotely. Pasting a copied message
achieves the same practical goal (fast entry of bank alerts) using nothing
but a text field, so it can never fail to build, never gets permission-
denied, and works identically on Android, iOS, and any other platform.

## Project structure

```
lib/
  main.dart                  # App entry, bottom nav + drawer shell, Welcome-Back Summary
  theme.dart                 # Light/dark Material 3 themes
  models/                    # Transaction, MoodEntry, Task, Note, Goal
  services/
    storage_service.dart     # SharedPreferences read/write helpers
    app_state.dart           # Single source of truth (ChangeNotifier)
    app_scope.dart           # InheritedNotifier so any screen can read state
  screens/                   # One file per screen (Home, Expenses, ...)
  widgets/                   # Reusable UI (SectionCard, QuickAddSheet, Drawer)
  utils/formatters.dart      # Date/money formatting helpers
```

No external state-management package is used (no Provider/Riverpod/Bloc) —
`AppScope` is a ~15-line `InheritedNotifier` wrapper, which keeps the
project easy to read for a student project while still avoiding prop-drilling.

## Running the project

**If you previously ran `flutter pub get` on this project before this
version:** delete `pubspec.lock` and run `flutter clean` first (the setup
scripts below do this automatically). Package versions in `pubspec.yaml`
are pinned to exact, older, well-established releases rather than open
ranges — a stale lockfile from an earlier run can otherwise keep pulling in
a newer, incompatible transitive dependency and cause a Gradle failure like
`Could not find method kotlin() ... project ':jni'`. That specific error
comes from a newer Android implementation of `shared_preferences`/
`path_provider` pulling in Google's `jni` package, which needs a Kotlin
Gradle Plugin setup this project doesn't configure — pinning to older,
stable versions avoids that dependency chain entirely.

This zip contains only the Dart/Flutter source (`lib/`, `pubspec.yaml`) —
platform folders (`android/`, `ios/`, `web/`, etc.) are intentionally left
out since they're large, auto-generated, and machine-specific.

```bash
# macOS/Linux
chmod +x setup.sh && ./setup.sh

# Windows (PowerShell)
.\setup.ps1
```

Or manually:

```bash
flutter create .
flutter pub get
flutter run
```

`flutter create .` scaffolds `android/`, `ios/`, `web/`, etc. around your
existing `lib/` and `pubspec.yaml` without touching them. No manifest edits
or extra setup steps are needed — every dependency this project uses is a
plain Dart/Flutter package.

Requires the Flutter SDK (stable channel) installed — see
https://docs.flutter.dev/get-started/install if you don't have it yet.

## Key packages used

| Package | Purpose |
|---|---|
| `shared_preferences` | Local JSON persistence for all data |
| `intl` | Date/number formatting |
| `uuid` | Generating unique IDs for records |
| `path_provider` | Locating a writable directory for CSV/backup export |
| `http` | Calling the OpenAI API for the "Ask AI" chat feature (pure Dart, no native code) |

That's the complete list. No permission-requiring or native-platform-channel
packages are used.

## Extending it further

- Swap `shared_preferences` for `sqflite` if you outgrow simple JSON
  storage (e.g. thousands of transactions).
- Add `fl_chart` for richer pie/bar charts in Reports (currently uses
  simple `LinearProgressIndicator` bars to avoid an extra dependency).
- If you want real OS push notifications despite the build-reliability
  tradeoff, `flutter_local_notifications` is the standard choice — just be
  aware it needs Android manifest permissions and (on Android 13+) a
  runtime permission request, which is exactly what this project avoids.
- If you want to read SMS automatically instead of pasting, `flutter_sms_inbox`
  + `permission_handler` can do it, with the same native-setup caveat.
- Add `local_auth` for fingerprint/Face ID app lock alongside the PIN.
#   p e r s o n a l _ t r a c k e r  
 #   p e r s o n a l _ t r a c k e r  
 