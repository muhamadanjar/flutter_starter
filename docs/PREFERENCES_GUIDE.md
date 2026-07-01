# Preferences System Guide

Type-safe preference storage using Hive + Riverpod for persistent user settings, auth tokens, and app configuration.

## Architecture

```
Pref<T>
  └─ Generic type-safe wrapper
  └─ Handles get/put/stream/delete

PrefGroup
  └─ Base class for grouping related preferences
  └─ Manages Hive box initialization

UserPref
  └─ Concrete implementation
  └─ Auth, UI, features, FCM preferences

Riverpod Providers
  └─ Dependency injection
  └─ Reactive streams
```

## Installation

Already integrated in: `lib/core/storage/preferences/`

```dart
import 'package:enterprise_flutter_app/core/storage/preferences/index.dart';
```

## Quick Start

### Initialize (in main_common.dart)

```dart
Future<void> mainCommon(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize preferences
  final userPref = UserPref();
  await userPref.initBox();
  
  // Rest of initialization...
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        userPrefProvider.overrideWithValue(userPref),
      ],
      child: const App(),
    ),
  );
}
```

## Usage Patterns

### Pattern 1: Synchronous Read (Simple)

```dart
// Get current value immediately
final userId = ref.watch(userPrefProvider).userId.get();
print('User ID: $userId');
```

### Pattern 2: Reactive Watch (Recommended)

```dart
@riverpod
String userId(UserIdRef ref) {
  return ref.watch(userIdStreamProvider).maybeWhen(
    data: (id) => id,
    orElse: () => '',
  );
}

// Use in widget
Consumer(
  builder: (context, ref, child) {
    final id = ref.watch(userIdProvider);
    return Text('ID: $id');
  },
);
```

### Pattern 3: Write (Imperative)

```dart
final userPref = ref.watch(userPrefProvider);
await userPref.username.put('john_doe');
await userPref.darkMode.put(true);
```

### Pattern 4: Listen for Changes

```dart
userPref.darkMode.stream().listen((isDark) {
  print('Theme changed: $isDark');
});
```

## API Reference

### Pref<T> Methods

```dart
T get()                          // Read synchronously
Future<void> put(T value)        // Write value
Stream<T> stream()               // Watch for changes
Future<void> delete()            // Remove preference
bool exists()                    // Check if exists
```

### PrefGroup Methods

```dart
Future<void> initBox()                    // Initialize Hive box
Pref<T> pref<T>(String key, T default)   // Create typed pref
Future<void> clear()                      // Clear all prefs
Future<void> close()                      // Close box
```

### UserPref Properties

**Auth (6)**
```dart
userId         // Current user ID
username       // Login username
email          // User email
accessToken    // JWT token
refreshToken   // Refresh token
isLoggedIn     // Login state
```

**UI (3)**
```dart
darkMode       // Theme mode
locale         // Language/locale
fontSize       // Font size preference
```

**Features (4)**
```dart
notificationsEnabled   // Push notifications
biometricEnabled       // Fingerprint/Face ID
autoSync               // Auto sync data
analyticsEnabled       // Analytics tracking
```

**FCM (2)**
```dart
fcmToken       // Firebase Cloud Messaging token
fcmTokenUpdatedAt  // Token update timestamp
```

## Common Use Cases

### Use Case 1: Save Login State

```dart
// Login
final userPref = ref.watch(userPrefProvider);
await userPref.username.put('john_doe');
await userPref.userId.put('user123');
await userPref.accessToken.put(jwtToken);
await userPref.isLoggedIn.put(true);

// Check if logged in
final isLoggedIn = userPref.isLoggedIn.get();
```

### Use Case 2: Handle Theme Changes

```dart
// Save preference
await userPref.darkMode.put(true);

// Watch for changes
@riverpod
bool isDarkMode(IsDarkModeRef ref) {
  return ref.watch(darkModeStreamProvider).maybeWhen(
    data: (isDark) => isDark,
    orElse: () => true,
  );
}
```

### Use Case 3: Logout (Clear Auth)

```dart
// Clear auth data only
await userPref.clearAuth();

// App continues, user preferences retained
```

### Use Case 4: App Reset

```dart
// Clear everything
await userPref.clearAll();
```

### Use Case 5: FCM Token Management

```dart
// Save token
final token = await messaging.getToken();
await userPref.fcmToken.put(token);
await userPref.fcmTokenUpdatedAt.put(DateTime.now().millisecondsSinceEpoch);

// Retrieve token
final currentToken = userPref.fcmToken.get();
```

### Use Case 6: Check Preferences for Features

```dart
// Feature gates
if (userPref.notificationsEnabled.get()) {
  // Show notification settings
}

if (userPref.biometricEnabled.get()) {
  // Show biometric auth option
}
```

## Riverpod Providers

### Read Preference

```dart
// Singleton
final userPref = ref.watch(userPrefProvider);

// Initialize
await ref.watch(initUserPrefProvider.future);
```

### Stream Providers (Reactive)

```dart
// Auth streams
ref.watch(userIdStreamProvider)
ref.watch(usernameStreamProvider)
ref.watch(accessTokenStreamProvider)
ref.watch(isLoggedInStreamProvider)

// UI streams
ref.watch(darkModeStreamProvider)
ref.watch(localeStreamProvider)
ref.watch(fontSizeStreamProvider)

// Feature streams
ref.watch(notificationsEnabledStreamProvider)
ref.watch(biometricEnabledStreamProvider)
ref.watch(fcmTokenStreamProvider)
```

## Integration Examples

### Auth Flow Integration

```dart
// In auth_repository_impl.dart
@override
Future<Either<Failure, User>> login({
  required String username,
  required String password,
}) async {
  // API call...
  
  // Save tokens
  final userPref = UserPref();
  await userPref.username.put(username);
  await userPref.accessToken.put(response.token);
  await userPref.refreshToken.put(response.refreshToken);
  await userPref.isLoggedIn.put(true);
  
  return right(user);
}
```

### Settings Integration

```dart
// In settings_provider.dart
@riverpod
Future<void> updateTheme(UpdateThemeRef ref, bool isDark) async {
  final userPref = ref.watch(userPrefProvider);
  await userPref.darkMode.put(isDark);
}

@riverpod
bool currentTheme(CurrentThemeRef ref) {
  return ref.watch(darkModeStreamProvider).maybeWhen(
    data: (isDark) => isDark,
    orElse: () => true,
  );
}
```

### Firebase Integration

```dart
// In firebase_service.dart
Future<void> updateFCMToken(String token) async {
  final userPref = UserPref();
  await userPref.fcmToken.put(token);
  await userPref.fcmTokenUpdatedAt.put(DateTime.now().millisecondsSinceEpoch);
  
  // Send to backend
  await sendTokenToBackend(token);
}
```

## Testing

### Unit Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('UserPref', () {
    late UserPref userPref;
    
    setUpAll(() async {
      await Hive.initFlutter();
    });
    
    setUp(() async {
      userPref = UserPref();
      await userPref.initBox();
    });
    
    tearDown(() async {
      await userPref.clear();
      await userPref.close();
    });
    
    test('save and retrieve username', () async {
      await userPref.username.put('john_doe');
      expect(userPref.username.get(), 'john_doe');
    });
    
    test('stream emits changes', (WidgetTester tester) async {
      final stream = userPref.darkMode.stream();
      
      unawaited(expectLater(
        stream,
        emitsInOrder([true, false]),
      ));
      
      await userPref.darkMode.put(false);
    });
    
    test('clearAuth removes auth data only', () async {
      await userPref.username.put('john_doe');
      await userPref.darkMode.put(true);
      
      await userPref.clearAuth();
      
      expect(userPref.username.get(), '');
      expect(userPref.darkMode.get(), true); // Retained
    });
  });
}
```

### Widget Test

```dart
testWidgets('Theme preference persists', (WidgetTester tester) async {
  final userPref = UserPref();
  await userPref.initBox();
  
  await userPref.darkMode.put(true);
  
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userPrefProvider.overrideWithValue(userPref),
      ],
      child: const App(),
    ),
  );
  
  expect(find.byType(DarkTheme), findsWidgets);
});
```

## Best Practices

### ✅ DO

```dart
// ✅ Use reactive streams for UI updates
ref.watch(darkModeStreamProvider).when(
  data: (isDark) => buildTheme(isDark),
  loading: () => buildDefault(),
  error: (e, st) => buildDefault(),
)

// ✅ Use typed Pref<T> for type safety
final pref = Pref<bool>(box, 'key', false);

// ✅ Initialize in main
await userPref.initBox();

// ✅ Use clearAuth() for logout
await userPref.clearAuth();

// ✅ Handle errors
try {
  await userPref.username.put('value');
} catch (e) {
  print('Error saving: $e');
}
```

### ❌ DON'T

```dart
// ❌ Don't use box.put directly
box.put('key', value);  // Use userPref.userId.put(value)

// ❌ Don't use dynamic
final data = box.get('key');  // Use Pref<T>

// ❌ Don't forget to initialize
// await userPref.initBox();  // Required!

// ❌ Don't mix sync/async without care
final token = userPref.accessToken.get();  // Might be stale
ref.watch(accessTokenStreamProvider);      // Use this instead

// ❌ Don't keep box references
// late Box box = await Hive.openBox('name');  // Use PrefGroup
```

## Troubleshooting

### Issue: "Box not found"

**Cause:** initBox() not called

```dart
// Fix
final userPref = UserPref();
await userPref.initBox();  // Required before use
```

### Issue: Type mismatch on read

**Cause:** Wrong type or corrupted data

```dart
// Fix: Use try-catch
T get() {
  try {
    return box.get(key, defaultValue: defaultValue) as T;
  } catch (e) {
    return defaultValue;  // Return default on error
  }
}
```

### Issue: Stream not updating

**Cause:** Not watching stream provider

```dart
// Wrong
final isDark = userPref.darkMode.get();  // Static value

// Right
final isDark = ref.watch(darkModeStreamProvider);  // Reactive
```

### Issue: Data persists after logout

**Cause:** Using clearAll() instead of clearAuth()

```dart
// Only clear auth
await userPref.clearAuth();

// Full reset (if needed)
await userPref.clearAll();
```

## File Structure

```
lib/core/storage/preferences/
├── pref.dart                  # Generic wrapper
├── pref_group.dart            # Base class
├── user_pref.dart             # Implementation
├── pref_providers.dart        # Riverpod DI
└── index.dart                 # Exports
```

## Migration from Old System

If migrating from older preference system:

```dart
// Old
import 'package:enterprise_flutter_app/data/user_pref.dart';

// New
import 'package:enterprise_flutter_app/core/storage/preferences/index.dart';

// Usage same, better type safety and Riverpod integration
final userPref = ref.watch(userPrefProvider);
```

## Performance Tips

1. **Lazy initialization:** Initialize only when needed
2. **Stream debouncing:** Use .distinct() on streams
3. **Batch updates:** Multiple puts should await in sequence
4. **Close boxes:** Call close() on app exit (optional, handles automatically)

## Security Considerations

⚠️ **Hive is not encrypted.** For sensitive data:

```dart
// Store tokens securely
// Use flutter_secure_storage for highly sensitive data
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Use Hive for preferences (non-sensitive)
// Use flutter_secure_storage for tokens/passwords
```

## Related Documentation

- [Clean Architecture](CLEAN_ARCHITECTURE.md)
- [Firebase Setup](FIREBASE_SETUP.md)
- [Semantic Versioning](SEMANTIC_VERSIONING.md)

## Support

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for troubleshooting or [AGENTS.md](AGENTS.md) for architecture questions.
