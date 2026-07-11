import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';
import 'package:hive/hive.dart';

// Data Sources
final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final dashboardLocalDataSourceProvider = Provider<DashboardLocalDataSource>((ref) {
  return DashboardLocalDataSourceImpl(cacheBox: Hive.box(AppConstants.cacheBox));
});

// Repository
final dashboardRepositoryProvider = Provider<DashboardRepositoryImpl>((ref) {
  return DashboardRepositoryImpl(
    remoteDataSource: ref.watch(dashboardRemoteDataSourceProvider),
    localDataSource: ref.watch(dashboardLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// Use Case
final getDashboardUseCaseProvider = Provider<GetDashboardUseCase>((ref) {
  return GetDashboardUseCase(ref.watch(dashboardRepositoryProvider));
});

// Dashboard State
class DashboardState {

  const DashboardState({
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.isOffline = false,
  });
  final DashboardData? data;
  final bool isLoading;
  final String? errorMessage;
  final bool isOffline;

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? errorMessage,
    bool? isOffline,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

// Dashboard Notifier
class DashboardNotifier extends StateNotifier<DashboardState> {

  DashboardNotifier(this._getDashboardUseCase) : super(const DashboardState());
  final GetDashboardUseCase _getDashboardUseCase;

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getDashboardUseCase(forceRefresh: forceRefresh);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        isOffline: failure is CacheFailure,
      ),
      (data) => state = state.copyWith(
        isLoading: false,
        data: data,
        isOffline: false,
      ),
    );
  }

  Future<void> refresh() async {
    await loadDashboard(forceRefresh: true);
  }
}

// Dashboard Provider
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.watch(getDashboardUseCaseProvider));
});
