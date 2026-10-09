# 0001 — Flutter instead of a PWA

- **Status:** accepted
- **Date:** 2026-10-09

## Context

MeMove was planned as a browser/PWA app. Its core feature is tracking movement
(GPS and/or IMU) whenever the user has tracking switched on, including while the
phone is locked or another app is in front.

The web platform can't do that:

- `navigator.geolocation` and `DeviceMotionEvent` only deliver data while the
  page is visible. iOS suspends a backgrounded or screen-locked PWA immediately;
  Android Chrome throttles and then pauses hidden pages.
- Service workers have no access to geolocation. Periodic Background Sync is
  Chromium-only and fires at most roughly every 12 hours.
- No background-location web API has shipped.

A PWA could only offer foreground "start a bout" tracking with the screen kept on
(Screen Wake Lock), which doesn't meet the requirement.

## Options considered

| Option | Background tracking | Performance | Notes |
|---|---|---|---|
| PWA | No | n/a | Simplest, no app stores, but fails the core requirement |
| Capacitor (web app in a native shell) | Yes, via native plugins | WebView UI | Keeps a web stack and a PWA build |
| **Flutter** | Yes, via native plugins | AOT-compiled Dart, own renderer | One codebase for Android, iOS and web |
| Native Swift + Kotlin | Yes | Best, marginally | Two codebases |

Battery and GPS behaviour are about the same in the three native options: the
actual tracking runs in each plugin's native Swift and Kotlin code. The differences
are UI performance and how many codebases there are to maintain.

## Decision

Build MeMove in Flutter, in `flutter/`. Targets: Android, iOS and web.

- **Android:** the primary target. CI builds a release APK on every version tag
  (see [releasing](../../README.md#releasing)).
- **iOS:** supported in the codebase. Not built automatically, because that needs
  macOS runners and Apple signing.
- **Web:** supported in the codebase, foreground-only (same limits as above). Not
  built automatically.

## Consequences

- Real background tracking on Android and iOS, at the cost of app-store
  distribution and background-location permission reviews (Apple's "Always"
  justification; Google Play's background-location declaration and demo video).
- The web build is a lesser experience: it can only track while open.
- Dart instead of a JS framework.
