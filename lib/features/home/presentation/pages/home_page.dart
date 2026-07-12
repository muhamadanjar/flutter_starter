import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_banner_carousel.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      body: RefreshIndicator(
        color: context.colors.primary,
        backgroundColor: context.colors.surface,
        onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: context.colors.background,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Home',
                  style: AppTypography.headlineSmall.copyWith(color: context.colors.textPrimary),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _GreetingHeader(user: user)),
            const SliverToBoxAdapter(child: _HomeBanner()),
            const SliverToBoxAdapter(child: _NotificationCard()),
            const SliverToBoxAdapter(child: _QuickActions()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? '';
    final avatarUrl = user?.avatarUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: context.colors.primary.withValues(alpha: 0.15),
            backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                ? NetworkImage(avatarUrl)
                : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Icon(Icons.person_rounded, color: context.colors.primary, size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: AppTypography.bodySmall.copyWith(color: context.colors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  name.isNotEmpty ? name : 'there',
                  style: AppTypography.headlineSmall.copyWith(color: context.colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _HomeBanner extends StatelessWidget {
  const _HomeBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: AppBannerCarousel(
        items: [
          BannerItem(
            title: 'Notifications',
            subtitle: 'Stay on top of what matters — see your latest updates.',
            icon: Icons.notifications_active_outlined,
            onTap: () => context.push('/notifications'),
          ),
          BannerItem(
            title: 'Map',
            subtitle: 'Explore layers around your current location.',
            icon: Icons.map_outlined,
            onTap: () => context.push('/map'),
          ),
          BannerItem(
            title: 'Your Profile',
            subtitle: 'Keep your personal info and avatar up to date.',
            icon: Icons.person_outline_rounded,
            onTap: () => context.go('/profile'),
          ),
          BannerItem(
            title: 'Settings',
            subtitle: 'Tune language, theme, and app preferences.',
            icon: Icons.settings_outlined,
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationListProvider);
    final recent = state.items.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/notifications'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: context.colors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: AppTypography.labelLarge.copyWith(color: context.colors.textPrimary),
                      ),
                    ),
                    if (state.unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.unread} unread',
                          style: AppTypography.labelSmall.copyWith(color: Colors.white),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: context.colors.textHint),
                  ],
                ),
                if (state.isLoading && state.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (recent.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'No notifications yet.',
                      style: AppTypography.bodySmall.copyWith(color: context.colors.textHint),
                    ),
                  )
                else ...[
                  const SizedBox(height: 8),
                  for (final item in recent)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isRead
                                  ? context.colors.divider
                                  : context.colors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: AppTypography.bodyMedium.copyWith(color: context.colors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.message.isNotEmpty)
                                  Text(
                                    item.message,
                                    style: AppTypography.bodySmall.copyWith(color: context.colors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (item.createdAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatRelative(item.createdAt!),
                              style: AppTypography.labelSmall.copyWith(color: context.colors.textHint),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: AppTypography.labelLarge.copyWith(color: context.colors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionButton(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                onTap: () => context.go('/profile'),
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => context.go('/settings'),
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.lock_outline_rounded,
                label: 'Password',
                onTap: () => context.go('/change-password'),
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.map,
                label: 'Map',
                onTap: () => context.push('/map'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: context.colors.primary, size: 24),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
