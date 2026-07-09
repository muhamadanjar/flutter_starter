import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/session_events.dart';
import '../../../../core/providers/fcm_sync_provider.dart';
import '../../../../core/services/fcm_sync_service.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

// Data Sources
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(
    authBox: Hive.box(AppConstants.authBox),
    userBox: Hive.box(AppConstants.userBox),
  );
});

// Repository
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// Use Cases
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

// Auth State
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthRepositoryImpl _repository;
  final FcmSyncService _fcmSync;
  late final StreamSubscription<void> _sessionExpiredSub;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthRepositoryImpl repository,
    required FcmSyncService fcmSync,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _repository = repository,
        _fcmSync = fcmSync,
        super(const AuthState()) {
    _sessionExpiredSub =
        SessionEvents.onSessionExpired.listen((_) => _handleSessionExpired());
  }

  Future<void> _handleSessionExpired() async {
    await _repository.clearLocalSession();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Session expired. Please login again.',
    );
  }

  void _onAuthenticated() {
    unawaited(_fcmSync.sync());
    _fcmSync.startTokenRefreshListener();
  }

  @override
  void dispose() {
    _sessionExpiredSub.cancel();
    super.dispose();
  }

  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _repository.isLoggedIn();
    if (isLoggedIn) {
      final result = await _repository.getProfile();
      result.fold(
        (failure) => state = const AuthState(status: AuthStatus.unauthenticated),
        (user) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
          _onAuthenticated();
        },
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String username, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _loginUseCase(username: username, password: password);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        status: AuthStatus.unauthenticated,
      ),
      (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: false,
        );
        _onAuthenticated();
      },
    );
  }

  Future<void> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _registerUseCase(
      username: username,
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
        status: AuthStatus.unauthenticated,
      ),
      (user) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: false,
        );
        _onAuthenticated();
      },
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    // Detach device pushes while the session is still valid
    await _fcmSync.detach();
    await _logoutUseCase();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    repository: ref.watch(authRepositoryProvider),
    fcmSync: ref.watch(fcmSyncServiceProvider),
  );
});
