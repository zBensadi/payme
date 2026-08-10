# Alpha 13: UX Polish & Synchronization Finalization

**Status:** Completed

## Objective
Finalize the offline-first replication logic by stabilizing the settings synchronization, refining the PDF generation layout, and polishing the overall UX for a premium user experience on fresh installs and bootstrap sequences.

## Key Accomplishments

1. **Synchronization Finalization**
   - Fixed a critical data-loss bug in `SettingsRemoteDataSource` by fully serializing and syncing `defaultDocumentTitle` and `defaultDocumentLayout` to Firestore.
   - Initialized new businesses with dirty default settings to ensure immediate synchronization upon creation.

2. **UX & UI Polish**
   - **Dashboard Bootstrap:** Prevented the "New Accounting Year" setup widget from flashing during the initial data synchronization phase on fresh logins. The UI now gracefully stays on a loading state until sync completes.
   - **Invoice Loading:** Refactored `GlobalInvoiceListController` to asynchronously await dependent controllers (Active Year & Clients) before building the view, resolving the delayed loading bug where invoices wouldn't appear until a search was triggered.
   - **Attachment Picker:** Added an explicit UI hint and validation enforcing a 5MB maximum file size limit for attachments, reusing constants for allowed file extensions (`pdf`, `jpg`, `jpeg`, `png`).

3. **PDF Generation Stability**
   - Solved a clipping issue when rendering the "duplicate" document layout by wrapping the duplicated columns in `pw.FittedBox`. This ensures that even lengthy invoices scale down proportionally and fit securely within their respective half-page constraints without silent overflow truncation.

## Next Steps
With Alpha 13 completed, the core offline-first replication engine, authentication flow, layout generation, and user interfaces are stable. The project is now ready to proceed towards a full V2 Release Candidate.
