import 'package:enterprise_flutter_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _populated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_populated) {
      _populateControllers();
      _populated = true;
    }
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
      _lastNameController.text =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
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

    if (mounted) context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final t = AppLocalizations.of(context);

    ref.listen<ProfileState>(profileProvider, (prev, next) {
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
        title: Text(t.profileEdit),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/profile'),
        ),
        actions: [
          TextButton.icon(
            onPressed: state.isLoading ? null : _onSave,
            icon: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'First Name',
                          hint: 'First name',
                          controller: _firstNameController,
                          prefixIcon: Icon(Icons.person_outline,
                              color: context.colors.textHint, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Last Name',
                          hint: 'Last name',
                          controller: _lastNameController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Email',
                    hint: 'Enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.email_outlined,
                        color: context.colors.textHint, size: 20),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Phone',
                    hint: 'Enter your phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icon(Icons.phone_outlined,
                        color: context.colors.textHint, size: 20),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Only basic information can be edited here. '
                    'Other details are managed by your administrator.',
                    style: AppTypography.bodySmall
                        .copyWith(color: context.colors.textHint),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
