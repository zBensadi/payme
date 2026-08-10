# Alpha 04: Business Bootstrap

## Description
Implemented an atomic provisioning flow for newly registered users. To prevent orphaned or incomplete database states, the bootstrap process uses a Firestore `WriteBatch` to execute a transactional setup of the user's business ecosystem.

## Key Changes
- Created `FirebaseBootstrapScreen` to collect the business name on first login.
- Built `FirebaseBootstrapRepository.bootstrapBusiness()` utilizing `WriteBatch`.
- Atomically provisions: `users`, `businesses`, `roles` (Dynamic Super Admin), `business_settings`, and `activity_logs`.
- Resolves the Windows Desktop C++ SDK gRPC transaction bug (`[cloud_firestore/unknown]`) by utilizing batched writes instead of `runTransaction`.
