import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's tracking intent and a heartbeat, so an interruption
/// can be detected on the next launch (docs/decisions/0002).
abstract class TrackingStateStore {
  Future<bool> loadIntent();
  Future<void> saveIntent(bool on);
  Future<DateTime?> loadHeartbeat();
  Future<void> saveHeartbeat(DateTime at);
}

class SharedPrefsTrackingStateStore implements TrackingStateStore {
  SharedPrefsTrackingStateStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _intentKey = 'tracking.intent';
  static const _heartbeatKey = 'tracking.heartbeat';

  final SharedPreferencesAsync _prefs;

  @override
  Future<bool> loadIntent() async => await _prefs.getBool(_intentKey) ?? false;

  @override
  Future<void> saveIntent(bool on) => _prefs.setBool(_intentKey, on);

  @override
  Future<DateTime?> loadHeartbeat() async {
    final ms = await _prefs.getInt(_heartbeatKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> saveHeartbeat(DateTime at) =>
      _prefs.setInt(_heartbeatKey, at.millisecondsSinceEpoch);
}

class MemoryTrackingStateStore implements TrackingStateStore {
  MemoryTrackingStateStore({this.intent = false, this.heartbeat});

  bool intent;
  DateTime? heartbeat;

  @override
  Future<bool> loadIntent() async => intent;

  @override
  Future<void> saveIntent(bool on) async => intent = on;

  @override
  Future<DateTime?> loadHeartbeat() async => heartbeat;

  @override
  Future<void> saveHeartbeat(DateTime at) async => heartbeat = at;
}
