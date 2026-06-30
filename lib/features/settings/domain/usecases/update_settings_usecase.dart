import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class UpdateSettingsUseCase {
  final SettingsRepository _repository;
  UpdateSettingsUseCase(this._repository);

  Future<Either<Failure, AppSettings>> call(AppSettings settings) => _repository.updateSettings(settings);
}
