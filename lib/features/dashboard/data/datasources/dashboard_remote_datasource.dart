import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardDataModel> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient _dioClient;

  DashboardRemoteDataSourceImpl(this._dioClient);

  @override
  Future<DashboardDataModel> getDashboardData() async {
    final response = await _dioClient.get(ApiConstants.dashboard);
    final data = response.data['data'] as Map<String, dynamic>;
    return DashboardDataModel.fromJson(data);
  }
}
