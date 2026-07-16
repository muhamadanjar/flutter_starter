import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/track_record.dart';
import '../../domain/repositories/track_record_repository.dart';
import '../datasources/track_record_local_datasource.dart';

/// Orchestrates local Hive storage and (future) server sync for tracks.
///
/// The local datasource is the source of truth (offline-first). `syncPending`
/// reads the outbox, uploads each record, and updates its sync status — the
/// actual HTTP call is stubbed until the backend endpoint exists.
class TrackRecordRepositoryImpl implements TrackRecordRepository {
  TrackRecordRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
  });

  final TrackRecordLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, List<TrackRecord>>> getTracks() async {
    try {
      return right(await localDataSource.getAll());
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TrackRecord>> getTrack(String id) async {
    try {
      final track = await localDataSource.getById(id);
      if (track == null) {
        return left(const CacheFailure(message: 'Track not found'));
      }
      return right(track);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> startTrack({
    required String name,
    String note = '',
  }) async {
    try {
      return right(await localDataSource.startTrack(name: name, note: note));
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addPoint(
    String trackId, {
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    double speed = 0.0,
    double accuracy = 0.0,
    DateTime? timestamp,
  }) async {
    try {
      await localDataSource.addPoint(
        trackId,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        speed: speed,
        accuracy: accuracy,
        timestamp: timestamp,
      );
      return right(unit);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveTrack(TrackRecord track) async {
    try {
      await localDataSource.saveTrack(track);
      return right(unit);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTrack(String trackId) async {
    try {
      await localDataSource.deleteTrack(trackId);
      return right(unit);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TrackRecord>>> getPending() async {
    try {
      return right(await localDataSource.getPending());
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> syncPending() async {
    try {
      final online = await networkInfo.isConnected;
      if (!online) return right(0);

      final pending = await localDataSource.getPending();
      if (pending.isEmpty) return right(0);

      var syncedCount = 0;
      for (final record in pending) {
        final ok = await _upload(record);
        if (ok) {
          await localDataSource.markSynced(record.id);
          syncedCount++;
        } else {
          await localDataSource.markFailed(record.id);
        }
      }
      return right(syncedCount);
    } on Exception catch (e) {
      return left(CacheFailure(message: e.toString()));
    }
  }

  /// Upload one record to the server.
  ///
  /// TODO(server-api): replace the stub with a real POST once the backend
  /// endpoint exists, e.g.
  ///   await remoteDataSource.uploadTrack(record.toUploadJson());
  /// Return `true` on 2xx, `false` otherwise.
  Future<bool> _upload(TrackRecord record) async {
    // ignore: avoid_print
    print(
      '[TrackSync] would upload track ${record.id} '
      '(${record.points.length} points) — server API not implemented yet',
    );
    return true; // stub: assume the server accepted it
  }
}
