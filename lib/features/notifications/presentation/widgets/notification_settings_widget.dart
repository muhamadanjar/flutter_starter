import 'package:enterprise_flutter_app/core/providers/firebase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettingsWidget extends ConsumerWidget {
  const NotificationSettingsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fcmTokenAsync = ref.watch(fcmTokenProvider);

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Push Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            // FCM Token display
            Text('FCM Token:', style: Theme.of(context).textTheme.labelMedium),
            SizedBox(height: 8),
            fcmTokenAsync.when(
              data: (token) => _buildTokenDisplay(context, token),
              loading: () => SizedBox(
                height: 20,
                child: Center(child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )),
              ),
              error: (err, _) => Text(
                'Failed to load token: $err',
                style: TextStyle(color: Colors.red),
              ),
            ),
            SizedBox(height: 16),
            // Topic subscription
            Text('Subscriptions:', style: Theme.of(context).textTheme.labelMedium),
            SizedBox(height: 8),
            _buildTopicButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenDisplay(BuildContext context, String? token) {
    if (token == null) {
      return Text('No token available', style: TextStyle(color: Colors.orange));
    }

    return SelectableText(
      token,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: Colors.blue,
          ),
    );
  }

  Widget _buildTopicButtons(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TopicButton(
          label: 'Subscribe News',
          topic: 'news',
          onPressed: () => subscribeToTopic(ref, 'news'),
        ),
        _TopicButton(
          label: 'Subscribe Updates',
          topic: 'updates',
          onPressed: () => subscribeToTopic(ref, 'updates'),
        ),
        _TopicButton(
          label: 'Subscribe Promotions',
          topic: 'promotions',
          onPressed: () => subscribeToTopic(ref, 'promotions'),
        ),
      ],
    );
  }
}

class _TopicButton extends ConsumerWidget {
  final String label;
  final String topic;
  final VoidCallback onPressed;

  const _TopicButton({
    required this.label,
    required this.topic,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(topicSubscriptionProvider);
    final isSubscribed = subscriptions.contains(topic);

    return ElevatedButton.icon(
      onPressed: isSubscribed
          ? () => unsubscribeFromTopic(ref, topic)
          : onPressed,
      icon: Icon(isSubscribed ? Icons.check : Icons.add),
      label: Text(isSubscribed ? '$label (✓)' : label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSubscribed ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
