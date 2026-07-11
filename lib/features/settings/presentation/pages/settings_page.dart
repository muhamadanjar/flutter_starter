import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/localization_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    if (state.isLoading && state.settings == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading settings...'),
      );
    }

    final settings = state.settings ?? const AppSettings();

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Appearance Section
              const _SectionHeader(title: 'Appearance'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_rounded,
                    iconColor: context.colors.primary,
                    title: context.l10n.settingsDarkMode,
                    subtitle: 'Use dark theme throughout the app',
                    trailing: Switch.adaptive(
                      value: settings.darkMode,
                      onChanged: (v) => ref.read(settingsProvider.notifier).updateSetting(darkMode: v),
                      activeThumbColor: context.colors.primary,
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.text_fields_rounded,
                    iconColor: context.colors.secondary,
                    title: context.l10n.settingsFontSize,
                    subtitle: 'Adjust text size',
                    trailing: DropdownButton<String>(
                      value: settings.fontSize,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'small', child: Text('Small')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'large', child: Text('Large')),
                      ],
                      onChanged: (v) {
                        if (v != null) ref.read(settingsProvider.notifier).updateSetting(fontSize: v);
                      },
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    iconColor: context.colors.info,
                    title: context.l10n.settingsLanguage,
                    subtitle: 'Select your preferred language',
                    trailing: DropdownButton<String>(
                      value: settings.language,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(settingsProvider.notifier).updateSetting(language: v);
                          ref.read(localizationProvider.notifier).setLocale(v);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Security Section
              const _SectionHeader(title: 'Security'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.fingerprint_rounded,
                    iconColor: context.colors.success,
                    title: context.l10n.settingsBiometric,
                    subtitle: 'Use fingerprint or face ID to login',
                    trailing: Switch.adaptive(
                      value: settings.biometricEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).updateSetting(biometricEnabled: v),
                      activeColor: context.colors.primary,
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    iconColor: context.colors.warning,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => context.go('/change-password'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notifications Section
              const _SectionHeader(title: 'Notifications'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: context.colors.accent,
                    title: context.l10n.settingsNotifications,
                    subtitle: 'Receive push notifications',
                    trailing: Switch.adaptive(
                      value: settings.notificationsEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).updateSetting(notificationsEnabled: v),
                      activeColor: context.colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Data & Privacy Section
              const _SectionHeader(title: 'Data & Privacy'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.sync_rounded,
                    iconColor: context.colors.secondary,
                    title: context.l10n.settingsAutoSync,
                    subtitle: 'Automatically sync data when online',
                    trailing: Switch.adaptive(
                      value: settings.autoSync,
                      onChanged: (v) => ref.read(settingsProvider.notifier).updateSetting(autoSync: v),
                      activeColor: context.colors.primary,
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.analytics_rounded,
                    iconColor: context.colors.info,
                    title: context.l10n.settingsAnalytics,
                    subtitle: 'Help improve the app with anonymous data',
                    trailing: Switch.adaptive(
                      value: settings.analyticsEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).updateSetting(analyticsEnabled: v),
                      activeColor: context.colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Account Section
              const _SectionHeader(title: 'Account'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    iconColor: context.colors.primary,
                    title: context.l10n.profileTitle,
                    subtitle: 'Manage your profile information',
                    onTap: () => context.go('/profile'),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: context.colors.textSecondary,
                    title: 'About',
                    subtitle: 'App version and information',
                    onTap: () => _showAboutDialog(context),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    iconColor: context.colors.error,
                    title: context.l10n.authLogout,
                    subtitle: 'Sign out of your account',
                    titleColor: context.colors.error,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enterprise Flutter App', style: AppTypography.labelLarge.copyWith(color: context.colors.textPrimary)),
            const SizedBox(height: 4),
            Text('Version 1.0.0', style: AppTypography.bodyMedium.copyWith(color: context.colors.textSecondary)),
            const SizedBox(height: 12),
            Text('Built with Flutter, Riverpod, Go Router, Dio, and Hive.', style: AppTypography.bodySmall.copyWith(color: context.colors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonOk),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.authLogout),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.bodyMedium.copyWith(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.l10n.authLogout),
          ),
        ],
      ),
    );
  }
}

// UI Components

class _SectionHeader extends StatelessWidget {

  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: context.colors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {

  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: context.colors.divider, height: 1),
    );
  }
}

class _SettingsTile extends StatelessWidget {

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.labelMedium.copyWith(color: titleColor ?? context.colors.textPrimary),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(color: context.colors.textHint),
            )
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: context.colors.textHint, size: 20),
      onTap: onTap,
    );
  }
}
