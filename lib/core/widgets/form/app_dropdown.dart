import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_form_field_scaffold.dart';
import 'app_form_option.dart';

/// Controlled dropdown styled to match `CustomTextField`'s field box.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.options,
    this.onChanged,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.errorText,
    this.enabled = true,
  });

  final String? label;
  final String? hint;
  final T? value;
  final List<AppFormOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final AutovalidateMode autovalidateMode;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppControlledFormField<T>(
      value: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      label: label,
      errorText: errorText,
      enabled: enabled,
      builder: (context, field) {
        final hasError = (errorText ?? field.errorText) != null;

        return AppFieldBox(
          hasError: hasError,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: context.colors.surface,
              hint: hint != null
                  ? Text(
                      hint!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.colors.textHint,
                      ),
                    )
                  : null,
              style: AppTypography.bodyLarge.copyWith(
                color: enabled
                    ? context.colors.textPrimary
                    : context.colors.textDisabled,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: context.colors.textSecondary,
              ),
              items: options
                  .map((option) => DropdownMenuItem<T>(
                        value: option.value,
                        enabled: option.enabled,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (option.icon != null) ...[
                              option.icon!,
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                option.label,
                                overflow: TextOverflow.ellipsis,
                                style: option.enabled
                                    ? null
                                    : AppTypography.bodyLarge.copyWith(
                                        color: context.colors.textDisabled,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: enabled
                  ? (newValue) {
                      field.didChange(newValue);
                      onChanged?.call(newValue);
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }
}
