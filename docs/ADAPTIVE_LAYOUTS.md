# Adaptive Layouts Guide

Complete guide for building responsive UIs that adapt to mobile, tablet, and desktop screens.

## Screen Size Breakpoints

```
Mobile:    < 600px    (phones)
Tablet:    600-1200px (tablets, large phones)
Desktop:   >= 1200px  (desktops, laptops)
```

Defined in `lib/core/widgets/responsive_builder.dart`.

## Core Tools

### 1. ResponsiveBuilder (Screen Detection)

Detect current screen size and build conditionally:

```dart
import 'package:enterprise_flutter_app/core/widgets/responsive_builder.dart';

ResponsiveBuilder(
  builder: (context, screenSize) {
    if (screenSize == ScreenSize.desktop) {
      return DesktopLayout();
    } else if (screenSize == ScreenSize.tablet) {
      return TabletLayout();
    } else {
      return MobileLayout();
    }
  },
);
```

**Utilities:**

```dart
// Check screen size statically
ResponsiveBuilder.isMobile(context)    // true/false
ResponsiveBuilder.isTablet(context)
ResponsiveBuilder.isDesktop(context)

// Get screen size
final size = ResponsiveBuilder.getScreenSize(context);  // ScreenSize enum

// Get value by screen type
final columns = ResponsiveBuilder.valueByScreen(
  context,
  mobile: 1,
  tablet: 2,
  desktop: 4,
);
```

### 2. AdaptiveSliverGrid (Responsive Grid)

Grid that changes column count by screen size:

```dart
AdaptiveSliverGrid(
  mobileColumns: 1,      // 1 column on mobile
  tabletColumns: 2,      // 2 columns on tablet
  desktopColumns: 4,     // 4 columns on desktop
  spacing: 12,
  childAspectRatio: 1.4,
  children: [
    StatCardWidget(...),
    StatCardWidget(...),
    StatCardWidget(...),
    StatCardWidget(...),
  ],
);
```

**Used in:**
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` (stat cards)

### 3. AdaptiveGrid (Non-Sliver Version)

For non-scrolling content:

```dart
AdaptiveGrid(
  mobileColumns: 1,
  tabletColumns: 2,
  desktopColumns: 3,
  children: [
    Card(child: Text('Card 1')),
    Card(child: Text('Card 2')),
    Card(child: Text('Card 3')),
  ],
);
```

### 4. AdaptiveWrap (Row/Column Toggle)

Switch between row, wrap, and column layouts:

```dart
AdaptiveWrap(
  spacing: 12,
  children: [
    Button(label: 'Save'),
    Button(label: 'Cancel'),
    Button(label: 'Delete'),
  ],
);

// Mobile: Stacked vertically
// Tablet: Wrapped horizontally
// Desktop: Full width row with spacing
```

### 5. AdaptivePadding (Dynamic Spacing)

Adjust padding based on screen:

```dart
AdaptivePadding(
  mobilePadding: EdgeInsets.all(12),    // Tight on mobile
  tabletPadding: EdgeInsets.all(16),    // Medium on tablet
  desktopPadding: EdgeInsets.all(24),   // Spacious on desktop
  child: Content(),
);
```

### 6. AdaptiveContainer (Content Width)

Constrain content width on desktop (prevent stretching):

```dart
AdaptiveContainer(
  maxWidth: 1400,  // Max content width
  child: ProfileCard(),
);

// Mobile: Full width
// Tablet: Full width
// Desktop: Centered, max 1400px width
```

### 7. AdaptiveText (Responsive Font Size)

Scale text size by screen:

```dart
AdaptiveText(
  'Hello, World!',
  baseStyle: Theme.of(context).textTheme.titleLarge,
  mobileScaleFactor: 0.9,      // Smaller on mobile
  tabletScaleFactor: 1.0,      // Normal on tablet
  desktopScaleFactor: 1.2,     // Larger on desktop
);
```

### 8. ScreenSizeVisibility (Conditional Visibility)

Show/hide elements by screen size:

```dart
ScreenSizeVisibility(
  showOnMobile: true,
  showOnTablet: true,
  showOnDesktop: false,
  child: Icon(Icons.menu),  // Show menu icon only on mobile/tablet
);
```

## Navigation Patterns

### Already Implemented in ShellWithNavigation

**Mobile:** Bottom NavigationBar
```
┌─────────────────┐
│    Content      │
├─────────────────┤
│  [Icon] [Icon]  │  <- Bottom nav
└─────────────────┘
```

**Tablet:** NavigationRail (sidebar)
```
┌──────┬─────────────┐
│ Rail │  Content    │
│ Icons│             │
└──────┴─────────────┘
```

**Desktop:** Extended NavigationRail
```
┌──────────┬─────────────┐
│ Extended │  Content    │
│ Rail     │             │
│ w/ Labels│             │
└──────────┴─────────────┘
```

See `lib/app/router/shell_with_nav.dart` for implementation.

## Layout Patterns

### Pattern 1: Single Column → Multi-Column

```dart
AdaptiveSliverGrid(
  mobileColumns: 1,
  tabletColumns: 2,
  desktopColumns: 3,
  children: [...cards],
);

// Result:
// Mobile:  [Card]
//          [Card]
//          [Card]
//
// Tablet:  [Card] [Card]
//          [Card]
//
// Desktop: [Card] [Card] [Card]
```

### Pattern 2: Stack → Side-by-Side

```dart
ResponsiveBuilder(
  builder: (context, screenSize) {
    if (screenSize == ScreenSize.mobile) {
      return Column(children: [Left(), Right()]);  // Stacked
    } else {
      return Row(children: [
        Expanded(child: Left()),
        Expanded(child: Right()),
      ]);  // Side-by-side
    }
  },
);
```

### Pattern 3: Hide Sidebar on Mobile

```dart
ScreenSizeVisibility(
  showOnMobile: false,
  showOnTablet: true,
  showOnDesktop: true,
  child: Sidebar(),
);
```

### Pattern 4: Adaptive Drawer

```dart
if (ResponsiveBuilder.isMobile(context)) {
  return Scaffold(
    drawer: Sidebar(),  // Drawer on mobile
    body: Content(),
  );
} else {
  return Row(children: [
    Sidebar(),          // Visible sidebar on tablet/desktop
    Expanded(child: Content()),
  ]);
}
```

## Common Patterns by Page Type

### Dashboard
- **Mobile:** 1-column grid (full width)
- **Tablet:** 2-column grid
- **Desktop:** 4-column grid

```dart
AdaptiveSliverGrid(
  mobileColumns: 1,
  tabletColumns: 2,
  desktopColumns: 4,
  children: [StatCard(...), ...],
);
```

### Settings/Form
- **Mobile:** Full-width form
- **Tablet:** Full-width form
- **Desktop:** Constrained width form (centered)

```dart
AdaptiveContainer(
  maxWidth: 800,  // Limit width on desktop
  child: Form(...),
);
```

### Master-Detail
- **Mobile:** Single column (tap to detail)
- **Tablet:** Split view (list + detail)
- **Desktop:** Split view (list + detail)

```dart
ResponsiveBuilder(
  builder: (context, screenSize) {
    if (screenSize == ScreenSize.mobile) {
      return MobileDetailView();  // Full screen
    } else {
      return Row(
        children: [
          Expanded(child: ListView(...)),
          Expanded(child: DetailView()),
        ],
      );
    }
  },
);
```

### Buttons/Controls
- **Mobile:** Stacked vertically
- **Tablet:** Wrapped horizontally
- **Desktop:** Row with spacing

```dart
AdaptiveWrap(
  spacing: 8,
  runSpacing: 8,
  children: [Button(...), Button(...), Button(...)],
);
```

## Best Practices

✅ **Do:**
- Use `AdaptiveSliverGrid` for content grids
- Use `AdaptiveContainer` to constrain desktop width
- Hide complex sidebars on mobile (use drawer instead)
- Scale fonts with `AdaptiveText` for readability
- Test on actual devices/emulators

❌ **Don't:**
- Hard-code fixed widths (use Expanded/Flexible)
- Forget to test tablet screens (between mobile & desktop)
- Scale padding/margins excessively on mobile
- Create desktop-only features (users on all devices)
- Use `MediaQuery.sizeOf()` directly (use ResponsiveBuilder)

## Testing Adaptive Layouts

### Device Sizes to Test

```
Mobile:     375x667   (iPhone 8)
            412x915   (Pixel 5)

Tablet:     600x800   (iPad Mini, landscape)
            768x1024  (iPad, portrait)

Desktop:    1280x720  (HD)
            1920x1080 (Full HD)
```

### Emulator Testing

```bash
# Android emulator
flutter run -d emulator-5554

# iOS simulator
open -a Simulator
flutter run -d iPhone

# Web (responsive)
flutter run -d chrome
# DevTools → Device → Custom (375x667) → Responsive
```

### Widget Test

```dart
testWidgets('Dashboard grid adapts to mobile', (tester) async {
  tester.binding.window.physicalSize = Size(375, 667);
  addTearDown(tester.binding.window.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(home: DashboardPage()),
  );

  // Verify 1 column on mobile
  expect(find.byType(StatCardWidget), findsWidgets);
});
```

## Migration Guide: Existing Code

### Before (Fixed Layout)

```dart
SliverGrid(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,  // Always 2 columns
    ...
  ),
  ...
);
```

### After (Adaptive)

```dart
AdaptiveSliverGrid(
  mobileColumns: 1,      // Add mobile column count
  tabletColumns: 2,
  desktopColumns: 4,     // Support larger screens
  children: [...],
);
```

## File Locations

| Component | File |
|-----------|------|
| ResponsiveBuilder | `lib/core/widgets/responsive_builder.dart` |
| Adaptive Widgets | `lib/core/widgets/adaptive_layout.dart` |
| Navigation | `lib/app/router/shell_with_nav.dart` |
| Dashboard (Example) | `lib/features/dashboard/presentation/pages/dashboard_page.dart` |

## Next Steps

1. ✅ Navigation already adapts (shell_with_nav.dart)
2. ✅ Dashboard grid now adapts (uses AdaptiveSliverGrid)
3. 🔄 Enhance other pages (settings, profile, etc.)
4. 🔄 Test on tablet/desktop devices
5. 🔄 Optimize touch targets (min 48x48 dp)
6. 🔄 Add keyboard navigation (desktop)

## References

- [Material Design - Responsive UI](https://material.io/design/layout/responsive-layout-grid.html)
- [Flutter Official Adaptive](https://flutter.dev/docs/development/ui/adaptive-and-responsive)
- [MediaQuery Documentation](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)
