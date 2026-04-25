# Implementation Plan: Profile, Settings & Clients Access

## Summary
Add a Profile screen, Settings screen, and make Clients discoverable by swapping the
Analytics nav tab with Clients (analytics data is already visible on the Home screen).
Profile is accessed via a person icon in the Home AppBar.

---

## Task Type
- [x] Frontend (Flutter — BLoC + SharedPreferences + Firebase Auth)

---

## Technical Solution

- **Profile screen**: reads from `FirebaseAuth.currentUser` + `SharedPreferences` (business name).
  Allows editing display name and business name. Links to Settings. Has Sign Out.
- **Settings screen**: reads/writes `SharedPreferences` for theme mode, default currency,
  default hourly rate. Theme change updates `AppTheme` via a `ValueNotifier` hoisted in `main.dart`.
- **Clients nav tab**: replace the Analytics tab (index 4) in `MainShell` with `ClientsScreen`.
  Analytics data is already surfaced on the Home screen stats cards, so no data is lost.
- **Profile entry point**: add an `IconButton(Icons.person_outline)` to the Home AppBar that
  pushes `ProfileScreen` as a named route.

---

## Implementation Steps

### Step 1 — Add `/profile` and `/settings` routes to `main.dart`
**File**: `lib/main.dart`
- Add `'/profile': (_) => const ProfileScreen()` to `routes`
- Add `'/settings': (_) => const SettingsScreen()` to `routes`
- Wrap `MaterialApp` theme with a `ValueListenableBuilder<ThemeMode>` driven by a
  `ValueNotifier<ThemeMode> themeModeNotifier` (initialized from SharedPreferences).
- Pass `themeModeNotifier` down via `InheritedWidget` or expose via service locator.

**Deliverable**: routes registered, theme notifier wired.

### Step 2 — Create `ProfileScreen`
**File**: `lib/presentation/screens/profile/profile_screen.dart` *(new)*

Layout (Scaffold + SingleChildScrollView):
```
AppBar(title: 'Profile', actions: [settings icon → /settings])
─────────────────────────────────────
  Avatar circle (initials or photo from FirebaseAuth)
  Display name  (editable inline or via dialog)
  Email         (read-only, from FirebaseAuth)
─────────────────────────────────────
  Section: Account
    ListTile: Business Name  → edit dialog (saves to SharedPrefs keyBusinessName)
    ListTile: Default Rate   → edit dialog (saves to SharedPrefs keyDefaultRate)
    ListTile: Currency       → dropdown dialog (saves to SharedPrefs keyCurrency)
─────────────────────────────────────
  Section: App
    ListTile: Settings       → Navigator.pushNamed '/settings'
─────────────────────────────────────
  Danger zone
    OutlinedButton: Sign Out → AuthBloc.add(SignOutRequested())
                              then Navigator.pushNamedAndRemoveUntil '/login'
```

**Deliverable**: `ProfileScreen` widget, reads Firebase user + SharedPrefs, edits name/business.

### Step 3 — Create `SettingsScreen`
**File**: `lib/presentation/screens/settings/settings_screen.dart` *(new)*

Layout (Scaffold + ListView):
```
AppBar(title: 'Settings')
─────────────────────────────────────
  Section: Appearance
    ListTile: Theme  → SegmentedButton (System / Light / Dark)
                       writes SharedPrefs keyThemeMode + updates themeModeNotifier
─────────────────────────────────────
  Section: Defaults
    ListTile: Currency        → DropdownDialog  (AppConstants.currencySymbols keys)
    ListTile: Hourly Rate     → TextFieldDialog (numeric)
─────────────────────────────────────
  Section: About
    ListTile: Version         → reads pubspec via PackageInfo or hardcoded '1.0.0'
    ListTile: Hustle tagline  → AppConstants.appTagline
```

**Deliverable**: `SettingsScreen` widget, theme change applies immediately app-wide.

### Step 4 — Add profile icon to `HomeScreen` AppBar
**File**: `lib/presentation/screens/home/home_screen.dart`
- In `SliverAppBar.actions`, replace the empty notifications `IconButton` callback
  and add before it:
  ```dart
  IconButton(
    icon: const Icon(Icons.person_outline),
    onPressed: () => Navigator.pushNamed(context, '/profile'),
  ),
  ```

**Deliverable**: tapping person icon opens ProfileScreen.

### Step 5 — Swap Analytics tab → Clients tab in `MainShell`
**File**: `lib/presentation/screens/main_shell.dart`
- Add import for `ClientsScreen` and `AddClientSheet`.
- Replace `DashboardScreen()` at index 4 with `ClientsScreen()`.
- Replace the Analytics `NavigationDestination` with:
  ```dart
  NavigationDestination(
    icon: Icon(Icons.people_outline),
    selectedIcon: Icon(Icons.people_rounded),
    label: 'Clients',
  )
  ```
- Remove unused `DashboardScreen` import (it's still used indirectly via `DashboardBloc`
  on HomeScreen — just remove from `_screens` list).

**Deliverable**: Clients tab is now in the bottom nav; clients can be added via the FAB.

---

## Key Files

| File | Operation | Description |
|------|-----------|-------------|
| `lib/main.dart` | Modify | Add routes, theme notifier |
| `lib/presentation/screens/profile/profile_screen.dart` | Create | Profile + account settings |
| `lib/presentation/screens/settings/settings_screen.dart` | Create | App preferences |
| `lib/presentation/screens/home/home_screen.dart` | Modify | Add profile icon to AppBar |
| `lib/presentation/screens/main_shell.dart` | Modify | Swap Analytics → Clients tab |

---

## Risks and Mitigation

| Risk | Mitigation |
|------|------------|
| Theme change not reflecting immediately | Use `ValueNotifier<ThemeMode>` at top level, rebuild `MaterialApp` |
| Firebase `currentUser` is null edge case | Null-guard everywhere; if null show placeholder and redirect to login |
| Removing DashboardScreen from nav breaks analytics visibility | Analytics data cards remain on HomeScreen; DashboardBloc still runs |
| SharedPrefs not yet initialized for new settings keys | Use `?? defaultValue` fallbacks for all reads |
