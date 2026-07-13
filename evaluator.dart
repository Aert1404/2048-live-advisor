import 'dart:math';

import 'board.dart';

/// Heuristic scoring for non-terminal expectimax leaves.
class BoardEvaluator {
  final double emptyWeight;
  final double monotonicityWeight;
  final double smoothnessWeight;
  final double cornerWeight;
  final double mergeWeight;
  final double isolationWeight;

  const BoardEvaluator({
    this.emptyWeight = 290.0,
    this.monotonicityWeight = 42.0,
    this.smoothnessWeight = 8.0,
    this.cornerWeight = 140.0,
    this.mergeWeight = 24.0,
    this.isolationWeight = 18.0,
  });

  double evaluate(Board board) {
    if (board.isGameOver) return -1000000.0;
    return board.emptyCount * emptyWeight +
        _monotonicity(board) * monotonicityWeight +
        _smoothness(board) * smoothnessWeight +
        _cornerBonus(board) * cornerWeight +
        _mergeOpportunities(board) * mergeWeight -
        _isolatedLargeTiles(board) * isolationWeight;
  }

  double _log2(int value) => value == 0 ? 0 : log(value) / ln2;

  double _monotonicity(Board board) {
    var total = 0.0;
    for (var index = 0; index < Board.size; index++) {
      total += _lineMonotonicity(board.cells[index]);
      total += _lineMonotonicity(
          List.generate(Board.size, (row) => board.cells[row][index]));
    }
    return total;
  }

  double _lineMonotonicity(List<int> line) {
    var increasing = 0.0;
    var decreasing = 0.0;
    for (var i = 0; i + 1 < line.length; i++) {
      final a = _log2(line[i]);
      final b = _log2(line[i + 1]);
      if (a > b) decreasing += a - b;
      if (b > a) increasing += b - a;
    }
    return max(increasing, decreasing);
  }

  double _smoothness(Board board) {
    var penalty = 0.0;
    for (var row = 0; row < Board.size; row++) {
      for (var column = 0; column < Board.size; column++) {
        final value = board.cells[row][column];
        if (value == 0) continue;
        for (final neighbor in [(row + 1, column), (row, column + 1)]) {
          if (neighbor.$1 < Board.size && neighbor.$2 < Board.size) {
            final other = board.cells[neighbor.$1][neighbor.$2];
            if (other != 0) penalty += (_log2(value) - _log2(other)).abs();
          }
        }
      }
    }
    return -penalty;
  }

  double _cornerBonus(Board board) {
    final maximum = board.maxTile;
    if (maximum == 0) return 0;
    final corners = [board.cells[0][0], board.cells[0][3], board.cells[3][0], board.cells[3][3]];
    return corners.contains(maximum) ? _log2(maximum) : -_log2(maximum) * 0.75;
  }

  int _mergeOpportunities(Board board) {
    var count = 0;
    for (var row = 0; row < Board.size; row++) {
      for (var column = 0; column < Board.size; column++) {
        final value = board.cells[row][column];
        if (value == 0) continue;
        if (row + 1 < Board.size && value == board.cells[row + 1][column]) count++;
        if (column + 1 < Board.size && value == board.cells[row][column + 1]) count++;
      }
    }
    return count;
  }

  int _isolatedLargeTiles(Board board) {
    var penalty = 0;
    for (var row = 0; row < Board.size; row++) {
      for (var column = 0; column < Board.size; column++) {
        final value = board.cells[row][column];
        if (value < 32) continue;
        final exponent = _log2(value);
        var compatibleNeighbor = false;
        for (final delta in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
          final r = row + delta.$1;
          final c = column + delta.$2;
          if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
            final neighbor = board.cells[r][c];
            if (neighbor != 0 && (_log2(neighbor) - exponent).abs() <= 1) {
              compatibleNeighbor = true;
            }
          }
        }
        if (!compatibleNeighbor) penalty += exponent.round();
      }
    }
    return penalty;
  }
}
