# Firebase Push Notifications Setup

Complete guide for setting up Firebase Cloud Messaging (FCM) for push notifications on Android, iOS, and Web.

## Prerequisites

- Firebase project created at [console.firebase.google.com](https://console.firebase.google.com)
- Android app registered in Firebase Console (with SHA-1 certificate)
- iOS app registered in Firebase Console (with APNs certificates)
- `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) downloaded

## Dependencies

```yaml
firebase_core: ^2.28.0
firebase_messaging: ^14.8.0
```

Already added to `pubspec.yaml`. Install:

```bash
flutter pub get
flutter pub run build_runner build
```

## Platform Setup

### Android Setup

1. **Download `google-services.json`**
   - Go to Firebase Console → Project Settings → General
   - Download `google-services.json`
   - Place in `android/app/` directory

2. **Update `android/build.gradle` (project-level)**

```gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
  }
}
```

3. **Update `android/app/build.gradle` (app-level)**

```gradle
apply plugin: 'com.google.gms.google-services'

android {
  compileSdkVersion 34
  
  defaultConfig {
    minSdkVersion 21  // Firebase requires API 21+
  }
}
```

4. **Update `android/app/AndroidManifest.xml`**

```xml
<manifest ...>
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

  <application ...>
    <service
      android:name=".service.FirebaseMessagingService"
      android:exported="false">
      <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
      </intent-filter>
    </service>
  </application>
</manifest>
```

### iOS Setup

1. **Download `GoogleService-Info.plist`**
   - Go to Firebase Console → Project Settings → General
   - Download `GoogleService-Info.plist`
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `GoogleService-Info.plist` into Runner project
   - Select "Copy items if needed" and "Runner" target

2. **Configure APNs Certificates**
   - In Xcode: Runner → Signing & Capabilities → Add "Push Notifications"
   - In Firebase Console → Project Settings → Cloud Messaging → iOS
   - Upload APNs key or certificate (from Apple Developer account)

3. **Update `ios/Podfile`**

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_NOTIFICATIONS=1',
      ]
    end
  end
end
```

4. **Enable Push Notifications in Xcode**
   - Runner → Signing & Capabilities → "+ Capability"
   - Add "Push Notifications"
   - Add "Background Modes" → Enable "Remote Notifications"

### Web Setup

Web support for Firebase Messaging is limited:

1. **Initialize Firebase (done in code)**
   - Firebase automatically initializes on web
   - FCM works in PWA mode only (HTTPS + service workers)

2. **Configure `web/index.html`**

```html
<script>
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", function () {
      navigator.serviceWorker.register("flutter_service_worker.js");
    });
  }
</script>
```

## Code Implementation

### Initialize Firebase in main.dart

Already implemented. Check `lib/main.dart`:

```dart
Future<void> _initializeFirebase() async {
  try {
    final firebaseService = FirebaseService();
    await firebaseService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
}
```

### Get FCM Token

```dart
// In any ConsumerWidget
final fcmTokenAsync = ref.watch(fcmTokenProvider);

fcmTokenAsync.when(
  data: (token) => Text('FCM Token: $token'),
  loading: () => CircularProgressIndicator(),
  error: (err, _) => Text('Error: $err'),
);
```

### Subscribe to Topic

```dart
// Subscribe
await subscribeToTopic(ref, 'news');

// Unsubscribe
await unsubscribeFromTopic(ref, 'news');

// Check subscriptions
final subscriptions = ref.watch(topicSubscriptionProvider);
```

### Handle Foreground Messages

Messages received while app is open trigger `_handleForegroundMessage`:

```dart
// Customize in lib/core/services/firebase_service.dart
static Future<void> _handleForegroundMessage(RemoteMessage message) async {
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
  
  // Show dialog/snackbar
  // Navigate to screen based on message.data
}
```

### Handle Background Messages

Messages received while app is closed/background:

```dart
// Customize in lib/core/services/firebase_service.dart
@pragma('vm:entry-point')
static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
  // Limited execution time (~30 seconds)
  // Avoid heavy operations
}
```

### Handle Notification Tap

Triggered when user taps notification while app is in background:

```dart
static Future<void> _handleNotificationTap(RemoteMessage message) async {
  // Navigate to screen
  if (message.data['screen'] == 'dashboard') {
    // Navigate to dashboard
  }
}
```

## Send Test Notifications

### Via Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title/body
4. Select "Send to devices"
5. Choose target (by topic, user segment, etc.)
6. Click "Send"

### Via curl (Server-side)

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_FCM_TOKEN",
      "notification": {
        "title": "Test Title",
        "body": "Test Body"
      },
      "data": {
        "screen": "dashboard"
      }
    }
  }'
```

### Via Dart backend

```dart
import 'package:firebase_admin/firebase_admin.dart';

void sendNotification() async {
  final message = Message(
    notification: Notification(title: 'Test', body: 'Body'),
    data: {'screen': 'dashboard'},
    token: 'DEVICE_FCM_TOKEN',
  );
  
  await FirebaseMessaging.instance.send(message);
}
```

## Troubleshooting

### 1. MissingPluginException on Android

**Problem:** `No implementation found for method getToken`

**Fix:**
- Ensure `google-services.json` is in `android/app/`
- Run `flutter clean && flutter pub get && flutter run`
- Rebuild Android app: `flutter build apk --release`

### 2. No Notifications on iOS

**Problem:** Notifications not showing in iOS

**Fix:**
- Verify APNs certificate uploaded in Firebase Console
- Check iOS app has "Push Notifications" capability
- Ensure device allows notifications in Settings
- Run on physical device (simulator may not receive notifications)

### 3. Token is null

**Problem:** `getToken()` returns null

**Fix:**
- Wait for Firebase initialization to complete
- Ensure internet connection
- Check Firebase Console → Cloud Messaging has at least one sender ID
- On Android: Verify `google-services.json` is correctly placed

### 4. Background Messages Don't Trigger

**Problem:** `onBackgroundMessage` not called

**Fix:**
- Background handler must be a top-level or static function
- Use `@pragma('vm:entry-point')` annotation
- Limit background execution time (30 seconds max)
- Test on physical device, not emulator

### 5. Web Notifications Not Working

**Problem:** Notifications not showing on web

**Fix:**
- Ensure HTTPS is used (service workers require it)
- Firebase supports web only in PWA mode
- Check browser notification permissions
- Verify service worker is registered in `web/index.html`

## Advanced Topics

### Custom Notification Handler

Override default notification behavior:

```dart
// In FirebaseService._handleForegroundMessage
if (message.notification != null) {
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (ctx) => AlertDialog(
      title: Text(message.notification!.title ?? ''),
      content: Text(message.notification!.body ?? ''),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Close'),
        ),
      ],
    ),
  );
}
```

### Deep Linking from Notifications

```dart
// Handle in _handleNotificationTap or after tap listener
final screen = message.data['screen'];
final id = message.data['id'];

if (screen == 'dashboard') {
  context.go('/dashboard/$id');
}
```

### Topic Segmentation

Organize notifications by user segments:

```dart
// Subscribe user to topics based on preferences
if (user.isVIP) await subscribeToTopic(ref, 'vip_offers');
if (user.location == 'US') await subscribeToTopic(ref, 'us_news');
if (user.interests.contains('sports')) await subscribeToTopic(ref, 'sports');
```

## API Reference

### FirebaseService

```dart
// Get instance
final firebaseService = FirebaseService();

// Initialize (called in main.dart)
await firebaseService.initialize();

// Get FCM token
final token = await firebaseService.getToken();

// Refresh token
final newToken = await firebaseService.refreshToken();

// Listen to token changes
firebaseService.onTokenRefresh.listen((newToken) {
  // Send to backend for user binding
});

// Subscribe to topic
await firebaseService.subscribeToTopic('news');

// Unsubscribe from topic
await firebaseService.unsubscribeFromTopic('news');

// Get initial message (on cold start)
final message = await firebaseService.getInitialMessage();
```

## Testing

Unit test notification handling:

```dart
test('handleForegroundMessage should log message', () async {
  final message = RemoteMessage(
    notification: RemoteNotification(
      title: 'Test',
      body: 'Body',
    ),
    data: {'key': 'value'},
  );

  await FirebaseService._handleForegroundMessage(message);
  // Verify message was logged or handled
});
```

Widget test notification UI:

```dart
testWidgets('NotificationSettingsWidget shows token', (tester) async {
  await tester.pumpWidget(
    ProviderContainer(
      overrides: [
        fcmTokenProvider.overrideWithValue(AsyncValue.data('test-token')),
      ],
      child: MaterialApp(home: NotificationSettingsWidget()),
    ),
  );

  expect(find.text('test-token'), findsOneWidget);
});
```

## Summary

| Step | Status |
|------|--------|
| Add firebase_core, firebase_messaging | ✅ Done |
| Android setup (google-services.json) | ⏳ Manual |
| iOS setup (GoogleService-Info.plist) | ⏳ Manual |
| Initialize Firebase in main.dart | ✅ Done |
| Create FirebaseService | ✅ Done |
| Create Riverpod providers | ✅ Done |
| Add notification UI widget | ✅ Done |
| Send test message via Firebase Console | ⏳ Manual |
| Handle foreground/background messages | ✅ Done |

Next: Download configuration files, complete platform setup, test notifications.
