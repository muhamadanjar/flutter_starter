import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_form_field_scaffold.dart';
import 'app_form_option.dart';

/// Controlled radio group: parent owns [value], receives changes via
/// [onChanged]. Supports Form validation via [validator] and external
/// (e.g. server-side) errors via [errorText].
class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({
    super.key,
    this.label,
    required this.value,
    required this.options,
    this.onChanged,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.errorText,
    this.enabled = true,
    this.direction = Axis.vertical,
  });

  final String? label;
  final T? value;
  final List<AppFormOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final AutovalidateMode autovalidateMode;
  final String? errorText;
  final bool enabled;
  final Axis direction;

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
        final tiles = options
            .map((option) => _RadioTile<T>(
                  option: option,
                  enabled: enabled && option.enabled,
                ))
            .toList();

        return RadioGroup<T>(
          groupValue: value,
          onChanged: enabled
              ? (newValue) {
                  field.didChange(newValue);
                  onChanged?.call(newValue);
                }
              : (_) {},
          child: direction == Axis.vertical
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: tiles,
                )
              : Wrap(spacing: 16, children: tiles),
        );
      },
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({required this.option, required this.enabled});

  final AppFormOption<T> option;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<T>(
          value: option.value,
          enabled: enabled,
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
              color: enabled
                  ? context.colors.textPrimary
                  : context.colors.textDisabled,
            ),
          ),
        ),
      ],
    );
  }
}
