import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pro_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../di/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/common/app_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _businessName = '';
  double _defaultRate = AppConstants.defaultHourlyRate;
  String _currency = AppConstants.defaultCurrency;
  Uint8List? _logoBytes;

  firebase_auth.User? get _user =>
      firebase_auth.FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() {
    final prefs = sl<SharedPreferences>();
    final logoBase64 = prefs.getString(AppConstants.keyLogoBase64);
    setState(() {
      _businessName = prefs.getString(AppConstants.keyBusinessName) ?? '';
      _defaultRate = prefs.getDouble(AppConstants.keyDefaultRate) ??
          double.tryParse(prefs.getString(AppConstants.keyDefaultRate) ?? '') ??
          AppConstants.defaultHourlyRate;
      _currency =
          prefs.getString(AppConstants.keyCurrency) ?? AppConstants.defaultCurrency;
      _logoBytes = (logoBase64 != null && logoBase64.isNotEmpty)
          ? base64Decode(logoBase64)
          : null;
    });
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      await sl<SharedPreferences>()
          .setString(AppConstants.keyLogoBase64, base64Encode(bytes));
      if (mounted) setState(() => _logoBytes = bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load image')),
        );
      }
    }
  }

  Future<void> _removeLogo() async {
    await sl<SharedPreferences>().remove(AppConstants.keyLogoBase64);
    if (mounted) setState(() => _logoBytes = null);
  }

  Future<void> _editName() async {
    final controller =
        TextEditingController(text: _user?.displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditDialog(
        title: 'Display Name',
        controller: controller,
        hintText: 'Your name',
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await _user?.updateDisplayName(result.trim());
      if (mounted) setState(() {});
    }
  }

  Future<void> _editBusinessName() async {
    final controller = TextEditingController(text: _businessName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditDialog(
        title: 'Business Name',
        controller: controller,
        hintText: 'Your business or freelance name',
      ),
    );
    if (result != null) {
      final prefs = sl<SharedPreferences>();
      await prefs.setString(AppConstants.keyBusinessName, result.trim());
      if (mounted) setState(() => _businessName = result.trim());
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(SignOutRequested());
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String get _initials {
    final name = _user?.displayName ?? _user?.email ?? '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final photoUrl = _user?.photoURL;
    final symbol = AppConstants.currencySymbols[_currency] ?? _currency;
    final isPro = sl<ProService>().isProUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── Header band ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.surfaceLight,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
              ),
            ),
            child: Column(
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.12),
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? Text(
                              _initials,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    GestureDetector(
                      onTap: _editName,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppTheme.cardDark
                                : AppTheme.surfaceLight,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Name
                Text(
                  _user?.displayName ?? 'Set your name',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 2),
                if (_user?.email != null)
                  Text(
                    _user!.email!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceMutedLight,
                    ),
                  ),
                if (_businessName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _businessName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Pro badge / upgrade CTA
                if (isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 5),
                        Text(
                          'HUSTLE PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/paywall'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.star_outline_rounded, size: 16),
                    label: const Text(
                      'Upgrade to Pro',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),

          // ── Account section ───────────────────────────────────────
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(title: 'Account'),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.business_rounded,
                        iconColor: AppTheme.primaryColor,
                        label: 'Business Name',
                        value: _businessName.isEmpty
                            ? 'Tap to set'
                            : _businessName,
                        onTap: _editBusinessName,
                      ),
                      const Divider(height: 1),
                      _ProfileTile(
                        icon: Icons.attach_money_rounded,
                        iconColor: AppTheme.successColor,
                        label: 'Default Rate',
                        value: '$symbol${_defaultRate.toStringAsFixed(0)}/hr',
                        onTap: () =>
                            Navigator.pushNamed(context, '/settings'),
                      ),
                      const Divider(height: 1),
                      _ProfileTile(
                        icon: Icons.currency_exchange_rounded,
                        iconColor: AppTheme.secondaryColor,
                        label: 'Currency',
                        value: _currency,
                        onTap: () =>
                            Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Branding ──────────────────────────────────────────
                const _SectionHeader(title: 'Branding'),
                const SizedBox(height: 8),
                AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.borderDark
                              : AppTheme.borderLight,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _logoBytes != null
                          ? Image.memory(_logoBytes!, fit: BoxFit.contain)
                          : const Icon(
                              Icons.image_outlined,
                              color: AppTheme.onSurfaceMutedLight,
                              size: 22,
                            ),
                    ),
                    title: const Text('Invoice Logo'),
                    subtitle: Text(
                      _logoBytes != null
                          ? 'Shown at the top of every invoice PDF'
                          : 'Tap to add your logo',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceMutedLight,
                      ),
                    ),
                    trailing: _logoBytes != null
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            tooltip: 'Remove',
                            onPressed: _removeLogo,
                          )
                        : const Icon(Icons.chevron_right_rounded,
                            size: 20, color: AppTheme.onSurfaceMutedLight),
                    onTap: _pickLogo,
                  ),
                ),
                const SizedBox(height: 16),

                // ── App section ───────────────────────────────────────
                const _SectionHeader(title: 'App'),
                const SizedBox(height: 8),
                AppCard(
                  child: _ProfileTile(
                    icon: Icons.settings_rounded,
                    iconColor: AppTheme.onSurfaceMutedLight,
                    label: 'Settings',
                    value: 'Theme, defaults & more',
                    onTap: () =>
                        Navigator.pushNamed(context, '/settings'),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Sign out ──────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _signOut,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: AppTheme.errorColor),
                    foregroundColor: AppTheme.errorColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
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

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: AppTheme.onSurfaceMutedLight),
      ),
      trailing: onTap != null
          ? const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.onSurfaceMutedLight,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _EditDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hintText;

  const _EditDialog({
    required this.title,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: hintText),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
