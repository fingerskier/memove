import 'movement.dart';

/// What a bout was for. Set by the user after the fact.
enum BoutCategory { general, exercise, work }

/// One continuous stretch of movement.
class Bout {
  Bout({
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.kind,
    this.category = BoutCategory.general,
  });

  final DateTime start;
  final DateTime end;
  final double distanceMeters;

  /// The movement kind the bout spent the most time in.
  final MovementKind kind;

  BoutCategory category;

  Duration get duration => end.difference(start);

  /// Average speed in m/s over the whole bout.
  double get averageSpeedMps {
    final seconds = duration.inMilliseconds / 1000;
    return seconds > 0 ? distanceMeters / seconds : 0;
  }
}
