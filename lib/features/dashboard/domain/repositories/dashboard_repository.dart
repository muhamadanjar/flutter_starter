import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardData>> getDashboardData({bool forceRefresh = false});
}
