# Implementation Plan: Fix Invoice Duplicate Button + Task Icon

## Bugs

### Bug 1: Two "New Invoice" buttons on Invoice screen
- `EmptyState` (shown when no invoices) has `actionLabel: 'New Invoice'` + `onAction`
- FAB (`FloatingActionButton.extended`) is ALWAYS rendered, also labelled "New Invoice"
- When list is empty: both visible simultaneously → confusing UX
- Fix: Remove `actionLabel` and `onAction` from the `EmptyState` call in invoices_screen.dart
  (FAB is the canonical primary action; EmptyState just explains the empty state)

### Bug 2: Solid dollar icon in Add Task sheet
- `add_task_sheet.dart:127` uses `Icons.attach_money` (solid/filled)
- All other icons in the same form are outlined style
- Fix: Change to `Icons.monetization_on_outlined` (outlined dollar circle)

## Files
| File | Line | Change |
|------|------|--------|
| lib/presentation/screens/invoices/invoices_screen.dart | 102–108 | Remove actionLabel + onAction from EmptyState |
| lib/presentation/screens/tasks/add_task_sheet.dart | 127 | Icons.attach_money → Icons.monetization_on_outlined |
