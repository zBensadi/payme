# Alpha 09: Invoice Synchronization

## Description
Integrated the Invoice domain into the sync engine. Uncovered a critical architectural constraint: Invoices cannot be synced until their associated Clients and Accounting Years are present locally.

## Key Changes
- Migrated Invoices to use soft deletes (`is_deleted` column).
- Assigned `SyncPriority.low` to Invoices.
- Identified the fresh-install SQLite `DatabaseException` (Foreign Key constraint failed) which occurs when downloading Invoices before Accounting Years are synced.
