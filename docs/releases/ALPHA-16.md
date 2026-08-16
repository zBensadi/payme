# Alpha 16 — Release Notes

**Tag:** `v2.0.0-alpha.16` *(pending — see below)*  
**Branch:** `alpha-16-public-prep`  
**Based on:** `v2.0.0-alpha.15`

---

## Summary

Alpha 16 completes the **final UI localization pass** across all user-facing strings in the application, and prepares the repository for **public open-source release** on GitHub.

---

## Localization Completion

Alpha 16 completes the final localization pass across English, French and Arabic and adds the missing translation keys.

### New ARB Keys (`app_en.arb`, `app_fr.arb`, `app_ar.arb`)

| Key | Usage |
|-----|-------|
| `deleteAccountingYearConfirm` | Accounting year delete dialog body |
| `systemOwnerDescription` | Business owner role description (dynamic, overrides DB value) |
| `systemRoleWarning` | System role modification warning banner |
| `priorityPrefix` | Role priority display (`Priority: {priority}`) |
| `clientVisibility` | Client form section heading |
| `visibilityEveryone` | Visibility selector segment |
| `visibilitySpecificUsers` | Visibility selector segment |
| `noUsersSelected` | Empty state in user picker |
| `selectUsers` | User picker dialog title |
| `deactivateUser` | User deactivation dialog title |
| `deactivateUserConfirm` | User deactivation confirmation message |
| `userWillLoseAccess` | Deactivation warning subtitle |
| `saveProfile` | Save button on user profile screen |
| `administration` | Administration section heading |
| `changeRole` | Role change button label |
| `searchUsers` | Search bar placeholder |
| `editRole` | Edit role screen title |
| `roleManagement` | Role management screen title |

### Screens Fully Localized
- ✅ Role Management list and editor screens
- ✅ User Management list screen (search, header)
- ✅ User detail/edit screen (save, role section, deactivation dialog)
- ✅ Client form — visibility selector and user picker dialog
- ✅ Accounting Year — delete confirmation dialog
- ✅ Dashboard — Roles and Administration quick-action labels

---

## Bug Fixes

- Fixed `const` compiler error on `SegmentedButton` segments using `AppLocalizations.of(context)!` (non-constant expression).
- Fixed system role description displaying English database value instead of localized string in non-English locales.

---

## Public Repository Preparation

### Firebase Decoupling
- Untracked `lib/firebase_options.dart`, `android/app/google-services.json`, `.firebaserc` from Git.
- Updated `.gitignore` to permanently exclude these files for all future contributors.
- Removed private project binding (`payme-dev-967bb`) from `firebase.json`.
- Created `lib/firebase_options.example.dart` as a reference template for new developers.

### Documentation
- Full `README.md` with prerequisites, setup, and build instructions.
- `CHANGELOG.md` covering Alpha 1–16.
- `docs/FIREBASE_SETUP.md` — step-by-step Firebase project configuration guide.
- `docs/CURRENT_STATUS.md` — Alpha release status and known limitations.
- `docs/releases/ALPHA-15.md` — Alpha 15 release notes.
- `docs/releases/ALPHA-16.md` — This file.

### Repository Hygiene
- Removed ~50 temporary development artifacts (`patch_*.py`, `scratch*.dart`, `*_output.txt`).
- Added MIT `LICENSE`.

---

## Git History

No Git history rewrite was performed. The complete audit confirmed **no real secrets** (private keys, service-account credentials, OAuth secrets) exist in any commit across the full project history.

---

## Known Limitations

- Firestore Security Rules (`allow read, write: if request.auth != null`) are **not production-ready**. Business-tenant isolation is enforced application-side via `SecuredRepository` only.
- Release APK uses debug signing. A production keystore must be configured for public distribution.
- No iOS or macOS support.

---

## Upgrade from Alpha 15

Alpha 16 includes automatic SQLite schema migration to version 14 for Accounting Year soft deletion. No manual database migration is required; existing Alpha 15 installations are upgraded automatically on startup. Localization changes are purely UI-layer. All existing Firestore data and local SQLite databases from Alpha 15 are fully compatible.

---

## Pending Before Tag Creation

- [ ] Final manual verification of all three locales on device
- [ ] Owner review of this release document
- [ ] `git tag v2.0.0-alpha.16`
