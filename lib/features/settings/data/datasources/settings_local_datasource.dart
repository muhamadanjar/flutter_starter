import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

abstract class SettingsLocalDataSource {
  Future<Map<String, dynamic>> getSettings();
  Future<void> saveSettings(Map<String, dynamic> settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {

  SettingsLocalDataSourceImpl({required Box<dynamic> settingsBox}) : _settingsBox = settingsBox;
  final Box<dynamic> _settingsBox;

  @override
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final settings = _settingsBox.get(AppConstants.appSettingsKey) as Map?;
      if (settings == null) {
        return _defaultSettings;
      }
      return Map<String, dynamic>.from(settings);
    } catch (_) {
      throw const CacheException(message: 'Failed to read settings');
    }
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _settingsBox.put(AppConstants.appSettingsKey, settings);
  }

  static const Map<String, dynamic> _defaultSettings = {
    'darkMode': true,
    'notificationsEnabled': true,
    'biometricEnabled': false,
    'language': 'en',
    'theme': 'dark',
    'autoSync': true,
    'analyticsEnabled': true,
    'fontSize': 'medium',
  };
}
