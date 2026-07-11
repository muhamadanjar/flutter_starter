import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_form_field_scaffold.dart';
import 'app_form_option.dart';

/// Controlled multi-select checkbox list: parent owns [values], receives the
/// updated selection via [onChanged].
class AppCheckboxGroup<T> extends StatelessWidget {
  const AppCheckboxGroup({
    super.key,
    this.label,
    required this.values,
    required this.options,
    this.onChanged,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.errorText,
    this.enabled = true,
    this.direction = Axis.vertical,
  });

  final String? label;
  final List<T> values;
  final List<AppFormOption<T>> options;
  final ValueChanged<List<T>>? onChanged;
  final FormFieldValidator<List<T>>? validator;
  final AutovalidateMode autovalidateMode;
  final String? errorText;
  final bool enabled;
  final Axis direction;

  void _toggle(FormFieldState<List<T>> field, T optionValue) {
    final newValues = List<T>.from(values);
    if (newValues.contains(optionValue)) {
      newValues.remove(optionValue);
    } else {
      newValues.add(optionValue);
    }
    field.didChange(newValues);
    onChanged?.call(newValues);
  }

  @override
  Widget build(BuildContext context) {
    return AppControlledFormField<List<T>>(
      value: values,
      validator: validator,
      autovalidateMode: autovalidateMode,
      label: label,
      errorText: errorText,
      enabled: enabled,
      builder: (context, field) {
        final tiles = options.map((option) {
          final tileEnabled = enabled && option.enabled;
          return InkWell(
            onTap: tileEnabled ? () => _toggle(field, option.value) : null,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: values.contains(option.value),
                  onChanged: tileEnabled
                      ? (_) => _toggle(field, option.value)
                      : null,
                  activeColor: context.colors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (option.icon != null) ...[
                  option.icon!,
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    option.label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: tileEnabled
                          ? context.colors.textPrimary
                          : context.colors.textDisabled,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList();

        return direction == Axis.vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: tiles,
              )
            : Wrap(spacing: 16, children: tiles);
      },
    );
  }
}
