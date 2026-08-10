# Alpha 12: Localization Infrastructure

## Description
Implemented comprehensive internationalization (i18n) to support English, French, and Arabic. Integrated persistent language selection and automatic Right-to-Left (RTL) layout switching.

## Key Changes
- Integrated `LocaleController` with `shared_preferences` to persist language settings.
- Built `LanguageSelectScreen` as a first-launch interceptor before authentication.
- Separated UI localization state from `BusinessSettings.languageCode` to maintain offline-first separation of concerns.
- Verified dynamic RTL mirroring for Arabic without app restarts.
- Fixed a compilation regression in `SettingsScreen` by restoring local state variables.
