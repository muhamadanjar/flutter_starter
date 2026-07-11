import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {

  const AppSettings({
    this.darkMode = true,
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    this.language = 'en',
    this.theme = 'dark',
    this.autoSync = true,
    this.analyticsEnabled = true,
    this.fontSize = 'medium',
  });
  final bool darkMode;
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final String language;
  final String theme;
  final bool autoSync;
  final bool analyticsEnabled;
  final String fontSize;

  @override
  List<Object?> get props => [darkMode, notificationsEnabled, biometricEnabled, language, theme, autoSync, analyticsEnabled, fontSize];
}
