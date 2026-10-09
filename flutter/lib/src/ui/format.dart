String _two(int n) => n.toString().padLeft(2, '0');

String formatTime(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String formatDate(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)}';

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${_two(m)}m';
  if (m > 0) return '${m}m ${_two(s)}s';
  return '${s}s';
}

String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(2)} km';

String formatSpeed(double mps) => '${(mps * 3.6).toStringAsFixed(1)} km/h';
