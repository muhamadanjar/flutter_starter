import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {

  SettingsRepositoryImpl({required this.localDataSource});
  final SettingsLocalDataSource localDataSource;

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      final data = await localDataSource.getSettings();
      return right(AppSettings(
        darkMode: data['darkMode'] as bool? ?? true,
        notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
        biometricEnabled: data['biometricEnabled'] as bool? ?? false,
        language: data['language'] as String? ?? 'en',
        theme: data['theme'] as String? ?? 'dark',
        autoSync: data['autoSync'] as bool? ?? true,
        analyticsEnabled: data['analyticsEnabled'] as bool? ?? true,
        fontSize: data['fontSize'] as String? ?? 'medium',
      ));
    } on CacheException catch (e) {
      return left(CacheFailure(message: e.message ?? 'Failed to load settings'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppSettings>> updateSettings(AppSettings settings) async {
    try {
      final data = {
        'darkMode': settings.darkMode,
        'notificationsEnabled': settings.notificationsEnabled,
        'biometricEnabled': settings.biometricEnabled,
        'language': settings.language,
        'theme': settings.theme,
        'autoSync': settings.autoSync,
        'analyticsEnabled': settings.analyticsEnabled,
        'fontSize': settings.fontSize,
      };
      await localDataSource.saveSettings(data);
      return right(settings);
    } on CacheException catch (e) {
      return left(CacheFailure(message: e.message ?? 'Failed to save settings'));
    } catch (e) {
      return left(UnknownFailure(message: e.toString()));
    }
  }
}
