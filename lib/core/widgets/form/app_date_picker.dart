import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_form_field_scaffold.dart';

/// Controlled date field: tappable field box that opens the Material date
/// dialog. Displays the value with [AppConstants.dateFormat] unless
/// [dateFormat] overrides it.
class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    this.label,
    this.hint,
    required this.value,
    this.onChanged,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.errorText,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.dateFormat,
  });

  final String? label;
  final String? hint;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final FormFieldValidator<DateTime>? validator;
  final AutovalidateMode autovalidateMode;
  final String? errorText;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? dateFormat;

  Future<void> _pick(BuildContext context, FormFieldState<DateTime> field) async {
    final first = firstDate ?? DateTime(1900);
    final last = lastDate ?? DateTime(2100);
    final now = DateTime.now();
    final initial = value ??
        (now.isBefore(first) ? first : (now.isAfter(last) ? last : now));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;

    field.didChange(picked);
    onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AppControlledFormField<DateTime>(
      value: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      label: label,
      errorText: errorText,
      enabled: enabled,
      builder: (context, field) {
        final hasError = (errorText ?? field.errorText) != null;
        final text = value != null
            ? DateFormat(dateFormat ?? AppConstants.dateFormat).format(value!)
            : null;

        return AppFieldBox(
          hasError: hasError,
          enabled: enabled,
          onTap: () => _pick(context, field),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text ?? hint ?? '',
                  style: text != null
                      ? AppTypography.bodyLarge.copyWith(
                          color: enabled
                              ? context.colors.textPrimary
                              : context.colors.textDisabled,
                        )
                      : AppTypography.bodyMedium.copyWith(
                          color: context.colors.textHint,
                        ),
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: context.colors.textSecondary,
              ),
            ],
          ),
        );
      },
    );
  }
}
