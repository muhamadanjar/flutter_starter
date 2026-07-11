import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/form/form_fields.dart';
import '../../../../core/widgets/universal_file_picker_widget.dart';

/// Dev-only gallery for the form field family. Not linked from navigation;
/// reachable at /dev/form-gallery. Serves as living usage documentation.
class FormGalleryPage extends StatefulWidget {
  const FormGalleryPage({super.key});

  @override
  State<FormGalleryPage> createState() => _FormGalleryPageState();
}

class _FormGalleryPageState extends State<FormGalleryPage> {
  final _formKey = GlobalKey<FormState>();

  String? _plan;
  bool _agreed = false;
  List<String> _channels = [];
  String? _country;
  DateTime? _birthDate;
  DateTime? _appointment;
  XFile? _attachment;

  static const _planOptions = [
    AppFormOption(value: 'free', label: 'Free'),
    AppFormOption(value: 'pro', label: 'Pro'),
    AppFormOption(value: 'enterprise', label: 'Enterprise', enabled: false),
  ];

  static const _channelOptions = [
    AppFormOption(value: 'email', label: 'Email'),
    AppFormOption(value: 'push', label: 'Push notification'),
    AppFormOption(value: 'sms', label: 'SMS'),
  ];

  static const _countryOptions = [
    AppFormOption(value: 'id', label: 'Indonesia'),
    AppFormOption(value: 'sg', label: 'Singapore'),
    AppFormOption(value: 'my', label: 'Malaysia'),
  ];

  void _submit() {
    final valid = _formKey.currentState!.validate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(valid ? 'Form valid' : 'Form has errors')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Gallery (dev)')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const CustomTextField(
              label: 'Text field (existing)',
              hint: 'Type something',
            ),
            const SizedBox(height: 24),
            AppRadioGroup<String>(
              label: 'Plan',
              value: _plan,
              options: _planOptions,
              onChanged: (v) => setState(() => _plan = v),
              validator: (v) => v == null ? 'Select a plan' : null,
            ),
            const SizedBox(height: 24),
            AppCheckboxGroup<String>(
              label: 'Notification channels',
              values: _channels,
              options: _channelOptions,
              onChanged: (v) => setState(() => _channels = v),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Pick at least one channel' : null,
            ),
            const SizedBox(height: 24),
            AppDropdown<String>(
              label: 'Country',
              hint: 'Select country',
              value: _country,
              options: _countryOptions,
              onChanged: (v) => setState(() => _country = v),
              validator: (v) => v == null ? 'Country is required' : null,
            ),
            const SizedBox(height: 24),
            AppDatePicker(
              label: 'Birth date',
              hint: 'Select date',
              value: _birthDate,
              lastDate: DateTime.now(),
              onChanged: (v) => setState(() => _birthDate = v),
              validator: (v) => v == null ? 'Birth date is required' : null,
            ),
            const SizedBox(height: 24),
            AppDateTimePicker(
              label: 'Appointment',
              hint: 'Select date & time',
              value: _appointment,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onChanged: (v) => setState(() => _appointment = v),
            ),
            const SizedBox(height: 24),
            AppFilePickerFormField(
              label: 'Attachment',
              hint: 'Image or document, max 10 MB',
              value: _attachment,
              pickerType: FilePickerType.mixed,
              maxFileSizeMB: 10,
              onChanged: (v) => setState(() => _attachment = v),
            ),
            const SizedBox(height: 24),
            AppCheckbox(
              title: 'I agree to the terms and conditions',
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v),
              validator: (v) => v != true ? 'You must agree to continue' : null,
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: 'Validate',
              onPressed: _submit,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
