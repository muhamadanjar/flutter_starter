import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Name _name = const Name.pure();
  Email _email = const Email.pure();
  Password _password = const Password.pure();
  ConfirmedPassword _confirmedPassword = const ConfirmedPassword.pure();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 32),

                      // Name
                      CustomTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icon(Icons.person_outline, color: context.colors.textHint, size: 20),
                        onChanged: (v) => setState(() => _name = Name.dirty(v)),
                        errorText: _name.invalid ? ValidatorMessages.nameError(_name.error) : null,
                      ),
                      const SizedBox(height: 20),

                      // Email
                      CustomTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icon(Icons.email_outlined, color: context.colors.textHint, size: 20),
                        onChanged: (v) => setState(() => _email = Email.dirty(v)),
                        errorText: _email.invalid ? ValidatorMessages.emailError(_email.error) : null,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icon(Icons.lock_outline, color: context.colors.textHint, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: context.colors.textHint,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _password = Password.dirty(v);
                            _confirmedPassword = ConfirmedPassword.dirty(
                              password: _passwordController.text,
                              value: _confirmPasswordController.text,
                            );
                          });
                        },
                        errorText: _password.invalid ? ValidatorMessages.passwordError(_password.error) : null,
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password
                      CustomTextField(
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
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
                            password: _passwordController.text,
                            value: v,
                          );
                        }),
                        errorText: _confirmedPassword.invalid ? ValidatorMessages.confirmedPasswordError(_confirmedPassword.error) : null,
                      ),
                      const SizedBox(height: 8),

                      // Terms
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: RichText(
                          text: TextSpan(
                            style: AppTypography.bodySmall.copyWith(color: context.colors.textHint),
                            children: [
                              const TextSpan(text: 'By signing up, you agree to our '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: AppTypography.bodySmall.copyWith(color: context.colors.primary),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: AppTypography.bodySmall.copyWith(color: context.colors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register Button
                      CustomButton(
                        label: 'Create Account',
                        onPressed: _onRegister,
                        isLoading: authState.isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Social
                      CustomButton(
                        label: 'Continue with Google',
                        onPressed: () {/* TODO: Google Sign In */},
                        variant: ButtonVariant.outline,
                        icon: Icons.g_mobiledata,
                      ),
                      const SizedBox(height: 32),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTypography.bodyMedium.copyWith(color: context.colors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              'Sign In',
                              style: AppTypography.labelLarge.copyWith(color: context.colors.primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: context.colors.accent.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 24),
        Text(
          'Create Account',
          style: AppTypography.headlineMedium.copyWith(color: context.colors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Fill in the details to get started',
          style: AppTypography.bodyMedium.copyWith(color: context.colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
