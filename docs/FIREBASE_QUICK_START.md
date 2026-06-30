# Firebase Push Notifications — Quick Start

Fast reference for common Firebase Messaging tasks.

## Installation ✅

Already in `pubspec.yaml`:
```yaml
firebase_core: ^2.28.0
firebase_messaging: ^14.8.0
```

Run: `flutter pub get`

## Initialize in main.dart ✅

Already done. Calls `FirebaseService().initialize()` before `ProviderScope`.

## Get FCM Token

```dart
// In ConsumerWidget
final fcmTokenAsync = ref.watch(fcmTokenProvider);

fcmTokenAsync.whenData((token) {
  print('FCM Token: $token');
  // Send to backend API
});
```

## Refresh Token Manually

```dart
final firebaseService = ref.watch(firebaseServiceProvider);
final newToken = await firebaseService.refreshToken();
```

## Listen to Token Changes

```dart
// Token refreshes when user signs in/out or after 24 hours
final tokenRefreshStream = ref.watch(fcmTokenRefreshProvider);

tokenRefreshStream.whenData((newToken) {
  print('Token refreshed: $newToken');
  // Update backend
});
```

## Subscribe to Topic

```dart
// Single subscribe
await subscribeToTopic(ref, 'news');

// Multiple subscribes
for (var topic in ['news', 'updates', 'sports']) {
  await subscribeToTopic(ref, topic);
}

// Check subscriptions
final topics = ref.watch(topicSubscriptionProvider);
print('Subscribed to: $topics');
```

## Unsubscribe from Topic

```dart
await unsubscribeFromTopic(ref, 'news');
```

## Handle Notifications

### Foreground (App Open)

Customize in `lib/core/services/firebase_service.dart`:

```dart
static Future<void> _handleForegroundMessage(RemoteMessage message) async {
  // Show dialog, snackbar, or local notification
  print('Foreground: ${message.notification?.title}');
}
```

### Background (App Closed/Minimized)

Customize in `lib/core/services/firebase_service.dart`:

```dart
@pragma('vm:entry-point')
static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // Limited ~30 seconds execution
  // Update cache, log event, etc.
  print('Background: ${message.notification?.title}');
}
```

### Tap Notification

Customize in `lib/core/services/firebase_service.dart`:

```dart
static Future<void> _handleNotificationTap(RemoteMessage message) async {
  // Navigate to screen
  final screen = message.data['screen'];
  print('Tapped: $screen');
}
```

## Send Test Notification via Console

1. Open [Firebase Console](https://console.firebase.google.com)
2. Project → Cloud Messaging
3. "Send your first message"
4. Title: "Test", Body: "Hello"
5. Select "Send to devices" → Topic (e.g., "news")
6. Click "Send"
7. Notification appears on subscribed devices

## Send Notification via API (Node.js)

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const message = {
  notification: {
    title: 'Hello',
    body: 'Test message',
  },
  data: {
    screen: 'dashboard',
  },
  topic: 'news',  // or token: 'device-fcm-token'
};

admin.messaging().send(message)
  .then(response => console.log('Sent:', response))
  .catch(error => console.error('Error:', error));
```

## Use NotificationSettingsWidget

Already created at `lib/features/notifications/presentation/widgets/notification_settings_widget.dart`.

Add to settings page:

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          NotificationSettingsWidget(),
          // Other settings
        ],
      ),
    );
  }
}
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Token is null | Wait for Firebase init to complete, check internet |
| No notifications on Android | Verify `google-services.json` in `android/app/` |
| No notifications on iOS | Check APNs cert in Firebase Console, run on device |
| Background message not triggered | Use `@pragma('vm:entry-point')`, test on device |
| Web notifications don't work | Use HTTPS + PWA, check service worker |

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed troubleshooting.

## File Locations

| Component | File |
|-----------|------|
| Firebase Service | `lib/core/services/firebase_service.dart` |
| Riverpod Providers | `lib/core/providers/firebase_provider.dart` |
| UI Widget | `lib/features/notifications/presentation/widgets/notification_settings_widget.dart` |
| Main init | `lib/main.dart` (`_initializeFirebase()`) |
| Documentation | `docs/FIREBASE_SETUP.md` |

## Next Steps

1. Download configuration files (Android & iOS)
2. Complete platform setup in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
3. Test notifications via Firebase Console
4. Customize message handlers for your app
5. Send tokens to backend API
