# Alpha 05: Current User Profile Layer

## Description
Decoupled Firestore user data from the Firebase Authentication layer to adhere to Clean Architecture. The Auth repository now only handles identity, while the new `UserProfileRepository` is responsible for fetching the user's role, business context, and profile.

## Key Changes
- Introduced `UserRole`, `BusinessContext`, and `UserProfile` domain entities.
- Implemented `UserProfileRepository` to hydrate the user state.
- Created `currentUserProvider` in Riverpod to cache the user profile.
- Ensured UI controllers consume the cached provider instead of querying Firestore directly, minimizing read operations.
