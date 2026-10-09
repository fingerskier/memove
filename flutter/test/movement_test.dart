import 'package:flutter_test/flutter_test.dart';
import 'package:memove/src/domain/movement.dart';

import 'support/fakes.dart';

void main() {
  test('classifies speed into movement kinds', () {
    const t = MovementThresholds();
    expect(t.classify(0.2), MovementKind.stationary);
    expect(t.classify(1.4), MovementKind.walking);
    expect(t.classify(3.5), MovementKind.running);
    expect(t.classify(15), MovementKind.driving);
  });

  test('distanceTo is close to the expected meters', () {
    expect(fixAt(0, 0).distanceTo(fixAt(1000, 0)), closeTo(1000, 1));
  });
}
