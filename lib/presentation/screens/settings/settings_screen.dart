import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/csv_export_service.dart';
import '../../../core/services/currency_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/database_helper.dart';
import '../../../di/service_locator.dart';
import '../../widgets/common/app_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _themeMode;
  late String _currency;
  late double _defaultRate;
  late bool _overdueNotifications;
  late bool _biometricEnabled;
  bool _biometricSupported = false;
  String _appVersion = '—';

  @override
  void initState() {
    super.initState();
    _themeMode = sl<ValueNotifier<ThemeMode>>().value;
    final prefs = sl<SharedPreferences>();
    _currency =
        prefs.getString(AppConstants.keyCurrency) ?? AppConstants.defaultCurrency;
    _defaultRate = prefs.getDouble(AppConstants.keyDefaultRate) ??
        double.tryParse(prefs.getString(AppConstants.keyDefaultRate) ?? '') ??
        AppConstants.defaultHourlyRate;
    _overdueNotifications =
        prefs.getBool(AppConstants.keyOverdueNotifications) ?? true;
    _biometricEnabled = sl<AppLockService>().isEnabled;
    _loadAsyncState();
  }

  Future<void> _loadAsyncState() async {
    try {
      final supported = await sl<AppLockService>().isDeviceSupported();
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _biometricSupported = supported;
        _appVersion = 'v${info.version}+${info.buildNumber}';
      });
    } catch (_) {}
  }

  Future<void> _setTheme(ThemeMode mode) async {
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await sl<SharedPreferences>().setString(AppConstants.keyThemeMode, modeStr);
    sl<ValueNotifier<ThemeMode>>().value = mode;
    setState(() => _themeMode = mode);
  }

  Future<void> _setCurrency(String currency) async {
    await sl<SharedPreferences>().setString(AppConstants.keyCurrency, currency);
    sl<ValueNotifier<String>>().value = currency;
    sl<CurrencyService>().fetchRates(forceRefresh: true);
    setState(() => _currency = currency);
  }

  Future<void> _editRate() async {
    final controller =
        TextEditingController(text: _defaultRate.toStringAsFixed(0));
    final symbol = AppConstants.currencySymbols[_currency] ?? _currency;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Default Hourly Rate'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '$symbol ',
            suffixText: '/hr',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      final rate = double.tryParse(result);
      if (rate != null && rate > 0) {
        await sl<SharedPreferences>()
            .setDouble(AppConstants.keyDefaultRate, rate);
        if (mounted) setState(() => _defaultRate = rate);
      }
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      final authed = await sl<AppLockService>().authenticate();
      if (!authed) return;
    }
    await sl<AppLockService>().setEnabled(enable);
    if (mounted) setState(() => _biometricEnabled = enable);
  }

  Future<void> _exportBackup() async {
    try {
      await sl<BackupService>().exportBackup();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
          'This will replace all your current Hustle data with the contents of the selected backup file. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Restore',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      final path = result?.files.firstOrNull?.path;
      if (path == null) return;
      final ok = await sl<BackupService>().restoreBackup(path);
      if (!mounted) return;
      if (ok) {
        await sl<DatabaseHelper>().close();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Backup restored. Please restart the app to see changes.'),
            duration: Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid backup file')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  Future<void> _shareApp() async {
    await Share.share(AppConstants.shareAppMessage);
  }

  Future<void> _rateApp() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This permanently deletes every client, task, time entry and invoice stored on this device. Your sign-in will be preserved, but everything else will be gone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete everything',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final prefs = sl<SharedPreferences>();
      final db = await sl<DatabaseHelper>().database;
      for (final table in [
        AppConstants.invoiceItemsTable,
        AppConstants.invoicesTable,
        AppConstants.timeEntriesTable,
        AppConstants.tasksTable,
        AppConstants.clientsTable,
      ]) {
        await db.delete(table);
      }
      // Clear only non-auth prefs; keep onboarding/theme so user stays in app
      for (final key in prefs.getKeys().toList()) {
        if (key == AppConstants.keyThemeMode ||
            key == AppConstants.keyCurrency ||
            key == AppConstants.keyOnboarded) continue;
        await prefs.remove(key);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final symbol = AppConstants.currencySymbols[_currency] ?? _currency;
    final isPro = sl<ProService>().isProUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ────────────────────────────────────────────
          const _SectionHeader(title: 'Appearance'),
          const SizedBox(height: 8),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsTile(
                    icon: Icons.palette_rounded,
                    iconColor: AppTheme.primaryColor,
                    title: 'Theme',
                    subtitle: switch (_themeMode) {
                      ThemeMode.system => 'Follows system',
                      ThemeMode.light => 'Light mode',
                      ThemeMode.dark => 'Dark mode',
                    },
                    trailing: null,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('Auto'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {_themeMode},
                      onSelectionChanged: (s) => _setTheme(s.first),
                      style: ButtonStyle(
                        minimumSize:
                            WidgetStateProperty.all(const Size(0, 40)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Defaults ──────────────────────────────────────────────
          const _SectionHeader(title: 'Defaults'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: _IconBox(
                    icon: Icons.currency_exchange_rounded,
                    color: AppTheme.secondaryColor,
                  ),
                  title: const Text('Currency'),
                  trailing: DropdownButton<String>(
                    value: _currency,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
                    items: AppConstants.currencySymbols.keys
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ))
                        .toList(),
                    onChanged: (c) {
                      if (c != null) _setCurrency(c);
                    },
                  ),
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? AppTheme.borderDark
                      : AppTheme.borderLight,
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: _IconBox(
                    icon: Icons.attach_money_rounded,
                    color: AppTheme.successColor,
                  ),
                  title: const Text('Hourly Rate'),
                  trailing: Text(
                    '$symbol${_defaultRate.toStringAsFixed(0)}/hr',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: _editRate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Security ──────────────────────────────────────────────
          if (_biometricSupported) ...[
            const _SectionHeader(title: 'Security'),
            const SizedBox(height: 8),
            AppCard(
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                secondary: _IconBox(
                  icon: Icons.fingerprint_rounded,
                  color: AppTheme.primaryColor,
                ),
                title: const Text('Biometric Lock'),
                subtitle: const Text('Require Face ID or fingerprint to open'),
                value: _biometricEnabled,
                activeThumbColor: AppTheme.primaryColor,
                onChanged: _toggleBiometric,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Notifications ─────────────────────────────────────────
          const _SectionHeader(title: 'Notifications'),
          const SizedBox(height: 8),
          AppCard(
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              secondary: _IconBox(
                icon: Icons.notifications_rounded,
                color: AppTheme.warningColor,
              ),
              title: const Text('Overdue Invoice Reminders'),
              subtitle: const Text('Get notified about unpaid invoices'),
              value: _overdueNotifications,
              activeThumbColor: AppTheme.primaryColor,
              onChanged: (v) async {
                await sl<NotificationService>().setEnabled(v);
                if (v) await sl<NotificationService>().requestPermission();
                setState(() => _overdueNotifications = v);
              },
            ),
          ),
          const SizedBox(height: 20),

          // ── Export ────────────────────────────────────────────────
          const _SectionHeader(title: 'Data Export'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: _IconBox(
                    icon: Icons.receipt_long_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text('Export Invoices'),
                  subtitle: Text(
                    isPro ? 'Download all invoices as CSV' : 'Pro feature',
                    style: TextStyle(
                      color: isPro
                          ? null
                          : AppTheme.onSurfaceMutedLight,
                    ),
                  ),
                  trailing: isPro
                      ? const Icon(Icons.download_rounded,
                          size: 20, color: AppTheme.primaryColor)
                      : _ProLockBadge(),
                  onTap: () async {
                    if (!isPro) {
                      Navigator.pushNamed(context, '/paywall');
                      return;
                    }
                    try {
                      await sl<CsvExportService>().exportInvoices();
                    } catch (_) {}
                  },
                ),
                Divider(
                  height: 1,
                  color:
                      isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: _IconBox(
                    icon: Icons.access_time_rounded,
                    color: AppTheme.infoColor,
                  ),
                  title: const Text('Export Time Entries'),
                  subtitle: Text(
                    isPro
                        ? 'Download all time entries as CSV'
                        : 'Pro feature',
                    style: TextStyle(
                      color: isPro
                          ? null
                          : AppTheme.onSurfaceMutedLight,
                    ),
                  ),
                  trailing: isPro
                      ? const Icon(Icons.download_rounded,
                          size: 20, color: AppTheme.primaryColor)
                      : _ProLockBadge(),
                  onTap: () async {
                    if (!isPro) {
                      Navigator.pushNamed(context, '/paywall');
                      return;
                    }
                    try {
                      await sl<CsvExportService>().exportTimeEntries();
                    } catch (_) {}
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Backup & Restore ──────────────────────────────────────
          const _SectionHeader(title: 'Backup'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 0),
                  leading: _IconBox(
                    icon: Icons.cloud_upload_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text('Export Backup'),
                  subtitle: const Text('Save all data as a single file'),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppTheme.onSurfaceMutedLight),
                  onTap: _exportBackup,
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 0),
                  leading: _IconBox(
                    icon: Icons.cloud_download_outlined,
                    color: AppTheme.infoColor,
                  ),
                  title: const Text('Restore from Backup'),
                  subtitle: const Text('Replace all data from a backup file'),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppTheme.onSurfaceMutedLight),
                  onTap: _restoreBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Support ───────────────────────────────────────────────
          const _SectionHeader(title: 'Support'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _IconBox(
                    icon: Icons.coffee_rounded,
                    color: const Color(0xFFBD5B04),
                  ),
                  title: const Text('Buy Me a Coffee'),
                  subtitle: const Text('Support the developer'),
                  trailing: const Icon(Icons.open_in_new_rounded,
                      size: 18, color: AppTheme.onSurfaceMutedLight),
                  onTap: () => _openUrl(AppConstants.buyMeACoffeeUrl),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _IconBox(
                    icon: Icons.ios_share_rounded,
                    color: AppTheme.secondaryColor,
                  ),
                  title: const Text('Share Hustle'),
                  subtitle: const Text('Tell a friend about the app'),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppTheme.onSurfaceMutedLight),
                  onTap: _shareApp,
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _IconBox(
                    icon: Icons.star_rounded,
                    color: AppTheme.warningColor,
                  ),
                  title: const Text('Rate the App'),
                  subtitle: const Text('Leave a review on the store'),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      size: 20, color: AppTheme.onSurfaceMutedLight),
                  onTap: _rateApp,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Legal ─────────────────────────────────────────────────
          const _SectionHeader(title: 'Legal'),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _IconBox(
                    icon: Icons.privacy_tip_outlined,
                    color: AppTheme.onSurfaceMutedLight,
                  ),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new_rounded,
                      size: 18, color: AppTheme.onSurfaceMutedLight),
                  onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _IconBox(
                    icon: Icons.description_outlined,
                    color: AppTheme.onSurfaceMutedLight,
                  ),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.open_in_new_rounded,
                      size: 18, color: AppTheme.onSurfaceMutedLight),
                  onTap: () => _openUrl(AppConstants.termsOfServiceUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────
          const _SectionHeader(title: 'About'),
          const SizedBox(height: 8),
          AppCard(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: const Text(AppConstants.appName),
              subtitle: const Text(AppConstants.appTagline),
              trailing: Text(
                _appVersion,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.onSurfaceMutedLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Danger Zone ───────────────────────────────────────────
          const _SectionHeader(title: 'Danger Zone'),
          const SizedBox(height: 8),
          AppCard(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: _IconBox(
                icon: Icons.delete_forever_rounded,
                color: AppTheme.errorColor,
              ),
              title: Text(
                'Clear All Data',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              subtitle: const Text('Permanently delete everything on this device'),
              onTap: _clearAllData,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.onSurfaceMutedLight,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: _IconBox(icon: icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}

class _ProLockBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 11, color: AppTheme.primaryColor),
          SizedBox(width: 3),
          Text(
            'PRO',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
