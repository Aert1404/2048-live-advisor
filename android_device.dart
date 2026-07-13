import 'dart:async';
import 'dart:io';

import 'human_swipe.dart';

/// Small dependency-free adapter for a USB-debugging-enabled Android phone.
/// It works with the same ADB connection used by scrcpy.
class AndroidDevice {
  final String adbPath;
  final String? serial;

  const AndroidDevice({this.adbPath = 'adb', this.serial});

  Future<String> status() async {
    final result = await _run(['devices']);
    if (result.exitCode != 0) throw StateError(result.stderr);
    return result.stdout.trim();
  }

  /// Saves a lossless native-resolution phone screenshot as a PNG.
  Future<void> capturePng(String outputPath) async {
    final process = await Process.start(adbPath, _withDevice(['exec-out', 'screencap', '-p']));
    final sink = File(outputPath).openWrite();
    await process.stdout.pipe(sink);
    final code = await process.exitCode;
    if (code != 0) throw StateError('Could not capture the phone screen (ADB exit $code).');
  }

  /// Executes the swipe using Android's standard USB-debugging input channel.
  /// Android accepts endpoints and duration; the generated intermediate points
  /// remain useful for diagnostics and a future scrcpy-control adapter.
  Future<void> performSwipe(HumanSwipe swipe) async {
    if (swipe.points.length < 2) throw ArgumentError('A swipe needs two points.');
    final start = swipe.points.first;
    final end = swipe.points.last;
    final result = await _run([
      'shell',
      'input',
      'swipe',
      start.x.round().toString(),
      start.y.round().toString(),
      end.x.round().toString(),
      end.y.round().toString(),
      swipe.duration.inMilliseconds.toString(),
    ]);
    if (result.exitCode != 0) throw StateError('Could not send swipe: ${result.stderr}');
  }

  Future<ProcessResult> _run(List<String> arguments) =>
      Process.run(adbPath, _withDevice(arguments));

  List<String> _withDevice(List<String> arguments) =>
      serial == null ? arguments : ['-s', serial!, ...arguments];
}
