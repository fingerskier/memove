import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/bout.dart';
import '../domain/bout_recorder.dart';
import '../domain/location_fix.dart';
import '../domain/movement.dart';
import 'tracking_service.dart';
import 'tracking_state_store.dart';

enum TrackingStatus { off, starting, tracking, interrupted }

/// A stretch of time when tracking was on but the app wasn't recording.
class TrackingGap {
  const TrackingGap(this.from, this.to);

  final DateTime from;
  final DateTime to;
}

/// Owns the tracking toggle. Keeps the user's intent separate from the actual
/// tracking state, and reports any mismatch the user didn't cause
/// (docs/decisions/0002-tracking-semantics.md).
class TrackingController extends ChangeNotifier {
  TrackingController({
    required this.service,
    required this.store,
    BoutRecorder? recorder,
    DateTime Function()? clock,
    this.tickInterval = const Duration(seconds: 30),
    this.gapThreshold = const Duration(minutes: 2),
  }) : _recorder = recorder ?? BoutRecorder(),
       _clock = clock ?? DateTime.now;

  final TrackingService service;
  final TrackingStateStore store;
  final BoutRecorder _recorder;
  final DateTime Function() _clock;

  /// How often to check for idle bouts and write the heartbeat.
  final Duration tickInterval;

  /// A heartbeat older than this on launch counts as an interruption.
  final Duration gapThreshold;

  bool _intent = false;
  TrackingStatus _status = TrackingStatus.off;
  InterruptionReason? _interruption;
  TrackingGap? _lastGap;
  LocationFix? _lastFix;
  final List<Bout> _bouts = [];

  StreamSubscription<LocationFix>? _positionSub;
  StreamSubscription<bool>? _serviceSub;
  Timer? _ticker;

  /// What the user asked for.
  bool get enabled => _intent;
  TrackingStatus get status => _status;
  InterruptionReason? get interruption => _interruption;

  /// Set on launch when tracking was on but the app had stopped recording.
  TrackingGap? get lastGap => _lastGap;
  LocationFix? get lastFix => _lastFix;
  MovementKind get currentKind => _recorder.currentKind;
  double? get currentSpeedMps => _recorder.currentSpeedMps;
  bool get inBout => _recorder.inBout;

  /// Completed bouts, newest first.
  List<Bout> get bouts => List.unmodifiable(_bouts);

  /// Restores the user's intent and resumes tracking if it was on.
  Future<void> init() async {
    _intent = await store.loadIntent();
    if (!_intent) {
      notifyListeners();
      return;
    }
    final heartbeat = await store.loadHeartbeat();
    final now = _clock();
    if (heartbeat != null && now.difference(heartbeat) > gapThreshold) {
      _lastGap = TrackingGap(heartbeat, now);
      // TODO(0002): post a local notification for the gap.
    }
    await _start();
  }

  Future<void> setEnabled(bool on) async {
    if (on == _intent) return;
    _intent = on;
    await store.saveIntent(on);
    if (on) {
      await _start();
    } else {
      _stop();
    }
  }

  /// Tries again after an interruption.
  Future<void> retry() async {
    if (_intent) await _start();
  }

  void dismissGap() {
    _lastGap = null;
    notifyListeners();
  }

  void setCategory(Bout bout, BoutCategory category) {
    bout.category = category;
    notifyListeners();
  }

  Future<void> _start() async {
    _cancelSubscriptions();
    _status = TrackingStatus.starting;
    _interruption = null;
    notifyListeners();
    _serviceSub = service.serviceStatusChanges().listen(_onServiceStatus);

    try {
      await service.ensureReady();
    } on TrackingException catch (e) {
      _interrupt(e.reason);
      return;
    }
    if (!_intent) return; // Turned off while waiting for permission.

    _positionSub = service.positions().listen(
      _onFix,
      onError: (Object e) => _interrupt(
        e is TrackingException ? e.reason : InterruptionReason.streamError,
      ),
    );
    _ticker = Timer.periodic(tickInterval, (_) => _tick());
    _status = TrackingStatus.tracking;
    unawaited(store.saveHeartbeat(_clock()));
    notifyListeners();
  }

  void _stop() {
    _cancelSubscriptions();
    _finishBout(_recorder.flush());
    _status = TrackingStatus.off;
    _interruption = null;
    notifyListeners();
  }

  void _onFix(LocationFix fix) {
    _lastFix = fix;
    _finishBout(_recorder.add(fix));
    notifyListeners();
  }

  void _tick() {
    _finishBout(_recorder.tick(_clock()));
    unawaited(store.saveHeartbeat(_clock()));
    notifyListeners();
  }

  void _onServiceStatus(bool enabled) {
    if (!enabled) {
      _interrupt(InterruptionReason.servicesDisabled);
    } else if (_status == TrackingStatus.interrupted && _intent) {
      unawaited(_start());
    }
  }

  void _interrupt(InterruptionReason reason) {
    if (!_intent) return;
    _positionSub?.cancel();
    _positionSub = null;
    _ticker?.cancel();
    _ticker = null;
    // Keep listening to service status so tracking resumes when location
    // services come back on.
    _finishBout(_recorder.flush());
    _status = TrackingStatus.interrupted;
    _interruption = reason;
    // TODO(0002): post a local notification for the interruption.
    notifyListeners();
  }

  void _finishBout(Bout? bout) {
    if (bout != null) _bouts.insert(0, bout);
  }

  void _cancelSubscriptions() {
    _ticker?.cancel();
    _ticker = null;
    _positionSub?.cancel();
    _positionSub = null;
    _serviceSub?.cancel();
    _serviceSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
