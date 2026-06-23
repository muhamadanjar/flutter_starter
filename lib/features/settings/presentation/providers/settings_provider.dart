import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/update_settings_usecase.dart';

// Data Sources
final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  return SettingsLocalDataSourceImpl(settingsBox: Hive.box(AppConstants.settingsBox));
});

// Repository
final settingsRepositoryProvider = Provider<SettingsRepositoryImpl>((ref) {
  return SettingsRepositoryImpl(localDataSource: ref.watch(settingsLocalDataSourceProvider));
});

// Use Cases
final getSettingsUseCaseProvider = Provider<GetSettingsUseCase>((ref) {
  return GetSettingsUseCase(ref.watch(settingsRepositoryProvider));
});

final updateSettingsUseCaseProvider = Provider<UpdateSettingsUseCase>((ref) {
  return UpdateSettingsUseCase(ref.watch(settingsRepositoryProvider));
});

// Settings State
class SettingsState {
  final AppSettings? settings;
  final bool isLoading;
  final String? errorMessage;

  const SettingsState({
    this.settings,
    this.isLoading = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Settings Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final GetSettingsUseCase _getSettingsUseCase;
  final UpdateSettingsUseCase _updateSettingsUseCase;

  SettingsNotifier({
    required GetSettingsUseCase getSettingsUseCase,
    required UpdateSettingsUseCase updateSettingsUseCase,
  })  : _getSettingsUseCase = getSettingsUseCase,
        _updateSettingsUseCase = updateSettingsUseCase,
        super(const SettingsState());

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getSettingsUseCase();

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (settings) => state = state.copyWith(isLoading: false, settings: settings),
    );
  }

  Future<void> updateSetting({
    bool? darkMode,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    String? language,
    String? theme,
    bool? autoSync,
    bool? analyticsEnabled,
    String? fontSize,
  }) async {
    final current = state.settings ?? const AppSettings();
    final updated = AppSettings(
      darkMode: darkMode ?? current.darkMode,
      notificationsEnabled: notificationsEnabled ?? current.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? current.biometricEnabled,
      language: language ?? current.language,
      theme: theme ?? current.theme,
      autoSync: autoSync ?? current.autoSync,
      analyticsEnabled: analyticsEnabled ?? current.analyticsEnabled,
      fontSize: fontSize ?? current.fontSize,
    );

    final result = await _updateSettingsUseCase(updated);

    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (settings) => state = state.copyWith(settings: settings),
    );
  }
}

// Settings Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(
    getSettingsUseCase: ref.watch(getSettingsUseCaseProvider),
    updateSettingsUseCase: ref.watch(updateSettingsUseCaseProvider),
  );
});
