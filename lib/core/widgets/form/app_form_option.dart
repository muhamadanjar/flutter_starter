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

  // Value-based equality so controlled fields recognize a re-created option
  // (e.g. rebuilt from server results) as the same selection.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFormOption<T> &&
          other.value == value &&
          other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}
