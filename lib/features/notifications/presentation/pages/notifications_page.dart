import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as err;
import '../../domain/entities/notification_item.dart';
import '../providers/notification_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationListProvider.notifier).loadMore();
    }
  }

  Future<void> _markAllAsRead() async {
    final success =
        await ref.read(notificationListProvider.notifier).markAllAsRead();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'All notifications marked as read'
              : 'Failed to mark notifications as read',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.colors.background,
        title: Text(
          'Notifications',
          style: AppTypography.headlineSmall
              .copyWith(color: context.colors.textPrimary),
        ),
        actions: [
          if (state.isMarkingAllRead)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed:
                  state.unread > 0 && state.items.isNotEmpty ? _markAllAsRead : null,
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingWidget(message: 'Loading notifications...');
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return err.AppErrorWidget(
        message: state.errorMessage,
        onRetry: () =>
            ref.read(notificationListProvider.notifier).loadInitial(),
      );
    }

    if (state.items.isEmpty) {
      return _EmptyNotifications(
        onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
      );
    }

    return RefreshIndicator(
      color: context.colors.primary,
      backgroundColor: context.colors.surface,
      onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 72,
          color: context.colors.divider,
        ),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _NotificationTile(item: state.items[index]);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: item.isRead
            ? colors.divider.withValues(alpha: 0.4)
            : colors.primary.withValues(alpha: 0.12),
        child: Icon(
          item.isRead
              ? Icons.notifications_none_rounded
              : Icons.notifications_active_rounded,
          color: item.isRead ? colors.textHint : colors.primary,
          size: 22,
        ),
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyMedium.copyWith(
          color: colors.textPrimary,
          fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.message.isNotEmpty)
            Text(
              item.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall
                  .copyWith(color: colors.textSecondary),
            ),
          if (item.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormatter.formatRelative(item.createdAt!.toLocal()),
              style: AppTypography.labelSmall.copyWith(color: colors.textHint),
            ),
          ],
        ],
      ),
      trailing: item.isRead
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: context.colors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: AppTypography.bodyLarge
                        .copyWith(color: context.colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: AppTypography.bodySmall
                        .copyWith(color: context.colors.textHint),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
