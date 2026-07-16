import 'package:enterprise_flutter_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/avatar_upload_widget.dart';
import '../../../../core/widgets/error_widget.dart' as err;
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/profile.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final t = AppLocalizations.of(context);

    ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profileName),
        actions: [
          if (state.profile != null)
            IconButton(
              tooltip: t.profileEdit,
              onPressed: () => context.go('/edit-profile'),
              icon: const Icon(Icons.edit_rounded, size: 20),
            ),
        ],
      ),
      body: state.isLoading && state.profile == null
          ? const LoadingWidget(message: 'Loading profile...')
          : state.errorMessage != null && state.profile == null
              ? err.AppErrorWidget(
                  message: state.errorMessage,
                  onRetry: () => ref.read(profileProvider.notifier).loadProfile(),
                )
              : _buildContent(state),
    );
  }

  Widget _buildContent(ProfileState state) {
    final profile = state.profile;
    if (profile == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 0,
              color: context.colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: context.colors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        AvatarUploadWidget(
                          currentAvatarUrl: profile.avatarUrl,
                          size: 96,
                          padding: EdgeInsets.zero,
                          // Backend has no avatar-delete endpoint
                          showRemoveButton: false,
                          isLoading: state.isLoading,
                          onImagePicked: (file) =>
                              ref.read(profileProvider.notifier).uploadAvatar(file),
                        ),
                        if (state.isOffline)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.colors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Offline',
                              style: AppTypography.labelSmall
                                  .copyWith(color: context.colors.warning),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.name,
                      style: AppTypography.headlineSmall
                          .copyWith(color: context.colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: AppTypography.bodyMedium
                          .copyWith(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bio
            if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
              const _SectionTitle(label: 'About'),
              Card(
                elevation: 0,
                color: context.colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.colors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    profile.bio!,
                    style: AppTypography.bodyMedium
                        .copyWith(color: context.colors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Personal Information
            const _SectionTitle(label: 'Personal Information'),
            Card(
              elevation: 0,
              color: context.colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.colors.divider),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: profile.phone ?? '-',
                  ),
                  _InfoTile(
                    icon: Icons.cake_outlined,
                    label: 'Date of Birth',
                    value: profile.dateOfBirth != null
                        ? DateFormatter.formatDate(profile.dateOfBirth!)
                        : '-',
                  ),
                  _InfoTile(
                    icon: Icons.wc_outlined,
                    label: 'Gender',
                    value: profile.gender ?? '-',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Address
            if (_hasAddress(profile)) ...[
              const _SectionTitle(label: 'Address'),
              Card(
                elevation: 0,
                color: context.colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.colors.divider),
                ),
                child: Column(
                  children: [
                    if (profile.address != null && profile.address!.trim().isNotEmpty)
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Street',
                        value: profile.address!,
                      ),
                    if (profile.city != null && profile.city!.trim().isNotEmpty)
                      _InfoTile(
                        icon: Icons.location_city_outlined,
                        label: 'City',
                        value: profile.city!,
                      ),
                    if (profile.country != null && profile.country!.trim().isNotEmpty)
                      _InfoTile(
                        icon: Icons.public_outlined,
                        label: 'Country',
                        value: profile.country!,
                      ),
                    if (profile.postalCode != null && profile.postalCode!.trim().isNotEmpty)
                      _InfoTile(
                        icon: Icons.markunread_mailbox_outlined,
                        label: 'Postal Code',
                        value: profile.postalCode!,
                        isLast: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Account
            const _SectionTitle(label: 'Account'),
            Card(
              elevation: 0,
              color: context.colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.colors.divider),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'User ID',
                    value: profile.id,
                  ),
                  if (profile.createdAt != null)
                    _InfoTile(
                      icon: Icons.event_available_outlined,
                      label: 'Member Since',
                      value: DateFormatter.formatDate(profile.createdAt!),
                      isLast: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Change Password
            Card(
              elevation: 0,
              color: context.colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.colors.divider),
              ),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.lock_outline, color: context.colors.warning, size: 22),
                ),
                title: Text(
                  'Change Password',
                  style: AppTypography.labelLarge
                      .copyWith(color: context.colors.textPrimary),
                ),
                subtitle: Text(
                  'Update your password',
                  style: AppTypography.bodySmall
                      .copyWith(color: context.colors.textSecondary),
                ),
                trailing: Icon(Icons.chevron_right, color: context.colors.textHint),
                onTap: () => context.go('/change-password'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  bool _hasAddress(UserProfile p) {
    return (p.address?.trim().isNotEmpty ?? false) ||
        (p.city?.trim().isNotEmpty ?? false) ||
        (p.country?.trim().isNotEmpty ?? false) ||
        (p.postalCode?.trim().isNotEmpty ?? false);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: context.colors.textHint,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: context.colors.textHint, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodySmall
                          .copyWith(color: context.colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTypography.bodyMedium
                          .copyWith(color: context.colors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: context.colors.divider, indent: 52),
      ],
    );
  }
}
