# Firebase Emulator Setup & Security Tests

## Architecture
We use the **Firebase Emulator Suite** via Docker for local, reproducible security testing. This ensures that developers can test Firestore Security Rules without needing access to a real Firebase project or risking production data.

## Prerequisites
- Docker & Docker Compose
- Node.js (for running the security test harness)

## Running the Emulators

1. Start the emulators using Docker Compose:
```bash
docker compose up -d firebase-emulator
```

2. The emulators will be available at:
- Auth: `localhost:9099`
- Firestore: `localhost:8080`
- Functions: `localhost:5001`
- Emulator UI: `localhost:4000`

> **Note**: The emulator project ID is `demo-payme-test`. Data is entirely local and isolated.

## Running the Security Tests

We use `@firebase/rules-unit-testing` and Mocha to assert our security rules.

1. Navigate to the test directory:
```bash
cd security-tests
```

2. Install dependencies:
```bash
npm install
```

3. Run the test suite:
```bash
npm test
```

## Phase 1 Note
In Phase 1, many tests for unauthorized access will **FAIL** because the `firestore.rules` file is still using the intentionally permissive Alpha 16 rules. This is expected. The tests are written for the *future* secure behavior. Once the secure rules are implemented in Phase 2, all tests will turn green.
