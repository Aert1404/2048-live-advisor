import 'android_device.dart';

/// Saves a native-resolution frame for calibrating and reading the board.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    throw ArgumentError(
      'Usage: dart run capture_frame.dart <path-to-adb.exe> <output.png>',
    );
  }
  final device = AndroidDevice(adbPath: arguments[0]);
  await device.capturePng(arguments[1]);
  print('Frame saved to ${arguments[1]}');
}
