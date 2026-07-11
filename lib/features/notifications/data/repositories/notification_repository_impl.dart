import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required this.remoteDataSource});

  final NotificationRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, NotificationPage>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final result = await remoteDataSource.getNotifications(
        page: page,
        perPage: perPage,
      );
      return right(result);
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'No internet connection'));
    } on UnauthorizedException catch (e) {
      return left(UnauthorizedFailure(message: e.message ?? 'Unauthorized'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> markAllAsRead() async {
    try {
      final updated = await remoteDataSource.markAllAsRead();
      return right(updated);
    } on NetworkException catch (e) {
      return left(NetworkFailure(message: e.message ?? 'No internet connection'));
    } on UnauthorizedException catch (e) {
      return left(UnauthorizedFailure(message: e.message ?? 'Unauthorized'));
    } on ServerException catch (e) {
      return left(ServerFailure(message: e.message ?? 'Server error'));
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}
