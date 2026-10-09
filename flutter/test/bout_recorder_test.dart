import 'package:flutter_test/flutter_test.dart';
import 'package:memove/src/domain/bout_recorder.dart';
import 'package:memove/src/domain/movement.dart';

import 'support/fakes.dart';

void main() {
  test('records a walking bout that ends after standing still', () {
    final r = BoutRecorder();
    // Walk 1.4 m/s for 10 minutes, one fix every 10 s.
    for (var s = 0; s <= 600; s += 10) {
      expect(r.add(fixAt(1.4 * s, s, speed: 1.4)), isNull);
    }
    expect(r.inBout, isTrue);
    expect(r.currentKind, MovementKind.walking);

    // Stand still at 840 m, reported speed 0.
    final bout =
        [for (var s = 610; s <= 900; s += 10) r.add(fixAt(840, s, speed: 0))]
                .whereType<Object>()
                .single
            as dynamic;

    expect(bout.kind, MovementKind.walking);
    expect(bout.distanceMeters, closeTo(840, 15));
    expect(bout.start, t0);
    expect(r.inBout, isFalse);
  });

  test('derives speed from distance when the device reports none', () {
    final r = BoutRecorder();
    for (var s = 0; s <= 300; s += 5) {
      r.add(fixAt(3.5 * s, s));
    }
    expect(r.currentKind, MovementKind.running);
    final bout = r.flush()!;
    expect(bout.kind, MovementKind.running);
    expect(bout.distanceMeters, closeTo(1050, 5));
  });

  test('tick ends a bout when fixes stop arriving', () {
    final r = BoutRecorder();
    for (var s = 0; s <= 300; s += 10) {
      r.add(fixAt(1.5 * s, s, speed: 1.5));
    }
    expect(r.tick(t0.add(const Duration(seconds: 400))), isNull);
    final bout = r.tick(t0.add(const Duration(seconds: 500)))!;
    expect(bout.end, t0.add(const Duration(seconds: 300)));
    expect(r.inBout, isFalse);
  });

  test('a long gap between fixes closes the bout without bridging it', () {
    final r = BoutRecorder();
    for (var s = 0; s <= 300; s += 10) {
      r.add(fixAt(1.5 * s, s, speed: 1.5));
    }
    final bout = r.add(fixAt(5000, 4000, speed: 1.5))!;
    expect(bout.distanceMeters, closeTo(450, 5));
    expect(r.inBout, isFalse);
  });

  test('ignores inaccurate fixes and drops tiny bouts', () {
    final r = BoutRecorder();
    expect(r.add(fixAt(0, 0, accuracy: 500)), isNull);
    r.add(fixAt(0, 0, speed: 1.4));
    r.add(fixAt(14, 10, speed: 1.4));
    expect(r.inBout, isTrue);
    expect(r.flush(), isNull); // 14 m in 10 s is below the minimums
  });
}
