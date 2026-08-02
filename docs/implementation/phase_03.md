# Phase 3: Accounting Years

## Objectives
- Established the foundational scoping entity: `AccountingYear`.
- Allowed the user to create, rename, switch the active year, and delete non-active years.
- Protected deletion of years behind the `ReauthGuard`.
- Exposed an `activeYearProvider` to track the globally active year for future domain features.

## Files Created
- `lib/core/utils/id_generator.dart`: Lightweight random UUID string generator.
- `lib/domain/entities/accounting_year.dart`: Immutable data class representing an accounting year.
- `lib/domain/repositories/accounting_year_repository.dart`: Interface for domain interactions.
- `lib/data/models/accounting_year_model.dart`: SQLite mapping logic.
- `lib/data/datasources/local/accounting_year_local_datasource.dart`: Data access layer handling SQFLite queries and transactional updates for active status.
- `lib/data/repositories_impl/accounting_year_repository_impl.dart`: Concrete repository implementation mapping database exceptions to `AppFailure`.
- `lib/presentation/providers/repository_providers.dart`: Centralized domain providers.
- `lib/presentation/providers/active_year_provider.dart`: Global provider tracking the active year.
- `lib/presentation/features/accounting_years/controllers/accounting_year_controller.dart`: `AsyncNotifier` managing UI state.
- `lib/presentation/features/accounting_years/screens/accounting_years_screen.dart`: UI for viewing and managing years.
- `lib/presentation/features/accounting_years/widgets/year_list_tile.dart`: Visual list item containing a contextual menu (Rename/Delete/Set Active).
- `test/domain/repositories/accounting_year_repository_test.dart`: Validates transactional integrity.
- `test/presentation/features/accounting_years/accounting_years_screen_test.dart`: Validates UI states.

## Files Modified
- `lib/presentation/routing/app_router.dart`: Added `/accounting-years` route.
- `lib/presentation/features/dashboard/screens/placeholder_home_screen.dart`: Added Navigation Drawer and dynamically displayed `activeYearProvider`.

## Architectural Decisions
- Strictly adhered to `Result<T>` and `AppFailure` patterns established in Phase 0-2.
- Implemented `IdGenerator` to avoid pulling in the external `uuid` dependency, satisfying architecture constraint simplicity.
- Leveraged `db.transaction()` to safely switch active year status, guaranteeing there is never zero or multiple active years.
- Validated `ReauthGuard` prior to invoking the `delete` command.

## Dependencies Added
- None

## Tests Executed
- `accounting_year_repository_test.dart`
- `accounting_years_screen_test.dart`
- Tests passed perfectly ensuring correct active state handling and failure paths.

## Verification Results
- 100% test pass rate.
- UI elements safely render the active state, update globally across the app when changed, and correctly display the contextual "Active Year" dashboard banner.
