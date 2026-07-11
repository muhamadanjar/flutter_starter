import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_item.dart';

abstract class NotificationRepository {
  Future<Either<Failure, NotificationPage>> getNotifications({
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, int>> markAllAsRead();
}
