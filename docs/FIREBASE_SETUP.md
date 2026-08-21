# Firebase Setup Guide

This guide explains how to configure a Firebase project to run PayMe locally or deploy your own instance.

> **Important:** PayMe's Firebase configuration files (`lib/firebase_options.dart` and `android/app/google-services.json`) are intentionally excluded from this repository via `.gitignore`. You must generate these files for your **own** Firebase project. Do not commit them.

---

## Prerequisites

- A Google account
- [Firebase CLI](https://firebase.google.com/docs/cli) installed:
  ```bash
  npm install -g firebase-tools
  firebase login
  ```
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) installed:
  ```bash
  dart pub global activate flutterfire_cli
  ```

---

## Step 1 — Create a Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project**
3. Name it (e.g., `payme-myname`)
4. Disable Google Analytics (not required)
5. Click **Create project**

---

## Step 2 — Create Cloud Firestore

1. In your Firebase project, go to **Firestore Database**
2. Click **Create database**
3. Select **Native mode**
4. Choose your preferred region
5. Use the **default database** — do not create a named database

> PayMe uses the Firestore default `(default)` database. No custom database ID is required.

---

## Step 3 — Enable Email/Password Authentication

1. In your Firebase project, go to **Authentication → Sign-in method**
2. Click **Email/Password**
3. Enable **Email/Password** (the first toggle)
4. Click **Save**

> PayMe uses **only** Email/Password authentication. No OAuth providers, Google Sign-In, or other providers are required.

---

## Step 4 — Register Platform Apps

### Android

1. In Firebase Console, go to **Project settings → Your apps**
2. Click **Add app → Android**
3. Enter the package name: `com.erascript.payme`
   *(Or your own if you've changed `applicationId` in `android/app/build.gradle.kts`)*
4. Click **Register app**
5. **Download `google-services.json`**
6. Place it at `android/app/google-services.json` in your local repository

### Windows (Web App)

1. In Firebase Console, click **Add app → Web**
2. Give it a nickname (e.g., `PayMe Windows`)
3. Click **Register app**
4. You do NOT need to copy the config values manually — they will be handled by `flutterfire configure` in the next step

---

## Step 5 — Run FlutterFire Configure

From the root of the PayMe repository:

```bash
flutterfire configure
```

Follow the prompts:
- Select your Firebase project
- Select the platforms: **android**, **windows**
- This will automatically generate `lib/firebase_options.dart`

> A reference template showing the expected structure of this file is available at `lib/firebase_options.example.dart`.

---

## Step 6 — Deploy Firebase Resources (Rules & Functions)

PayMe Alpha 17 relies on Cloud Functions for secure business bootstrapping and user provisioning, and Firebase Storage for business logos.

Deploy the security rules and cloud functions to your project:

```bash
firebase use --add          # Link your project to the Firebase CLI
firebase deploy --only firestore:rules,storage,functions
```

> **Note:** Deploying Cloud Functions requires your Firebase project to be on the Blaze (pay-as-you-go) plan.

---

## Step 7 — Run PayMe

```bash
flutter pub get
flutter gen-l10n
flutter run -d windows   # or -d android
```

---

## Firestore Database Schema

PayMe uses the following top-level collection structure:

```
/users/{uid}
    businessId: String
    roleId: String

/businesses/{businessId}
    name: String
    ownerId: String
    createdAt: Timestamp
    /roles/{roleId}
        name: String
        permissions: List<String>
        priority: int
        isSystemRole: bool
    /users/{uid}
        name: String
        email: String
        isActive: bool
        roleId: String
    /clients/{clientId}
        name: String
        ...
    /invoices/{invoiceId}
        ...
    /payments/{paymentId}
        ...
    /accounting_years/{yearId}
        ...
    /client_visibility/{clientId_userId}
        clientId: String
        userId: String
        syncedAt: String (ISO8601)
```

> No manual seed data or migration scripts are required. PayMe bootstraps the initial business, owner role, and user pointer automatically on first login via `FirebaseBootstrapRepository`.

---

## Required Firebase Services

| Service | Required | Notes |
|---------|----------|-------|
| Authentication | ✅ Yes | Email/Password only |
| Cloud Firestore | ✅ Yes | Default database, native mode |
| Cloud Storage | ✅ Yes | Used for Business Logos |
| Cloud Messaging | ❌ No | Not used |
| Functions | ✅ Yes | Required for Business Bootstrap and User Provisioning |
