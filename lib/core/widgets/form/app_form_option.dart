import 'package:flutter/material.dart';

/// A single selectable option shared by `AppRadioGroup`, `AppCheckboxGroup`
/// and `AppDropdown`. Using one option type lets a field switch between
/// radio/dropdown/checkbox presentation without rewriting its items.
class AppFormOption<T> {
  const AppFormOption({
    required this.value,
    required this.label,
    this.enabled = true,
    this.icon,
  });

  final T value;
  final String label;
  final bool enabled;
  final Widget? icon;
}
