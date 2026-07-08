# Manifest Fellowship Tracker

A multi-user fellowship monitoring app for a university Christian fellowship
(Victoria University & Makerere campuses, Uganda). Built with Flutter and a
Firebase backend (Firestore + Firebase Auth), offline-first by default via
Firestore's built-in persistence.

## Roles

Each signed-in user has a `role` in `/users/{uid}`, and `AuthGate`
(`lib/auth_gate.dart`) routes to the matching home screen:

| Role         | Home screen                        |
|--------------|-------------------------------------|
| `admin`      | Admin Dashboard                     |
| `leader`     | Admin Dashboard                     |
| `usher`      | Usher Home                          |
| `callCentre` | Call Centre Home                    |
| `transport`  | Transport Home                      |

If a signed-in user has no `/users/{uid}` doc yet, they see a
"pending approval — contact admin" screen instead.

## Features

- **Usher**: record fellowship/prayer/outreach sessions with a +/- counter
  form (Year 1s, Year 2s, Year 3+, visitors, new believers), auto-computed
  total attendance, optional offering and notes.
- **Members Register**: searchable member list, full add/edit form, and a
  stripped-down "first-timer quick add" form for registering several
  first-timers quickly during a service.
- **Call Centre**: streams assignments given to the signed-in caller,
  tap-to-dial via `tel:` links, and outcome buttons (reached / no answer /
  needs visit / prayed with) that log a call and mark the assignment done.
- **Transport**: event list plus a form for mobilised count, attended count,
  and transport cost.
- **Admin Dashboard**: this-week-vs-last-week attendance, a Year 1 trend line
  chart and attendance bar chart (`fl_chart`), call-completion rate, pending
  first-timer follow-ups, and tools to manage users/roles and assign calls.

## Tech stack

- Flutter (Material 3), `colorScheme` built from Black / White / Golden
  Orange (`lib/theme.dart`)
- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `intl`, `url_launcher`, `fl_chart`
- Data models in `lib/models/` with `fromDoc`/`toMap` converters
- One screen per file under `lib/screens/`

## Firestore collections

`users`, `members`, `sessions`, `callLogs`, `assignments`, `events` — see
`firestore.rules` for the full field list and access rules (e.g. `callLogs`
is readable only by `callCentre` + leadership for pastoral privacy;
assignees can only update the `status` field of their own assignments).

## Local setup

This project's Flutter/Android SDKs and caches live on an external `E:`
drive on the primary dev machine. Before running any `flutter`/Gradle
command:

```powershell
$env:Path = "E:\dev\flutter\bin;$env:Path"
$env:ANDROID_HOME = "E:\dev\android-sdk"
$env:ANDROID_SDK_ROOT = "E:\dev\android-sdk"
$env:PUB_CACHE = "E:\dev\.pub-cache"
```

Then:

```powershell
flutter pub get
flutter run -d chrome   # or a connected Android device
```

Firebase is already connected (`lib/firebase_options.dart`, project
`manifest-fellowship-tracker`). To reconnect from a fresh machine:

```powershell
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=manifest-fellowship-tracker --platforms=android,web --yes
```

Deploy security rule changes with:

```powershell
firebase deploy --only firestore:rules --project manifest-fellowship-tracker
```

## Building an APK

Local release builds are slow on low-RAM machines. Instead, push to `main`
and let `.github/workflows/build-release-artifacts.yml` build it on
GitHub's servers (~10 min) and publish an arm64 release APK — zipped and
raw — to the rolling `latest-build` GitHub release. Prefer the zipped
asset when sharing to Android phones; some devices hang scanning a raw
`.apk` download but handle a `.zip` fine.

## Verified working

All 5 role screens have been smoke-tested end-to-end against the real
Firebase project (login → role routing → data write → Admin Dashboard
aggregation), using throwaway test accounts per role. Two bugs turned up
and were fixed:

- `orderBy('name')` queries silently drop any document missing that exact
  field (a Firestore behavior, not a crash) — hit this on accounts created
  manually via the console with inconsistent field casing. Manage Users,
  Members Register, and the assignment member-picker now fetch unsorted
  and sort client-side instead.
- The "Assign To" dropdown in New Assignment went blank after selecting a
  value, because `AppUser` had no value equality, so `DropdownButtonFormField`
  couldn't match the selection against a fresh list of instances from the
  live `StreamBuilder`. Fixed by adding `==`/`hashCode` by `uid` — the
  underlying save was never actually broken, just the display.

## Not yet built (phase 2)

- Phone OTP login
- PDF export
- Google Forms sync

## Next session

All 5 role screens are verified and the codebase is clean of test data.
Remaining work is the **app logo**: still deciding whether to use an
existing image file or design something new from the Black/White/Golden
Orange palette, and whether it should replace just the login screen's
placeholder icon or also the Android launcher icon (via
`flutter_launcher_icons`).
