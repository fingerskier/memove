import 'dart:math' as math;

/// A single position sample, independent of the location plugin.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyMeters,
    this.speedMps,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;

  /// Horizontal accuracy radius, if the platform reports one.
  final double? accuracyMeters;

  /// Device-reported speed in m/s. Null or negative means unknown.
  final double? speedMps;

  /// Great-circle distance to [other] in meters (haversine).
  double distanceTo(LocationFix other) {
    const earthRadius = 6371000.0;
    final lat1 = _rad(latitude);
    final lat2 = _rad(other.latitude);
    final dLat = lat2 - lat1;
    final dLon = _rad(other.longitude - longitude);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(a)));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
