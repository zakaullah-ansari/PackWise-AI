# 📦 PackWise AI — Intelligent Food Packaging Recommendation System

> An AgriTech/FoodTech Flutter application that uses **Google Gemini AI** to
> recommend optimal food packaging materials from commodity properties
> (moisture, fat, pH, respiration rate, desired shelf life, storage
> temperature/humidity/type). Built as a **Smart India Hackathon (SIH)**
> submission and as a **university workshop teaching resource** for MVVM +
> Provider architecture in Flutter/Dart 3.

---

## 🎯 What it does

1. A user (signed in via **Firebase Auth**) enters a food commodity's
   physical/chemical properties and desired storage conditions.
2. The app sends this to **Google Gemini 1.5 Flash** with a strict JSON
   response schema and receives the **top 3 recommended packaging
   materials** (LDPE, HDPE, PET, Metalized Film, Aluminum Foil, PLA,
   Biodegradable Film, or Micro-perforated Film) — each with predicted OTR
   (Oxygen Transmission Rate), WVTR (Water Vapor Transmission Rate), film
   thickness, MAP (Modified Atmosphere Packaging) gas ratios, a
   sustainability score, and a predicted shelf life.
3. If the network/API is unavailable, a fully **offline rules engine**
   (`LocalFallbackService`) transparently takes over so the app always
   produces a usable recommendation — labeled clearly as "Offline Mode" in
   the UI.
4. Results can be saved to **Cloud Firestore** and browsed later in a
   real-time **History** screen.

---

## 🧱 Architecture — MVVM + Provider

```
View  ⇄  Provider (ChangeNotifier ViewModel)  ⇄  Repository  ⇄  Service (Gemini / Firestore / Auth / Offline)
```

- **Views** (`lib/views/**`) are dumb/declarative — they only read state from
  a `Provider`/`Consumer` and call ViewModel methods; they never talk to a
  service directly.
- **Providers** (`lib/providers/**`) are `ChangeNotifier` ViewModels holding
  UI state machines (`AuthStatus`, `RecommendationViewState`).
- **Repositories** (`lib/data/repositories/**`) orchestrate one or more
  services and translate low-level exceptions into a `Result<T>`
  (`Success`/`ResultError`) that ViewModels can pattern-match on.
- **Services** (`lib/services/**`) are the only classes that talk to the
  outside world: `GeminiService` (REST), `FirestoreService`, `AuthService`,
  and `LocalFallbackService` (pure Dart, offline).

See `lib/` for the full folder layout — it mirrors the specification this
project was built against (see below for a syllabus-topic mapping table).

---

## 🚀 Getting Started

> ⚠️ **This sandbox environment could not reach `pub.dev` / the Flutter SDK
> download host**, so `flutter pub get` / `flutter analyze` / `flutter build`
> could **not** be executed here. Every file was written carefully and
> statically verified (see *"How this was verified"* below), but you should
> run the commands below yourself the first time you open this project.

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Generate platform runners (Android/iOS/Web/etc.)

This repository intentionally ships **only** the cross-platform `lib/`
Dart source + `pubspec.yaml` — not the generated native `android/`, `ios/`,
`web/`, `windows/`, `macos/`, `linux/` runner folders (those are
machine-generated boilerplate that `flutter create` regenerates safely
without touching your `lib/` code):

```bash
flutter create --platforms=android,ios,web .
```

### 3. Configure Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This **overwrites** the placeholder `lib/firebase_options.dart` with your
real Firebase project's keys, and drops `google-services.json` /
`GoogleService-Info.plist` into the native folders (already git-ignored).

Enable **Email/Password** sign-in under Firebase Auth, and create a
**Cloud Firestore** database (start in test mode for local development).

### 4. Configure your Gemini API key

Get a free key at [Google AI Studio](https://aistudio.google.com/app/apikey),
then run the app with it injected at build time (never hard-code it):

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

Without a key, the app still runs end-to-end using the offline rules engine
(`LocalFallbackService`) — useful for demos with no internet.

### 5. Run tests

```bash
flutter test
```

---

## 📁 Folder Structure & Syllabus Mapping

| Path | Purpose | Syllabus Topics |
|---|---|---|
| `app/theme/` | Dark cyber-glassmorphism design system | Theming, design systems |
| `app/routes/` | `onGenerateRoute` + typed route arguments | **Named Routing** |
| `core/constants/` | API/app/validation constants | Encapsulation, static members |
| `core/errors/` | `AppException` hierarchy + `Failure`/`Result` sealed classes | **OOP**, **Exception Handling**, Dart 3 pattern matching |
| `core/utils/` | Form validators, logger | Static utilities, defensive programming |
| `data/models/` | `FoodCommodity`, abstract `PackagingMaterial` + 8 subclasses, `Recommendation`, `LayerSpec` | **OOP** (abstraction/inheritance/polymorphism), enums, JSON |
| `data/mixins/` | Barrier math, sustainability scoring, cross-field validation | **Mixins** |
| `data/repositories/` | Orchestrate services, expose `Result<T>` | Repository pattern, async/await |
| `services/` | Gemini REST client, Firestore CRUD/streams, Firebase Auth, offline engine | **REST API**, **Firebase Auth**, **Firestore**, **Streams**, **Async/Future** |
| `providers/` | `ChangeNotifier` ViewModels | **State Management** |
| `views/` | Screens (splash, auth, home, input form, result, history, material detail) | **Layouts**, **MediaQuery**, **Animations**, Forms |
| `widgets/` | Reusable buttons, sliders, dropdowns, cards, badges | Widget composition, **Generics** |
| `painters/` | Film cross-section, shelf-life gauge, OTR/WVTR bar chart | **CustomPainter** |

---

## 🎨 Design System

| Token | Value |
|---|---|
| Background | `#0B0F19` |
| Primary Accent (Neon Teal) | `#00F2FE` |
| Secondary Accent (Emerald) | `#10B981` |
| Error | `#EF4444` |
| Text Primary | `#FFFFFF` |
| Text Secondary | `#94A3B8` |
| Fonts | Google Fonts **Inter** (body) + **JetBrains Mono** (numeric readouts) |
| Radii | 16px cards · 12px buttons · 8px chips |

---

## 🧪 How this was verified (important disclaimer)

This sandbox's network egress is restricted to `github.com` — `pub.dev`,
`storage.googleapis.com` (the Flutter SDK's Dart-SDK download host),
`dl.google.com`, `raw.githubusercontent.com`, and even the Debian package
mirrors were all unreachable, so the Flutter/Dart toolchain could not be
installed and `flutter pub get` / `flutter analyze` / `flutter test` /
`flutter build` could not be run in this environment.

To compensate, every file in this PR was:

1. Written with careful, deliberate Dart 3 syntax (sealed classes, pattern
   matching, enum switch-expressions, mixins) cross-checked line-by-line
   against the Flutter/Dart language spec and each package's well-known
   public API shape.
2. Statically verified with custom scripts checking: brace/paren/bracket
   balance across all 48+ `lib/` files and 5 `test/` files, that **every**
   internal `package:packwise_ai/...` import resolves to a real file, and
   that there are **no circular import cycles**.
3. Cross-checked for enum-switch exhaustiveness (every `MaterialType`,
   `FoodCategory`, `StorageType`, `BarrierLevel`, `EcoGrade` case is handled
   everywhere they're switched on).
4. Manually traced through the five test files' assertions against the
   exact implementation logic (e.g. hand-computed the sustainability-score
   formula and the offline ranking engine's output for the test fixtures).

**Please run `flutter pub get && flutter analyze && flutter test` locally
as the final verification step** — this environment simply couldn't do it
for you.

---

## 🧠 Resilience by design

- **No API key / no internet** → `LocalFallbackService` offline rules engine
  (uses the same `PackagingMaterial.isSuitableFor()` polymorphism +
  sustainability mixin as the "real" catalogue) produces a ranked result
  instantly, visibly labeled "Offline Mode".
- **Gemini returns malformed/partial JSON** → Markdown-fence stripping +
  per-entry parsing (one bad entry doesn't discard the other two) +
  automatic fallback to offline mode.
- **Gemini rate-limited / 5xx** → bounded retry with linear backoff, then
  offline fallback.
- **Firestore/Auth errors** → mapped to typed, user-friendly messages via
  the `AppException` → `Failure` pipeline instead of raw stack traces.

---

## 📄 License

Built for educational and hackathon purposes.
