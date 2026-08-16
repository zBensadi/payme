# PayMe — Client Receivables Manager

A cross-platform (Windows + Android) offline-first client receivables management application built with Flutter and Firebase.

> **Status:** v2.0.0-alpha.16 — Alpha/Testing release. Not production-ready.

---

## Features

- **Offline-first architecture** — Full local SQLite database with bi-directional Firestore sync
- **Multi-tenant** — Each business operates in its own isolated namespace
- **Role-based access control** — Configurable roles and permissions per business
- **Client management** — Client visibility controls per user
- **Invoice & payment tracking** — Full lifecycle management
- **Accounting years** — Multi-year book management
- **Localization** — English, French, and Arabic (RTL) support
- **Platforms** — Windows desktop + Android

---

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Flutter | ≥ 3.32 (`sdk: ^3.12.2`) |
| Dart | ≥ 3.12.2 |
| Firebase CLI | Latest |
| FlutterFire CLI | Latest |
| Android SDK | API 21+ |
| Windows | Windows 10+ (for desktop build) |

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/payme.git
cd payme
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

PayMe requires your **own Firebase project**. See [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) for the complete step-by-step guide.

> The `lib/firebase_options.dart` and `android/app/google-services.json` files are intentionally excluded from this repository (`.gitignore`). You must generate them for your own Firebase project using the FlutterFire CLI.

A reference template is available at: [`lib/firebase_options.example.dart`](lib/firebase_options.example.dart)

### 4. Generate localization files

```bash
flutter gen-l10n
```

### 5. Run the application

```bash
# Windows
flutter run -d windows

# Android (with device connected)
flutter run -d android
```

---

## Build

### Windows installer (Inno Setup)

```bash
flutter build windows --release
# Then compile installer.iss using Inno Setup
```

### Android APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Testing

```bash
flutter test
flutter analyze
```

---

## Project Structure

```
lib/
  core/           # Database, sync engine, error handling
  data/           # Data sources and repository implementations
  domain/         # Entities, use cases, repository interfaces
  l10n/           # Localization ARB files (en, fr, ar)
  presentation/   # Flutter UI (screens, widgets, providers)
  firebase_options.example.dart  # Reference config (see Firebase Setup)
firestore.rules   # Firestore security rules
firestore.indexes.json
docs/             # Project documentation
```

---

## Documentation

- [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) — Firebase project configuration guide
- [`docs/CURRENT_STATUS.md`](docs/CURRENT_STATUS.md) — Alpha release status
- [`CHANGELOG.md`](CHANGELOG.md) — Release history

---

## License

MIT License — see [LICENSE](LICENSE).
