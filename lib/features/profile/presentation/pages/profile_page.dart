import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/avatar_upload_widget.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as err;
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateControllers() {
    final profile = ref.read(profileProvider).profile;
    if (profile != null) {
      // API returns a single display name; split on the first space as a
      // best-effort prefill for the first_name/last_name fields.
      final nameParts = profile.name.trim().split(RegExp(r'\s+'));
      _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _emailController.text = profile.email;
      _phoneController.text = profile.phone ?? '';
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    // PUT /auth/profile only accepts these fields (ProfileUpdateRequest)
    await ref.read(profileProvider.notifier).updateProfile({
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    });

    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

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
      // Populate controllers when profile loads
      if (next.profile != null && prev?.profile == null) {
        _populateControllers();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: () {
                _populateControllers();
                setState(() => _isEditing = true);
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit'),
            )
          else
            TextButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save'),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Section
              Center(
                child: Column(
                  children: [
                    AvatarUploadWidget(
                      currentAvatarUrl: profile.avatarUrl,
                      size: 96,
                      padding: EdgeInsets.zero,
                      // Backend has no avatar-delete endpoint
                      showRemoveButton: false,
                      isLoading: state.isLoading,
                      onImagePicked: (file) => ref.read(profileProvider.notifier).uploadAvatar(file),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.name,
                      style: AppTypography.headlineSmall.copyWith(color: context.colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email,
                      style: AppTypography.bodyMedium.copyWith(color: context.colors.textSecondary),
                    ),
                    if (state.isOffline) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Offline - Cached Data',
                          style: AppTypography.labelSmall.copyWith(color: context.colors.warning),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields (PUT /auth/profile: first_name, last_name, email, phone)
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'First Name',
                      hint: 'First name',
                      controller: _firstNameController,
                      enabled: _isEditing,
                      prefixIcon: Icon(Icons.person_outline, color: context.colors.textHint, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Last Name',
                      hint: 'Last name',
                      controller: _lastNameController,
                      enabled: _isEditing,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(Icons.email_outlined, color: context.colors.textHint, size: 20),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: 'Phone',
                hint: 'Enter your phone number',
                controller: _phoneController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                prefixIcon: Icon(Icons.phone_outlined, color: context.colors.textHint, size: 20),
              ),
              const SizedBox(height: 32),

              // Change Password
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.lock_outline, color: context.colors.warning, size: 22),
                ),
                title: Text('Change Password', style: AppTypography.labelLarge.copyWith(color: context.colors.textPrimary)),
                subtitle: Text('Update your password', style: AppTypography.bodySmall.copyWith(color: context.colors.textSecondary)),
                trailing: Icon(Icons.chevron_right, color: context.colors.textHint),
                onTap: () => context.go('/change-password'),
              ),
              const SizedBox(height: 16),

              // Member Since
              if (profile.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Member since ${DateFormatter.formatDate(profile.createdAt!)}',
                    style: AppTypography.bodySmall.copyWith(color: context.colors.textHint),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
