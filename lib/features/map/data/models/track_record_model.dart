import '../../domain/entities/track_record.dart';

class TrackPointModel extends TrackPoint {
  const TrackPointModel({
    required super.latitude,
    required super.longitude,
    super.altitude,
    super.speed,
    super.accuracy,
    required super.timestamp,
  });

  factory TrackPointModel.fromJson(Map<String, dynamic> json) {
    return TrackPointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'speed': speed,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
      };
}

class TrackRecordModel extends TrackRecord {
  const TrackRecordModel({
    required super.id,
    required super.name,
    super.note,
    required super.createdAt,
    super.updatedAt,
    required super.points,
    super.syncStatus,
    super.syncedAt,
  });

  factory TrackRecordModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List?) ?? [];
    return TrackRecordModel(
      id: json['id'] as String,
      name: json['name'] as String,
      note: (json['note'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      points: rawPoints
          .map((e) => TrackPointModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      syncStatus: _parseStatus(json['syncStatus']),
      syncedAt: json['syncedAt'] == null
          ? null
          : DateTime.parse(json['syncedAt'] as String),
    );
  }

  factory TrackRecordModel.fromEntity(TrackRecord record) {
    return TrackRecordModel(
      id: record.id,
      name: record.name,
      note: record.note,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      points: record.points
          .map((p) => TrackPointModel(
                latitude: p.latitude,
                longitude: p.longitude,
                altitude: p.altitude,
                speed: p.speed,
                accuracy: p.accuracy,
                timestamp: p.timestamp,
              ))
          .toList(),
      syncStatus: record.syncStatus,
      syncedAt: record.syncedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'points': points.map((p) => (p as TrackPointModel).toJson()).toList(),
        'syncStatus': syncStatus.name,
        'syncedAt': syncedAt?.toIso8601String(),
      };

  TrackRecord toEntity() => TrackRecord(
        id: id,
        name: name,
        note: note,
        createdAt: createdAt,
        updatedAt: updatedAt,
        points: points,
        syncStatus: syncStatus,
        syncedAt: syncedAt,
      );

  static SyncStatus _parseStatus(dynamic raw) {
    if (raw is String) {
      return SyncStatus.values.firstWhere(
        (s) => s.name == raw,
        orElse: () => SyncStatus.pending,
      );
    }
    return SyncStatus.pending;
  }
}
