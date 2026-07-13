import 'move.dart';

/// A 4 by 4 2048 board.
///
/// `cells` is intentionally public to match simple UI and automation adapters.
/// Values must be either zero or a positive power of two.
class Board {
  static const int size = 4;

  List<List<int>> cells;

  Board(List<List<int>> cells)
      : cells = cells.map((row) => List<int>.from(row)).toList() {
    _validate();
  }

  factory Board.empty() => Board(List.generate(size, (_) => List.filled(size, 0)));

  Board copy() => Board(cells);

  int get emptyCount =>
      cells.expand((row) => row).where((value) => value == 0).length;

  int get maxTile => cells
      .expand((row) => row)
      .fold<int>(0, (largest, value) => value > largest ? value : largest);

  bool get isGameOver => legalMoves().isEmpty;

  List<Move> legalMoves() =>
      Move.values.where((move) => moveBoard(move).changed).toList(growable: false);

  /// Computes a move without changing this board.
  MoveResult moveBoard(Move move) {
    final next = Board.empty();
    var score = 0;

    for (var line = 0; line < size; line++) {
      final source = <int>[];
      for (var index = 0; index < size; index++) {
        final point = _point(move, line, index);
        source.add(cells[point.$1][point.$2]);
      }
      final collapsed = _collapse(source);
      score += collapsed.$2;
      for (var index = 0; index < size; index++) {
        final point = _point(move, line, index);
        next.cells[point.$1][point.$2] = collapsed.$1[index];
      }
    }
    return MoveResult(next, score, !_sameCells(next));
  }

  /// Returns all possible boards after the random 2/4 tile is added.
  /// Each result carries its exact probability.
  List<SpawnResult> spawnOutcomes() {
    final empties = <(int, int)>[];
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        if (cells[row][column] == 0) empties.add((row, column));
      }
    }
    if (empties.isEmpty) return const [];

    final results = <SpawnResult>[];
    for (final point in empties) {
      for (final tile in const <(int, double)>[(2, 0.9), (4, 0.1)]) {
        final next = copy();
        next.cells[point.$1][point.$2] = tile.$1;
        results.add(SpawnResult(next, tile.$2 / empties.length));
      }
    }
    return results;
  }

  (List<int>, int) _collapse(List<int> line) {
    final values = line.where((value) => value != 0).toList();
    final result = <int>[];
    var gained = 0;
    for (var index = 0; index < values.length; index++) {
      if (index + 1 < values.length && values[index] == values[index + 1]) {
        final merged = values[index] * 2;
        result.add(merged);
        gained += merged;
        index++;
      } else {
        result.add(values[index]);
      }
    }
    result.addAll(List.filled(size - result.length, 0));
    return (result, gained);
  }

  /// Maps a line ordered from the move edge toward the opposite edge.
  (int, int) _point(Move move, int line, int index) => switch (move) {
        Move.left => (line, index),
        Move.right => (line, size - 1 - index),
        Move.up => (index, line),
        Move.down => (size - 1 - index, line),
      };

  bool _sameCells(Board other) {
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        if (cells[row][column] != other.cells[row][column]) return false;
      }
    }
    return true;
  }

  void _validate() {
    if (cells.length != size || cells.any((row) => row.length != size)) {
      throw ArgumentError('A Board must contain exactly 4 rows of 4 cells.');
    }
    for (final value in cells.expand((row) => row)) {
      if (value < 0 || (value != 0 && (value & (value - 1)) != 0)) {
        throw ArgumentError('Cell values must be zero or powers of two.');
      }
    }
  }
}

class MoveResult {
  final Board board;
  final int scoreGained;
  final bool changed;

  const MoveResult(this.board, this.scoreGained, this.changed);
}

class SpawnResult {
  final Board board;
  final double probability;

  const SpawnResult(this.board, this.probability);
}
