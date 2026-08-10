# Alpha 10: Accounting Year Synchronization

## Description
Resolved the Alpha 09 foreign key issues by bringing Accounting Years into the synchronization engine. Accounting years are synced with medium priority (before Invoices) to satisfy SQLite referential integrity.

## Key Changes
- Authored schema migration `v6_accounting_year_sync.sql` (adding `updated_at`, maintaining hard deletes).
- Implemented `AccountingYearConflictResolver` handling active year collisions.
- Fixed a silent background crash caused by an invalid SQLite dynamic `DEFAULT` value in the migration.
- Fixed `activeYearProvider` riverpod invalidation wiring to use instantiated repositories instead of tokens.
