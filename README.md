# Personal Tracker

<p align="center">
  <strong>A calmer way to keep up with your day.</strong><br>
  Mood check-ins, tasks, goals, notes, and personal insights in one private, offline-first Flutter app.
</p>

<p align="center">
  <a href="https://github.com/snehithtoomove19-lab/personal_tracker/actions/workflows/flutter.yml"><img src="https://github.com/snehithtoomove19-lab/personal_tracker/actions/workflows/flutter.yml/badge.svg" alt="Flutter CI"></a>
  <img src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white" alt="Flutter stable">
  <img src="https://img.shields.io/badge/Language-Dart-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/License-not%20specified-lightgrey" alt="License not specified">
</p>

Personal Tracker helps you notice how you feel, choose what matters, and keep moving at your own pace. Your records stay on your device by default; cloud backup and AI features are optional and require your own account or API key.

## Contents

- [Features](#features)
- [Privacy](#privacy-by-default)
- [Get started](#get-started)
- [Cloud backup setup](#optional-supabase-cloud-backup)
- [Tech stack](#tech-stack)
- [Contributing](#contributing)
- [Tests and analysis](#tests-and-analysis)

## What you can do

| Make space to reflect | Keep the day moving | Understand your patterns |
|---|---|---|
| Log your mood and daily signals without streak pressure. | Organize tasks, reminders, notes, goals, and birthdays. | Review mood and focus insights based only on what you choose to log. |

- **A useful daily view** with a gentle check-in, focus signals, upcoming tasks, and shortcuts.
- **Flexible planning** with repeating tasks, subtasks, priorities, reminders, and goal progress.
- **A personal record** with searchable notes, a unified calendar, monthly reviews, and daily mood history.
- **Optional tools** including voice logging, AI chat, and manual Supabase backup.
- **Android quick capture** — share plain text from another app to Personal Tracker and confirm before saving it as a note.
- **Your pace, your privacy** with dark mode, theme choices, and an optional PIN lock.

## Privacy by default

- Tracker data is stored locally on the device.
- Shared text is saved only after you confirm the Android save prompt.
- Cloud sync is optional and manual; it uploads or restores a per-user backup only when you choose.
- AI chat uses an API key you provide. Personalization is opt-in and sends a limited rolling summary, not raw notes or task titles.
- Voice recognition is optional, uses the device's speech service, and does not save audio recordings.

See [Optional Supabase cloud backup](#optional-supabase-cloud-backup) for setup and data-handling details.

## Get started

### Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- A connected device, emulator, or supported desktop/web target

### Run the app

```bash
flutter pub get
flutter run
```

On a fresh checkout that needs platform scaffolding regenerated, the one-time setup scripts are also available: `.\setup.ps1` on Windows or `chmod +x setup.sh && ./setup.sh` on macOS/Linux. They clean build artifacts and refresh dependency resolution before preparing the platform folders.

## Optional Supabase cloud backup

1. Create a Supabase project and open its SQL Editor.
2. Run [`supabase/migrations/20261030000000_user_backups.sql`](supabase/migrations/20261030000000_user_backups.sql) to create the owner-only backup table and RLS policy.
3. In the app, open **Settings → Cloud sync** and enter the project's HTTPS URL and public anon/publishable key from **Project Settings → API**.
4. Create an account or sign in with email/password. If email confirmation is enabled, confirm the account before signing in.
5. Choose **Upload this device** or **Restore cloud backup**. Upload replaces that account's previous snapshot; restore replaces local tracker records.

Sync stores one versioned JSON backup per authenticated user. It is manual, and restore requires confirmation. Export a local backup before restoring if you need to keep the current local records. Never put a database password, service-role key, or other secret in the client.

## Features

### Mood
- Daily mood check-in with a tappable calendar — log or edit *any* day, not just today
- Monthly mood recap and a gentle nudge for days you haven't logged

### Tasks & Goals
- Tasks with due date + time, category, priority, checklists (sub-tasks), and repeat (daily/weekly/monthly)
- Opt-in task reminders with audible notifications, vibration, a reminder-sound test, and automatic rescheduling after app restarts
- Goals with a target date, progress slider, and a "days left / overdue" indicator
- A Reminders screen that covers *every* task — overdue, upcoming, and even ones with no due date
- A blameless review for overdue tasks, with a supportive blocker check-in and an optional two-day smaller-step plan that does not reset streaks

### Notes & Calendar
- Quick notes with pinning and search
- A unified calendar view showing tasks, mood, goals, and notes for any day

### Audible reminders
- Enable notification and exact-alarm access from Settings, then turn on a reminder while creating or editing a task
- Tasks without a chosen time use 9:00 AM; reminders already in the past are not scheduled
- Android and iOS notification, sound, focus/Do Not Disturb, and battery settings can still silence or delay an alert

### Cloud backup
- Optional Supabase email/password account with per-user Row Level Security
- Enter the Supabase project URL and public anon/publishable key in Cloud Sync; the app never needs a database password or service-role key
- Explicit upload and restore actions keep local storage usable offline; restoring replaces local records and requires confirmation
- Supabase auth sessions are stored using the platform's secure storage

### Ask AI
- A built-in chat assistant (bring your own OpenAI API key) for quick questions, right inside the app
- Optional AI personalization adds only a rolling 30-day aggregate of mood, daily-signal, and task counts to the prompt when explicitly enabled in Settings; raw notes, task titles, and daily records are excluded
- Personalization changes the prompt context; it does not train or fine-tune model weights. Personal tracker summaries are sent directly to OpenAI only when this opt-in is enabled

### Focus & Energy
- Optionally log any known daily signal; unreported values remain unknown and are excluded from comparisons rather than treated as zero/default
- Show signal associations only when each comparison has enough observations; these are personal correlations, not causal or medical conclusions
- Estimate a 0–100 daily capacity from the logged sleep, meeting, high-priority task, and workout load, with the calculation shown in the app
- Present mode summarizes today's tracked alerts, offers a cautious next-day planning estimate, and answers local questions about logged mood, exercise, water, and tasks
- Review and import normalized daily-signal CSV or JSON records; imports merge only provided fields and preserve other saved values
- Use the microphone to dictate a natural-language entry and review the extracted water, exercise, and mood items before saving; the lightweight parser does not save the transcript, and assumes 250 ml per glass/cup
- Speech recognition is provided by the device/platform service; offline availability depends on the device and its speech service. The app does not save audio recordings.

Present mode currently uses only data already stored on the device. It does not read email or connect to Google Calendar, Plaid, Apple Health, or Health Connect. Live provider sync requires separate OAuth/provider configuration and explicit user authorization; no provider credentials are bundled in the app.

Expense tracking and SMS detection/import have been removed. Older transaction records remain in local storage and backups for compatibility; they are not shown in the app.

### Extras
- Dark mode, PIN app lock, global search, birthday/age tracking, daily streak, motivational quotes, a "Welcome-Back Summary" popup that surfaces anything needing attention when you open the app

## Tech Stack

- **Flutter** (Dart) — cross-platform UI and app logic
- **Kotlin** — Android share-intent integration for quick capture into notes
- **State management:** a lightweight custom `InheritedNotifier` (`AppScope`) — no external state package
- **Storage:** `shared_preferences` (local JSON), fully offline
- **Optional cloud backup:** Supabase Auth + a private JSONB backup row, protected by PostgreSQL Row Level Security
- **AI:** OpenAI Chat Completions API via `http` (user-supplied API key)
- **Voice input:** `speech_to_text` using the device's speech-recognition service

Microphone permission is requested only when starting voice input. The device's speech-recognition service may require network access; voice input is optional.

## Contributing

Contributions and bug reports are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Use the repository's issue forms for reproducible bug reports or feature ideas, and remove personal data from logs and screenshots.

## Tests and analysis

Run the same checks used by GitHub Actions before submitting a change:

```bash
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

GitHub Actions runs formatting, static analysis, tests, and an Android debug build for pushes and pull requests to `main`.

## Project Structure

```
lib/
  main.dart                  # App entry, navigation shell, startup logic
  theme.dart                 # Shared light/dark Material 3 design system
  models/                    # MoodEntry, Task, Note, Goal, daily signals, ChatMessage
  services/
    app_state.dart            # Single source of truth (ChangeNotifier)
    app_scope.dart            # Shared state access for screens and widgets
    storage_service.dart      # Local persistence
    ai_service.dart           # Optional AI integration
    focus_insights_service.dart # Capacity estimate and signal comparisons
    supabase_sync_service.dart # Optional, manual per-user backups
    task_reminder_service.dart  # Local task notifications
  screens/                    # App pages and flows
  widgets/                    # Shared UI components
  utils/                      # Navigation and formatting helpers
supabase/migrations/          # Database schema and row-level security
test/                         # Unit and widget tests
```

This repository does not currently declare a software license. Ask the maintainer before reusing or redistributing the code.
