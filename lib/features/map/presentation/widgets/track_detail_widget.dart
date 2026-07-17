import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/track_record.dart';
import '../providers/map_providers.dart';

/// Detail view for one track: summary stats, its GPS point list, and a
/// manual sync button (flushes the outbox for this record's status).
///
/// [onShowOnMap] (when provided) is invoked from the app bar so the caller
/// can draw the route and dismiss the detail view.
class TrackDetailWidget extends ConsumerWidget {
  const TrackDetailWidget({
    super.key,
    required this.trackId,
    this.onShowOnMap,
  });

  final String trackId;
  final void Function(TrackRecord track)? onShowOnMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTracks = ref.watch(trackRecordsProvider);
    final colors = context.colors;

    return asyncTracks.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Failed to load: $e',
            style: TextStyle(color: colors.textSecondary)),
      ),
      data: (tracks) {
        final track = tracks.where((t) => t.id == trackId).firstOrNull;
        if (track == null) {
          return Center(
            child: Text('Track not found',
                style: TextStyle(color: colors.textSecondary)),
          );
        }

        final (statusColor, statusLabel) = _syncMeta(track.syncStatus);

        return Scaffold(
          appBar: AppBar(
            title: Text(track.name),
            actions: [
              if (onShowOnMap != null)
                IconButton(
                  icon: const Icon(Icons.route_outlined),
                  tooltip: 'Show on map',
                  onPressed: () {
                    Navigator.of(context).pop();
                    onShowOnMap!(track);
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              _SummaryCard(
                track: track,
                statusColor: statusColor,
                statusLabel: statusLabel,
              ),
              const SizedBox(height: 12),
              if (track.syncStatus != SyncStatus.synced)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Sync now'),
                      onPressed: () async {
                        final uc = ref.read(syncTrackRecordsUseCaseProvider);
                        await uc.call();
                        ref.invalidate(trackRecordsProvider);
                        ref.invalidate(pendingTracksProvider);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: track.points.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: colors.divider),
                  itemBuilder: (_, i) =>
                      _PointTile(point: track.points[i], index: i + 1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.track,
    required this.statusColor,
    required this.statusLabel,
  });

  final TrackRecord track;
  final Color statusColor;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: colors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(track.name,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (track.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(track.note,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'Distance',
                    value: _formatDistance(track.distanceMeters)),
                _Stat(label: 'Points', value: '${track.points.length}'),
                _Stat(label: 'Duration', value: _formatDuration(track.duration)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: colors.textHint, fontSize: 11)),
      ],
    );
  }
}

class _PointTile extends StatelessWidget {
  const _PointTile({required this.point, required this.index});
  final TrackPoint point;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: colors.surfaceVariant,
        child: Text('$index',
            style: TextStyle(color: colors.textSecondary, fontSize: 11)),
      ),
      title: Text(
        '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
        style: TextStyle(color: colors.textPrimary, fontSize: 13),
      ),
      subtitle: Text(
        'alt ${point.altitude.toStringAsFixed(1)} m · '
        'spd ${point.speed.toStringAsFixed(1)} m/s',
        style: TextStyle(color: colors.textHint, fontSize: 11),
      ),
      trailing: Text(
        '${point.timestamp.hour}:${point.timestamp.minute.toString().padLeft(2, '0')}',
        style: TextStyle(color: colors.textHint, fontSize: 11),
      ),
    );
  }
}

(Color, String) _syncMeta(SyncStatus status) {
  switch (status) {
    case SyncStatus.pending:
      return (const Color(0xFFC49A2A), 'Pending');
    case SyncStatus.synced:
      return (const Color(0xFF4E8C4A), 'Synced');
    case SyncStatus.failed:
      return (const Color(0xFF7B2525), 'Failed');
  }
}

String _formatDistance(double meters) {
  if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
  return '${meters.toStringAsFixed(0)} m';
}

String _formatDuration(Duration? d) {
  if (d == null) return '-';
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return m > 0 ? '$m min $s s' : '$s s';
}
