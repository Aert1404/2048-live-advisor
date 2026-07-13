import 'dart:async';
import 'dart:io';

import 'android_device.dart';
import 'purple_board_reader.dart';
import 'solver.dart';

/// Continuously displays the strongest recommended move without controlling
/// the phone. Stop it at any time with Ctrl+C.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    throw ArgumentError('Usage: dart run live_advisor.dart <path-to-adb.exe>');
  }
  final device = AndroidDevice(adbPath: arguments.first);
  final reader = PurpleBoardReader();
  final framePath = '${Directory.current.path}${Platform.pathSeparator}advisor-frame.png';
  String? previous;

  print('Advisor started. Open the purple 2048 game; press Ctrl+C to stop.');
  while (true) {
    try {
      await device.capturePng(framePath);
      final board = await reader.read(framePath);
      final signature = board.cells.expand((row) => row).join(',');
      if (signature != previous) {
        previous = signature;
        final depth = board.emptyCount >= 9
            ? 3
            : board.emptyCount >= 5
                ? 4
                : 5;
        final solver = AI2048Solver(searchDepth: depth);
        print('\nBoard: ${board.cells}');
        print('Search depth: $depth');
        print('Recommended move: ${solver.getBestMove(board)}');
      }
    } catch (error) {
      print('Waiting for a clear board: $error');
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }
}
