# Enterprise Flutter App

Enterprise-grade Flutter application with Clean Architecture, Riverpod state management, Go Router navigation, Firebase push notifications, and multi-environment support.

## Features

✅ **Architecture**
- Clean Architecture (Domain → Data → Presentation layers)
- Feature-modular structure (scalable)
- Dependency injection via Riverpod
- Type-safe error handling (Either pattern with fpdart)

✅ **State Management & Navigation**
- Riverpod 2.5.1 (state, async, DI)
- Go Router 14.8.0 (declarative routing, deep links)
- Adaptive navigation (mobile: bottom nav, tablet/desktop: sidebar)

✅ **Network & Storage**
- Dio 5.10.0 (HTTP client with interceptors, retry logic)
- Hive 2.2.3 (NoSQL offline storage)
- Connectivity Plus (network status monitoring)
- Firebase Cloud Messaging (push notifications)

✅ **UI & Responsiveness**
- Material Design 3
- Responsive Framework (adaptive layouts: mobile/tablet/desktop)
- Dark/Light themes
- Support for internationalization (i18n)

✅ **Multi-Environment Support**
- Flavor-based configuration (dev/staging/production)
- Easy base URL switching
- Environment-specific debug settings

---

## Quick Start

### Prerequisites

- Flutter SDK: ≥ 3.2.0, < 4.0.0
- Dart SDK: ≥ 3.2.0
- Android SDK (API 21+) or iOS 11.0+
- Git

### Installation

```bash
# Clone repository
git clone <repository-url>
cd enterprise_flutter_app

# Install dependencies
flutter pub get

# Generate code (models, routes, providers)
flutter pub run build_runner build
```

### Run Development Flavor (Default)

```bash
flutter run
```

Runs with:
- Base URL: `http://localhost:3000/api`
- Debug mode: ON
- Environment: development

### Run Other Flavors

```bash
# Staging environment
flutter run -t lib/main_staging.dart

# Production environment
flutter run -t lib/main_production.dart
```

---

## Development

### Project Structure

```
lib/
├── main.dart                           # Entry point (exports main_dev.dart)
├── main_common.dart                    # Shared initialization
├── main_dev.dart                       # Dev flavor
├── main_staging.dart                   # Staging flavor
├── main_production.dart                # Production flavor
│
├── app/
│   ├── app.dart                        # Root widget, theme setup
│   └── router/                         # Navigation & routing
│       ├── app_router.dart             # Go Router config
│       └── shell_with_nav.dart         # Adaptive navigation
│
├── core/
│   ├── config/
│   │   └── app_config.dart             # Environment configs (dev/staging/prod)
│   ├── constants/
│   │   ├── app_constants.dart          # App-wide constants
│   │   └── api_constants.dart          # API endpoints
│   ├── errors/
│   │   ├── exceptions.dart             # Data layer exceptions
│   │   └── failures.dart               # Domain layer failures
│   ├── localization/
│   │   └── l10n_provider.dart          # Internationalization
│   ├── network/
│   │   ├── dio_client.dart             # HTTP client
│   │   └── network_info.dart           # Connectivity monitoring
│   ├── providers/
│   │   ├── config_provider.dart        # Environment config provider
│   │   └── firebase_provider.dart      # FCM provider
│   ├── services/
│   │   └── firebase_service.dart       # Firebase initialization
│   ├── theme/
│   │   ├── app_colors.dart             # Color palette
│   │   ├── app_typography.dart         # Text styles
│   │   └── app_theme.dart              # Theme definitions
│   ├── utils/
│   │   ├── extensions.dart             # String, DateTime, etc.
│   │   └── validators.dart             # Input validation
│   └── widgets/
│       ├── responsive_builder.dart     # Screen size detection
│       ├── adaptive_layout.dart        # Responsive UI widgets
│       └── [shared components]
│
└── features/
    ├── auth/                           # Authentication feature
    ├── dashboard/                      # Dashboard feature
    ├── profile/                        # User profile feature
    ├── settings/                       # App settings feature
    └── notifications/                  # Notifications feature
        └── presentation/
            └── widgets/
                └── notification_settings_widget.dart

docs/
├── AGENTS.md                           # Project rules & setup
├── CLEAN_ARCHITECTURE.md               # Architecture patterns & examples
├── ADAPTIVE_LAYOUTS.md                 # Responsive UI guide
├── ENVIRONMENT_CONFIGURATION.md        # Environment setup theory
├── ENVIRONMENT_SETUP.md                # Environment setup (implemented)
├── FIREBASE_SETUP.md                   # Firebase configuration
├── FIREBASE_QUICK_START.md             # Firebase quick reference
├── DEPENDENCY_AUDIT.md                 # Package audit report
├── PACKAGE_UPGRADE_ROADMAP.md          # Package upgrade strategy
└── PRIORITY1_UPDATES.md                # Completed updates
```

### Running Tests

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Watch mode
flutter test --watch
```

### Code Generation

Generate models, routes, and providers:

```bash
# One-time build
flutter pub run build_runner build

# Watch mode (auto-rebuild)
flutter pub run build_runner watch

# Clean & rebuild (fixes conflicts)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Code Analysis

```bash
# Analyze code for issues
flutter analyze

# Format code
dart format lib/

# Check for unused imports
dart fix --apply
```

---

## Environment Configuration

### Flavors (Environments)

App supports 3 environments via flavors:

#### Development (Local)
```bash
flutter run -t lib/main_dev.dart
# or just: flutter run (default)
```
- Base URL: `http://localhost:3000/api`
- Debug mode: ON
- Hot reload: ✅ enabled

#### Staging
```bash
flutter run -t lib/main_staging.dart
```
- Base URL: `https://staging-api.example.com/api`
- Debug mode: OFF
- Firebase: staging configuration

#### Production
```bash
flutter run -t lib/main_production.dart
```
- Base URL: `https://api.example.com/api`
- Debug mode: OFF
- Firebase: production configuration

### Changing Configuration

Edit `lib/core/config/app_config.dart`:

```dart
static const staging = AppConfig(
  baseUrl: 'https://new-api.example.com/api',  // ← Change here
  apiVersion: 'v1',
  environment: 'staging',
  debugMode: false,
);
```

Then run:
```bash
flutter run -t lib/main_staging.dart
```

See [ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md) for details.

---

## Building for Release

### Android APK/AAB

```bash
# APK (for testing)
flutter build apk -t lib/main_production.dart --release

# AAB (for Play Store)
flutter build appbundle -t lib/main_production.dart --release
```

### iOS IPA

```bash
flutter build ios -t lib/main_production.dart --release
```

### Web

```bash
flutter build web -t lib/main_production.dart --release
```

---

## Core Libraries

| Library | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | 2.5.1 | State management & DI |
| `go_router` | 14.8.0 | Navigation & routing |
| `dio` | 5.10.0 | HTTP client |
| `hive` | 2.2.3 | Offline storage |
| `firebase_core` | 2.32.0 | Firebase platform |
| `firebase_messaging` | 14.9.4 | Push notifications |
| `freezed` | 2.5.2 | Code generation |
| `fpdart` | 1.1.0 | Functional programming (Either/Option) |

See [DEPENDENCY_AUDIT.md](docs/DEPENDENCY_AUDIT.md) for upgrade roadmap.

---

## Architecture

### Clean Architecture Pattern

```
Domain Layer (Business Logic)
  ├── Entities (immutable data models)
  ├── Repositories (abstract interfaces)
  └── UseCases (application logic)
        ↓
Data Layer (Fetching & Storage)
  ├── Models (JSON serializable)
  ├── DataSources (local/remote)
  └── Repository Implementations
        ↓
Presentation Layer (UI)
  ├── Pages (screens)
  ├── Widgets (reusable components)
  └── Providers (Riverpod state)
```

### Adding New Feature

1. **Domain Layer** → Create entities, repositories, usecases
2. **Data Layer** → Implement models, datasources, repository impl
3. **Presentation Layer** → Create pages, widgets, providers
4. **Routing** → Add route in `app_router.dart`

See [CLEAN_ARCHITECTURE.md](docs/CLEAN_ARCHITECTURE.md) for detailed guide.

---

## Responsive Design

App adapts to all screen sizes:

- **Mobile** (< 600px): Bottom navigation, single-column layout
- **Tablet** (600-1200px): Sidebar navigation, 2-column layout
- **Desktop** (≥ 1200px): Extended sidebar, 4-column layout, constrained width

Use adaptive widgets:
```dart
AdaptiveSliverGrid(
  mobileColumns: 1,
  tabletColumns: 2,
  desktopColumns: 4,
  children: [...],
);
```

See [ADAPTIVE_LAYOUTS.md](docs/ADAPTIVE_LAYOUTS.md) for patterns.

---

## Push Notifications (Firebase)

### Setup

1. Configure Firebase in Firebase Console
2. Download `google-services.json` (Android) & `GoogleService-Info.plist` (iOS)
3. Platform-specific setup (see [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md))

### Usage

```dart
// Get FCM token
final token = await ref.watch(fcmTokenProvider);

// Subscribe to topic
await subscribeToTopic(ref, 'news');

// Handle notifications
// Foreground: customize in FirebaseService._handleForegroundMessage()
// Background: customize in FirebaseService._handleBackgroundMessage()
// Tap: customize in FirebaseService._handleNotificationTap()
```

See [FIREBASE_QUICK_START.md](docs/FIREBASE_QUICK_START.md) for quick reference.

---

## Package Management

### Current Packages

All packages maintained & up-to-date. Recently migrated:
- `dartz` 0.10.1 → `fpdart` 1.1.0 (active maintenance)
- Removed: `either_dart` (unused)

### Upgrade Plan

**Priority 1** (Ready): dio, formz, cached_network_image
**Priority 2** (Blocked): Requires hive_generator update
**Priority 3** (Soon): Linters (flutter_lints, lints)
**Priority 4** (Next): freezed 3.x, Firebase 4.x
**Priority 5** (Future): Riverpod 3.x, Go Router 17.x

See [PACKAGE_UPGRADE_ROADMAP.md](docs/PACKAGE_UPGRADE_ROADMAP.md).

---

## Troubleshooting

### Build Errors

```bash
# Clean everything
flutter clean
flutter pub get

# Rebuild code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Rebuild native code
flutter pub get
flutter run
```

### "No implementation found for method..."

App uses Hive (local storage). On web/emulator, ensure `hive_flutter` initialization completes.

See [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md#troubleshooting) for Firebase-specific issues.

### Port Already in Use (Dev Server)

```bash
# Run on different port
flutter run --host 127.0.0.1 --device-vmservice-port 12345
```

### Locale/Internationalization Not Loading

Generated files located at `lib/l10n/app_localizations*.dart`. If missing:

```bash
flutter pub get
flutter gen-l10n
flutter pub run build_runner build
```

---

## Git Workflow

### Allowed Operations
✅ `git log`, `git status`, `git diff`, `git show`
✅ `git add`, `git commit`, `git push`

### Forbidden Operations
❌ `git reset --hard` (destructive)
❌ `git push --force` (overwrites remote)
❌ `git rebase -i` (interactive)
❌ `git checkout .` (discard changes)

See [AGENTS.md](docs/AGENTS.md) for rules.

---

## Documentation

| Document | Content |
|----------|---------|
| [AGENTS.md](docs/AGENTS.md) | Project rules, stack, git operations |
| [CLEAN_ARCHITECTURE.md](docs/CLEAN_ARCHITECTURE.md) | Architecture guide with examples |
| [ADAPTIVE_LAYOUTS.md](docs/ADAPTIVE_LAYOUTS.md) | Responsive UI patterns |
| [ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md) | Flavor setup (implemented) |
| [FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md) | Firebase & push notifications |
| [DEPENDENCY_AUDIT.md](docs/DEPENDENCY_AUDIT.md) | Package audit & migrations |
| [PACKAGE_UPGRADE_ROADMAP.md](docs/PACKAGE_UPGRADE_ROADMAP.md) | Upgrade strategy |

---

## Contributing

1. **Read** [AGENTS.md](docs/AGENTS.md) for rules & architecture
2. **Follow** [CLEAN_ARCHITECTURE.md](docs/CLEAN_ARCHITECTURE.md) when adding features
3. **Use** flavors for environment-specific testing
4. **Run** tests before committing: `flutter test`
5. **Analyze** code: `flutter analyze`

---

## Version Info

- **Dart SDK:** ≥ 3.2.0, < 4.0.0
- **Flutter:** Latest stable
- **Riverpod:** 2.5.1 (3.x available next quarter)
- **Go Router:** 14.8.0 (17.x available next quarter)

---

## Support

- 📖 See [docs/](docs/) for detailed guides
- 🔍 Check [AGENTS.md](docs/AGENTS.md) for architecture & rules
- 🚀 See [ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md) for multi-env setup
