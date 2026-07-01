# Logging Management Guide

Centralized logging system using `logger` package with Riverpod integration.

## Architecture

```
LoggerManager (Singleton)
  └─ Logger instance (logger package)
  
LoggerProvider (Riverpod)
  ├─ loggerManagerProvider → Singleton
  └─ logNotifierProvider → Logging operations
```

## Installation

Already added to `pubspec.yaml`:
```yaml
dependencies:
  logger: ^2.3.0
```

## Quick Start

### Global Access

```dart
import 'package:enterprise_flutter_app/core/logger/index.dart';

// Use directly
log.d('Debug message');
log.i('Info message');
log.w('Warning message');
log.e('Error message', error, stackTrace);
```

### Riverpod Access

```dart
@riverpod
void logMessage(LogMessageRef ref) {
  final logNotifier = ref.watch(logNotifierProvider.notifier);
  logNotifier.d('Message via Riverpod');
}
```

## Log Levels

```dart
LogLevel.verbose  // All messages
LogLevel.debug    // Debug+
LogLevel.info     // Info+
LogLevel.warning  // Warning+
LogLevel.error    // Errors only
```

## Usage Examples

### Example 1: API Call Logging

```dart
@riverpod
Future<User> fetchUser(FetchUserRef ref) async {
  final dio = ref.watch(dioClientProvider);
  
  log.d('Fetching user...');
  
  try {
    final response = await dio.get('/users/me');
    log.i('User fetched: ${response.data}');
    return User.fromJson(response.data);
  } catch (e, st) {
    log.e('Failed to fetch user', e, st);
    rethrow;
  }
}
```

### Example 2: State Changes

```dart
@riverpod
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.initial());
  
  Future<void> login(String username, String password) async {
    log.d('Attempting login for: $username');
    
    try {
      // Login logic...
      log.i('Login successful');
      state = const AuthState.authenticated();
    } catch (e) {
      log.e('Login failed', e);
      state = AuthState.error(e.toString());
    }
  }
}
```

### Example 3: Feature Tracking

```dart
void trackFeatureUsage(String feature) {
  log.i('Feature used: $feature');
  // Can be extended for analytics
}

Consumer(
  builder: (context, ref, child) {
    return GestureDetector(
      onTap: () {
        trackFeatureUsage('button_tap');
      },
      child: child,
    );
  },
);
```

### Example 4: Error Handler

```dart
void handleError(Object error, StackTrace stackTrace) {
  log.e(
    'Unhandled exception',
    error,
    stackTrace,
  );
  
  // Could send to Sentry, etc.
  // reportToSentry(error, stackTrace);
}

// In main:
void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    handleError(details.exception, details.stack ?? StackTrace.current);
  };
}
```

### Example 5: Set Log Level by Environment

```dart
void mainCommon(AppConfig config) async {
  // Initialize logger with environment-based level
  final logLevel = config.debugMode 
    ? LogLevel.debug 
    : LogLevel.warning;
  
  LoggerManager().setMinLevel(logLevel);
  
  log.i('App started in ${config.environment} mode');
}
```

## API Reference

### LoggerManager Methods

```dart
log.v(String message, [error, stackTrace])    // Verbose
log.d(String message, [error, stackTrace])    // Debug
log.i(String message, [error, stackTrace])    // Info
log.w(String message, [error, stackTrace])    // Warning
log.e(String message, [error, stackTrace])    // Error

log.setMinLevel(LogLevel level)               // Set minimum level
LogLevel minLevel = log.minLevel               // Get level
```

### Riverpod Providers

```dart
// Get logger manager
final manager = ref.watch(loggerManagerProvider);

// Log via notifier
final notifier = ref.watch(logNotifierProvider.notifier);
notifier.d('Message');

// Set log level
ref.watch(setLogLevelProvider)(LogLevel.info);
```

## Console Output Format

```
┌─────────────────────────────────────────────────────────────────────────────
│ 🐛  MyFeature | main                                      main.dart:123
├─────────────────────────────────────────────────────────────────────────────
│ Debug message here
└─────────────────────────────────────────────────────────────────────────────

┌─────────────────────────────────────────────────────────────────────────────
│ 🔴  MyError | onError                                     handler.dart:45
├─────────────────────────────────────────────────────────────────────────────
│ Exception: Something failed
│ StackTrace:
│ #0 main (file:///app/main.dart:123)
└─────────────────────────────────────────────────────────────────────────────
```

## Integration Points

### 1. Network Layer

```dart
// In dio_client.dart
InterceptorsWrapper _logInterceptor() {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      log.d('→ ${options.method} ${options.path}');
      handler.next(options);
    },
    onResponse: (response, handler) {
      log.d('← ${response.statusCode} ${response.requestOptions.path}');
      handler.next(response);
    },
    onError: (error, handler) {
      log.e('✗ ${error.message}', error);
      handler.next(error);
    },
  );
}
```

### 2. State Management

```dart
// In providers
@riverpod
class MyProvider extends StateNotifier<MyState> {
  void updateState(NewState state) {
    log.d('State changed: ${this.state} → $state');
    this.state = state;
  }
}
```

### 3. Local Storage

```dart
// In preferences
Future<void> put(T value) async {
  log.d('Saving $key = $value');
  await box.put(key, value);
}
```

### 4. Error Handling

```dart
// In repository
catch (e, st) {
  log.e('Repository error', e, st);
  return left(ServerFailure(message: e.toString()));
}
```

## Best Practices

### ✅ DO

```dart
// ✅ Log with context
log.d('Fetching user #123');
log.e('Login failed', exception, stackTrace);

// ✅ Use appropriate levels
log.d('Debug info');     // Development
log.i('User logged in'); // Important events
log.w('Deprecated API'); // Warnings
log.e('Crash', e, st);   // Errors

// ✅ Include stack trace on errors
log.e('Failed to save', error, StackTrace.current);

// ✅ Use global log object
log.d('Message');
```

### ❌ DON'T

```dart
// ❌ Print for logging
print('Debug message');  // Use log.d instead

// ❌ Bare exceptions
catch (e) {
  log.e('Error: $e');   // Missing stackTrace
}

// ❌ PII in logs
log.d('Password: $password');  // Sensitive data!

// ❌ Always verbose level
LoggerManager().setMinLevel(LogLevel.verbose);  // Production!
```

## Environment Configuration

### Development

```dart
// Full logging
LoggerManager().setMinLevel(LogLevel.verbose);
// Output: All messages with colors and details
```

### Staging

```dart
// Debug level
LoggerManager().setMinLevel(LogLevel.debug);
// Output: Debug and above
```

### Production

```dart
// Warning level only
LoggerManager().setMinLevel(LogLevel.warning);
// Output: Warnings and errors only
```

## Extending Logger

### Add Custom Printer

```dart
class CustomPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    // Custom formatting
    return ['Custom: ${event.message}'];
  }
}

// Update LoggerManager._initLogger():
_logger = Logger(
  printer: CustomPrinter(),
);
```

### Add File Logging

```dart
// Add to pubspec.yaml
dependencies:
  logger: ^2.3.0
  file_logger: ^0.1.0

// In LoggerManager:
import 'package:file_logger/file_logger.dart';

void _initLogger() {
  final fileLogger = FileLogger(
    directoryName: 'logs',
    fileName: 'app_${DateTime.now().toIso8601String()}.log',
  );
  
  _logger.addOutput(fileLogger);
}
```

### Send to Remote Service

```dart
// Add Sentry integration
class SentryOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    if (event.level == Level.error) {
      Sentry.captureException(
        Exception(event.lines.join()),
      );
    }
  }
}

// In LoggerManager:
_logger.addOutput(SentryOutput());
```

## Performance

- **Minimal overhead** in production (warning level)
- **Zero cost** when log level filters message
- **Synchronous** (non-blocking)
- **No network calls** (local only)

## Testing

```dart
test('Logger logs messages', () {
  final logger = LoggerManager();
  logger.setMinLevel(LogLevel.debug);
  
  // Logs will appear in test output
  logger.d('Test message');
  
  // Assertions on state...
});
```

## Migration from Other Loggers

If migrating from `debugPrint`:

```dart
// Old
debugPrint('Message');

// New
log.d('Message');
log.i('Important info');
log.w('Warning');
log.e('Error', error, stackTrace);
```

## File Structure

```
lib/core/logger/
├── logger_manager.dart   (Singleton + methods)
├── logger_provider.dart  (Riverpod providers)
└── index.dart           (Exports)
```

## Related Documentation

- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md) - Error handling patterns
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Debugging tips
- [AGENTS.md](AGENTS.md) - Development rules

## Support

For issues, see Logger package: https://pub.dev/packages/logger
