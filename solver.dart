import 'board.dart';
import 'evaluator.dart';
import 'expectimax.dart';
import 'move.dart';

/// Public entry point for deciding the next 2048 move.
class AI2048Solver {
  final Expectimax _search;

  AI2048Solver({int searchDepth = 4, BoardEvaluator evaluator = const BoardEvaluator()})
      : _search = Expectimax(evaluator: evaluator, maxDepth: searchDepth);

  /// Returns the highest-scoring legal move.
  ///
  /// Throws [StateError] if the board has no legal moves.
  Move getBestMove(Board board) {
    final move = _search.bestMove(board);
    if (move == null) throw StateError('Cannot choose a move: the game is over.');
    return move;
  }
}
