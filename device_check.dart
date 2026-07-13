import 'android_device.dart';

/// Verifies that ADB sees the phone. Run before the first bot session.
Future<void> main(List<String> arguments) async {
  // Pass a full path to adb.exe when the scrcpy folder is not in PATH.
  final device = AndroidDevice(adbPath: arguments.isEmpty ? 'adb' : arguments.first);
  print(await device.status());
}
