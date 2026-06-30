import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/dashboard_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DashboardData>> getDashboardData({bool forceRefresh = false}) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteData = await remoteDataSource.getDashboardData();
        await localDataSource.cacheDashboardData(remoteData);
        await localDataSource.setLastSyncTime(DateTime.now());
        return right(remoteData);
      } on ServerException catch (e) {
        return left(ServerFailure(message: e.message ?? 'Server error'));
      } on NetworkException catch (e) {
        return _getCachedDashboard();
      } catch (e) {
        return _getCachedDashboard();
      }
    } else {
      return _getCachedDashboard();
    }
  }

  Future<Either<Failure, DashboardData>> _getCachedDashboard() async {
    try {
      final cachedData = await localDataSource.getCachedDashboardData();
      if (cachedData != null) {
        return right(cachedData);
      }
      return left(CacheFailure(message: 'No cached data available. Please connect to the internet.'));
    } on CacheException catch (e) {
      return left(CacheFailure(message: e.message ?? 'Cache error'));
    }
  }
}
