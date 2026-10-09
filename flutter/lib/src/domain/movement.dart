/// How the user is moving, judged by speed alone.
enum MovementKind {
  stationary,
  walking,
  running,
  driving;

  String get label => switch (this) {
    stationary => 'Stationary',
    walking => 'Walking',
    running => 'Running',
    driving => 'Driving',
  };
}

/// Speed thresholds in m/s. Speed alone can't separate slow traffic from
/// running, or cycling from either, so treat the result as a first guess.
class MovementThresholds {
  const MovementThresholds({
    this.stationaryBelow = 0.5, // 1.8 km/h
    this.walkingBelow = 2.2, // 7.9 km/h
    this.runningBelow = 6.0, // 21.6 km/h
  });

  final double stationaryBelow;
  final double walkingBelow;
  final double runningBelow;

  MovementKind classify(double speedMps) {
    if (speedMps < stationaryBelow) return MovementKind.stationary;
    if (speedMps < walkingBelow) return MovementKind.walking;
    if (speedMps < runningBelow) return MovementKind.running;
    return MovementKind.driving;
  }
}
