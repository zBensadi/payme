# Alpha 11: Payments Synchronization

## Description
Brought the Payments domain up to parity with the rest of the offline-first architecture. Synchronizes payment metadata and soft deletes, ensuring referential integrity with Invoices.

## Key Changes
- Authored schema migration `v7_payment_sync.sql` (adding `is_deleted`).
- Updated `Payment` entity and `PaymentModel` with synchronization properties.
- Audited all mutation paths (`create`, `update`, `delete`) to aggressively set `is_dirty = 1` and update timestamps.
- Assigned Payments lowest priority to ensure Invoices are synced first.
- Explicitly scoped out binary file attachments for future milestones.
