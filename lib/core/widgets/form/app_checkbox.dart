import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_form_field_scaffold.dart';

/// Controlled single checkbox with inline title. For agreement/consent
/// fields use a [validator] that rejects `false`.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    this.label,
    required this.title,
    required this.value,
    this.onChanged,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.errorText,
    this.enabled = true,
  });

  final String? label;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final FormFieldValidator<bool>? validator;
  final AutovalidateMode autovalidateMode;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppControlledFormField<bool>(
      value: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      label: label,
      errorText: errorText,
      enabled: enabled,
      builder: (context, field) {
        return InkWell(
          onTap: enabled
              ? () {
                  final newValue = !value;
                  field.didChange(newValue);
                  onChanged?.call(newValue);
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: value,
                onChanged: enabled
                    ? (newValue) {
                        field.didChange(newValue ?? false);
                        onChanged?.call(newValue ?? false);
                      }
                    : null,
                activeColor: context.colors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: enabled
                        ? context.colors.textPrimary
                        : context.colors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
