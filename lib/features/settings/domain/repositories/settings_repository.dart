import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, AppSettings>> getSettings();
  Future<Either<Failure, AppSettings>> updateSettings(AppSettings settings);
}
