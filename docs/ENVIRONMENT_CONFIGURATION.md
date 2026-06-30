# Environment Configuration Guide

Flutter best practices for managing base URLs, API endpoints, and environment-specific settings.

## Problem: Why NOT .env in Flutter?

### ❌ `.env` Approach (Not Recommended)

```
❌ No native .env support in Flutter
❌ Manual parsing required
❌ Secrets easily leaked to Git
❌ Build artifacts include all values
❌ Complex build process
❌ Not indexed by Dart compiler
```

### ✅ Recommended: Flavors + dart-define

```
✅ Native Dart feature
✅ Compile-time constants (tree-shaken)
✅ Secure build args
✅ Multiple config files per flavor
✅ Platform-native support (iOS/Android)
✅ Indexed by Dart analyzer
```

---

## Solution 1: Flavors (Recommended for Production)

Create separate build flavors for dev/staging/production with different configurations.

### 1.1 Create Flavor Config File

**lib/core/config/app_config.dart**

```dart
class AppConfig {
  final String baseUrl;
  final String apiVersion;
  final String environment;
  final bool debugMode;
  final Duration requestTimeout;

  const AppConfig({
    required this.baseUrl,
    required this.apiVersion,
    required this.environment,
    required this.debugMode,
    this.requestTimeout = const Duration(seconds: 30),
  });

  // Dev environment
  static const dev = AppConfig(
    baseUrl: 'http://localhost:3000/api',
    apiVersion: 'v1',
    environment: 'development',
    debugMode: true,
  );

  // Staging environment
  static const staging = AppConfig(
    baseUrl: 'https://staging-api.example.com/api',
    apiVersion: 'v1',
    environment: 'staging',
    debugMode: false,
  );

  // Production environment
  static const production = AppConfig(
    baseUrl: 'https://api.example.com/api',
    apiVersion: 'v1',
    environment: 'production',
    debugMode: false,
  );

  /// Get config based on flavor
  factory AppConfig.fromFlavor(String flavor) {
    switch (flavor) {
      case 'dev':
        return dev;
      case 'staging':
        return staging;
      case 'production':
        return production;
      default:
        return dev;
    }
  }
}
```

### 1.2 Update main.dart

```dart
// main_dev.dart
import 'package:enterprise_flutter_app/main_common.dart';
import 'package:enterprise_flutter_app/core/config/app_config.dart';

void main() {
  mainCommon(AppConfig.dev);
}

// main_staging.dart
import 'package:enterprise_flutter_app/main_common.dart';
import 'package:enterprise_flutter_app/core/config/app_config.dart';

void main() {
  mainCommon(AppConfig.staging);
}

// main_production.dart
import 'package:enterprise_flutter_app/main_common.dart';
import 'package:enterprise_flutter_app/core/config/app_config.dart';

void main() {
  mainCommon(AppConfig.production);
}

// main_common.dart (shared initialization)
Future<void> mainCommon(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await _initializeHive();

  // Initialize Firebase
  await _initializeFirebase();

  // Store config in Riverpod
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const App(),
    ),
  );
}
```

### 1.3 Create Riverpod Provider

```dart
// lib/core/providers/config_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden');
});
```

### 1.4 Use in DIO Client

```dart
// lib/core/network/dio_client.dart
@riverpod
Dio dioClient(DioClientRef ref) {
  final config = ref.watch(appConfigProvider);

  return Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.requestTimeout,
      receiveTimeout: config.requestTimeout,
      headers: {
        'Accept': 'application/json',
        'X-API-Version': config.apiVersion,
      },
    ),
  );
}
```

### 1.5 Build Commands

```bash
# Development
flutter run -t lib/main_dev.dart

# Staging
flutter run -t lib/main_staging.dart

# Production
flutter run -t lib/main_production.dart

# Build APK
flutter build apk -t lib/main_production.dart --release

# Build IPA
flutter build ios -t lib/main_production.dart --release
```

---

## Solution 2: dart-define (For Build Arguments)

Pass configuration as build-time constants.

### 2.1 Create Config Class

```dart
// lib/core/config/build_config.dart
class BuildConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const String apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'v1',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );
}
```

### 2.2 Build Commands

```bash
# Development (local)
flutter run \
  --dart-define=BASE_URL=http://localhost:3000/api \
  --dart-define=API_VERSION=v1 \
  --dart-define=ENVIRONMENT=development \
  --dart-define=DEBUG_MODE=true

# Staging
flutter build apk --release \
  --dart-define=BASE_URL=https://staging-api.example.com/api \
  --dart-define=API_VERSION=v1 \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=DEBUG_MODE=false

# Production
flutter build apk --release \
  --dart-define=BASE_URL=https://api.example.com/api \
  --dart-define=API_VERSION=v1 \
  --dart-define=ENVIRONMENT=production \
  --dart-define=DEBUG_MODE=false
```

### 2.3 Use env File

**env/production.env**
```
BASE_URL=https://api.example.com/api
API_VERSION=v1
ENVIRONMENT=production
DEBUG_MODE=false
```

**env/staging.env**
```
BASE_URL=https://staging-api.example.com/api
API_VERSION=v1
ENVIRONMENT=staging
DEBUG_MODE=false
```

**Build with env file:**
```bash
flutter build apk --release \
  --dart-define-from-file=env/production.env
```

---

## Solution 3: Hybrid (Recommended)

Combine **flavors** (structure) + **dart-define** (secrets).

### 3.1 Architecture

```
lib/
├── main_dev.dart (imports main_common with AppConfig.dev)
├── main_staging.dart (imports main_common with AppConfig.staging)
├── main_production.dart (imports main_common with dart-define vars)
├── main_common.dart (shared initialization)
└── core/
    └── config/
        ├── app_config.dart (base config structure)
        └── build_config.dart (dart-define values)
```

### 3.2 Secure Secrets

**DO NOT** commit secrets to Git.

```bash
# Create .gitignore entry
echo "lib/core/config/secrets.dart" >> .gitignore

# Create secrets file (never commit)
# lib/core/config/secrets.dart
class ApiSecrets {
  static const String apiKey = String.fromEnvironment('API_KEY');
  static const String jwtSecret = String.fromEnvironment('JWT_SECRET');
}

# Build with secrets
flutter run --dart-define=API_KEY=xxx --dart-define=JWT_SECRET=yyy
```

### 3.3 Environment-Specific Secrets

**CI/CD Pipeline (GitHub Actions example)**

```yaml
# .github/workflows/build.yml
name: Build Production

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build APK
        run: |
          flutter build apk --release \
            --dart-define=BASE_URL=${{ secrets.PROD_BASE_URL }} \
            --dart-define=API_KEY=${{ secrets.PROD_API_KEY }} \
            --dart-define=ENVIRONMENT=production
```

---

## Comparison Table

| Feature | Flavors | dart-define | Hybrid |
|---------|---------|-------------|--------|
| **Setup** | 🟢 Simple | 🟡 Medium | 🟡 Medium |
| **Security** | 🟢 Good | 🟡 Requires care | 🟢 Best |
| **Multiple configs** | 🟢 Easy | 🟠 Command-line heavy | 🟢 Easy |
| **Production-ready** | 🟢 Yes | 🟢 Yes | 🟢 Yes |
| **Team friendly** | 🟢 Yes | 🟠 Complex CLI | 🟢 Yes |
| **Secrets management** | 🟠 Risky | 🟢 Safe (env-based) | 🟢 Safe (secrets) |

**Recommendation:** Use **Flavors + dart-define (Hybrid)**

---

## Implementation for enterprise_flutter_app

### Step 1: Create Config

**lib/core/config/app_config.dart**
```dart
class AppConfig {
  final String baseUrl;
  final String environment;
  final bool debugMode;

  const AppConfig({
    required this.baseUrl,
    required this.environment,
    required this.debugMode,
  });

  static const dev = AppConfig(
    baseUrl: 'http://localhost:3000/api',
    environment: 'dev',
    debugMode: true,
  );

  static const staging = AppConfig(
    baseUrl: 'https://staging-api.example.com/api',
    environment: 'staging',
    debugMode: false,
  );

  static const prod = AppConfig(
    baseUrl: 'https://api.example.com/api',
    environment: 'production',
    debugMode: false,
  );
}
```

### Step 2: Create main_*.dart files

**lib/main_dev.dart**
```dart
import 'package:enterprise_flutter_app/main_common.dart';
import 'package:enterprise_flutter_app/core/config/app_config.dart';

void main() => mainCommon(AppConfig.dev);
```

**lib/main_staging.dart**
```dart
import 'package:enterprise_flutter_app/main_common.dart';
import 'package:enterprise_flutter_app/core/config/app_config.dart';

void main() => mainCommon(AppConfig.staging);
```

**lib/main_production.dart**
```dart
import 'package:enterprise_flutter_app/main_common.dart';
import 'package:enterprise_flutter_app/core/config/app_config.dart';

void main() => mainCommon(AppConfig.prod);
```

### Step 3: Update main.dart → main_common.dart

Move current main() logic to mainCommon(), add config parameter.

### Step 4: Use Config in DIO

Update dio_client.dart to use baseUrl from config.

### Step 5: Build Commands

```bash
flutter run -t lib/main_dev.dart
flutter run -t lib/main_staging.dart
flutter build apk -t lib/main_production.dart --release
```

---

## Sensitive Data Handling

### ❌ DON'T

```dart
// ❌ Hardcoded secrets
const apiKey = 'sk_live_xyz123';
const jwtSecret = 'my-secret-key';
```

### ✅ DO

```dart
// ✅ Environment variables
class ApiSecrets {
  static const apiKey = String.fromEnvironment('API_KEY');
  static const jwtSecret = String.fromEnvironment('JWT_SECRET');
}

// Build:
// flutter run --dart-define=API_KEY=$API_KEY_ENV_VAR
```

### ✅ OR: Secure Storage

```dart
// ✅ Use Flutter Secure Storage for runtime secrets
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
final apiKey = await storage.read(key: 'api_key');
```

---

## Testing Configurations

```dart
// test/helpers/test_config.dart
final testConfig = AppConfig(
  baseUrl: 'http://localhost:8000/api',
  environment: 'test',
  debugMode: true,
);

// test/features/auth/auth_test.dart
testWidgets('Login flow', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(testConfig),
      ],
      child: const App(),
    ),
  );
  // Test...
});
```

---

## Summary

| Approach | Use Case |
|----------|----------|
| **Flavors** | Multiple versions (dev/staging/prod) |
| **dart-define** | Build-time configuration |
| **Hybrid** | Production apps with secrets + flavors |
| **Secure Storage** | Runtime secrets (tokens, API keys) |
| **Remote Config** | Dynamic configuration (Firebase) |

**Recommendation for enterprise_flutter_app:**
1. ✅ Implement Flavors (dev/staging/production)
2. ✅ Use dart-define for secrets in CI/CD
3. ✅ Use Secure Storage for user tokens
4. ✅ Never commit .env files
