import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/track_record.dart';
import '../providers/map_providers.dart';
import 'track_detail_widget.dart';

/// Bottom sheet listing all stored tracks (newest first), each with its
/// sync status, distance and point count. Tapping a row draws its route on
/// the map (via `onSelected`) and lets the user inspect the points.
void showTrackListSheet(
  BuildContext context, {
  required void Function(TrackRecord track) onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => TrackListSheet(onSelected: onSelected),
  );
}

class TrackListSheet extends ConsumerWidget {
  const TrackListSheet({required this.onSelected, super.key});
  final void Function(TrackRecord track) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(trackRecordsProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scroll) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Text('Tracks', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync pending tracks',
                  onPressed: () {
                    ref.invalidate(trackSyncProvider);
                    ref.invalidate(trackRecordsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: tracksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load: $e')),
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return const Center(
                      child: Text('No tracks yet. Tap + to start recording.'),
                    );
                  }
                  return ListView.separated(
                    controller: scroll,
                    itemCount: tracks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final t = tracks[i];
                      return ListTile(
                        leading: _SyncBadge(status: t.syncStatus),
                        title: Text(t.name),
                        subtitle: Text(
                          '${t.points.length} pts · '
                          '${t.distanceMeters.toStringAsFixed(0)} m · '
                          '${DateFormat('dd MMM HH:mm').format(t.createdAt)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              tooltip: 'Details',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TrackDetailWidget(
                                    trackId: t.id,
                                    onShowOnMap: (track) => onSelected(track),
                                  ),
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelected(t);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      SyncStatus.synced => (Colors.green, Icons.cloud_done),
      SyncStatus.failed => (Colors.red, Icons.cloud_off),
      SyncStatus.pending => (Colors.orange, Icons.cloud_upload),
    };
    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
