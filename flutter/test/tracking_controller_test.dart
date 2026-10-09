import 'package:flutter_test/flutter_test.dart';
import 'package:memove/src/tracking/tracking_controller.dart';
import 'package:memove/src/tracking/tracking_service.dart';
import 'package:memove/src/tracking/tracking_state_store.dart';

import 'support/fakes.dart';

void main() {
  late FakeTrackingService service;
  late MemoryTrackingStateStore store;
  var now = t0;

  TrackingController build() =>
      TrackingController(service: service, store: store, clock: () => now);

  setUp(() {
    service = FakeTrackingService();
    store = MemoryTrackingStateStore();
    now = t0;
  });

  test('toggling persists intent and records bouts', () async {
    final c = build();
    await c.init();
    expect(c.status, TrackingStatus.off);

    await c.setEnabled(true);
    expect(store.intent, isTrue);
    expect(c.status, TrackingStatus.tracking);

    for (var s = 0; s <= 300; s += 10) {
      service.positionsController.add(fixAt(1.4 * s, s, speed: 1.4));
    }
    await pumpEventQueue();
    expect(c.inBout, isTrue);

    await c.setEnabled(false);
    expect(store.intent, isFalse);
    expect(c.status, TrackingStatus.off);
    expect(c.bouts, hasLength(1));
    c.dispose();
  });

  test('stream errors interrupt without changing intent', () async {
    final c = build();
    await c.setEnabled(true);
    service.positionsController.addError(
      const TrackingException(InterruptionReason.permissionDenied),
    );
    await pumpEventQueue();
    expect(c.status, TrackingStatus.interrupted);
    expect(c.interruption, InterruptionReason.permissionDenied);
    expect(c.enabled, isTrue);
    c.dispose();
  });

  test('resumes when location services come back on', () async {
    final c = build();
    await c.setEnabled(true);
    service.serviceController.add(false);
    await pumpEventQueue();
    expect(c.interruption, InterruptionReason.servicesDisabled);

    service.serviceController.add(true);
    await pumpEventQueue();
    expect(c.status, TrackingStatus.tracking);
    c.dispose();
  });

  test('permission failure at start is an interruption', () async {
    service.readyError = const TrackingException(
      InterruptionReason.permissionDenied,
    );
    final c = build();
    await c.setEnabled(true);
    expect(c.status, TrackingStatus.interrupted);
    c.dispose();
  });

  test('reports a gap on launch when the heartbeat is stale', () async {
    store
      ..intent = true
      ..heartbeat = t0;
    now = t0.add(const Duration(hours: 2));
    final c = build();
    await c.init();
    expect(c.lastGap?.from, t0);
    expect(c.lastGap?.to, now);
    expect(c.status, TrackingStatus.tracking);
    c.dispose();
  });

  test('no gap when the heartbeat is recent', () async {
    store
      ..intent = true
      ..heartbeat = t0;
    now = t0.add(const Duration(seconds: 30));
    final c = build();
    await c.init();
    expect(c.lastGap, isNull);
    c.dispose();
  });
}
