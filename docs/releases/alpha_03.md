# Alpha 03: Authentication Foundation

## Description
Transition from local-only authentication to Firebase Authentication (Email/Password). This milestone locked down the application routing using a reactive Riverpod controller to gate access based on the user's authentication state.

## Key Changes
- Implemented `FirebaseAuthenticationRepository` and `FirebaseAuthController`.
- Added `FirebaseLoginScreen` and `FirebaseForgotPasswordScreen`.
- Configured GoRouter to listen to `FirebaseAuthState` (Splash → Login → Dashboard).
- Added a secure Logout mechanism.
