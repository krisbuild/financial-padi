# Financial Padi

An AI-powered personal finance app: track money, understand spending, save
toward goals, and get coached by an AI financial assistant that reasons over
your own real data. Nothing is hardcoded to one income level, currency, or
set of spending categories — every user sets these during onboarding and can
change them anytime.

## Features

- **Auth** — email/password sign up, sign in, and password reset (Firebase Auth).
- **Onboarding** — a short, adaptive setup flow: name, currency (any of 20
  supported), and a pick-your-own starting set of categories (or add your
  own). This is what makes the app generalize across users instead of
  assuming a fixed income, location, or spending profile.
- **AI Coach** — a chat screen plus a home-screen "insight of the day" card.
  It reasons over a live snapshot of the signed-in user's own transactions,
  budgets, goals, and bills (see **AI Coach architecture** below).
- **Transactions** — log income and expenses against categories, with notes and dates.
- **Categories** — fully user-owned: add, rename, recolor, re-icon, or delete
  any category at any time (Categories screen, under More).
- **Budgets** — set a monthly spending limit per category and track progress.
- **Goals** — savings goals with a target amount, optional target date, and progress bar.
- **Recurring bills** — weekly/monthly/yearly bills with due-date local push reminders; "mark as paid" logs a transaction and rolls the bill to its next due date.
- **Reports** — spending-by-category pie chart and a 6-month income vs. expense bar chart.
- **Settings** — currency selection, light/dark/system theme, sign out, delete account.

## AI Coach architecture

The coach is built behind a small interface so a real model can be dropped
in later without touching any UI or provider code:

```
lib/services/ai_coach_service.dart          -> abstract AiCoachService
lib/services/mock_ai_coach_service.dart     -> today's implementation
lib/models/financial_snapshot.dart          -> the data shape the coach reasons over
lib/providers/ai_coach_provider.dart        -> builds the snapshot from live data,
                                                exposes chat state
```

`MockAiCoachService` is **rule-based, not a real LLM** — it inspects the
user's `FinancialSnapshot` (built fresh from their transactions, budgets,
goals, and bills every time) and returns templated, but genuinely
data-driven, observations and answers. This was a deliberate choice for now:
wiring a real model requires an API key, and that key must never live in a
mobile client. To connect a real model later:

1. Stand up a minimal backend (a Cloud Function, or any small server) that
   holds the API key and proxies chat requests.
2. Implement `AiCoachService` with a class that POSTs the question + a
   serialized `FinancialSnapshot` to that backend and returns the reply.
3. Swap the implementation in `aiCoachServiceProvider`
   (`lib/providers/ai_coach_provider.dart`) — nothing else changes.

Chat history is currently in-memory only (resets on app restart); persisting
it to Firestore under `users/{uid}/chatMessages` would be a small addition
using the same pattern as the other collections in `FirestoreService`.

## Tech stack

- **Flutter** (Dart), Material 3
- **State management:** Riverpod
- **Routing:** go_router (auth + onboarding-aware redirect guard, bottom-nav shell)
- **Backend:** Firebase Auth + Cloud Firestore
- **Charts:** fl_chart
- **Local notifications:** flutter_local_notifications + timezone

## Navigation

Bottom tabs: **Home**, **Coach**, **Activity** (transactions), **Budgets**,
**More** (Reports, Recurring Bills, Categories, Settings).

## Project structure

```
lib/
  core/            theme, router, formatting utils, icon registry, category templates
  models/          plain Dart models with Firestore (de)serialization
  services/        AuthService, FirestoreService, NotificationService, AiCoachService (+ mock)
  providers/       Riverpod providers (auth, transactions, budgets, goals, bills, settings, ai coach)
  widgets/          shared building blocks (buttons, text fields, empty states, nav shell)
  features/
    onboarding/     splash + the setup flow (name, currency, categories)
    auth/           login, signup, forgot password
    dashboard/      home screen: balance, AI insight card, budgets/bills preview, recent transactions
    coach/          AI coach chat screen
    transactions/   list + add/edit
    budgets/        budgets & goals (tabs)
    goals/
    bills/          recurring bills + reminders
    categories/     add/edit/delete categories
    reports/        charts
    more/           hub screen linking to reports/bills/categories/settings
    settings/
```

Firestore data lives under `users/{uid}/...` (transactions, categories, budgets,
goals, bills), so a single security rule can enforce per-user isolation — see
**Firestore security rules** below. Categories are no longer seeded with a
fixed list on signup — they're created by the user during onboarding (from
suggestions) or later from the Categories screen, so the collection only
ever contains what a given user actually chose.

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

- `flutter analyze` and `flutter test` are clean as of this commit. This was
  built and verified with static analysis and unit/widget tests only — no
  APK/app bundle has been built or run on a device/emulator in this
  environment.
- The AI Coach is intentionally mocked (see **AI Coach architecture**) —
  connecting a real model needs a backend to hold the API key.
- Consider adding next: persisting chat history to Firestore; a "streak" or
  daily-check-in mechanic for extra engagement; CSV/PDF export; biometric
  app-lock; push (not just local) notifications for bill reminders.
