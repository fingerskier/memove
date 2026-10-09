import 'package:flutter/material.dart';

import '../domain/bout.dart';
import '../domain/movement.dart';
import '../tracking/tracking_controller.dart';
import 'format.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('MeMove')),
        body: ListView(
          children: [
            if (controller.lastGap case final gap?)
              MaterialBanner(
                leading: const Icon(Icons.history_toggle_off),
                content: Text(
                  'Tracking was interrupted '
                  '${formatDate(gap.from)} ${formatTime(gap.from)}–'
                  '${formatTime(gap.to)}.',
                ),
                actions: [
                  TextButton(
                    onPressed: controller.dismissGap,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            SwitchListTile(
              title: const Text('Tracking'),
              subtitle: Text(_statusText(controller)),
              value: controller.enabled,
              onChanged: controller.setEnabled,
            ),
            if (controller.status == TrackingStatus.interrupted)
              _InterruptionCard(controller: controller),
            if (controller.status == TrackingStatus.tracking)
              _LiveCard(controller: controller),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Bouts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (controller.bouts.isEmpty)
              const ListTile(title: Text('No bouts yet')),
            for (final bout in controller.bouts)
              _BoutTile(bout: bout, controller: controller),
          ],
        ),
      ),
    );
  }

  static String _statusText(TrackingController c) => switch (c.status) {
    TrackingStatus.off => 'Off',
    TrackingStatus.starting => 'Starting…',
    TrackingStatus.tracking => c.inBout ? 'Recording a bout' : 'On',
    TrackingStatus.interrupted => 'Interrupted',
  };
}

class _InterruptionCard extends StatelessWidget {
  const _InterruptionCard({required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.location_off, color: colors.onErrorContainer),
        title: Text(
          controller.interruption?.label ?? 'Tracking stopped',
          style: TextStyle(color: colors.onErrorContainer),
        ),
        trailing: TextButton(
          onPressed: controller.retry,
          child: const Text('Retry'),
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.controller});

  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    final speed = controller.currentSpeedMps;
    return ListTile(
      leading: Icon(_icon(controller.currentKind)),
      title: Text(controller.currentKind.label),
      subtitle: Text(speed == null ? 'Waiting for a fix…' : formatSpeed(speed)),
    );
  }
}

class _BoutTile extends StatelessWidget {
  const _BoutTile({required this.bout, required this.controller});

  final Bout bout;
  final TrackingController controller;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_icon(bout.kind)),
      title: Text(
        '${formatDistance(bout.distanceMeters)} · '
        '${formatDuration(bout.duration)}',
      ),
      subtitle: Text(
        '${formatDate(bout.start)} ${formatTime(bout.start)}–'
        '${formatTime(bout.end)} · ${bout.kind.label}',
      ),
      trailing: DropdownButton<BoutCategory>(
        value: bout.category,
        underline: const SizedBox.shrink(),
        onChanged: (c) {
          if (c != null) controller.setCategory(bout, c);
        },
        items: [
          for (final c in BoutCategory.values)
            DropdownMenuItem(value: c, child: Text(c.name)),
        ],
      ),
    );
  }
}

IconData _icon(MovementKind kind) => switch (kind) {
  MovementKind.stationary => Icons.accessibility_new,
  MovementKind.walking => Icons.directions_walk,
  MovementKind.running => Icons.directions_run,
  MovementKind.driving => Icons.directions_car,
};
