# MeMove app

Flutter app for Android, iOS and web. Decisions and roadmap live in the
[root README](../README.md).

## Layout

```
lib/main.dart                         app entry, wires the real services
lib/src/domain/                       pure Dart, no plugins
  location_fix.dart                   position sample + haversine distance
  movement.dart                       speed → stationary/walking/running/driving
  bout.dart                           a bout and its category
  bout_recorder.dart                  fixes → bouts (start, idle timeout, gaps)
lib/src/tracking/
  tracking_service.dart               platform location interface
  geolocator_tracking_service.dart    geolocator implementation
  tracking_state_store.dart           persisted intent + heartbeat
  tracking_controller.dart            the toggle: intent vs actual state
lib/src/ui/                           screens
test/                                 unit and widget tests (fake location)
```

## Develop

```sh
flutter pub get
flutter analyze
flutter test
flutter run            # pick a device; web tracks only while the tab is open
```

Builds:

```sh
flutter build apk --release   # prefer CI: see "Releasing" in the root README
flutter build ios             # macOS only
flutter build web
```
