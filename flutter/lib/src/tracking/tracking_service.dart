import '../domain/location_fix.dart';

/// Why tracking stopped without the user turning it off.
enum InterruptionReason {
  permissionDenied,
  servicesDisabled,
  streamError,

  /// The app wasn't running for a while even though tracking was on.
  appNotRunning;

  String get label => switch (this) {
    permissionDenied => 'Location permission was denied or revoked',
    servicesDisabled => 'Location services are turned off',
    streamError => 'The location stream failed',
    appNotRunning => 'The app was stopped',
  };
}

class TrackingException implements Exception {
  const TrackingException(this.reason, [this.detail]);

  final InterruptionReason reason;
  final Object? detail;

  @override
  String toString() => 'TrackingException(${reason.name}: $detail)';
}

/// Platform location source. Implementations must keep delivering fixes while
/// the app is in the background where the platform allows it.
///
/// See docs/decisions/0003-location-plugin.md.
abstract class TrackingService {
  /// Checks location services and permission, prompting where needed.
  /// Throws [TrackingException] if tracking can't start.
  Future<void> ensureReady();

  /// Position updates. Errors are [TrackingException]s.
  Stream<LocationFix> positions();

  /// Emits whenever location services are switched on (true) or off (false).
  /// Empty where the platform can't report it.
  Stream<bool> serviceStatusChanges();
}
