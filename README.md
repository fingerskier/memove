# memove

MeMove is a movement tracker.

* Flutter app for Android (primary), iOS and web
* Tracks device movement: GPS (IMU later)
* Determines, by speed, whether walking, running or driving
* Keeps a log of _bouts_ showing distance and time traveled
* Allows marking of _bouts_ as general, exercise, work, etc.
* Generates reports, e.g. work bouts in a certain date range
* Background tracking: the user toggles tracking on or off. While on, it tracks
  best-effort in the background and tells the user if anything other than the
  user stops it

## Decisions

| # | Decision |
|---|---|
| [0001](docs/decisions/0001-flutter-over-pwa.md) | Flutter instead of a PWA: browsers can't track location in the background |
| [0002](docs/decisions/0002-tracking-semantics.md) | Tracking toggle is best-effort, with a notification when tracking stops involuntarily |
| [0003](docs/decisions/0003-location-plugin.md) | Start with the free `geolocator` plugin behind an interface; revisit Transistorsoft before release |

## Platform notes

| | Android | iOS | Web |
|---|---|---|---|
| Background tracking | Foreground service with a persistent notification | `location` background mode | No: only while the page is open |
| Survives app kill / reboot | Not yet (see 0003) | Not yet (see 0003) | No |
| Built by CI | APK on every push to main (artifact); release on version tags | No (needs macOS + Apple signing) | No |

Some Android vendors kill background apps regardless; users may need to exempt
MeMove from battery optimization (https://dontkillmyapp.com).

## Repository layout

```
docs/decisions/   decision records
flutter/          the app (see flutter/README.md)
.github/workflows apk.yml
```

## Status and next steps

Done: domain model (fixes, speed classification, bout segmentation), tracking
toggle with persisted intent, interruption detection while running, gap report
on launch, a basic home screen, release APK workflow.

Next:

1. Local notifications for interruptions and gaps, and the dead-man's switch
   (0002 layers 1–3).
2. Persist bouts (e.g. `drift`, which supports mobile and web).
3. Reports by category and date range.
4. Request "Always" location on iOS and battery-optimization exemption on Android.

## Releasing

APKs are built on GitHub Actions, not locally. Every push to `main` (and every
pull request) builds one; download it from the run's **Artifacts** (or
`gh run download -n memove-apk`). To build without pushing code, run the **APK**
workflow manually from the Actions tab (`gh workflow run apk.yml`).

For a release, push a version tag; CI builds the APK and attaches it to a GitHub release:

```sh
git tag v0.1.0
git push origin v0.1.0
```

The tag sets the version name (`v0.1.0` → `0.1.0`), and the workflow run number
is the version code. Tags containing `-` (e.g. `v0.2.0-beta.1`) are marked as
prereleases.

Without signing secrets the APK is signed with a debug key, which is fine for
sideloading but not for Google Play. To sign properly, add these repository
secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

```sh
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
base64 -w0 upload-keystore.jks   # value for ANDROID_KEYSTORE_BASE64
```

Keep the keystore safe: Android only accepts updates signed with the same key.
