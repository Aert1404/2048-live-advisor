import 'dart:math';

import 'move.dart';
import 'swipe_zone.dart';

/// Produces plausible swipe plans for a touch-injection adapter.
///
/// It does not send input itself. The phone/ADB integration should execute the
/// returned [HumanSwipe.points] over [HumanSwipe.duration] and then wait for
/// [HumanSwipe.pauseAfter]. This separation keeps the solver platform-neutral.
class HumanSwipeGenerator {
  final Random _random;
  final List<SwipeZone> zones;

  /// Use a seed in a benchmark or replay test; omit it for natural variation.
  HumanSwipeGenerator({required this.zones, int? seed})
      : assert(zones.isNotEmpty),
        _random = seed == null ? Random() : Random(seed);

  HumanSwipe next(Move move) {
    final zone = _weightedZone();
    final start = zone.randomPoint(_random);
    final direction = _directionRadians(move) + _normal(0, 1.7) * pi / 180;
    final length = _truncatedNormal(330, 24, 285, 380);
    final duration = _truncatedNormal(116, 18, 78, 165).round();
    final pause = _nextPause();

    final end = SwipePoint(
      start.x + cos(direction) * length,
      start.y + sin(direction) * length,
    );

    return HumanSwipe(
      zoneName: zone.name,
      points: _curvedPath(start, end),
      duration: Duration(milliseconds: duration),
      pauseAfter: Duration(milliseconds: pause),
    );
  }

  SwipeZone _weightedZone() {
    final total = zones.fold<double>(0, (sum, zone) => sum + zone.weight);
    var ticket = _random.nextDouble() * total;
    for (final zone in zones) {
      ticket -= zone.weight;
      if (ticket < 0) return zone;
    }
    return zones.last; // Unreachable, preserves a total function.
  }

  List<SwipePoint> _curvedPath(SwipePoint start, SwipePoint end) {
    // 4-6 samples resemble a hand path better than a mathematically straight
    // line, while still being small enough for a real-time input adapter.
    final samples = 4 + _random.nextInt(3);
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final magnitude = sqrt(dx * dx + dy * dy).toDouble();
    final normalX = -dy / magnitude;
    final normalY = dx / magnitude;
    final bow = _normal(0, 3.2);
    final points = <SwipePoint>[];

    for (var index = 0; index < samples; index++) {
      final t = index / (samples - 1);
      final curve = sin(pi * t) * bow;
      final jitter = index == 0 || index == samples - 1 ? 0 : _normal(0, 1.1);
      points.add(SwipePoint(
        start.x + dx * t + normalX * (curve + jitter),
        start.y + dy * t + normalY * (curve + jitter),
      ));
    }
    return points;
  }

  int _nextPause() {
    // Around 12% of moves have a noticeably longer "thinking" pause.
    if (_random.nextDouble() < .12) {
      return _truncatedNormal(820, 140, 500, 1150).round();
    }
    return _truncatedNormal(125, 38, 70, 230).round();
  }

  double _directionRadians(Move move) => switch (move) {
        Move.up => -pi / 2,
        Move.down => pi / 2,
        Move.left => pi,
        Move.right => 0,
      };

  double _truncatedNormal(double mean, double deviation, double minimum, double maximum) {
    return _normal(mean, deviation).clamp(minimum, maximum).toDouble();
  }

  /// Box-Muller transform. It gives smooth variation rather than uniform noise.
  double _normal(double mean, double deviation) {
    final u1 = 1.0 - _random.nextDouble();
    final u2 = 1.0 - _random.nextDouble();
    return (mean +
            deviation * sqrt(-2 * log(u1)).toDouble() * cos(2 * pi * u2))
        .toDouble();
  }
}

class HumanSwipe {
  final String zoneName;
  final List<SwipePoint> points;
  final Duration duration;
  final Duration pauseAfter;

  const HumanSwipe({
    required this.zoneName,
    required this.points,
    required this.duration,
    required this.pauseAfter,
  });
}
