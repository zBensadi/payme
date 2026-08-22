# Current Project Status

## PayMe — v2.0.0-alpha.18 (Next Release Candidate)

*Note: The previously published foundational milestone `v2.0.0-alpha.17` remains frozen and available under its respective git tag.*

| Property | Value |
|----------|-------|
| Version | `2.0.0-alpha.18` |
| Status | **Alpha / Testing** |
| Production Ready | **No** |
| Platforms | Windows (desktop), Android |
| Localization | English, French, Arabic (RTL) |

---

## What is Alpha?

PayMe is currently in **Alpha**. This means:

- Core features are implemented and functional.
- The application is suitable for controlled testing environments.
- **It is not suitable for use with real client data in a production business context.**
- APIs, data schemas, and UI may change between Alpha releases.
- APIs, data schemas, and UI may change between Alpha releases.

---

## What works in Alpha 18 (Upcoming)

- ✅ Offline-first client receivables management
- ✅ Firebase sync (bi-directional) with conflict resolution
- ✅ Multi-tenant business isolation
- ✅ Role-based access control with permission matrix
- ✅ User management (invite, activate/deactivate, role assignment)
- ✅ Client management with per-user visibility scoping
- ✅ Invoice and payment lifecycle tracking
- ✅ Multi-year accounting management
- ✅ PDF invoice generation with Arabic/RTL support
- ✅ CSV client export
- ✅ Full UI localization (English, French, Arabic)
- ✅ Windows desktop + Android builds
- ✅ Production-grade Firestore Security Rules with Custom Claims
- ✅ Business logo synchronization via Firebase Storage
- ✅ PDF invoice duplicate printing on A4 and numeric amount-in-words localization
- ✅ UI/UX Navigation Polish (F5/Backspace shortcuts, screen-local actions)

---

## Known Limitations (Alpha)

- No production signing configuration is included. Release APKs are signed with the debug key.
- No iOS or macOS support.
- No web support.

---

## Roadmap to Production

- [ ] Android release signing keystore
- [ ] Firebase App Check integration
- [ ] iOS support (optional)
