import 'dart:math';

/// A single GPS sample captured during a tracking session (SW Maps-style).
class TrackPoint {
  const TrackPoint({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.accuracy = 0.0,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;
  final double accuracy;
  final DateTime timestamp;
}

/// One tracking session: an ordered list of [TrackPoint] samples.
class TrackRecord {
  const TrackRecord({
    required this.id,
    required this.name,
    this.note = '',
    required this.createdAt,
    this.updatedAt,
    required this.points,
  });

  final String id;
  final String name;
  final String note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TrackPoint> points;

  /// Total distance in meters, summed between consecutive points
  /// using the haversine formula.
  double get distanceMeters {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 1; i < points.length; i++) {
      total += _haversine(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return total;
  }

  /// Duration of the track (last point minus first point).
  Duration? get duration {
    if (points.length < 2) return null;
    return points.last.timestamp.difference(points.first.timestamp);
  }

  TrackRecord copyWith({
    String? id,
    String? name,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TrackPoint>? points,
  }) {
    return TrackRecord(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      points: points ?? this.points,
    );
  }
}

/// Great-circle distance between two coordinates in meters.
double _haversine(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371000; // Earth radius in meters
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _toRad(double deg) => deg * (pi / 180);
