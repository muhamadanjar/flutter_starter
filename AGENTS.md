# Enterprise Flutter App

Enterprise-grade Flutter application built with Clean Architecture, Riverpod state management, and Go Router navigation.

## Stack Overview

| Layer | Libraries | Purpose |
|-------|-----------|---------|
| **State Management** | `flutter_riverpod` 2.5.1 | Global state, async operations, dependency injection |
| **Navigation** | `go_router` 14.2.0 | Declarative routing with deep linking |
| **Network** | `dio` 5.4.3 | HTTP client with interceptors |
| **Local Storage** | `hive` 2.2.3 + `hive_flutter` 1.1.0 | NoSQL offline-first storage |
| **UI Components** | Material Design 3 | Native Flutter widgets |
| **Responsive** | `responsive_framework` 1.4.0 | Adaptive layouts (mobile/tablet/web) |
| **Icons** | `iconsax` 0.0.8 | Icon library |
| **Charts** | `fl_chart` 0.68.0 | Data visualization |
| **Utilities** | `freezed`, `json_serializable` | Code generation (models, serialization) |
| **Push Notifications** | `firebase_core` 2.28.0, `firebase_messaging` 14.8.0 | FCM push notifications |

## Project Structure

```
lib/
├── main.dart                    # App entry point, Hive initialization
├── app/
│   ├── app.dart                 # Root widget, theme, localization
│   └── router/
│       └── app_router.dart      # Go Router navigation config
│       └── shell_with_nav.dart  # Adaptive navigation (mobile/tablet/desktop)
├── core/
│   ├── constants/
│   │   └── app_constants.dart   # Hive box names, API endpoints
│   ├── errors/
│   │   └── failures.dart        # Domain layer error handling
│   ├── localization/
│   │   └── l10n_provider.dart   # Localization manager
│   ├── network/
│   │   └── network_info.dart    # Connectivity status
│   ├── services/
│   │   └── firebase_service.dart # Firebase messaging service
│   ├── theme/
│   │   └── app_theme.dart       # Material 3 themes (light/dark)
│   ├── utils/
│   │   └── extensions.dart      # String, DateTime, etc. utilities
│   ├── providers/
│   │   └── firebase_provider.dart # Riverpod FCM providers
│   └── widgets/
│       ├── responsive_builder.dart    # Screen size detection
│       ├── adaptive_layout.dart       # Adaptive UI widgets
│       └── [shared UI components]
└── features/
    ├── dashboard/               # Feature module (scalable)
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    └── notifications/           # Push notifications feature
        └── presentation/
            └── widgets/         # Notification settings widget
```

## Core Libraries — Usage

### 1. Riverpod (State Management)

```dart
// Define async provider
@riverpod
Future<DashboardData> dashboardData(DashboardDataRef ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.fetchDashboard();
}

// Consume in widget
Consumer(
  builder: (context, ref, child) {
    final asyncValue = ref.watch(dashboardDataProvider);
    return asyncValue.when(
      data: (data) => DashboardPage(data: data),
      loading: () => Loader(),
      error: (err, st) => ErrorWidget(error: err),
    );
  },
);

// Dependency injection
@riverpod
DashboardRepository dashboardRepository(DashboardRepositoryRef ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRepositoryImpl(dio);
}
```

**When to use**: Global state, async data fetching, dependency injection. Replaces Provider, GetX, BLoC.

### 2. Go Router (Navigation)

```dart
// Define routes (in app/router/app_router.dart)
final appRouterProvider = Provider((ref) => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => DashboardPage()),
    GoRoute(path: '/settings', builder: (ctx, state) => SettingsPage()),
  ],
));

// Navigate
context.go('/settings');
context.push('/details/${id}');  // Deep link
```

**When to use**: All navigation. Supports deep linking, named routes, nested shells.

### 3. Hive (Local Storage)

```dart
// Initialize (done in main.dart)
await Hive.initFlutter();  // Handles web + mobile
await Hive.openBox(AppConstants.authBox);

// Read/Write
final box = Hive.box(AppConstants.userBox);
await box.put('user', UserModel.toJson());
final user = box.get('user');

// For web compatibility: use Hive.initFlutter(), not getApplicationDocumentsDirectory()
```

**When to use**: Cache, offline data, user preferences. **Do NOT use path_provider on web** — use `Hive.initFlutter()`.

### 4. Dio (HTTP Client)

```dart
@riverpod
Dio dio(DioRef ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: Duration(seconds: 10),
  ));
  
  // Add interceptors
  dio.interceptors.add(LoggingInterceptor());
  return dio;
}

// Fetch
final response = await dio.get('/dashboard');
final data = DashboardModel.fromJson(response.data);
```

**When to use**: All API calls. Supports interceptors, retry logic, request/response transformation.

### 5. Freezed + JSON Serializable (Models)

```dart
// Define model (requires code generation)
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    @JsonKey(name: 'email_address') required String email,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

// Generate: flutter pub run build_runner build
```

**When to use**: All domain/data models. Immutability + serialization.

### 6. Firebase Messaging (Push Notifications)

```dart
// Get FCM token
final fcmTokenAsync = ref.watch(fcmTokenProvider);

fcmTokenAsync.when(
  data: (token) => Text('Token: $token'),
  loading: () => Loader(),
  error: (err, _) => ErrorWidget(error: err),
);

// Subscribe to topic
await subscribeToTopic(ref, 'news');

// Listen to token refresh
FirebaseService().onTokenRefresh.listen((newToken) {
  // Send to backend
});
```

**When to use**: Push notifications, user messaging, topic-based broadcasts.

**Setup:** See [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md) for platform-specific configuration.

### 7. Responsive Framework (Adaptive UI)

```dart
// Wrap at root (already done in App)
ResponsiveWrapper.builder(child)

// Check breakpoints in widgets
if (context.isPhone) {
  // Mobile layout
} else if (context.isTablet) {
  // Tablet layout
}

// Custom breakpoints
ResponsiveBreakpoints(
  breakpoints: [const Breakpoint(start: 0, end: 600, name: MOBILE)],
  child: child,
)
```

**When to use**: Apps targeting mobile + tablet + web. Adjusts layout automatically.

## Setup & Build

```bash
# Install dependencies
flutter pub get

# Generate code (models, routes, providers)
flutter pub run build_runner build

# Watch mode (auto-rebuild on changes)
flutter pub run build_runner watch

# Build APK (Android)
flutter build apk

# Build IPA (iOS)
flutter build ios

# Build web
flutter build web

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Environment Configuration (Flavors)

**Flavor-based setup** for dev/staging/production with different base URLs and configs.

- **Structure:** `main_dev.dart`, `main_staging.dart`, `main_production.dart` → `main_common.dart`
- **Config:** `lib/core/config/app_config.dart` (dev/staging/prod presets)
- **Access:** Riverpod provider `appConfigProvider`
- **Integration:** DIO client uses config for base URL, request timeout, API version

**Run by flavor:**
```bash
flutter run                              # Dev (default)
flutter run -t lib/main_staging.dart     # Staging
flutter run -t lib/main_production.dart  # Production
```

See **[ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md)** for details.

---

## Responsive Design

**Adaptive layouts** adapt to mobile (< 600px), tablet (600-1200px), and desktop (≥ 1200px) screens.

- **Navigation:** Mobile bottom nav → Tablet/desktop sidebar (via `ShellWithNavigation`)
- **Grids:** Mobile 1 column → Tablet 2 → Desktop 4 (via `AdaptiveSliverGrid`)
- **Content width:** Desktop constrained to max-width (via `AdaptiveContainer`)
- **Spacing/fonts:** Scale by screen size (via `AdaptivePadding`, `AdaptiveText`)

**Tools:** `ResponsiveBuilder`, `AdaptiveGrid`, `AdaptiveWrap`, `AdaptiveContainer`, `ScreenSizeVisibility`

See **[ADAPTIVE_LAYOUTS.md](docs/ADAPTIVE_LAYOUTS.md)** for complete guide.

---

## Architecture

**Clean Architecture** separates code into Domain (business logic), Data (sources), and Presentation (UI). See **[CLEAN_ARCHITECTURE.md](docs/CLEAN_ARCHITECTURE.md)** for detailed guide.

---

## Common Workflows

### Add New Feature
1. Create `lib/features/[feature]/domain/` (entities, repositories, usecases)
2. Create `lib/features/[feature]/data/` (models, datasources, repository impl)
3. Create `lib/features/[feature]/presentation/` (pages, widgets, providers)
4. Add route in `app/router/app_router.dart`

**Full walkthrough:** See [Clean Architecture Guide](docs/CLEAN_ARCHITECTURE.md#checklist-adding-new-feature)

### Add API Endpoint
1. Define request/response models in `data/models/`
2. Add method to repository interface in `domain/repositories/`
3. Implement in repository using `dio`
4. Expose via Riverpod provider
5. Call from page using `ref.watch()`

### Store Data Offline
1. Open box in `main.dart` → `_initializeHive()`
2. Add to `AppConstants` box names
3. Use `Hive.box(name).put(key, value)` in repository/datasource
4. Read via `Hive.box(name).get(key)`

### Handle Errors
- Domain layer: Use `Failure` (from `core/errors/failures.dart`)
- Async operations: Use `AsyncValue.when(data:, loading:, error:)`
- Network: Dio interceptors catch `DioException`

### Setup Push Notifications
1. Complete platform setup in [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md) (Android/iOS/Web)
2. Get FCM token via `fcmTokenProvider`
3. Send token to backend for user binding
4. Test via Firebase Console → Cloud Messaging
5. Customize message handlers in `FirebaseService` (foreground/background/tap)
6. Subscribe users to topics: `await subscribeToTopic(ref, 'news')`

## Git Operations

### Allowed ✅
- `git log` — View history
- `git status` — Check state
- `git diff` — Review changes
- `git show` — Inspect commits

### Forbidden ❌
- `git reset --hard` — Destructive
- `git rebase -i` — Interactive rebase
- `git push --force` — Force overwrite
- `git checkout .` — Discard changes (use `git diff` + manual edit instead)
- `git commit` — Create commits
- `git add` — Stage files
- `git push` — Push to remote

## Code Quality

```bash
# Fix formatting
dart format lib/

# Run linter
flutter analyze

# Check for unused imports
dart fix --apply

# Build runner (after model/provider changes)
flutter pub run build_runner build --delete-conflicting-outputs
```

## Documentation

**Rule: All documentation goes in `/docs` folder**

### Types of Documentation

| Type | File | Purpose |
|------|------|---------|
| Setup | `SETUP_GUIDE.md` | First-time developer setup |
| Architecture | `CLEAN_ARCHITECTURE.md` | Design patterns, layers |
| Features | `ADAPTIVE_LAYOUTS.md`, etc. | Feature-specific guides |
| Configuration | `ENVIRONMENT_SETUP.md` | Environment config |
| Versioning | `SEMANTIC_VERSIONING.md` | Release & versioning |
| Storage | `PREFERENCES_GUIDE.md` | Preference system |
| Logging | `LOGGING_GUIDE.md` | Logging setup & usage |
| Dependencies | `PACKAGE_UPGRADE_ROADMAP.md` | Dependency strategy |
| Firebase | `FIREBASE_SETUP.md` | Push notifications |
| Integration | `DEPENDENCY_AUDIT.md` | Migration history |
| Track Record | `TRACK_RECORD_GUIDE.md` | Offline GPS tracking + sync outbox |

### Documentation Checklist

When adding new feature/system:

- [ ] Create `docs/FEATURE_NAME.md`
- [ ] Include: Overview, Architecture, Quick Start, API Reference, Examples
- [ ] Add to README.md links
- [ ] Update AGENTS.md if it's a core system
- [ ] Include troubleshooting section
- [ ] Link to related docs
- [ ] Keep under 600 lines (split if larger)

### Example: Adding New Feature Documentation

```markdown
# Feature Name Guide

## Overview
Concise description

## Architecture
Diagram/structure

## Quick Start
Minimal working example

## API Reference
Methods/properties

## Common Use Cases
5-6 real examples

## Best Practices
DO/DON'T checklist

## Troubleshooting
Common issues

## Related Docs
Links
```

### Current Documentation

✅ **Complete** (11 docs):
- SETUP_GUIDE.md - First time setup
- CLEAN_ARCHITECTURE.md - Architecture patterns
- ADAPTIVE_LAYOUTS.md - Responsive UI
- ENVIRONMENT_SETUP.md - Flavor configuration
- ENVIRONMENT_CONFIGURATION.md - Config theory
- PREFERENCES_GUIDE.md - Storage system
- LOGGING_GUIDE.md - Logging management
- FIREBASE_SETUP.md - Push notifications
- FIREBASE_QUICK_START.md - Firebase reference
- SEMANTIC_VERSIONING.md - Release process
- PACKAGE_UPGRADE_ROADMAP.md - Upgrade strategy
- DEPENDENCY_AUDIT.md - Package migrations
- PRIORITY1_UPDATES.md - Completed updates
- TRACK_RECORD_GUIDE.md - Offline GPS tracking & sync outbox

## Known Issues & Fixes

**MissingPluginException (path_provider on web)**
- ✅ Fixed: Use `Hive.initFlutter()` instead of `getApplicationDocumentsDirectory()`

**ThemeData assertion (colorSchemeSeed conflict)**
- ✅ Fixed: Removed duplicate `colorSchemeSeed` from light/dark themes

**flutter_adaptive_scaffold not used**
- ✅ Removed: Project uses custom adaptive layout via `responsive_framework`

**Firebase setup (Android/iOS)**
- ⏳ Manual: Download `google-services.json` (Android) & `GoogleService-Info.plist` (iOS)
- ⏳ Manual: Configure APNs certificates for iOS
- ✅ Code: `FirebaseService`, `firebase_provider`, message handlers in `main.dart`
- 📖 Guide: [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)

## Version & Release Management

**Current Version:** See `pubspec.yaml` (e.g., 1.0.0+1)

**Semantic Versioning (SemVer 2.0.0)**
- MAJOR: Breaking changes (feat!:)
- MINOR: New features (feat:)
- PATCH: Bug fixes (fix:)
- BUILD: CI/CD increments (+1, +2, ...)

**Commit Message Convention (Conventional Commits)**
- `fix:` → PATCH version
- `feat:` → MINOR version
- `feat!:` or `BREAKING CHANGE:` → MAJOR version
- `docs:`, `style:`, `refactor:`, `perf:`, `test:` → PATCH version

**Example Commits:**
```
fix(auth): resolve token expiry check

feat(notifications): add firebase push notifications

feat!: migrate dartz to fpdart (BREAKING CHANGE)
```

**Automatic Versioning:**
- Commit messages analyzed on push to master
- Version auto-bumped in pubspec.yaml
- Git tag created (v1.0.0)
- GitHub release published
- Build number increments per CI run

📖 See [SEMANTIC_VERSIONING.md](docs/SEMANTIC_VERSIONING.md) for complete guide.

---

## Version Constraints

- Dart: `>=3.2.0 <4.0.0`
- Flutter: Latest stable
- Riverpod: 2.5.1 (3.x available but requires migration)
- Go Router: 14.2.0+

**Dependency Status & Upgrades:**

✅ **Completed:**
- Removed `either_dart` (unused, unmaintained)
- Migrated `dartz` → `fpdart` 1.1.0 (all 20 files updated)

🟢 **Priority 1 (Ready Now):** Safe patches & minors
- `dio` 5.9.2 → 5.10.0, `intl` 0.20.2 → 0.20.3
- `cached_network_image` 3.4.0 → 3.4.1, `formz` 0.7.0 → 0.8.0
- 📖 [PRIORITY1_UPDATES.md](docs/PRIORITY1_UPDATES.md) — step-by-step guide

🟡 **Priority 2-4 (Next Month):** Build tools, linters, freezed
- build_runner, json_*, mockito, flutter_lints
- Freezed 3.x (code generation)

🔴 **Priority 5 (Next Quarter):** Major versions
- Riverpod 2.x → 3.x (breaking changes, core state mgmt)
- Go Router 14.x → 17.x (breaking changes, all routing)
- Firebase 2.x → 4.x, FL Chart 0.68 → 1.2, Google Fonts 6.x → 8.x

- 📖 [PACKAGE_UPGRADE_ROADMAP.md](docs/PACKAGE_UPGRADE_ROADMAP.md) — full strategy
- 📖 [DEPENDENCY_AUDIT.md](docs/DEPENDENCY_AUDIT.md) — migration history

## Performance Tips

1. **Use `riverpod_annotation` + code generation** — Refactored providers with `@riverpod`
2. **Lazy load Hive boxes** — Open only needed boxes in `main.dart`
3. **Cache API responses** — Store in Hive for offline access
4. **Use `const` widgets** — Prevents unnecessary rebuilds
5. **Profile with DevTools** — `flutter pub global activate devtools`
