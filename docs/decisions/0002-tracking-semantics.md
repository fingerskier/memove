# 0002 — Tracking toggle semantics: best-effort, notify on involuntary stop

- **Status:** accepted (detection layers 1 and 3 started, layer 2 not yet built)
- **Date:** 2026-10-09

## Context

The user switches tracking on or off. While it's on, MeMove should keep tracking
no matter what. The mobile OSes don't allow a hard guarantee:

- On iOS, after a user force-quit, tracking only resumes when the phone moves a
  significant distance (and only if the app holds "Always" permission).
- Some Android vendors (Samsung, Xiaomi, Huawei, …) kill background apps unless
  the user exempts them from battery optimization (see https://dontkillmyapp.com).
- The user can turn off location services or downgrade the permission at any time.

## Decision

Tracking is **best-effort**. Whenever tracking stops for a reason other than the
user turning it off, MeMove **tells the user**.

The app persists the user's *intent* (on/off) separately from the *actual*
tracking state. A mismatch the user didn't cause is an interruption. There are
three detection layers:

1. **Immediate (app alive):** the location stream errors, location services turn
   off, or permission is revoked → show the problem in the app and post a local
   notification.
2. **Dead-man's switch (app killed):** schedule a local notification ~30 min
   ahead and push it back on every location fix or heartbeat. If the OS kills the
   app, nothing pushes it back and the OS shows the notification on its own. While
   the user is stationary the app may legitimately sleep (especially on iOS), so
   the switch pauses in stationary mode to avoid false alarms.
3. **Gap report on next launch:** if intent is on but the last heartbeat is old,
   record and show the gap ("Tracking was interrupted 14:05–16:40"). On Android,
   `ApplicationExitInfo` can supply the reason.

### Known blind spot

Android "Force stop", and swipe-away on some vendors, also cancels scheduled
notifications, so nothing fires until the next launch. Closing this needs a
server-side heartbeat plus push, which needs a backend. Out of scope for now.

## Consequences

- Android tracking runs as a foreground service with a persistent notification.
- iOS needs the `location` background mode; "Always" permission is needed for
  relaunch after termination.
- The app needs notification permission (Android 13+, iOS) for interruption
  alerts.
