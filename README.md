# SprintTrack

A project and SLA task tracker for a small software team, built with Flutter.
Create and assign tasks, set priorities and deadlines, follow progress, and see
which tasks need attention before they are late.

All data is stored on the device. There is no backend and no account on any
server.

**Group 32:** Solomon Leek, Grace Njunge, Hategekimana Eric, Milliam Mukamukiza

## Contents

- [Features](#features)
- [Run it on your machine](#run-it-on-your-machine)
- [Sign in to the demo](#sign-in-to-the-demo)
- [Screens](#screens)
- [SLA rules](#sla-rules)
- [How data is stored](#how-data-is-stored)
- [Project structure](#project-structure)
- [Tests](#tests)
- [Troubleshooting](#troubleshooting)

## Features

- Create, edit and delete tasks with a title, description, category, assignee,
  due date and time, priority and status.
- Every task is classified as **On Track**, **At Risk**, **Overdue** or
  **Completed**, and the status updates by itself as time passes.
- Dashboard with overall progress, a count for each status, a donut chart and a
  "Needs attention" list.
- Task list with search, status filters and sorting.
- Task details with a time-used indicator and a history of every change.
- Team members: add, edit and remove members, and switch the signed-in user.
- Form validation with clear error messages, and a warning before unsaved
  changes are discarded.
- Data is kept when the app is closed and reopened.

## Run it on your machine

### 1. What you need

| Tool | Notes |
| --- | --- |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | Dart 3.13.5 or newer is required. The project was built with Flutter 3.47.6. |
| [Git](https://git-scm.com/downloads) | To clone the repository. |
| [Android Studio](https://developer.android.com/studio) | Provides the Android SDK and the emulator. |
| An Android emulator or phone | The app does **not** run in a browser (see below). |

Check your setup with:

```bash
flutter doctor
```

Fix anything marked with a red cross under **Flutter** and **Android
toolchain** before continuing. If it reports Android licences are not accepted,
run `flutter doctor --android-licenses`.

**Windows only:** switch on Developer Mode, which Flutter needs to build
plugins. Run this, then turn on **Developer Mode** in the window that opens:

```powershell
start ms-settings:developers
```

### 2. Get the code

```bash
git clone https://github.com/solomon-211/sla-mobile-app-project.git
cd sla-mobile-app-project
```

All commands below must be run from this folder, the one containing
`pubspec.yaml`.

### 3. Install the packages

```bash
flutter pub get
```

### 4. Start a device

**Emulator:** open Android Studio, go to **Device Manager**, and press the play
button beside a virtual device. Or from the terminal:

```bash
flutter emulators                  # lists the emulators you have
flutter emulators --launch <id>    # starts one
```

**Physical phone:** enable **Developer options** and **USB debugging** on the
phone, connect it by USB, and accept the prompt on the phone.

Confirm Flutter can see the device:

```bash
flutter devices
```

### 5. Run the app

```bash
flutter run
```

The first build takes a few minutes. If more than one device is listed, choose
the Android one, or run `flutter run -d <device-id>`.

While the app is running, press `r` in the terminal for hot reload, `R` for a
full restart, and `q` to quit.

Keep the device online the first time you run the app: the fonts are downloaded
on first use. Without a connection the app still works, with the system font.

### Why not Chrome or the web

The app stores its data with `sqflite`, which has no web implementation, so it
must run on an emulator or a phone.

### Optional: build an APK

```bash
flutter build apk --release
```

The file is written to `build/app/outputs/flutter-apk/app-release.apk` and can
be copied to an Android phone and installed. The release build has no internet
permission, so it shows the system font instead of the downloaded ones.

## Sign in to the demo

The first launch creates a demo team and a set of demo tasks.

| Email | Password |
| --- | --- |
| `amina@devteam.app` | `sprint123` |
| `brian@devteam.app` | `sprint123` |
| `chloe@devteam.app` | `sprint123` |
| `deng@devteam.app` | `sprint123` |

You can also create your own account with **Get started** on the first screen;
it uses the password you choose. Once signed in, **Team → Switch user** changes
to another member.

Sign-in is a local demonstration only. Passwords are stored on the device as
plain text and there is no real authentication.

**To reset the demo data:** clear the app's storage (Android **Settings → Apps
→ SprintTrack → Storage → Clear storage**) or uninstall and run again. The demo
deadlines are calculated from the moment of first launch.

## Screens

| Screen | File |
| --- | --- |
| Landing (first screen) | `lib/screens/landing_screen.dart` |
| Create Account | `lib/screens/register_screen.dart` |
| Sign In | `lib/screens/sign_in_screen.dart` |
| Project Dashboard | `lib/screens/dashboard_screen.dart` |
| Task List | `lib/screens/task_list_screen.dart` |
| Task Details | `lib/screens/task_details_screen.dart` |
| Create / Edit Task | `lib/screens/task_form_screen.dart` |
| Team Members (with Switch user) | `lib/screens/team_screen.dart` |

Navigation uses named routes defined in `lib/app_router.dart`:

```
Landing → Create Account or Sign In → Home (Dashboard, Tasks, Team tabs)
Home    → Task Details → Create / Edit Task (edit)
Home    → Create / Edit Task (new)
```

The app opens on Landing, or straight on the Dashboard when a signed-in user is
remembered on the device.

## SLA rules

The rules are in `lib/utils/sla.dart` and are checked in this order:

1. **Completed** — the task status is Done.
2. **Overdue** — not done, and the deadline has passed.
3. **At Risk** — not done, and either
   - less time is left than the lead time for its priority
     (High 72 hours, Medium 48 hours, Low 24 hours), or
   - 75% or more of the time between creation and deadline has been used.
4. **On Track** — everything else.

Higher-priority tasks are flagged earlier so there is still time to react. The
75% rule catches short tasks that the lead time alone would miss. Statuses are
recalculated every minute while the app is open.

## How data is stored

| Storage | Holds | Why |
| --- | --- | --- |
| SQLite (`sqflite`) | Tasks, team members, task history | These are related records that need sorting and lookups |
| `SharedPreferences` | The signed-in user and the project name | These are single key-value settings |

The database has three tables: `members`, `tasks` and `activities`. Deleting a
task also deletes its history. A task and its history entry are always saved
together in one transaction. The code is in
`lib/services/database_helper.dart` and `lib/services/session_service.dart`.

State is managed with Flutter's `setState()`. Shared data is loaded once in
`HomeShell` and passed down to the three tabs.

## Project structure

```
lib/
  main.dart            App entry point; restores the saved session
  app_router.dart      Named routes
  theme/               Colours, text styles and ThemeData
  models/              Task, TeamMember, TaskActivity
  services/            DatabaseHelper (sqflite), SessionService (SharedPreferences)
  utils/               SLA rules, validators, date formatting
  data/                Demo data inserted on first launch
  screens/             One file per screen, plus HomeShell (bottom navigation)
  widgets/             Shared widgets: buttons, cards, badges, avatars, task
                       card, dialogs, donut chart, bottom nav, animations
assets/images/         Landing screen photo (from Pexels)
test/
  sla_test.dart        Unit tests for the SLA rules and validators, and
                       widget tests
```

### Packages used

| Package | Used for |
| --- | --- |
| `sqflite`, `path` | Local SQLite database |
| `shared_preferences` | Saved session and project name |
| `intl` | Date and time formatting |
| `google_fonts` | Sora and Manrope typefaces |

## Tests

```bash
flutter analyze    # static checks
flutter test       # unit and widget tests
```

The tests cover the SLA rules and their boundaries, the validators, and key
screens. They do not need an emulator.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `No pubspec.yaml file found` | You are in the wrong folder. `cd` into `sla-mobile-app-project`. |
| `Building with plugins requires symlink support` | Windows: switch on Developer Mode (`start ms-settings:developers`), then run again. |
| `The current Dart SDK version is ...` | Your Flutter is too old. Run `flutter upgrade`. |
| `No supported devices connected` | Start an emulator or connect a phone, then check `flutter devices`. |
| The app opens in Chrome and fails | Choose the Android device: `flutter run -d <device-id>`. |
| Build errors after pulling new code | Run `flutter clean`, then `flutter pub get`, then `flutter run`. |
| Demo tasks all look overdue | The demo data is old. Clear the app's storage to recreate it. |
