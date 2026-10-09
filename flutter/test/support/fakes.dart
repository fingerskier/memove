import 'dart:async';

import 'package:memove/src/domain/location_fix.dart';
import 'package:memove/src/tracking/tracking_service.dart';

class FakeTrackingService implements TrackingService {
  final positionsController = StreamController<LocationFix>.broadcast();
  final serviceController = StreamController<bool>.broadcast();
  TrackingException? readyError;

  @override
  Future<void> ensureReady() async {
    if (readyError case final e?) throw e;
  }

  @override
  Stream<LocationFix> positions() => positionsController.stream;

  @override
  Stream<bool> serviceStatusChanges() => serviceController.stream;
}

/// A fix [meters] north of the origin, [seconds] after [t0].
LocationFix fixAt(
  double meters,
  int seconds, {
  double? speed,
  double accuracy = 5,
}) {
  return LocationFix(
    latitude: meters / 111194.93, // meters per degree of latitude
    longitude: 0,
    timestamp: t0.add(Duration(seconds: seconds)),
    accuracyMeters: accuracy,
    speedMps: speed,
  );
}

final t0 = DateTime(2026, 10, 9, 8);
