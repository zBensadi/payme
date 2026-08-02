# PayMe UI/UX Guidelines

These guidelines define the established patterns for building user interfaces within the PayMe application. The `Client` module serves as the primary reference implementation for these patterns.

## Core Principles

1. **Consistency**: Ensure all modules behave and look identical.
2. **Predictability**: Use standard Flutter paradigms (AppBars, FloatingActionButtons, ListTiles).
3. **Resilience**: Every screen must gracefully handle empty, loading, and error states.

## Shared Components (`lib/presentation/widgets/`)

### 1. EmptyStateView
Use this component when a collection is empty or a search yields no results.
- **Usage**: Always provide a descriptive `message` and an appropriate `icon`.
- **Actions**: For main lists, provide an `actionLabel` and `onAction` callback to encourage entity creation. Do not provide actions for empty search results or deleted items lists.

### 2. LoadingView
Use this component whenever asynchronous data is being fetched.
- **Usage**: Replace the entire body content with `LoadingView`. Do not use overlays unless explicitly required by a specific flow.

### 3. ErrorView
Use this component when a repository operation fails during the initial load.
- **Usage**: Always provide a clear `message`.
- **Actions**: Always provide an `onRetry` callback that calls `ref.invalidateSelf()` or equivalent on the controller to allow the user to try again.

### 4. ConfirmDialog
Use this component before performing any destructive or state-altering actions (e.g., delete, restore, force save on duplicate).
- **Usage**: Always clearly state the action in the `title` and the consequence in the `content`.
- **Destructive Actions**: Set `isDestructive: true` to highlight the primary button in red (e.g., Deletion).

## Forms and Validation

- **Layout**: Use a `ListView` wrapped in a `Form`. Pad the list view by 16px.
- **Inputs**: Use `OutlineInputBorder` for all `TextFormField`s. 
- **Keyboard Actions**: Set appropriate `textInputAction` (`next` for intermediate fields, `done` for the final field).
- **Required Fields**: Suffix required field labels with `*`. Ensure validation logic clearly identifies required fields.
- **State Separation**: Form state and list state should be isolated. `AsyncNotifier` (or equivalent) should manage the form saving lifecycle, while a separate `AsyncNotifier` manages the list.

## Lists and Search

- **Search Placement**: Place the search `TextField` in the `bottom` property of the `AppBar` using a `PreferredSize` widget for immediate accessibility.
- **Soft Deletion**: Active items and deleted items must reside on completely separate screens (`/entity` vs `/entity/deleted`).
- **Actions**: Use `PopupMenuButton` in the `trailing` property of `ListTile` for row-level actions (Edit, Delete, Restore).

## Snackbars

- Use `ScaffoldMessenger` to display success (green) or failure (red) feedback following form submissions or row-level actions. Strip `Exception: ` prefixes from error strings before displaying them.
