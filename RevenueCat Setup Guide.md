  RevenueCat Setup Guide

  1. Create RevenueCat Account

  - Go to app.revenuecat.com → Sign up
  - Create a new Project → Name it Hustle

  2. Add Android App

  - In your project → + Add app → Select Google Play Store
  - App name: Hustle
  - Package name: com.yourcompany.hustle (check your android/app/build.gradle → applicationId)
  - Copy your Public API Key (starts with appl_... or goog_...)

  3. Create Products in Google Play Console

  Go to play.google.com/console → Your app → Monetize → Subscriptions

  Create two subscriptions:

  ┌────────────────┬────────────────────┬───────────────────┐
  │     Field      │      Monthly       │      Annual       │
  ├────────────────┼────────────────────┼───────────────────┤
  │ Product ID     │ hustle_pro_monthly │ hustle_pro_annual │
  ├────────────────┼────────────────────┼───────────────────┤
  │ Name           │ Hustle Pro Monthly │ Hustle Pro Annual │
  ├────────────────┼────────────────────┼───────────────────┤
  │ Price          │ $4.99              │ $39.99            │
  ├────────────────┼────────────────────┼───────────────────┤
  │ Billing period │ 1 month            │ 1 year            │
  └────────────────┴────────────────────┴───────────────────┘

  4. Link Play Console to RevenueCat

  - RevenueCat dashboard → App settings → Google Play tab
  - Upload your Google Play service account JSON (needed for RevenueCat to verify purchases)
  - Guide: RevenueCat docs → "Google Play Store" → "Service Credentials"

  5. Create Entitlement + Offering in RevenueCat

  Entitlement:
  - Dashboard → Entitlements → + → ID: pro → Save

  Products:
  - Dashboard → Products → + → Add both hustle_pro_monthly and hustle_pro_annual

  Offering:
  - Dashboard → Offerings → + → ID: default
  - Add a Package → Identifier: $rc_monthly → attach hustle_pro_monthly
  - Add a Package → Identifier: $rc_annual → attach hustle_pro_annual
  - Attach both to entitlement pro

  6. Paste API Key into Your App

  Open lib/core/constants/app_constants.dart and replace:
  static const String revenueCatApiKeyAndroid = 'PASTE_YOUR_REVENUECAT_ANDROID_KEY';
  with your actual key:
  static const String revenueCatApiKeyAndroid = 'goog_xxxxxxxxxxxxxxxxxxxxxxxx';

  7. Test

  - Use a test Google account added as a license tester in Play Console
  - Or use RevenueCat's sandbox mode (works on debug builds automatically)
  - Check RevenueCat dashboard → Customer View to see purchases appear

  ---
  That's it. Once the key is pasted and products are live, the paywall screen in your app will load real pricing and process real purchases.

● How is Claude doing this session? (optional)
  1: Bad    2: Fine   3: Good   0: Dismiss