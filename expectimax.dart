import 'board.dart';
import 'evaluator.dart';
import 'move.dart';

/// Expectimax search: player nodes choose the best move and chance nodes
/// average all possible 2/4 tile spawns using their probabilities.
class Expectimax {
  final BoardEvaluator evaluator;
  final int maxDepth;
  final Map<String, double> _cache = {};

  Expectimax({required this.evaluator, this.maxDepth = 4})
      : assert(maxDepth > 0);

  Move? bestMove(Board board) {
    _cache.clear();
    Move? best;
    var bestScore = double.negativeInfinity;
    for (final move in board.legalMoves()) {
      final result = board.moveBoard(move);
      final score = result.scoreGained.toDouble() +
          _chance(result.board, maxDepth - 1);
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    return best;
  }

  double _player(Board board, int depth) {
    if (depth <= 0 || board.isGameOver) return evaluator.evaluate(board);
    final key = 'p:$depth:${_key(board)}';
    final cached = _cache[key];
    if (cached != null) return cached;
    var best = double.negativeInfinity;
    for (final move in board.legalMoves()) {
      final result = board.moveBoard(move);
      final score = result.scoreGained.toDouble() +
          _chance(result.board, depth - 1);
      best = best > score
          ? best
          : score;
    }
    return _cache[key] = best;
  }

  double _chance(Board board, int depth) {
    if (depth <= 0 || board.isGameOver) return evaluator.evaluate(board);
    final key = 'c:$depth:${_key(board)}';
    final cached = _cache[key];
    if (cached != null) return cached;
    final outcomes = board.spawnOutcomes();
    if (outcomes.isEmpty) return _player(board, depth);
    var expected = 0.0;
    for (final outcome in outcomes) {
      expected += outcome.probability * _player(outcome.board, depth);
    }
    return _cache[key] = expected;
  }

  String _key(Board board) => board.cells.expand((row) => row).join(',');
}
