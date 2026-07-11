import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_form_field_scaffold.dart';

/// Controlled date+time field: two-step Material dialogs (date, then time).
/// Displays the value with [AppConstants.dateTimeFormat] unless
/// [dateTimeFormat] overrides it.
class AppDateTimePicker extends StatelessWidget {
  const AppDateTimePicker({
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
    this.dateTimeFormat,
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
  final String? dateTimeFormat;

  Future<void> _pick(BuildContext context, FormFieldState<DateTime> field) async {
    final first = firstDate ?? DateTime(1900);
    final last = lastDate ?? DateTime(2100);
    final now = DateTime.now();
    final initial = value ??
        (now.isBefore(first) ? first : (now.isAfter(last) ? last : now));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value ?? now),
    );
    if (pickedTime == null) return;

    final result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    field.didChange(result);
    onChanged?.call(result);
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
            ? DateFormat(dateTimeFormat ?? AppConstants.dateTimeFormat)
                .format(value!)
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
                Icons.event_outlined,
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
