import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/responsive_builder.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';

/// A single navigation destination in the app shell.
class _NavItem {
  const _NavItem({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeProvider,
  });
  // ignore: prefer_const_constructors_in_immutables


  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  /// Optional provider that returns an unread count for a badge.
  final ProviderListenable<int>? badgeProvider;
}

/// Ordered destinations shown in the shell navigation.
/// Index here MUST match `_calculateIndex` in app_router.dart.
final List<_NavItem> _destinations = [
  _NavItem(
    route: '/home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Home',
  ),
  _NavItem(
    route: '/map',
    icon: Icons.map_outlined,
    selectedIcon: Icons.map_rounded,
    label: 'Map',
  ),
  _NavItem(
    route: '/notifications',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_rounded,
    label: 'Alerts',
    badgeProvider: notificationListProvider.select((s) => s.unread),
  ),
  _NavItem(
    route: '/profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person_rounded,
    label: 'Profile',
  ),
  _NavItem(
    route: '/settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    label: 'Settings',
  ),
];

class ShellWithNavigation extends StatelessWidget {
  ShellWithNavigation({
    super.key,
    required this.currentIndex,
    required this.child,
  });
  final int currentIndex;
  final Widget child;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onDestinationSelected(BuildContext context, int index) {
    final route = _destinations[index].route;
    if (GoRouterState.of(context).matchedLocation != route) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = ResponsiveBuilder(
      builder: (context, screenSize) {
        if (screenSize == ScreenSize.desktop) {
          return _buildRailLayout(context, extended: true);
        } else if (screenSize == ScreenSize.tablet) {
          return _buildRailLayout(context, extended: false);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: _NavDrawer(
        currentIndex: currentIndex,
        onSelected: _onDestinationSelected,
      ),
      body: Stack(
        children: [
          layout,
          // Top-left menu button opens the navigation drawer on all layouts.
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'shell-menu',
                tooltip: 'Menu',
                backgroundColor: context.colors.surface,
                foregroundColor: context.colors.textPrimary,
                elevation: 2,
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                child: const Icon(Icons.menu_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        backgroundColor: context.colors.surface,
        indicatorColor: context.colors.primary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (int i = 0; i < _destinations.length; i++)
            _mobileDestination(context, i),
        ],
      ),
    );
  }

  NavigationDestination _mobileDestination(BuildContext context, int index) {
    final item = _destinations[index];
    return NavigationDestination(
      icon: _BadgeIcon(icon: item.icon, provider: item.badgeProvider),
      selectedIcon:
          _BadgeIcon(icon: item.selectedIcon, provider: item.badgeProvider),
      label: item.label,
    );
  }

  Widget _buildRailLayout(BuildContext context, {required bool extended}) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
              extended: extended,
              minWidth: 72,
              minExtendedWidth: 200,
              backgroundColor: context.colors.surface,
              indicatorColor: context.colors.primary.withValues(alpha: 0.15),
              selectedIconTheme: IconThemeData(color: context.colors.primary),
              unselectedIconTheme:
                  IconThemeData(color: context.colors.textHint),
              selectedLabelTextStyle:
                  AppTypography.labelMedium.copyWith(color: context.colors.primary),
              unselectedLabelTextStyle:
                  AppTypography.labelMedium.copyWith(color: context.colors.textHint),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: extended
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.rocket_launch_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Enterprise',
                            style: AppTypography.labelLarge
                                .copyWith(color: context.colors.textPrimary),
                          ),
                        ],
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.rocket_launch_rounded,
                            color: Colors.white, size: 22),
                      ),
              ),
              trailing: Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer(
                        builder: (context, ref, child) => IconButton(
                          icon: Icon(Icons.logout_rounded,
                              color: context.colors.textHint),
                          onPressed: () {
                            ref.read(authProvider.notifier).logout();
                          },
                          tooltip: 'Sign Out',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              destinations: [
                for (int i = 0; i < _destinations.length; i++)
                  _railDestination(context, i, extended),
              ],
            ),
            VerticalDivider(width: 1, thickness: 1, color: context.colors.divider),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  NavigationRailDestination _railDestination(
    BuildContext context,
    int index,
    bool extended,
  ) {
    final item = _destinations[index];
    return NavigationRailDestination(
      icon: _BadgeIcon(icon: item.icon, provider: item.badgeProvider),
      selectedIcon:
          _BadgeIcon(icon: item.selectedIcon, provider: item.badgeProvider),
      label: extended
          ? Text(item.label)
          : const SizedBox.shrink(),
      // When collapsed, show the label below the icon for clarity.
      padding: extended ? null : const EdgeInsets.symmetric(vertical: 4),
    );
  }
}

/// Navigation drawer opened from the top-left menu button on all layouts.
/// Mirrors the bottom nav / side rail destinations.
class _NavDrawer extends ConsumerWidget {
  const _NavDrawer({
    required this.currentIndex,
    required this.onSelected,
  });
  final int currentIndex;
  final void Function(BuildContext context, int index) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Drawer(
      backgroundColor: colors.surface,
      child: Column(
        children: [
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Enterprise',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (int i = 0; i < _destinations.length; i++)
                  _DrawerTile(
                    item: _destinations[i],
                    selected: i == currentIndex,
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelected(context, i);
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: colors.textHint),
            title: Text(
              'Sign Out',
              style: AppTypography.labelMedium.copyWith(color: colors.textPrimary),
            ),
            onTap: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DrawerTile extends ConsumerWidget {
  const _DrawerTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return ListTile(
      leading: _BadgeIcon(icon: item.icon, provider: item.badgeProvider),
      title: Text(
        item.label,
        style: AppTypography.labelMedium.copyWith(
          color: selected ? colors.primary : colors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: selected,
      selectedTileColor: colors.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
    );
  }
}

/// Icon wrapper that shows a small unread-count badge when count > 0.
class _BadgeIcon extends ConsumerWidget {
  const _BadgeIcon({required this.icon, this.provider});
  final IconData icon;
  final ProviderListenable<int>? provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = provider == null ? 0 : ref.watch(provider!);
    if (count <= 0) return Icon(icon);
    return Badge.count(count: count, child: Icon(icon));
  }
}
