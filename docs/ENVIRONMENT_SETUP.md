# Environment Configuration Setup (Implemented)

Flavor-based environment configuration for dev/staging/production.

## Architecture

```
lib/
├── main.dart              → exports main_dev.dart (default)
├── main_dev.dart          → Development flavor
├── main_staging.dart      → Staging flavor
├── main_production.dart   → Production flavor
├── main_common.dart       → Shared initialization
└── core/
    ├── config/
    │   └── app_config.dart         → Config definitions (dev/staging/prod)
    └── providers/
        └── config_provider.dart    → Riverpod provider
```

## Configuration Values

**Development (Local)**
```
Base URL: http://localhost:3000/api
API Version: v1
Environment: development
Debug Mode: true
Request Timeout: 30s
```

**Staging**
```
Base URL: https://staging-api.example.com/api
API Version: v1
Environment: staging
Debug Mode: false
Request Timeout: 30s
```

**Production**
```
Base URL: https://api.example.com/api
API Version: v1
Environment: production
Debug Mode: false
Request Timeout: 30s
```

## Usage

### Running Different Flavors

```bash
# Development (default)
flutter run

# Staging
flutter run -t lib/main_staging.dart

# Production
flutter run -t lib/main_production.dart
```

### Building for Release

```bash
# Android APK
flutter build apk -t lib/main_production.dart --release

# iOS IPA
flutter build ios -t lib/main_production.dart --release

# Web
flutter build web -t lib/main_production.dart --release
```

## How It Works

### 1. AppConfig Class

Defines configuration for each environment:
```dart
// lib/core/config/app_config.dart
static const production = AppConfig(
  baseUrl: 'https://api.example.com/api',
  apiVersion: 'v1',
  environment: 'production',
  debugMode: false,
);
```

### 2. Flavor Entry Points

Minimal entry point for each flavor:
```dart
// lib/main_production.dart
void main() => mainCommon(AppConfig.production);
```

### 3. Common Initialization

Shared setup logic:
```dart
// lib/main_common.dart
Future<void> mainCommon(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeHive();
  await _initializeFirebase();
  await _checkInitialConnectivity();

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

### 4. Usage in Code

Access config via Riverpod:
```dart
// lib/core/network/dio_client.dart
final dioClientProvider = Provider<DioClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return DioClient(
    config: config,
    // ...
  );
});
```

```dart
// Any widget
@riverpod
SomeData getData(GetDataRef ref) {
  final config = ref.watch(appConfigProvider);
  print('Environment: ${config.environment}');
  print('Base URL: ${config.baseUrl}');
  // Use config...
}
```

## Modifying Configuration

To change a config value, edit `lib/core/config/app_config.dart`:

```dart
static const staging = AppConfig(
  baseUrl: 'https://new-staging-api.example.com/api', // ← Change here
  apiVersion: 'v2', // ← Or here
  environment: 'staging',
  debugMode: false,
);
```

No need to hardcode URLs throughout the codebase.

## Adding New Config Values

1. Add field to `AppConfig` class:
```dart
class AppConfig {
  final String baseUrl;
  final String newValue; // ← Add here
  
  const AppConfig({
    required this.baseUrl,
    required this.newValue,
    // ...
  });
}
```

2. Update each flavor:
```dart
static const dev = AppConfig(
  baseUrl: '...',
  newValue: 'dev-value', // ← Set for dev
);

static const staging = AppConfig(
  baseUrl: '...',
  newValue: 'staging-value', // ← Set for staging
);

static const production = AppConfig(
  baseUrl: '...',
  newValue: 'prod-value', // ← Set for production
);
```

3. Use in code:
```dart
final config = ref.watch(appConfigProvider);
print(config.newValue);
```

## Best Practices

✅ **DO:**
- Store all environment-specific values in `AppConfig`
- Use Riverpod provider to access config
- Define new config values in all flavors consistently
- Document new config values with comments

❌ **DON'T:**
- Hardcode URLs in network calls
- Use `dart-define` for non-secret values (use AppConfig instead)
- Duplicate config logic across files
- Create environment checks scattered in code (use AppConfig)

## Security: Secrets Management

For sensitive values (API keys, tokens), use `dart-define` in build commands:

```bash
# Pass via CLI (CI/CD environment)
flutter build apk --release \
  --dart-define=API_KEY=${{ secrets.PROD_API_KEY }} \
  --dart-define=JWT_SECRET=${{ secrets.JWT_SECRET }}
```

Access in code:
```dart
class ApiSecrets {
  static const apiKey = String.fromEnvironment('API_KEY');
  static const jwtSecret = String.fromEnvironment('JWT_SECRET');
}
```

**Never** commit secrets to Git.

## Testing

Test with different configurations:

```dart
testWidgets('Login works in production config', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.production),
      ],
      child: const App(),
    ),
  );
  // Test...
});
```

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
# .github/workflows/build.yml
name: Build Production

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build APK
        run: |
          flutter build apk --release \
            -t lib/main_production.dart
      
      - name: Upload to Play Store
        run: |
          # Upload build/app/outputs/apk/release/app-release.apk
```

## Troubleshooting

### "appConfigProvider must be overridden"

**Problem:** Running without specifying a flavor

**Solution:** Use a flavor entry point:
```bash
flutter run -t lib/main_dev.dart  # ✅
flutter run                       # ❌ Uses main.dart which re-exports main_dev.dart
```

### Base URL not changing

**Problem:** Config not being used

**Solution:** Verify `DioClient` receives config:
```dart
// Check dio_client.dart has:
DioClient({
  required AppConfig config,  // ← Config parameter
  // ...
})
```

### Wrong environment in production build

**Problem:** Built with wrong flavor

**Solution:** Always specify flavor for release builds:
```bash
flutter build apk -t lib/main_production.dart --release  # ✅
flutter build apk --release                              # ❌
```

## Next Steps

1. Update backend API URLs when moving between environments
2. Add CI/CD integration to auto-build correct flavors
3. Consider adding feature flags (Firebase Remote Config)
4. Monitor which flavor is running in production (analytics)

## Files Modified/Created

| File | Status |
|------|--------|
| `lib/main.dart` | ✅ Updated (exports main_dev.dart) |
| `lib/main_common.dart` | ✅ Created (shared init) |
| `lib/main_dev.dart` | ✅ Created |
| `lib/main_staging.dart` | ✅ Created |
| `lib/main_production.dart` | ✅ Created |
| `lib/core/config/app_config.dart` | ✅ Created |
| `lib/core/providers/config_provider.dart` | ✅ Created |
| `lib/core/network/dio_client.dart` | ✅ Updated (uses config) |

All files compiled successfully. Ready to use.
