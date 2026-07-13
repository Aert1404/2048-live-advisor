import 'dart:convert';
import 'dart:io';

import 'board.dart';

/// Reads the purple game's 4 by 4 grid with the Windows OCR engine.
class PurpleBoardReader {
  final String scriptPath;

  PurpleBoardReader({String? scriptPath})
      : scriptPath = scriptPath ?? '${Directory.current.path}${Platform.pathSeparator}read_purple_board.ps1';

  Future<Board> read(String imagePath) async {
    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', scriptPath, imagePath],
    );
    if (result.exitCode != 0) throw StateError('Board OCR failed: ${result.stderr}');
    final decoded = jsonDecode(result.stdout.trim()) as List<dynamic>;
    if (decoded.length != Board.size || decoded.any((row) => row is! List || row.length != Board.size)) {
      throw FormatException('OCR did not return a 4 by 4 board.');
    }
    return Board(decoded
        .map((row) => (row as List<dynamic>).map((value) => value as int).toList())
        .toList());
  }
}
