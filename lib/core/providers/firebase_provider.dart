import 'package:enterprise_flutter_app/core/services/firebase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase Service instance
final firebaseServiceProvider = Provider((ref) => FirebaseService());

// FCM Token provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getToken();
});

// FCM Token refresh stream
final fcmTokenRefreshProvider = StreamProvider<String>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.onTokenRefresh;
});

// Topic subscription manager
final topicSubscriptionProvider = StateProvider<List<String>>((ref) => []);

// Subscribe to topic
Future<void> subscribeToTopic(WidgetRef ref, String topic) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  await firebaseService.subscribeToTopic(topic);

  // Update state
  ref.read(topicSubscriptionProvider.notifier).state = [
    ...ref.read(topicSubscriptionProvider),
    topic,
  ];
}

// Unsubscribe from topic
Future<void> unsubscribeFromTopic(WidgetRef ref, String topic) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  await firebaseService.unsubscribeFromTopic(topic);

  // Update state
  ref.read(topicSubscriptionProvider.notifier).state =
      ref.read(topicSubscriptionProvider).where((t) => t != topic).toList();
}
