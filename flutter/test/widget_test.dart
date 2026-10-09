import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memove/main.dart';
import 'package:memove/src/tracking/tracking_controller.dart';
import 'package:memove/src/tracking/tracking_state_store.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('switch turns tracking on and off', (tester) async {
    final controller = TrackingController(
      service: FakeTrackingService(),
      store: MemoryTrackingStateStore(),
    );
    await tester.pumpWidget(MeMoveApp(controller: controller));
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('No bouts yet'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(controller.status, TrackingStatus.tracking);
    expect(find.text('On'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Off'), findsOneWidget);
    controller.dispose();
  });
}
