import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/responsive_builder.dart';

class ShellWithNavigation extends StatelessWidget {
  final int currentIndex;
  final Widget child;

  const ShellWithNavigation({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics_rounded),
      label: 'Analytics',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        // Analytics placeholder - navigate to dashboard for now
        context.go('/dashboard');
        break;
      case 2:
        context.go('/profile');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        if (screenSize == ScreenSize.desktop) {
          return _buildDesktopLayout(context);
        } else if (screenSize == ScreenSize.tablet) {
          return _buildTabletLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        destinations: _destinations,
        backgroundColor: context.colors.surface,
        indicatorColor: context.colors.primary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => _onDestinationSelected(context, index),
              destinations: _destinations.map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                );
              }).toList(),
              backgroundColor: context.colors.surface,
              indicatorColor: context.colors.primary.withOpacity(0.15),
              selectedIconTheme: IconThemeData(color: context.colors.primary),
              unselectedIconTheme: IconThemeData(color: context.colors.textHint),
              selectedLabelTextStyle: AppTypography.labelSmall.copyWith(color: context.colors.primary),
              unselectedLabelTextStyle: AppTypography.labelSmall.copyWith(color: context.colors.textHint),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                ),
              ),
              labelType: NavigationRailLabelType.all,
              minWidth: 72,
            ),
            VerticalDivider(width: 1, thickness: 1, color: context.colors.divider),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Extended Navigation Rail
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => _onDestinationSelected(context, index),
              destinations: _destinations.map((d) {
                return NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                );
              }).toList(),
              backgroundColor: context.colors.surface,
              indicatorColor: context.colors.primary.withValues(alpha: 0.15),
              selectedIconTheme: IconThemeData(color: context.colors.primary),
              unselectedIconTheme: IconThemeData(color: context.colors.textHint),
              selectedLabelTextStyle: AppTypography.labelMedium.copyWith(color: context.colors.primary),
              unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(color: context.colors.textHint),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Enterprise',
                      style: AppTypography.labelLarge.copyWith(color: context.colors.textPrimary),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.logout_rounded, color: context.colors.textHint),
                        onPressed: () {/* TODO: Logout */},
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
                ),
              ),
              extended: true,
              minExtendedWidth: 200,
            ),
            VerticalDivider(width: 1, thickness: 1, color: context.colors.divider),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
