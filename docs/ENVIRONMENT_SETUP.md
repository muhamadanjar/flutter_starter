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
    │   └── app_config.dart         → Validated runtime API config
    └── providers/
        └── config_provider.dart    → Riverpod provider
```

## Configuration Values

Each flavor loads a dedicated local file. The API values are required; startup
fails if a file is missing or a value is invalid. `debugMode` remains fixed by
the flavor: enabled for development and disabled for staging/production.

| Flavor | Loaded file | Environment | Debug mode |
| --- | --- | --- | --- |
| Development | `.env.dev` | `development` | enabled |
| Staging | `.env.staging` | `staging` | disabled |
| Production | `.env.production` | `production` | disabled |

Every file requires:

```env
API_BASE_URL=https://api.example.com
API_VERSION=v1
REQUEST_TIMEOUT_SECONDS=30
```

`API_BASE_URL` must be an HTTP(S) origin without a path, query, or fragment.
For example, use `https://api.example.com`, not `https://api.example.com/v1`.
The actual `.env.*` files are ignored by Git. Copy the matching committed
`.env.*.example` file before running a flavor.

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

Builds validated API configuration from the environment file selected by the
flavor:
```dart
// lib/core/config/app_config.dart
final config = AppConfig.fromDotEnv(
  environment: 'production',
  debugMode: false,
);
```

### 2. Flavor Entry Points

Minimal entry point for each flavor:
```dart
// lib/main_production.dart
Future<void> main() => mainCommon(
  environment: 'production',
  debugMode: false,
  envFile: '.env.production',
);
```

### 3. Common Initialization

Shared setup logic:
```dart
// lib/main_common.dart
Future<void> mainCommon({
  required String environment,
  required bool debugMode,
  required String envFile,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: envFile);
  final config = AppConfig.fromDotEnv(
    environment: environment,
    debugMode: debugMode,
  );
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

To change a config value, copy the relevant template if needed, then edit the
local environment file. For example, to configure staging:

```bash
cp .env.staging.example .env.staging
```

```env
# .env.staging
API_BASE_URL=https://new-staging-api.example.com
API_VERSION=v2
REQUEST_TIMEOUT_SECONDS=30
```

Do not put API URLs in Dart source. Restart the app after changing an
environment file; hot reload does not reload bundled assets.

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
  const config = AppConfig(
    baseUrl: 'https://api.example.com',
    apiVersion: 'v1',
    environment: 'production',
    debugMode: false,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
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
