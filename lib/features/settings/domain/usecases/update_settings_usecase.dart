import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class UpdateSettingsUseCase {
  UpdateSettingsUseCase(this._repository);
  final SettingsRepository _repository;

  Future<Either<Failure, AppSettings>> call(AppSettings settings) => _repository.updateSettings(settings);
}
