import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/location_fix.dart';
import 'tracking_service.dart';

/// [TrackingService] backed by the `geolocator` plugin.
///
/// Android runs a foreground service with a persistent notification; iOS uses
/// background location updates; web only tracks while the page is visible.
class GeolocatorTrackingService implements TrackingService {
  const GeolocatorTrackingService();

  @override
  Future<void> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const TrackingException(InterruptionReason.servicesDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    // "While in use" is enough to keep tracking after the app goes to the
    // background, as long as tracking was started in the foreground.
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      throw TrackingException(InterruptionReason.permissionDenied, permission);
    }
  }

  @override
  Stream<LocationFix> positions() {
    return Geolocator.getPositionStream(locationSettings: _settings())
        .map(_toFix)
        .handleError((Object error) => throw _toTrackingException(error));
  }

  @override
  Stream<bool> serviceStatusChanges() {
    if (kIsWeb) return const Stream.empty();
    return Geolocator.getServiceStatusStream().map(
      (status) => status == ServiceStatus.enabled,
    );
  }

  static LocationSettings _settings() {
    const accuracy = LocationAccuracy.high;
    const distanceFilter = 5;
    if (kIsWeb) {
      return WebSettings(accuracy: accuracy, distanceFilter: distanceFilter);
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          intervalDuration: const Duration(seconds: 5),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'MeMove is tracking',
            notificationText: 'Turn tracking off in the app to stop.',
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
          activityType: ActivityType.fitness,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      default:
        return const LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        );
    }
  }

  static LocationFix _toFix(Position p) => LocationFix(
    latitude: p.latitude,
    longitude: p.longitude,
    timestamp: p.timestamp,
    accuracyMeters: p.accuracy,
    // Browsers often report no speed, which the plugin turns into 0.
    speedMps: kIsWeb && p.speed == 0 ? null : p.speed,
  );

  static TrackingException _toTrackingException(Object error) {
    if (error is TrackingException) return error;
    if (error is LocationServiceDisabledException) {
      return TrackingException(InterruptionReason.servicesDisabled, error);
    }
    if (error is PermissionDeniedException) {
      return TrackingException(InterruptionReason.permissionDenied, error);
    }
    return TrackingException(InterruptionReason.streamError, error);
  }
}
