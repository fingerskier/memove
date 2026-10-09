import 'bout.dart';
import 'location_fix.dart';
import 'movement.dart';

/// Turns a stream of [LocationFix]es into [Bout]s.
///
/// A bout starts when the smoothed speed rises above stationary. It ends once
/// the user has been stationary for [idleTimeout], when no fix arrives for
/// [idleTimeout] (platform distance filters stop fixes while standing still;
/// see [tick]), or when [flush] is called.
class BoutRecorder {
  BoutRecorder({
    this.thresholds = const MovementThresholds(),
    this.idleTimeout = const Duration(minutes: 3),
    this.minDistanceMeters = 50,
    this.minDuration = const Duration(minutes: 1),
    this.maxAccuracyMeters = 50,
    this.speedWindow = 5,
  });

  final MovementThresholds thresholds;
  final Duration idleTimeout;
  final double minDistanceMeters;
  final Duration minDuration;

  /// Fixes less accurate than this are ignored.
  final double maxAccuracyMeters;

  /// Number of recent speed samples the median is taken over.
  final int speedWindow;

  LocationFix? _last;
  final List<double> _speeds = [];
  MovementKind _kind = MovementKind.stationary;

  DateTime? _boutStart;
  double _distance = 0;
  final Map<MovementKind, Duration> _timeByKind = {};
  DateTime? _lastMovingAt;
  DateTime? _stationarySince;
  double _distanceAtStationary = 0;

  /// The current movement kind, from the smoothed speed.
  MovementKind get currentKind => _kind;

  /// The smoothed speed in m/s, or null before the second fix.
  double? get currentSpeedMps => _speeds.isEmpty ? null : _median(_speeds);

  bool get inBout => _boutStart != null;

  /// Feeds one fix. Returns a bout if this fix completed one.
  Bout? add(LocationFix fix) {
    final accuracy = fix.accuracyMeters;
    if (accuracy != null && accuracy > maxAccuracyMeters) return null;

    final prev = _last;
    _last = fix;
    if (prev == null) return null;

    final dt = fix.timestamp.difference(prev.timestamp);
    if (dt <= Duration.zero) return null;

    if (dt > idleTimeout) {
      // Standing still (no fixes) or tracking was interrupted. Either way,
      // don't bridge the gap with a straight line.
      _speeds.clear();
      _kind = MovementKind.stationary;
      return inBout ? _close(_stationarySince ?? prev.timestamp) : null;
    }

    final segment = prev.distanceTo(fix);
    final reported = fix.speedMps;
    final speed = (reported != null && reported >= 0)
        ? reported
        : segment / (dt.inMilliseconds / 1000);
    _speeds.add(speed);
    if (_speeds.length > speedWindow) _speeds.removeAt(0);
    _kind = thresholds.classify(_median(_speeds));

    if (!inBout) {
      if (_kind == MovementKind.stationary) return null;
      _boutStart = prev.timestamp;
      _distance = 0;
      _timeByKind.clear();
    }

    _distance += segment;
    _timeByKind.update(_kind, (d) => d + dt, ifAbsent: () => dt);

    if (_kind == MovementKind.stationary) {
      if (_stationarySince == null) {
        _stationarySince = prev.timestamp;
        _distanceAtStationary = _distance - segment;
      }
      if (fix.timestamp.difference(_stationarySince!) >= idleTimeout) {
        return _close(_stationarySince!);
      }
    } else {
      _stationarySince = null;
      _lastMovingAt = fix.timestamp;
    }
    return null;
  }

  /// Call periodically. Ends the current bout if no fix has arrived for
  /// [idleTimeout], which is how standing still looks with a distance filter.
  Bout? tick(DateTime now) {
    final last = _last;
    if (!inBout || last == null) return null;
    if (now.difference(last.timestamp) < idleTimeout) return null;
    _speeds.clear();
    _kind = MovementKind.stationary;
    return _close(_stationarySince ?? last.timestamp);
  }

  /// Ends the current bout, e.g. when the user turns tracking off.
  Bout? flush() {
    if (!inBout) return null;
    return _close(_stationarySince ?? _lastMovingAt ?? _last!.timestamp);
  }

  Bout? _close(DateTime end) {
    // Drop GPS jitter accumulated while standing still at the end.
    final distance = _stationarySince != null
        ? _distanceAtStationary
        : _distance;
    final moving =
        _timeByKind.entries
            .where((e) => e.key != MovementKind.stationary)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final start = _boutStart!;

    _boutStart = null;
    _distance = 0;
    _timeByKind.clear();
    _lastMovingAt = null;
    _stationarySince = null;
    _distanceAtStationary = 0;

    final bout = Bout(
      start: start,
      end: end,
      distanceMeters: distance,
      kind: moving.isEmpty ? MovementKind.walking : moving.first.key,
    );
    if (bout.distanceMeters < minDistanceMeters ||
        bout.duration < minDuration) {
      return null;
    }
    return bout;
  }

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
