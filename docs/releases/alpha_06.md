# Alpha 06: Synchronization Infrastructure

## Description
The foundation of the V2 Offline-First reactive synchronization architecture. This phase built the core engine that observes local changes and synchronizes them with Firestore in the background.

## Key Changes
- Introduced `SyncService` with debounce timers for background sync.
- Created `SyncPriority` enum to manage relational dependencies during sync.
- Implemented `SynchronizableRepository` interface.
- Developed `ConflictResolver` abstractions using Last-Write-Wins (LWW).
