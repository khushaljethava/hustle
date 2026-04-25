# Plan: Remove RevenueCat → Google Play Billing Direct

## Task Type
- [x] Fullstack (service layer + UI)

## Technical Solution
Replace `purchases_flutter` with Flutter's official `in_app_purchase` plugin.
Stream-based purchase updates bridged to `Future<PurchaseResult>` via Completer.
Pro status persisted to SharedPreferences for offline/cold-start reliability.

## Implementation Steps

1. `pubspec.yaml` — swap `purchases_flutter` for `in_app_purchase: ^3.2.0`
2. `app_constants.dart` — remove RC keys, add `keyIsPro` pref key
3. `pro_service.dart` — full rewrite using `in_app_purchase` with Completer bridge
4. `paywall_screen.dart` — replace `Package`/`Offerings` with `ProductDetails`
5. `service_locator.dart` — inject `prefs` into ProService constructor
6. `AndroidManifest.xml` — add BILLING permission

## Key Files
| File | Operation | Description |
|------|-----------|-------------|
| pubspec.yaml | Modify | Remove purchases_flutter, add in_app_purchase |
| lib/core/constants/app_constants.dart | Modify | Remove RC keys, add keyIsPro |
| lib/core/services/pro_service.dart | Rewrite | in_app_purchase implementation |
| lib/presentation/screens/paywall/paywall_screen.dart | Modify | ProductDetails instead of Package |
| lib/di/service_locator.dart | Modify | ProService(prefs) constructor |
| android/app/src/main/AndroidManifest.xml | Modify | BILLING permission |

## SESSION_ID
- CODEX_SESSION: n/a
- GEMINI_SESSION: n/a
