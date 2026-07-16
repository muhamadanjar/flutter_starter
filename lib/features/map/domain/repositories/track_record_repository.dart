import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/track_record.dart';

/// Domain contract for track-record storage and synchronization.
///
/// Implementations decide where data lives (Hive locally, a future server
/// remotely) and how the local outbox is flushed — callers only see
/// [Either<Failure, ...>] results, never datasource or Hive details.
abstract class TrackRecordRepository {
  /// All stored tracks, newest first.
  Future<Either<Failure, List<TrackRecord>>> getTracks();

  /// A single track by id, or a [Failure] when missing.
  Future<Either<Failure, TrackRecord>> getTrack(String id);

  /// Create a new empty track; returns its id.
  Future<Either<Failure, String>> startTrack({
    required String name,
    String note = '',
  });

  /// Append a GPS sample to an existing track.
  Future<Either<Failure, Unit>> addPoint(
    String trackId, {
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    double speed = 0.0,
    double accuracy = 0.0,
    DateTime? timestamp,
  });

  /// Persist (create or update) a full track locally.
  Future<Either<Failure, Unit>> saveTrack(TrackRecord track);

  /// Remove a track.
  Future<Either<Failure, Unit>> deleteTrack(String trackId);

  /// Tracks not yet delivered to the server.
  Future<Either<Failure, List<TrackRecord>>> getPending();

  /// Flush the outbox: push every pending/failed record to the server and
  /// mark each as synced (or failed). Returns the number actually synced.
  /// No-op while offline.
  Future<Either<Failure, int>> syncPending();
}
