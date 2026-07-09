import 'package:flutter/material.dart';
import 'responsive_builder.dart';

/// Responsive grid that adapts column count based on screen size
class AdaptiveGrid extends StatelessWidget {

  const AdaptiveGrid({
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 4,
    this.padding = const EdgeInsets.all(16),
    Key? key,
  }) : super(key: key);
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        late int columns;
        switch (screenSize) {
          case ScreenSize.mobile:
            columns = mobileColumns ?? 1;
            break;
          case ScreenSize.tablet:
            columns = tabletColumns ?? 2;
            break;
          case ScreenSize.desktop:
            columns = desktopColumns ?? 4;
            break;
        }

        return Padding(
          padding: padding,
          child: GridView.count(
            crossAxisCount: columns,
            mainAxisSpacing: runSpacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: children,
          ),
        );
      },
    );
  }
}

/// Responsive sliver grid
class AdaptiveSliverGrid extends StatelessWidget {

  const AdaptiveSliverGrid({
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 4,
    this.childAspectRatio = 1.4,
    Key? key,
  }) : super(key: key);
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        late int columns;
        switch (screenSize) {
          case ScreenSize.mobile:
            columns = mobileColumns ?? 1;
            break;
          case ScreenSize.tablet:
            columns = tabletColumns ?? 2;
            break;
          case ScreenSize.desktop:
            columns = desktopColumns ?? 4;
            break;
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: runSpacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio ?? 1.4,
            ),
            delegate: SliverChildListDelegate(children),
          ),
        );
      },
    );
  }
}

/// Responsive row/column that switches based on screen size
class AdaptiveWrap extends StatelessWidget { // Force column layout on tablet/desktop

  const AdaptiveWrap({
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.forceColumn = false,
    Key? key,
  }) : super(key: key);
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final bool forceColumn;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        if (forceColumn || screenSize == ScreenSize.mobile) {
          return Column(
            spacing: runSpacing,
            children: children,
          );
        } else if (screenSize == ScreenSize.tablet) {
          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: children,
          );
        } else {
          return Row(
            spacing: spacing,
            children: children.map((child) => Expanded(child: child)).toList(),
          );
        }
      },
    );
  }
}

/// Adaptive padding based on screen size
class AdaptivePadding extends StatelessWidget {

  const AdaptivePadding({
    required this.child,
    this.mobilePadding = const EdgeInsets.all(12),
    this.tabletPadding = const EdgeInsets.all(16),
    this.desktopPadding = const EdgeInsets.all(24),
    Key? key,
  }) : super(key: key);
  final Widget child;
  final EdgeInsets mobilePadding;
  final EdgeInsets tabletPadding;
  final EdgeInsets desktopPadding;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        late EdgeInsets padding;
        switch (screenSize) {
          case ScreenSize.mobile:
            padding = mobilePadding;
            break;
          case ScreenSize.tablet:
            padding = tabletPadding;
            break;
          case ScreenSize.desktop:
            padding = desktopPadding;
            break;
        }

        return Padding(padding: padding, child: child);
      },
    );
  }
}

/// Adaptive container width (constrain content on desktop)
class AdaptiveContainer extends StatelessWidget {

  const AdaptiveContainer({
    required this.child,
    this.maxWidth = 1400,
    this.alignment = MainAxisAlignment.center,
    Key? key,
  }) : super(key: key);
  final Widget child;
  final double maxWidth;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        if (screenSize == ScreenSize.desktop) {
          return Row(
            mainAxisAlignment: alignment,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: child,
              ),
            ],
          );
        }
        return child;
      },
    );
  }
}

/// Adaptive font size
class AdaptiveText extends StatelessWidget {

  const AdaptiveText(
    this.text, {
    this.baseStyle,
    this.mobileScaleFactor = 1.0,
    this.tabletScaleFactor = 1.1,
    this.desktopScaleFactor = 1.2,
    this.textAlign,
    this.maxLines,
    this.overflow,
    Key? key,
  }) : super(key: key);
  final String text;
  final TextStyle? baseStyle;
  final double mobileScaleFactor;
  final double tabletScaleFactor;
  final double desktopScaleFactor;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        late double scaleFactor;
        switch (screenSize) {
          case ScreenSize.mobile:
            scaleFactor = mobileScaleFactor;
            break;
          case ScreenSize.tablet:
            scaleFactor = tabletScaleFactor;
            break;
          case ScreenSize.desktop:
            scaleFactor = desktopScaleFactor;
            break;
        }

        final style = baseStyle?.copyWith(
          fontSize: (baseStyle?.fontSize ?? 14) * scaleFactor,
        );

        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Show content only on specific screen sizes
class ScreenSizeVisibility extends StatelessWidget {

  const ScreenSizeVisibility({
    required this.child,
    this.showOnMobile = true,
    this.showOnTablet = true,
    this.showOnDesktop = true,
    Key? key,
  }) : super(key: key);
  final Widget child;
  final bool showOnMobile;
  final bool showOnTablet;
  final bool showOnDesktop;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screenSize) {
        bool show = false;
        switch (screenSize) {
          case ScreenSize.mobile:
            show = showOnMobile;
            break;
          case ScreenSize.tablet:
            show = showOnTablet;
            break;
          case ScreenSize.desktop:
            show = showOnDesktop;
            break;
        }

        return Visibility(visible: show, child: child);
      },
    );
  }
}
