# Current Project Status

## PayMe — v2.0.0-alpha.16

| Property | Value |
|----------|-------|
| Version | `2.0.0-alpha.16` |
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
- The Firestore Security Rules are **not production-grade** (see [FIREBASE_SETUP.md](FIREBASE_SETUP.md)).

---

## What works in Alpha 16

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

---

## Known Limitations (Alpha)

- Firestore Security Rules use a broad `if request.auth != null` policy. Business-tenant isolation is enforced **application-side only** by the `SecuredRepository` layer. A malicious authenticated user could bypass this via direct Firestore API calls.
- No production signing configuration is included. Release APKs are signed with the debug key.
- No iOS or macOS support.
- No web support.

---

## Roadmap to Production

- [ ] Production-grade Firestore Security Rules with business-tenant enforcement
- [ ] Android release signing keystore
- [ ] Firebase App Check integration
- [ ] iOS support (optional)
