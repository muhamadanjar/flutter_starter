import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/dashboard_model.dart';

abstract class DashboardLocalDataSource {
  Future<void> cacheDashboardData(DashboardDataModel data);
  Future<DashboardDataModel?> getCachedDashboardData();
  Future<DateTime?> getLastSyncTime();
  Future<void> setLastSyncTime(DateTime time);
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  final Box<dynamic> _cacheBox;

  DashboardLocalDataSourceImpl({required Box<dynamic> cacheBox}) : _cacheBox = cacheBox;

  @override
  Future<void> cacheDashboardData(DashboardDataModel data) async {
    await _cacheBox.put(AppConstants.dashboardCacheKey, data.toLocalJson());
  }

  @override
  Future<DashboardDataModel?> getCachedDashboardData() async {
    try {
      final json = _cacheBox.get(AppConstants.dashboardCacheKey) as Map?;
      if (json == null) return null;
      return DashboardDataModel.fromLocalJson(Map<String, dynamic>.from(json));
    } catch (_) {
      throw const CacheException(message: 'Failed to read dashboard from cache');
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final timeStr = _cacheBox.get(AppConstants.lastSyncKey) as String?;
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    await _cacheBox.put(AppConstants.lastSyncKey, time.toIso8601String());
  }
}
