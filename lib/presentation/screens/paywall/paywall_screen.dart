import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../di/service_locator.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PurchasePackage? _selectedProduct;
  bool _loadingProducts = true;
  bool _productsUnavailable = false;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
      _productsUnavailable = false;
    });

    final proService = sl<ProService>();

    // If products already cached, use them immediately.
    if (proService.products.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedProduct =
              proService.annualProduct ?? proService.monthlyProduct;
          _loadingProducts = false;
        });
      }
      return;
    }

    // Otherwise, query the store now.
    await proService.reloadProducts();

    if (mounted) {
      final hasProducts = proService.products.isNotEmpty || kDebugMode;
      setState(() {
        _selectedProduct =
            proService.annualProduct ?? proService.monthlyProduct;
        _loadingProducts = false;
        _productsUnavailable = !hasProducts;
      });
    }
  }

  PurchasePackage? get _monthly => sl<ProService>().monthlyProduct;
  PurchasePackage? get _annual => sl<ProService>().annualProduct;

  Future<void> _purchase() async {
    if (_purchasing) return;
    setState(() => _purchasing = true);

    if (_selectedProduct == null) {
      if (kDebugMode) {
        // Simulate a successful purchase in debug so the full UI flow can be tested.
        await Future.delayed(const Duration(milliseconds: 800));
        await sl<ProService>().debugActivatePro();
        if (!mounted) return;
        setState(() => _purchasing = false);
        _showSnack('[DEBUG] Pro activated — no real purchase made.');
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _purchasing = false);
      _showSnack('Subscription not available yet. Please try again later.');
      return;
    }

    final result =
        await sl<ProService>().purchaseProduct(_selectedProduct!);

    if (!mounted) return;
    setState(() => _purchasing = false);

    switch (result) {
      case PurchaseResult.success:
        _showSnack('Welcome to Hustle Pro!');
        Navigator.of(context).pop(true);
      case PurchaseResult.cancelled:
        break;
      case PurchaseResult.notEntitled:
        _showSnack('Purchase completed but not activated. Contact support.');
      case PurchaseResult.error:
        _showSnack('Purchase failed. Please try again.');
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    final restored = await sl<ProService>().restorePurchases();
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (restored) {
      _showSnack('Purchases restored! Welcome back to Pro.');
      Navigator.of(context).pop(true);
    } else {
      _showSnack('No previous purchases found.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroHeader(
                onClose: () => Navigator.of(context).pop(false)),
          ),

          // ── Feature list ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _FeatureRow(
                  icon: Icons.people_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: 'Unlimited Clients',
                  subtitle:
                      'Free plan limited to ${AppConstants.freeClientLimit} clients',
                ),
                const SizedBox(height: 10),
                const _FeatureRow(
                  icon: Icons.repeat_rounded,
                  iconColor: AppTheme.secondaryColor,
                  title: 'Recurring Invoices',
                  subtitle: 'Auto-generate weekly, monthly or quarterly',
                ),
                const SizedBox(height: 10),
                const _FeatureRow(
                  icon: Icons.currency_exchange_rounded,
                  iconColor: AppTheme.successColor,
                  title: 'Multiple Currencies',
                  subtitle: 'Bill clients in their local currency',
                ),
                const SizedBox(height: 10),
                const _FeatureRow(
                  icon: Icons.style_rounded,
                  iconColor: AppTheme.accentColor,
                  title: 'Custom Invoice Templates',
                  subtitle: 'Classic, Modern or Minimal branding',
                ),
                const SizedBox(height: 10),
                const _FeatureRow(
                  icon: Icons.insights_rounded,
                  iconColor: AppTheme.primaryColor,
                  title: 'Full Analytics Dashboard',
                  subtitle: 'Track earnings, trends and performance',
                ),
                const SizedBox(height: 10),
                const _FeatureRow(
                  icon: Icons.download_rounded,
                  iconColor: AppTheme.infoColor,
                  title: 'CSV Data Export',
                  subtitle: 'Export invoices and time entries',
                ),
                const SizedBox(height: 10),
                const _FeatureRow(
                  icon: Icons.notifications_active_rounded,
                  iconColor: AppTheme.warningColor,
                  title: 'Overdue Reminders',
                  subtitle: 'Push notifications for unpaid invoices',
                ),
                const SizedBox(height: 10),
                const _FeatureRow(
                  icon: Icons.picture_as_pdf_rounded,
                  iconColor: AppTheme.errorColor,
                  title: 'PDF Invoice Export',
                  subtitle: 'Share professional invoices instantly',
                ),
              ]),
            ),
          ),

          // ── Plan selector ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _loadingProducts
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _productsUnavailable
                      ? _buildRetryState(theme)
                      : _buildPlanSelector(theme, isDark),
            ),
          ),

          // ── CTA ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _purchasing ? null : _purchase,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _purchasing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                _selectedProduct != null
                                    ? 'Start Hustle Pro'
                                    : 'Get Hustle Pro',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _purchasing ? null : _restore,
                    child: const Text('Restore Purchases'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cancel anytime. Billed via Google Play.\nSubscription renews automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceMutedLight,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 10),
          Text(
            'Could not load subscription options.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(ThemeData theme, bool isDark) {
    final monthly = _monthly;
    final annual = _annual;

    final monthlyPrice = monthly?.priceString ?? '\$4.99';
    final annualPrice = annual?.priceString ?? '\$39.99';

    // Calculate savings vs monthly
    final annualRaw = annual?.rawPrice ?? 39.99;
    final monthlyRaw = monthly?.rawPrice ?? 4.99;
    final savingsPct = monthlyRaw > 0
        ? ((1 - (annualRaw / 12) / monthlyRaw) * 100).round().clamp(0, 99)
        : 33;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your plan',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PlanCard(
                title: 'Monthly',
                price: monthlyPrice,
                period: 'per month',
                isSelected: _selectedProduct == monthly,
                badge: null,
                onTap: () => setState(() => _selectedProduct = monthly),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PlanCard(
                title: 'Annual',
                price: annualPrice,
                period: 'per year',
                isSelected: _selectedProduct == annual,
                badge: 'SAVE $savingsPct%',
                onTap: () => setState(() => _selectedProduct = annual),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _HeroHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 28),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    onPressed: onClose,
                  ),
                ],
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Hustle Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Unlock your full earning potential',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature row ───────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconColor, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceMutedLight),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded,
            color: AppTheme.successColor, size: 20),
      ],
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  final String title;
  final String price;
  final String period;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;
  final bool isDark;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.isSelected,
    required this.badge,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                : (widget.isDark ? AppTheme.cardDark : AppTheme.surfaceLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primaryColor
                  : (widget.isDark
                      ? AppTheme.borderDark
                      : AppTheme.borderLight),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                widget.title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: AppTheme.onSurfaceMutedLight),
              ),
              const SizedBox(height: 4),
              Text(
                widget.price,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: widget.isSelected ? AppTheme.primaryColor : null,
                ),
              ),
              Text(
                widget.period,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.onSurfaceMutedLight),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isSelected
                            ? AppTheme.primaryColor
                            : (widget.isDark
                                ? AppTheme.borderDark
                                : AppTheme.borderLight),
                        width: 2,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 11,
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isSelected ? 'Selected' : 'Tap to select',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: widget.isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.onSurfaceMutedLight,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
