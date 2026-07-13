import 'dart:math';

/// A rectangular area where a swipe may start, in board-local pixels.
class SwipeZone {
  final String name;
  final double left;
  final double top;
  final double right;
  final double bottom;

  /// Relative sampling frequency. A weight of 12 is picked 12 times as often
  /// as a weight of 1, before invalid starts are discarded.
  final double weight;

  const SwipeZone({
    required this.name,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.weight,
  }) : assert(left < right && top < bottom && weight > 0);

  SwipePoint randomPoint(Random random) => SwipePoint(
        left + random.nextDouble() * (right - left),
        top + random.nextDouble() * (bottom - top),
      );
}

/// The marked cells from the screenshot, expressed as zero-based grid positions.
/// Column zero is deliberately absent: a bot never starts a swipe there.
class RightSideSwipePolicy {
  static const _definitions = <_CellZoneDefinition>[
    // Red: three primary cells; combined probability weight = 12.
    _CellZoneDefinition('active', 1, 2, 4),
    _CellZoneDefinition('active', 1, 3, 4),
    _CellZoneDefinition('active', 2, 2, 4),
    // Yellow: four secondary cells; combined weight = 4.
    _CellZoneDefinition('occasional', 0, 2, 1),
    _CellZoneDefinition('occasional', 0, 3, 1),
    _CellZoneDefinition('occasional', 2, 3, 1),
    _CellZoneDefinition('occasional', 3, 2, 1),
    // Dark green: two uncommon cells; combined weight = 1.
    _CellZoneDefinition('rare', 2, 1, .5),
    _CellZoneDefinition('rare', 3, 3, .5),
  ];

  const RightSideSwipePolicy();

  List<SwipeZone> forBoard({
    required double boardLeft,
    required double boardTop,
    required double boardWidth,
    required double boardHeight,
  }) => _definitions
      .map((zone) {
        // Stay inside the central 60% of a cell: a real finger does not land
        // perfectly on its mathematical centre and avoids the tile borders.
        const padding = .20;
        const span = 1 - padding * 2;
        final cellWidth = boardWidth / 4;
        final cellHeight = boardHeight / 4;
        return SwipeZone(
          name: zone.name,
          left: boardLeft + (zone.column + padding) * cellWidth,
          top: boardTop + (zone.row + padding) * cellHeight,
          right: boardLeft + (zone.column + padding + span) * cellWidth,
          bottom: boardTop + (zone.row + padding + span) * cellHeight,
          weight: zone.weight,
        );
      })
      .toList(growable: false);
}

class SwipePoint {
  final double x;
  final double y;

  const SwipePoint(this.x, this.y);
}

class _CellZoneDefinition {
  final String name;
  final int row;
  final int column;
  final double weight;

  const _CellZoneDefinition(this.name, this.row, this.column, this.weight);
}
