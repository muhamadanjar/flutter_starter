import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/profile_provider.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  Password _newPassword = const Password.pure();
  ConfirmedPassword _confirmedPassword = const ConfirmedPassword.pure();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(profileProvider.notifier).changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    final state = ref.read(profileProvider);
    if (state.successMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go('/profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

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
        title: const Text('Change Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Icon
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.colors.warning.withOpacity(0.2), context.colors.warning.withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.lock_reset_rounded, color: context.colors.warning, size: 36),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Change Password',
                    style: AppTypography.headlineSmall.copyWith(color: context.colors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your current password and choose a new one',
                    style: AppTypography.bodyMedium.copyWith(color: context.colors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Current Password
                  CustomTextField(
                    label: 'Current Password',
                    hint: 'Enter current password',
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    prefixIcon: Icon(Icons.lock_outline, color: context.colors.textHint, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: context.colors.textHint,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // New Password
                  CustomTextField(
                    label: 'New Password',
                    hint: 'Enter new password',
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    prefixIcon: Icon(Icons.lock_outline, color: context.colors.textHint, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: context.colors.textHint,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _newPassword = Password.dirty(v);
                        _confirmedPassword = ConfirmedPassword.dirty(
                          password: _newPasswordController.text,
                          value: _confirmPasswordController.text,
                        );
                      });
                    },
                    errorText: _newPassword.invalid ? ValidatorMessages.passwordError(_newPassword.error) : null,
                  ),
                  const SizedBox(height: 20),

                  // Password Strength Indicator
                  if (_newPasswordController.text.isNotEmpty) ...[
                    _PasswordStrengthIndicator(password: _newPasswordController.text),
                    const SizedBox(height: 20),
                  ],

                  // Confirm New Password
                  CustomTextField(
                    label: 'Confirm New Password',
                    hint: 'Re-enter new password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icon(Icons.lock_outline, color: context.colors.textHint, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: context.colors.textHint,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    onChanged: (v) => setState(() {
                      _confirmedPassword = ConfirmedPassword.dirty(
                        password: _newPasswordController.text,
                        value: v,
                      );
                    }),
                    errorText: _confirmedPassword.invalid ? ValidatorMessages.confirmedPasswordError(_confirmedPassword.error) : null,
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  CustomButton(
                    label: 'Update Password',
                    onPressed: _onChangePassword,
                    isLoading: state.isLoading,
                    variant: ButtonVariant.primary,
                  ),
                  const SizedBox(height: 16),

                  // Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.info.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: context.colors.info, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'After changing your password, you will need to sign in again with the new password.',
                            style: AppTypography.bodySmall.copyWith(color: context.colors.info),
                          ),
                        ),
                      ],
                    ),
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

class _PasswordStrengthIndicator extends StatelessWidget {

  const _PasswordStrengthIndicator({required this.password});
  final String password;

  int get _strength {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  Color _getColor(BuildContext context) {
    switch (_strength) {
      case 0:
      case 1:
        return context.colors.error;
      case 2:
      case 3:
        return context.colors.warning;
      case 4:
        return context.colors.secondary;
      case 5:
        return context.colors.success;
      default:
        return context.colors.textHint;
    }
  }

  String get _label {
    switch (_strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            5,
            (index) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: index < _strength ? _getColor(context) : context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Password Strength: $_label',
          style: AppTypography.bodySmall.copyWith(color: _getColor(context)),
        ),
      ],
    );
  }
}
