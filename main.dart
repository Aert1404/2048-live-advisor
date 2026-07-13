import 'board.dart';
import 'human_swipe.dart';
import 'solver.dart';
import 'swipe_zone.dart';

/// Console entry point for trying the solver before a phone connection is added.
void main() {
  final board = Board([
    [4, 2, 0, 0],
    [8, 2, 0, 0],
    [2, 8, 16, 2],
    [64, 32, 4, 8],
  ]);

  final move = AI2048Solver(searchDepth: 4).getBestMove(board);
  final zones = const RightSideSwipePolicy().forBoard(
    boardLeft: 42,
    boardTop: 334,
    boardWidth: 482,
    boardHeight: 482,
  );
  final swipe = HumanSwipeGenerator(zones: zones).next(move);
  final path = swipe.points
      .map((point) => '(${point.x.toStringAsFixed(0)}, ${point.y.toStringAsFixed(0)})')
      .join(' -> ');

  print('Recommended move: $move');
  print('Start zone: ${swipe.zoneName}');
  print('Path: $path');
  print('Duration: ${swipe.duration.inMilliseconds} ms');
  print('Pause: ${swipe.pauseAfter.inMilliseconds} ms');
}
