import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import '../theme/app_colors.dart';

class AdaptiveAppScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onNavigationSelected;
  final List<NavigationDestination> destinations;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AdaptiveAppScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onNavigationSelected,
    required this.destinations,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      bodyRatio: 0.05,
      body: (_) => AdaptiveScaffold(
        selectedIndex: selectedIndex,
        onSelectedIndexChanged: onNavigationSelected,
        destinations: destinations,
        body: (_) => _buildBody(context),
        smallBody: (_) => _buildBody(context),
        useDrawer: false,
      ),
      secondaryBody: (_) => AdaptiveScaffold(
        selectedIndex: selectedIndex,
        onSelectedIndexChanged: onNavigationSelected,
        destinations: destinations,
        body: (_) => _buildBody(context),
        smallBody: (_) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class AdaptiveNavigationWrapper extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget child;

  const AdaptiveNavigationWrapper({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      selectedIndex: currentIndex,
      onSelectedIndexChanged: onDestinationSelected,
      destinations: destinations,
      body: (_) => SafeArea(child: child),
      smallBody: (_) => SafeArea(child: child),
      navigationTypeProvider: (context) {
        final width = MediaQuery.sizeOf(context).width;
        if (width >= 1200) {
          return NavigationType.navigationRail;
        } else if (width >= 600) {
          return NavigationType.navigationRail;
        }
        return NavigationType.bottomNavigationBar;
      },
    );
  }
}
