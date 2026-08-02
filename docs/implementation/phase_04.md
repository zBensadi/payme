# Phase 4: Clients Implementation

## Objectives

1. Establish the Client module as the foundational reference for all future CRUD business entities.
2. Implement soft-deletion logic for the Client entity.
3. Establish robust, decoupled state-management controllers for List and Form screens using Riverpod AsyncNotifiers.
4. Define standard, reusable UI components for Empty, Error, Loading states, and Confirm Dialogs.
5. Provide search capabilities and duplicate-checking on form submission.

## Files Created

### Domain Layer
- `lib/domain/entities/client.dart`: Defined the `Client` entity with fields for identification, contact info, and soft-delete/sync flags.
- `lib/domain/repositories/client_repository.dart`: Defined the abstract repository interface for `Client` operations, including `checkDuplicate`.

### Data Layer
- `lib/data/models/client_model.dart`: Created the SQLite-specific model mapped to the `Client` entity.
- `lib/data/datasources/local/client_local_datasource.dart`: Implemented native SQLite queries with search and soft-delete support.
- `lib/data/repositories_impl/client_repository_impl.dart`: Implemented `ClientRepository` mapping data source models to domain entities and handling `Result`/`AppFailure`.

### Presentation Layer - Widgets (Shared)
- `lib/presentation/widgets/empty_state_view.dart`: Reusable widget for empty data states.
- `lib/presentation/widgets/error_view.dart`: Reusable widget for repository errors.
- `lib/presentation/widgets/loading_view.dart`: Reusable centered circular progress indicator.
- `lib/presentation/widgets/confirm_dialog.dart`: Reusable confirmation dialog for destructive actions (e.g. deletion).

### Presentation Layer - Clients Module
- `lib/presentation/features/clients/controllers/client_list_controller.dart`: Managed fetching, searching, and deleting active clients.
- `lib/presentation/features/clients/controllers/deleted_clients_controller.dart`: Managed fetching, searching, and restoring deleted clients.
- `lib/presentation/features/clients/controllers/client_form_controller.dart`: Managed client validation, duplicate checks, and save/update operations.
- `lib/presentation/features/clients/widgets/client_list_tile.dart`: Shared UI element representing a client row with actions.
- `lib/presentation/features/clients/widgets/client_form.dart`: Reusable form UI extracted for potential dialog embedding.
- `lib/presentation/features/clients/screens/client_list_screen.dart`: Main active client listing with search.
- `lib/presentation/features/clients/screens/deleted_clients_screen.dart`: Deleted clients listing with restore capabilities.
- `lib/presentation/features/clients/screens/client_form_screen.dart`: Standalone screen to create or edit a client.

### Tests
- `test/domain/repositories/client_repository_test.dart`: Validated raw SQL implementations for client CRUD and duplicate checking.
- `test/presentation/features/clients/client_list_screen_test.dart`: Validated that visible and deleted clients accurately affect the UI.

### Documentation
- `docs/UI_UX_Guidelines.md`: Documented rules on shared components, forms, and layout predictability to ensure UI consistency for future modules.
- `docs/implementation/phase_04.md`: Detailed record of this phase.

## Architectural Decisions

1. **Notifier vs StateProvider**: Adapted to newer Riverpod conventions by replacing legacy `StateProvider` instances with `NotifierProvider` for robust, declarative state manipulation during search flows.
2. **Controller Decoupling**: Rigidly decoupled `ClientListController` and `ClientFormController` to ensure form submissions do not pollute list fetching operations, relying on `ref.invalidate` for sync.
3. **Soft Deletion Mechanism**: Standardized the use of the `is_deleted` column across DataSources to abstract deletion away from the application code without losing historical data.
4. **Duplicate Warnings**: Elected to enforce duplicate checking at the controller level rather than raw SQLite level (since SQLite lacks a composite unique constraint in our schema). A `FormatException` acts as a controlled signal for UI dialogs to prompt confirmation.

## Dependencies Added

None. Leveraged existing dependencies.

## Tests Executed & Verification Results

- Tests passed: 100%
- Integration verified: Yes, manual testing of drawer routing, forms, search fields, and soft-delete/restore verified accurate UI updates and state management.

## Lessons Learned

- Dealing with `AsyncNotifier` rebuilding in widget tests requires careful consideration of the asynchronous event loop (`tester.pump()` and delays) to prevent `find.text` from evaluating on a momentary `AsyncLoading` state.
