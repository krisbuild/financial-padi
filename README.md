# Financial Padi

A budgeting and personal finance management app built with Flutter. Track
income and expenses, set category budgets, save toward goals, get reminders
for recurring bills, and see your spending trends at a glance.

## Features

- **Auth** — email/password sign up, sign in, and password reset (Firebase Auth).
- **Transactions** — log income and expenses against categories, with notes and dates.
- **Categories** — a seeded set of income/expense categories per user.
- **Budgets** — set a monthly spending limit per category and track progress.
- **Goals** — savings goals with a target amount, optional target date, and progress bar.
- **Recurring bills** — weekly/monthly/yearly bills with due-date local push reminders; "mark as paid" logs a transaction and rolls the bill to its next due date.
- **Reports** — spending-by-category pie chart and a 6-month income vs. expense bar chart.
- **Settings** — currency selection, light/dark/system theme, sign out, delete account.

## Tech stack

- **Flutter** (Dart), Material 3
- **State management:** Riverpod
- **Routing:** go_router (with an auth-aware redirect guard and a bottom-nav shell)
- **Backend:** Firebase Auth + Cloud Firestore
- **Charts:** fl_chart
- **Local notifications:** flutter_local_notifications + timezone

## Project structure

```
lib/
  core/            theme, router, formatting utils, icon registry
  models/          plain Dart models with Firestore (de)serialization
  services/        AuthService, FirestoreService, NotificationService
  providers/       Riverpod providers (auth, transactions, budgets, goals, bills, settings)
  widgets/          shared building blocks (buttons, text fields, empty states, nav shell)
  features/
    auth/          login, signup, forgot password
    dashboard/      home screen: balance, budgets/bills preview, recent transactions
    transactions/   list + add/edit
    budgets/        budgets & goals (tabs)
    goals/
    bills/          recurring bills + reminders
    reports/        charts
    settings/
```

Firestore data lives under `users/{uid}/...` (transactions, categories, budgets,
goals, bills), so a single security rule can enforce per-user isolation — see
**Firestore security rules** below.

## Setup

### 1. Install Flutter

Follow https://docs.flutter.dev/get-started/install for your OS, then run
`flutter doctor` and resolve anything it flags (Android SDK, an emulator or
device, etc).

### 2. Get dependencies

```sh
flutter pub get
```

### 3. Connect a real Firebase project

The app ships with a **placeholder** `lib/firebase_options.dart` so it
compiles out of the box, but it does not point at a real backend yet. To wire
up your own Firebase project:

```sh
dart pub global activate flutterfire_cli
flutterfire configure
```

This walks you through selecting/creating a Firebase project, enables the
platforms you need, downloads `google-services.json` / `GoogleService-Info.plist`,
and regenerates `lib/firebase_options.dart` for you.

In the Firebase console for that project:

- **Authentication** → Sign-in method → enable **Email/Password**.
- **Firestore Database** → create a database (production mode), then apply
  the security rules below.

### 4. Firestore security rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 5. Run it

```sh
flutter run
```

## Building for the Play Store

1. **App icon** — replace the default Flutter icon. Easiest path: add
   `flutter_launcher_icons` as a dev dependency, drop your artwork in
   `assets/icon.png`, configure it in `pubspec.yaml`, then run
   `dart run flutter_launcher_icons`.
2. **Application ID** — the placeholder id is `com.financialpadi.financial_padi`
   (set in `android/app/build.gradle.kts` as `applicationId` and in
   `android/app/src/main/kotlin/.../MainActivity.kt`'s package). Change it to
   your own reverse-domain id before release, and re-run `flutterfire configure`
   afterwards so `google-services.json` matches.
3. **Signing** — generate a release keystore and configure
   `android/key.properties` + the `signingConfig` in
   `android/app/build.gradle.kts` per the
   [official guide](https://docs.flutter.dev/deployment/android#signing-the-app).
   (`key.properties` and `*.jks`/`*.keystore` are already gitignored.)
4. **Build the app bundle** (the format Play Store requires):
   ```sh
   flutter build appbundle --release
   ```
   The output lands at `build/app/outputs/bundle/release/app-release.aab`.
5. Upload the `.aab` to a new app in the
   [Play Console](https://play.google.com/console), fill in the store
   listing, content rating, and privacy policy (required for a finance app),
   then submit for review.

## Notes / next steps

- `flutter analyze` and `flutter test` are clean as of this commit.
- This app was scaffolded and coded in a sandboxed environment without a
  configured Android SDK/emulator or a real Firebase project, so it hasn't
  been run end-to-end on a device yet — do that first after following the
  setup steps above.
- Consider adding: recurring-bill push notifications while the app is
  terminated need `flutter_local_notifications`' exact-alarm permission to
  be granted at runtime on Android 12+ (the manifest already declares it);
  a category management screen (rename/add/delete custom categories) beyond
  the seeded defaults; CSV/PDF export; biometric app-lock.
