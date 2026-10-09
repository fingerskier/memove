import 'package:flutter/material.dart';

import 'src/tracking/geolocator_tracking_service.dart';
import 'src/tracking/tracking_controller.dart';
import 'src/tracking/tracking_state_store.dart';
import 'src/ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TrackingController(
    service: const GeolocatorTrackingService(),
    store: SharedPrefsTrackingStateStore(),
  )..init();
  runApp(MeMoveApp(controller: controller));
}

class MeMoveApp extends StatelessWidget {
  const MeMoveApp({super.key, required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeMove',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: HomePage(controller: controller),
    );
  }
}
