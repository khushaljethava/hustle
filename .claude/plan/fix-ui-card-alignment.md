# Implementation Plan: Fix UI Card Alignment Regression

## Problem
`crossAxisAlignment: CrossAxisAlignment.stretch` was added to Row widgets
containing StatCard pairs. This causes cards without a subtitle to expand to
match the height of cards with a subtitle, leaving large blank empty space
below the value text. The result looks "hollow" and worse than the original.

## Root Cause
- `StatCard` → `AppCard` → `Container` → `Column(mainAxisSize: max, start-aligned)`
- When Row stretches children, the Column fills available height but content
  stays at top → blank space below.
- `CrossAxisAlignment.stretch` alone does NOT use intrinsic (content-driven)
  height — it stretches to whatever the Row's cross-axis size happens to be.

## Correct Solution: IntrinsicHeight
`IntrinsicHeight` wraps the Row and:
1. Measures each child's **natural content height** (intrinsic height)
2. Sets Row height = max of all intrinsic heights
3. Combined with `CrossAxisAlignment.stretch` inside, stretches each child to
   that height — equal heights, content-driven, no empty space

## Task Type
- [x] Frontend only

## Implementation Steps

### Step 1 — dashboard_screen.dart (2 Row widgets)
File: `lib/presentation/screens/dashboard/dashboard_screen.dart`
- Remove `crossAxisAlignment: CrossAxisAlignment.stretch` from both Rows
  in `_buildMetricsGrid()`
- Wrap each Row in `IntrinsicHeight(...)`

### Step 2 — home_screen.dart (2 Row widgets)
File: `lib/presentation/screens/home/home_screen.dart`
- Remove `crossAxisAlignment: CrossAxisAlignment.stretch` from both Rows
  in `_buildEarningsSection()`
- Wrap each Row in `IntrinsicHeight(...)`

### Step 3 — invoices_screen.dart (1 Row widget)
File: `lib/presentation/screens/invoices/invoices_screen.dart`
- Remove `crossAxisAlignment: CrossAxisAlignment.stretch` from the Row
  in `_buildStatsBar()`
- Wrap the Row in `IntrinsicHeight(...)`

## Pattern (apply identically in all 3 files)
```dart
// BEFORE (regression)
Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Expanded(child: StatCard(...)),
    const SizedBox(width: 12),
    Expanded(child: StatCard(..., subtitle: '...')),
  ],
)

// AFTER (correct)
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: StatCard(...)),
      const SizedBox(width: 12),
      Expanded(child: StatCard(..., subtitle: '...')),
    ],
  ),
)
```

## Key Files
| File | Operation | Lines |
|------|-----------|-------|
| lib/presentation/screens/dashboard/dashboard_screen.dart | Modify | _buildMetricsGrid rows |
| lib/presentation/screens/home/home_screen.dart | Modify | _buildEarningsSection rows |
| lib/presentation/screens/invoices/invoices_screen.dart | Modify | _buildStatsBar row |

## Risks
| Risk | Mitigation |
|------|------------|
| IntrinsicHeight performance cost | These are static stat cards (max 4 items per row), negligible impact |
| SizedBox(width:12) spacer inside IntrinsicHeight | SizedBox in a stretched Row reports its own intrinsic height as 0; tallest card still drives the height — correct behaviour |
