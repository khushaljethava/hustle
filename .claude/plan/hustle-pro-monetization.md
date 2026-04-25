# Implementation Plan: Hustle Pro Monetization

## Summary
Add a "Hustle Pro" subscription tier using RevenueCat. Free users get up to 3 clients and
basic invoicing. Pro users ($4.99/mo or $39.99/yr) unlock unlimited clients, PDF invoice
export, and the full analytics dashboard. A paywall screen handles the purchase flow.

---

## Task Type
- [x] Fullstack (Flutter — RevenueCat SDK + PDF generation + UI gating)

---

## Technical Solution

- **RevenueCat** (`purchases_flutter`) manages subscriptions and entitlements — no backend needed
- **`ProService`** wraps RevenueCat, exposes `isProUser` bool + `purchasePackage()` method
- **Feature gates** check `sl<ProService>().isProUser` before allowing gated actions
- **PDF export** uses the already-installed `pdf` + `printing` packages, activated per-invoice
- **Analytics tab** is re-added to the bottom nav but shows `PaywallScreen` for free users

---

## Prerequisites (manual — user must do before running app)

1. Create free account at revenuecat.com → New Project → "Hustle"
2. Add Android app (package: `com.solopro.hustle`) → copy Android API key
3. Create products in Google Play Console:
   - `hustle_pro_monthly` — subscription, $4.99/month
   - `hustle_pro_annual`  — subscription, $39.99/year
4. In RevenueCat dashboard → Entitlements → create `pro` → attach both products
5. In RevenueCat → Offerings → Default → add both packages
6. Paste the Android API key into `AppConstants.revenueCatApiKeyAndroid`

---

## Implementation Steps

### Step 1 — Add `purchases_flutter` to pubspec.yaml
**File**: `pubspec.yaml`
```yaml
purchases_flutter: ^8.0.0   # add under dependencies
```
Run `flutter pub get`.

### Step 2 — Add Pro constants to `AppConstants`
**File**: `lib/core/constants/app_constants.dart`
```dart
// RevenueCat
static const String revenueCatApiKeyAndroid = 'PASTE_YOUR_KEY_HERE';
static const String revenueCatApiKeyIos     = 'PASTE_YOUR_KEY_HERE';
static const String proEntitlementId        = 'pro';
static const String proMonthlyProductId     = 'hustle_pro_monthly';
static const String proAnnualProductId      = 'hustle_pro_annual';

// Free tier limits
static const int freeClientLimit = 3;
```

### Step 3 — Create `ProService`
**File**: `lib/core/services/pro_service.dart` *(new)*

```dart
class ProService {
  bool _isPro = false;
  bool get isProUser => _isPro;

  Future<void> initialize() async {
    await Purchases.configure(PurchasesConfiguration(
      Platform.isAndroid
        ? AppConstants.revenueCatApiKeyAndroid
        : AppConstants.revenueCatApiKeyIos,
    ));
    await _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final info = await Purchases.getCustomerInfo();
    _isPro = info.entitlements.active.containsKey(AppConstants.proEntitlementId);
  }

  Future<bool> purchasePackage(Package package) async {
    final info = await Purchases.purchasePackage(package);
    _isPro = info.entitlements.active.containsKey(AppConstants.proEntitlementId);
    return _isPro;
  }

  Future<bool> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    _isPro = info.entitlements.active.containsKey(AppConstants.proEntitlementId);
    return _isPro;
  }

  Future<Offerings?> getOfferings() async {
    return await Purchases.getOfferings();
  }
}
```

### Step 4 — Register `ProService` in service locator
**File**: `lib/di/service_locator.dart`
- Import `ProService`
- After SharedPreferences registration:
```dart
final proService = ProService();
await proService.initialize();
sl.registerSingleton<ProService>(proService);
```

### Step 5 — Create `PaywallScreen`
**File**: `lib/presentation/screens/paywall/paywall_screen.dart` *(new)*

Layout:
```
Scaffold
  AppBar(title: 'Hustle Pro', leading: close X)
  ─────────────────────────────────────────────
  ⚡ Brand icon + "Go Pro" headline
  Subtitle: "Everything you need to grow your freelance business"
  ─────────────────────────────────────────────
  Feature list (checkmarks):
    ✓ Unlimited clients (free: 3)
    ✓ PDF invoice export & sharing
    ✓ Full analytics dashboard
    ✓ Priority support
  ─────────────────────────────────────────────
  BlocBuilder → show loading or two plan cards:
    [Monthly — $4.99/mo]  [Annual — $39.99/yr  SAVE 33%]
  ─────────────────────────────────────────────
  ElevatedButton: "Start Free Trial" or "Subscribe"
  TextButton: "Restore Purchases"
  ─────────────────────────────────────────────
  Fine print: "Cancel anytime. Billed via Google Play."
```

State: `_selectedPackage` (monthly default), loading indicator during purchase.
On success: Navigator.pop + show SnackBar "Welcome to Pro!".

### Step 6 — Add `/paywall` route in `main.dart`
**File**: `lib/main.dart`
```dart
'/paywall': (_) => const PaywallScreen(),
```

### Step 7 — Gate client creation (free limit = 3)
**File**: `lib/presentation/screens/clients/clients_screen.dart`

In `_showAddClient()`:
```dart
void _showAddClient(BuildContext context) {
  final proService = sl<ProService>();
  final clients = /* get current client list from state */;
  if (!proService.isProUser && clients.length >= AppConstants.freeClientLimit) {
    Navigator.pushNamed(context, '/paywall');
    return;
  }
  // existing bottom sheet code
}
```

Also update the FAB and empty state action with the same guard.

### Step 8 — Add PDF export to invoices (Pro feature)
**File**: `lib/core/services/invoice_pdf_service.dart` *(new)*

```dart
class InvoicePdfService {
  Future<Uint8List> generate(InvoiceModel invoice) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Column(children: [
        // Header: company name / invoice number
        // Bill to: client name, email
        // Line items table: description | qty | rate | amount
        // Subtotal, tax, TOTAL
        // Notes
        // "Thank you for your business"
      ]),
    ));
    return pdf.save();
  }
}
```

**File**: `lib/presentation/screens/invoices/invoices_screen.dart`

Add "Export PDF" option to `_InvoiceCard` `PopupMenuButton`:
```dart
PopupMenuItem(value: 'pdf', child: Row(children: [
  Icon(Icons.picture_as_pdf_outlined),
  SizedBox(width: 8),
  Text('Export PDF'),
])),
```

In `onSelected`:
```dart
if (v == 'pdf') {
  if (!sl<ProService>().isProUser) {
    Navigator.pushNamed(context, '/paywall');
    return;
  }
  final bytes = await sl<InvoicePdfService>().generate(invoice);
  await Printing.sharePdf(bytes: bytes,
    filename: 'invoice-${invoice.invoiceNumber}.pdf');
}
```

Register `InvoicePdfService` in service locator as singleton.

### Step 9 — Re-add Analytics tab, gate for Pro
**File**: `lib/presentation/screens/main_shell.dart`

Replace `ClientsScreen()` at index 4 with a `_AnalyticsOrPaywall` widget:
```dart
class _AnalyticsOrPaywall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (sl<ProService>().isProUser) {
      return const DashboardScreen();
    }
    return _AnalyticsUpsellScreen();  // inline locked screen with upgrade CTA
  }
}
```

Restore `DashboardScreen` import and add `ClientsScreen` to the nav as a separate visible item? 
→ Better: keep 5 tabs: Home | Tasks | Timer | Invoices | Analytics(locked)
→ Clients remains accessible via the existing tab (index 4 stays Clients, add Analytics behind Pro)

**Revised nav (5 tabs):**
- Home | Tasks | Timer | Invoices | Clients  ← keep as-is
- Analytics accessible from Home screen "See details" → PaywallScreen for free users

Update Home screen "See all" / analytics CTA to check Pro status.

### Step 10 — Pro badge in `ProfileScreen`
**File**: `lib/presentation/screens/profile/profile_screen.dart`

Next to user name in the header:
```dart
if (sl<ProService>().isProUser)
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.primaryColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text('PRO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
  ),
else
  TextButton(
    onPressed: () => Navigator.pushNamed(context, '/paywall'),
    child: Text('Upgrade to Pro →'),
  ),
```

---

## Key Files

| File | Operation | Description |
|------|-----------|-------------|
| `pubspec.yaml` | Modify | Add `purchases_flutter: ^8.0.0` |
| `lib/core/constants/app_constants.dart` | Modify | Add RevenueCat keys + free tier limit |
| `lib/core/services/pro_service.dart` | Create | RevenueCat wrapper, entitlement check |
| `lib/core/services/invoice_pdf_service.dart` | Create | PDF generation from InvoiceModel |
| `lib/di/service_locator.dart` | Modify | Register ProService + InvoicePdfService |
| `lib/main.dart` | Modify | Add `/paywall` route |
| `lib/presentation/screens/paywall/paywall_screen.dart` | Create | Subscription purchase UI |
| `lib/presentation/screens/clients/clients_screen.dart` | Modify | Gate add client at limit 3 |
| `lib/presentation/screens/invoices/invoices_screen.dart` | Modify | Add PDF export popup item |
| `lib/presentation/screens/profile/profile_screen.dart` | Modify | Pro badge + upgrade CTA |

---

## Risks and Mitigation

| Risk | Mitigation |
|------|------------|
| RevenueCat API key not set | App initializes gracefully — `isProUser` defaults to `false`, all features work except Pro ones |
| Play Store products not configured | `getOfferings()` returns null → PaywallScreen shows "Coming soon" fallback |
| PDF package generates blank/corrupt PDF | Test with a sample invoice in debug mode before release |
| User clears app data / reinstalls | "Restore Purchases" button calls `Purchases.restorePurchases()` |
| `purchases_flutter` version conflict | Pin to `^8.0.0`, run `flutter pub deps` to check conflicts |

---

## Post-Implementation Checklist (manual)
- [ ] Replace `PASTE_YOUR_KEY_HERE` with real RevenueCat API keys
- [ ] Create products on Google Play Console
- [ ] Link Play Console to RevenueCat
- [ ] Test purchase flow on physical device (not emulator)
- [ ] Test restore purchases
- [ ] Submit app to Play Store
