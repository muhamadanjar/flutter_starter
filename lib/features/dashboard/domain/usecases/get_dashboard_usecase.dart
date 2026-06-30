import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardUseCase {
  final DashboardRepository _repository;

  GetDashboardUseCase(this._repository);

  Future<Either<Failure, DashboardData>> call({bool forceRefresh = false}) {
    return _repository.getDashboardData(forceRefresh: forceRefresh);
  }
}
