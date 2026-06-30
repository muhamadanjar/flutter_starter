# Setup Guide

Complete setup instructions for new developers.

## Prerequisites

Before starting, ensure you have:

```bash
# Check Flutter version (3.2.0 - 4.0.0)
flutter --version

# Check Dart version (3.2.0+)
dart --version

# Optional: Android SDK (API 21+) or Xcode (iOS 11.0+)
flutter doctor
```

If issues appear, run: `flutter doctor -v` to diagnose.

---

## First Time Setup

### Step 1: Clone Repository

```bash
git clone <repository-url>
cd enterprise_flutter_app
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

Expected output:
```
Running "flutter pub get" in enterprise_flutter_app...
Got dependencies! (X packages)
```

### Step 3: Generate Code

Generate models, routes, and providers:

```bash
flutter pub run build_runner build
```

Expected output:
```
Building package executable... (takes ~30 seconds)
[INFO] Generating build script...
[INFO] Generating build script completed...
[INFO] Building...
[INFO] Built assets/...
```

### Step 4: Verify Setup

Check for errors:

```bash
flutter analyze
```

Expected output:
```
Analyzing enterprise_flutter_app...
info • [lines of info messages]
```

**No `error` lines = success** ✅

---

## Running the App

### Development (Default)

```bash
flutter run
```

App starts with:
- Base URL: `http://localhost:3000/api`
- Debug mode: ON
- Features: All enabled

### Staging Environment

```bash
flutter run -t lib/main_staging.dart
```

App starts with:
- Base URL: `https://staging-api.example.com/api`
- Debug mode: OFF
- Firebase: staging config

### Production Environment

```bash
flutter run -t lib/main_production.dart
```

App starts with:
- Base URL: `https://api.example.com/api`
- Debug mode: OFF
- Firebase: production config

---

## Common Tasks

### Update Dependencies

```bash
# Check outdated packages
flutter pub outdated

# Update specific package
flutter pub add package_name:^new_version

# Update all
flutter pub upgrade
```

### Regenerate Code After Changes

When you modify:
- Models (with `@freezed`)
- Routes
- Riverpod providers
- Hive models

Run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or watch mode (auto-rebuild):
```bash
flutter pub run build_runner watch
```

### Run Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/features/auth/auth_test.dart

# Watch mode
flutter test --watch

# Coverage report
flutter test --coverage
```

### Format & Lint

```bash
# Format code
dart format lib/

# Check lints
flutter analyze

# Fix auto-fixable issues
dart fix --apply
```

### Clean Build

If you encounter strange issues:

```bash
flutter clean
flutter pub get
flutter pub run build_runner build
flutter run
```

---

## Project Structure Overview

### Layers (Clean Architecture)

```
features/
└── dashboard/
    ├── domain/              ← Business logic (pure Dart)
    │   ├── entities/        → UserEntity, DashboardEntity, etc.
    │   ├── repositories/    → Abstract DashboardRepository
    │   └── usecases/        → GetDashboardUseCase, etc.
    │
    ├── data/                ← Data fetching & storage
    │   ├── models/          → UserModel (extends entity)
    │   ├── datasources/     → Remote (Dio), Local (Hive)
    │   └── repositories/    → Concrete repository implementation
    │
    └── presentation/        ← UI & user interaction
        ├── pages/           → Full screens (DashboardPage)
        ├── widgets/         → Reusable components
        └── providers/       → Riverpod state management
```

### Core (Shared)

```
core/
├── config/          ← Environment configs (dev/staging/prod)
├── constants/       ← App & API constants
├── errors/          ← Exceptions & failures
├── network/         ← Dio client, connectivity
├── providers/       ← Global Riverpod providers
├── services/        ← Firebase, etc.
├── theme/           ← Colors, typography, themes
├── utils/           ← Extensions, validators
└── widgets/         ← Responsive builders, adaptive UI
```

---

## Adding a New Feature

### 1. Create Domain Layer

```bash
mkdir -p lib/features/myfeature/domain/{entities,repositories,usecases}
```

**lib/features/myfeature/domain/entities/my_entity.dart**
```dart
@freezed
class MyEntity with _$MyEntity {
  const factory MyEntity({
    required String id,
    required String name,
  }) = _MyEntity;
}
```

**lib/features/myfeature/domain/repositories/my_repository.dart**
```dart
abstract class MyRepository {
  Future<Either<Failure, List<MyEntity>>> getItems();
}
```

**lib/features/myfeature/domain/usecases/get_items_usecase.dart**
```dart
class GetItemsUseCase {
  final MyRepository repository;
  
  GetItemsUseCase(this.repository);
  
  Future<Either<Failure, List<MyEntity>>> call() {
    return repository.getItems();
  }
}
```

### 2. Create Data Layer

```bash
mkdir -p lib/features/myfeature/data/{models,datasources,repositories}
```

**lib/features/myfeature/data/models/my_model.dart**
```dart
@freezed
class MyModel extends MyEntity with _$MyModel {
  const factory MyModel({
    required String id,
    required String name,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

**lib/features/myfeature/data/repositories/my_repository_impl.dart**
```dart
class MyRepositoryImpl implements MyRepository {
  final MyRemoteDataSource remoteDataSource;

  MyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MyEntity>>> getItems() async {
    try {
      final items = await remoteDataSource.getItems();
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

### 3. Create Presentation Layer

```bash
mkdir -p lib/features/myfeature/presentation/{pages,widgets,providers}
```

**lib/features/myfeature/presentation/providers/my_provider.dart**
```dart
@riverpod
Future<List<MyEntity>> myItems(MyItemsRef ref) async {
  final repository = ref.watch(myRepositoryProvider);
  final result = await repository.getItems();
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (items) => items,
  );
}
```

**lib/features/myfeature/presentation/pages/my_page.dart**
```dart
class MyPage extends ConsumerWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(myItemsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('My Feature')),
      body: itemsAsync.when(
        data: (items) => ListView(
          children: items.map((item) => ListTile(title: Text(item.name))).toList(),
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

### 4. Add Route

**lib/app/router/app_router.dart**
```dart
GoRoute(
  path: '/myfeature',
  builder: (context, state) => const MyPage(),
),
```

### 5. Generate Code

```bash
flutter pub run build_runner build
flutter analyze
flutter run
```

---

## Environment Configuration

### Change Base URL

Edit **lib/core/config/app_config.dart**:

```dart
static const staging = AppConfig(
  baseUrl: 'https://new-url.com/api',  // ← Change here
  apiVersion: 'v1',
  environment: 'staging',
  debugMode: false,
);
```

Run:
```bash
flutter run -t lib/main_staging.dart
```

### Add New Config Value

1. Add field to `AppConfig`:
```dart
class AppConfig {
  final String newValue;
  // ...
}
```

2. Set in all flavors:
```dart
static const dev = AppConfig(
  baseUrl: '...',
  newValue: 'dev-value',
  // ...
);
```

3. Use in code:
```dart
final config = ref.watch(appConfigProvider);
print(config.newValue);
```

---

## Debugging

### Enable Debug Logging

In dev flavor, logging is enabled by default:

```bash
flutter run -v  # Verbose output
```

### Inspect Network Requests

Dio client logs all requests/responses. Check console output:

```
[DioLog] ↗ POST /auth/login
[DioLog] ↙ 200 OK
```

### Firebase Debugging

Check Firebase initialization:

```dart
// Already in main_common.dart
debugPrint('[Firebase] Initialized successfully');
```

### Hive Debugging

Check local storage:

```bash
flutter run -v | grep -i hive
```

---

## Building for Release

### Android

```bash
# APK (for testing)
flutter build apk -t lib/main_production.dart --release

# AAB (for Play Store)
flutter build appbundle -t lib/main_production.dart --release

# Output: build/app/outputs/
```

### iOS

```bash
flutter build ios -t lib/main_production.dart --release

# Output: build/ios/iphoneos/
```

### Web

```bash
flutter build web -t lib/main_production.dart --release

# Output: build/web/
```

---

## Troubleshooting

### "flutter: command not found"

Flutter SDK not in PATH:

```bash
# Find Flutter installation
which flutter

# Add to PATH (bash)
export PATH="$PATH:/path/to/flutter/bin"

# Verify
flutter --version
```

### "MissingPluginException"

Plugin not available on current platform:

```bash
flutter pub get
flutter clean
flutter run
```

### "Gradle build failed" (Android)

```bash
cd android
./gradlew clean
cd ..
flutter run
```

### "Pod install failed" (iOS)

```bash
cd ios
rm -rf Pods
pod install
cd ..
flutter run
```

### Code Generation Not Running

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Port Already in Use

```bash
flutter run --device-vmservice-port 12345
```

---

## Next Steps

1. ✅ Complete setup above
2. 📖 Read [AGENTS.md](AGENTS.md) for rules & architecture
3. 🏗️ Read [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md) for patterns
4. 🎯 Start adding features using pattern from "Adding a New Feature"
5. 🧪 Write tests for domain/data layers
6. 📤 Create PR following git rules

---

## Resources

| Resource | Link |
|----------|------|
| Flutter Docs | https://flutter.dev/docs |
| Riverpod Docs | https://riverpod.dev |
| Go Router Docs | https://pub.dev/packages/go_router |
| Clean Architecture | https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html |
| Effective Dart | https://dart.dev/guides/language/effective-dart |

---

## Getting Help

- **Architecture questions?** → See [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- **Build error?** → See Troubleshooting section above
- **Setup issue?** → See [AGENTS.md](AGENTS.md)
- **Environment config?** → See [ENVIRONMENT_SETUP.md](ENVIRONMENT_SETUP.md)
- **Firebase?** → See [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

---

## Checklist (First Time)

- [ ] Cloned repository
- [ ] Ran `flutter pub get`
- [ ] Ran `flutter pub run build_runner build`
- [ ] Ran `flutter analyze` (no errors)
- [ ] Ran `flutter run` (app launches)
- [ ] Read [AGENTS.md](AGENTS.md)
- [ ] Read [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [ ] Ready to start developing ✅
