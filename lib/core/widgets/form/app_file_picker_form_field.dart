import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../universal_file_picker_widget.dart';
import 'app_form_field_scaffold.dart';

/// Controlled [FormField] wrapper around [UniversalFilePickerWidget], so a
/// picked file participates in Form validation. Single file only, matching
/// the existing picker widgets.
class AppFilePickerFormField extends StatelessWidget {
  const AppFilePickerFormField({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    this.onChanged,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.errorText,
    this.pickerType = FilePickerType.mixed,
    this.maxFileSizeMB = 100,
    this.isLoading = false,
    this.customAllowedExtensions,
  });

  final String label;
  final String? hint;
  final XFile? value;
  final ValueChanged<XFile?>? onChanged;
  final FormFieldValidator<XFile>? validator;
  final AutovalidateMode autovalidateMode;
  final String? errorText;
  final FilePickerType pickerType;
  final double maxFileSizeMB;
  final bool isLoading;
  final List<String>? customAllowedExtensions;

  @override
  Widget build(BuildContext context) {
    return AppControlledFormField<XFile>(
      value: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (context, field) {
        return UniversalFilePickerWidget(
          label: label,
          hint: hint,
          pickerType: pickerType,
          maxFileSizeMB: maxFileSizeMB,
          isLoading: isLoading,
          customAllowedExtensions: customAllowedExtensions,
          selectedFileName: value?.name,
          errorMessage: errorText ?? field.errorText,
          onFilePicked: (file) {
            field.didChange(file);
            onChanged?.call(file);
          },
          onFileRemoved: () {
            field.didChange(null);
            onChanged?.call(null);
          },
        );
      },
    );
  }
}
