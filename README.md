# PayMe

Offline-First Client Receivables Manager for Windows Desktop and Android.

## Project Overview

PayMe is a local, offline-first application designed for accountants and small businesses to track client invoices, payments, and outstanding balances. It runs entirely on local SQLite with no backend and is scoped to a single admin user, a single currency, and one active accounting year at a time. It uses a Clean Architecture approach with a focus on simplicity, maintainability, and data security.

## Prerequisites

- Flutter SDK (see version below)
- Android Studio (for Android build)
- Visual Studio (for Windows desktop build)
- Git

## Flutter Version

Ensure you are using the latest stable Flutter SDK version 3.29.x (or as defined in `pubspec.yaml` environment constraints `^3.12.2`).

## Supported Platforms

- Windows Desktop
- Android

## How to Run the Project

1. Clone the repository.
2. Ensure you have the required prerequisites for your target platform (Windows or Android).
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   - For Windows: `flutter run -d windows`
   - For Android: `flutter run -d android` (requires an attached device or running emulator)
