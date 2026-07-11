import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_read_usecase.dart';

// Data Source
final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

// Repository
final notificationRepositoryProvider =
    Provider<NotificationRepositoryImpl>((ref) {
  return NotificationRepositoryImpl(
    remoteDataSource: ref.watch(notificationRemoteDataSourceProvider),
  );
});

// Use Cases
final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>((ref) {
  return GetNotificationsUseCase(ref.watch(notificationRepositoryProvider));
});

final markAllReadUseCaseProvider = Provider<MarkAllReadUseCase>((ref) {
  return MarkAllReadUseCase(ref.watch(notificationRepositoryProvider));
});

// State
class NotificationListState {
  const NotificationListState({
    this.items = const [],
    this.page = 0,
    this.total = 0,
    this.unread = 0,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isMarkingAllRead = false,
    this.errorMessage,
  });

  final List<NotificationItem> items;
  final int page;
  final int total;
  final int unread;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isMarkingAllRead;
  final String? errorMessage;

  NotificationListState copyWith({
    List<NotificationItem>? items,
    int? page,
    int? total,
    int? unread,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isMarkingAllRead,
    String? errorMessage,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      unread: unread ?? this.unread,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMarkingAllRead: isMarkingAllRead ?? this.isMarkingAllRead,
      errorMessage: errorMessage,
    );
  }
}

// Notifier
class NotificationListNotifier extends StateNotifier<NotificationListState> {
  NotificationListNotifier(
    this._getNotifications,
    this._markAllRead,
  ) : super(const NotificationListState());

  final GetNotificationsUseCase _getNotifications;
  final MarkAllReadUseCase _markAllRead;

  static const _perPage = 20;

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _getNotifications(page: 1, perPage: _perPage);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (data) => state = state.copyWith(
        isLoading: false,
        items: data.items,
        page: data.page,
        total: data.total,
        unread: data.unread,
        hasMore: data.hasMore,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    final result = await _getNotifications(
      page: state.page + 1,
      perPage: _perPage,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      ),
      (data) => state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...data.items],
        page: data.page,
        total: data.total,
        unread: data.unread,
        hasMore: data.hasMore,
      ),
    );
  }

  Future<void> refresh() async {
    state = const NotificationListState();
    await loadInitial();
  }

  Future<bool> markAllAsRead() async {
    if (state.isMarkingAllRead) return false;
    state = state.copyWith(isMarkingAllRead: true, errorMessage: null);

    final result = await _markAllRead();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isMarkingAllRead: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        final now = DateTime.now();
        state = state.copyWith(
          isMarkingAllRead: false,
          unread: 0,
          items: state.items
              .map((n) => n.isRead ? n : n.copyWith(isRead: true, readAt: now))
              .toList(),
        );
        return true;
      },
    );
  }
}

// Provider
final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>(
        (ref) {
  return NotificationListNotifier(
    ref.watch(getNotificationsUseCaseProvider),
    ref.watch(markAllReadUseCaseProvider),
  );
});
