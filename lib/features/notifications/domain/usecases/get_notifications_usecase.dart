import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_item.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Either<Failure, NotificationPage>> call({
    int page = 1,
    int perPage = 20,
  }) {
    return _repository.getNotifications(page: page, perPage: perPage);
  }
}
