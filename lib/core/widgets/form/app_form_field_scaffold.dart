import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Shared chrome for the form field family: label above, error text below,
/// matching the visual language of `CustomTextField`.
class AppFormFieldScaffold extends StatelessWidget {
  const AppFormFieldScaffold({
    super.key,
    this.label,
    this.errorText,
    required this.child,
  });

  final String? label;
  final String? errorText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        child,
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              errorText!,
              style: AppTypography.bodySmall.copyWith(
                color: context.colors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Controlled [FormField] bridge: the parent owns `value`; this keeps the
/// internal [FormFieldState] in sync so `validator` and `Form.validate()`
/// see the current value.
class AppControlledFormField<T> extends StatelessWidget {
  const AppControlledFormField({
    super.key,
    required this.value,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.label,
    this.errorText,
    this.enabled = true,
    required this.builder,
  });

  final T? value;
  final FormFieldValidator<T>? validator;
  final AutovalidateMode autovalidateMode;
  final String? label;
  final String? errorText;
  final bool enabled;
  final Widget Function(BuildContext context, FormFieldState<T> field) builder;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      enabled: enabled,
      builder: (field) {
        if (field.value != value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (field.mounted) field.didChange(value);
          });
        }
        return AppFormFieldScaffold(
          label: label,
          errorText: errorText ?? field.errorText,
          child: builder(context, field),
        );
      },
    );
  }
}

/// Filled container matching `CustomTextField`'s field box: surfaceVariant
/// fill, radius 12, error border when [hasError].
class AppFieldBox extends StatelessWidget {
  const AppFieldBox({
    super.key,
    required this.child,
    this.hasError = false,
    this.enabled = true,
    this.onTap,
  });

  final Widget child;
  final bool hasError;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: hasError
            ? Border.all(color: context.colors.error, width: 1.5)
            : null,
      ),
      child: child,
    );

    if (onTap == null) return box;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: box,
    );
  }
}
