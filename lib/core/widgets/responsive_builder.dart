import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop }

class ResponsiveBuilder extends StatelessWidget {

  const ResponsiveBuilder({super.key, required this.builder});
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return ScreenSize.desktop;
    if (width >= 600) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  static bool isMobile(BuildContext context) => getScreenSize(context) == ScreenSize.mobile;
  static bool isTablet(BuildContext context) => getScreenSize(context) == ScreenSize.tablet;
  static bool isDesktop(BuildContext context) => getScreenSize(context) == ScreenSize.desktop;

  static T valueByScreen<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        ScreenSize screenSize;
        if (constraints.maxWidth >= 1200) {
          screenSize = ScreenSize.desktop;
        } else if (constraints.maxWidth >= 600) {
          screenSize = ScreenSize.tablet;
        } else {
          screenSize = ScreenSize.mobile;
        }
        return builder(context, screenSize);
      },
    );
  }
}
