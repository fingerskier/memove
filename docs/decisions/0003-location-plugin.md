# 0003 — Location plugin: start with `geolocator`, keep it swappable

- **Status:** accepted (provisional)
- **Date:** 2026-10-09

## Context

Two realistic plugins for background location in Flutter:

| | `geolocator` | Transistorsoft `flutter_background_geolocation` |
|---|---|---|
| Cost | Free (MIT) | Free on iOS and Android debug builds; **paid license for Android release builds** (check current terms) |
| Platforms | Android, iOS, web | Android, iOS (no web) |
| Android background | Foreground service with notification | Foreground service, plus motion-based GPS on/off |
| Survives app kill / reboot | No | Yes (`stopOnTerminate: false`, `startOnBoot: true`) |
| Battery management | Do it yourself | Built in (motion detection turns GPS off when still) |
| Activity recognition | No (separate plugin) | Built in |

## Decision

Start with `geolocator` behind a `TrackingService` interface
(`flutter/lib/src/tracking/tracking_service.dart`). It's free, covers all three
targets, and builds in CI without license keys.

Revisit before a public release. If kill/reboot survival and battery life matter
more than the license cost, add a `TrackingService` implementation backed by
Transistorsoft for Android and iOS, and keep `geolocator` for web.

## Consequences

- For now, tracking stops when the OS or the user kills the app. Layers 1 and 3 of
  [0002](0002-tracking-semantics.md) still apply; layer 2 is what tells the user.
- Walk/run/drive classification uses GPS speed only until a plugin with activity
  recognition is added.
