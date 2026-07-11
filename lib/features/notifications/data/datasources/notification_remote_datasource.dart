import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationPageModel> getNotifications({
    int page = 1,
    int perPage = 20,
  });

  Future<int> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  NotificationRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<NotificationPageModel> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.notifications,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return NotificationPageModel.fromResponse(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await _dioClient.post(ApiConstants.notificationsReadAll);
    final data = response.data['data'];
    return data is Map<String, dynamic> ? data['updated'] as int? ?? 0 : 0;
  }
}
