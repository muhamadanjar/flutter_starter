import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../data/datasources/profile_local_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';

// Data Sources
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSourceImpl(userBox: Hive.box(AppConstants.userBox));
});

// Repository
final profileRepositoryProvider = Provider<ProfileRepositoryImpl>((ref) {
  return ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    localDataSource: ref.watch(profileLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// Use Cases
final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.watch(profileRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.watch(profileRepositoryProvider));
});

// Profile State
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool isOffline;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.isOffline = false,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? isOffline,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

// Profile Notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;

  ProfileNotifier({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
  })  : _getProfileUseCase = getProfileUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _changePasswordUseCase = changePasswordUseCase,
        super(const ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getProfileUseCase();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        isOffline: failure is CacheFailure || failure is NetworkFailure,
      ),
      (profile) => state = state.copyWith(
        isLoading: false,
        profile: profile,
        isOffline: false,
      ),
    );
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    final result = await _updateProfileUseCase(data);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (profile) => state = state.copyWith(
        isLoading: false,
        profile: profile,
        successMessage: 'Profile updated successfully',
      ),
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    final result = await _changePasswordUseCase(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        successMessage: 'Password changed successfully',
      ),
    );
  }
}

// Profile Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(
    getProfileUseCase: ref.watch(getProfileUseCaseProvider),
    updateProfileUseCase: ref.watch(updateProfileUseCaseProvider),
    changePasswordUseCase: ref.watch(changePasswordUseCaseProvider),
  );
});
