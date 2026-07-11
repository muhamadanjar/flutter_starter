import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

class MarkAllReadUseCase {
  MarkAllReadUseCase(this._repository);

  final NotificationRepository _repository;

  Future<Either<Failure, int>> call() {
    return _repository.markAllAsRead();
  }
}
