# Plan: Next Polish Items (minimalism-respecting)

## Philosophy check
You said: **minimal features, simple to use.** So this plan only lists items that:
- Add zero new tabs / screens / configuration
- Add a single toggle, one button, or one line of polish
- Make the app feel *finished* rather than *fuller*

Items ranked by impact-per-line-of-code.

---

## Tier 1 — Ship these (high trust/polish, tiny surface)

### 1. Biometric app lock
One toggle in Settings → "Require Face ID / fingerprint".
- Package: `local_auth: ^2.3.0`
- 1 SharedPreferences key: `lock_enabled`
- On app resume from background → show auth prompt; blur underlying UI
- **Why**: Financial data. One toggle = huge trust bump. ~60 lines.

### 2. Backup & Restore (single file)
Two buttons in Settings → "Export backup" / "Restore from backup".
- Export: Zip of `hustle.db` + SharedPreferences JSON → share sheet
- Restore: Pick `.hustle-backup` file → replace DB + prefs → restart
- Package: already have `share_plus`, `path_provider`; add `archive: ^3.6.1` for zip
- **Why**: #1 objection to local-first apps is "what if I lose my phone?". ~120 lines.

### 3. Dynamic app version in Settings
About section currently shows hardcoded `v1.0.0`. Read from `package_info_plus`.
- Package: `package_info_plus: ^8.0.2`
- 1 future-builder, 5 lines in About tile
- **Why**: Version out of sync is embarrassing. ~10 lines.

### 4. Undo for deletes (snackbar action)
On Invoice / Task / Client / Time-entry delete → snackbar with `UNDO` action (5s window).
- No new events; keep a "last deleted" item in-memory, re-insert on undo
- **Why**: Prevents rage-quit when accidentally deleting. Standard Material pattern. ~40 lines per screen, shared helper.

### 5. Logo on invoice PDF
One row in Profile → "Upload your logo". Picker stores path in SharedPreferences. PDF service draws it top-left.
- Package: `image_picker: ^1.1.2` (already common, may be transitively present)
- Store bytes as base64 in prefs (small enough)
- **Why**: Single biggest "professional upgrade" for the user's clients. ~80 lines.

---

## Tier 2 — Only if Tier 1 feels light

### 6. Legal links (required for App Store anyway)
Two tiles in Settings → Privacy Policy · Terms of Service.
Host a simple markdown on your site; `url_launcher` (already installed) opens.
- **Why**: App Store rejection blocker if missing. ~15 lines.

### 7. Share Hustle + Rate app
Two tiles in Settings → "Share with a friend" · "Rate on the App Store".
- Share: `Share.share('Check out Hustle: <storeURL>')`
- Rate: `in_app_review: ^2.0.10` → `requestReview()`
- **Why**: Organic growth; costs nothing. ~20 lines.

### 8. Clear all data
One destructive tile in Settings → "Clear all data" with confirmation dialog.
- Deletes DB file, clears SharedPreferences (except auth), restarts
- **Why**: GDPR / "start fresh" request. Already needed for testing. ~30 lines.

---

## Explicitly NOT recommended right now
(Respecting minimalism — bring these up later if you want.)

- ❌ Home-screen widgets (iOS/Android) — platform-specific, 3-5 days work
- ❌ Expense tracking — that's a new feature, not polish
- ❌ Payment integration (Stripe) — feature, not polish
- ❌ Cloud sync (Firestore) — big architectural move
- ❌ Projects hierarchy — feature bloat
- ❌ AI writing assistant — feature, scope creep
- ❌ Team / multi-user — way out of scope

---

## Execution order (if you approve)

Week 1: Item 3 (15 min) → Item 4 (2 hrs) → Item 1 (4 hrs)
Week 2: Item 2 (1 day) → Item 5 (4 hrs)

Total scope: ~2 weeks of polish. Zero new tabs. Zero new "concepts" for the user to learn. App feels 2× more finished.

---

## Key Files to touch

| File | Item | Notes |
|------|------|-------|
| `pubspec.yaml` | 1,2,3,5,7 | Add: local_auth, archive, package_info_plus, image_picker, in_app_review |
| `lib/presentation/screens/settings/settings_screen.dart` | 1,2,3,6,7,8 | New "Security", "Data", "Legal" sections |
| `lib/main.dart` | 1 | Wrap in lock guard on resume |
| `lib/presentation/screens/profile/profile_screen.dart` | 5 | Logo upload tile + About version dynamic |
| `lib/core/services/invoice_pdf_service.dart` | 5 | Draw logo if present |
| `lib/core/services/backup_service.dart` (NEW) | 2 | Export/import zip |
| `lib/presentation/widgets/common/undo_snackbar.dart` (NEW) | 4 | Shared helper |

---

## Your move
Pick a subset — or say "ship all Tier 1" and I'll go.
