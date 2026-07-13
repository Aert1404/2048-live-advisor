# 2048 Dart solver

Dependency-free Expectimax solver for a 4×4 2048 board. The public API is:

```dart
final board = Board([
  [4, 2, 0, 0],
  [8, 2, 0, 0],
  [2, 8, 16, 2],
  [64, 32, 4, 8],
]);
final move = AI2048Solver(searchDepth: 4).getBestMove(board);
```

Run the built-in demo with:

```powershell
dart run main.dart
```

Files:

- `board.dart` — validation, movement, merges, and random-tile outcomes.
- `move.dart` — directions.
- `evaluator.dart` — configurable board heuristic.
- `expectimax.dart` — cached player/chance search.
- `solver.dart` — small public API.
- `swipe_zone.dart` — future UI/automation sampling zones for the right side.
- `human_swipe.dart` — natural-looking paths, duration, angle, length and rhythm.
- `game_profile.dart` — geometry of the purple-cat interface, independent of colours.
- `android_device.dart` — capture and swipe adapter for the connected Android phone.

Increase `searchDepth` to make stronger, slower decisions. Depth 4 is a sensible mobile baseline; depth 5+ is appropriate for benchmarking on a desktop.

## Swipe generation

After the phone image supplies the board rectangle in screen pixels, create the
generator once and call `next` after every solver decision:

```dart
final zones = const RightSideSwipePolicy().forBoard(
  boardLeft: 42, boardTop: 334, boardWidth: 482, boardHeight: 482,
);
final swipes = HumanSwipeGenerator(zones: zones);
final next = swipes.next(move);
```

`next.points` contains a subtly curved path. Its duration is usually around
116 ms, length around 330 px, its direction varies by about 1.7 degrees, and
the post-swipe pause is normally 70–230 ms with occasional 500–1150 ms pauses.

## Phone connection check

With USB debugging enabled, run this from the project folder. If `adb` is not
already in Windows PATH, pass the full path to the `adb.exe` bundled with scrcpy:

```powershell
dart run device_check.dart
# or:
dart run device_check.dart "C:\Users\Artem\Desktop\scrcpy-win64-v4.1\adb.exe"
```

It must show the phone serial followed by `device`. The adapter uses the native
phone resolution, so it is unaffected by the size of the scrcpy window.

To save a calibration frame from the phone (while the purple game board is open):

```powershell
dart run capture_frame.dart "C:\Users\Artem\Desktop\scrcpy-win64-v4.1\adb.exe" purple-board.png
```

## Live advisor (does not control the phone)

The live advisor captures a native frame, reads the 16 cells with the built-in
Windows OCR engine, and prints a recommended move whenever the board changes:

```powershell
dart run live_advisor.dart "C:\Users\Artem\Desktop\scrcpy-win64-v4.1\adb.exe"
```

Stop it with `Ctrl+C`.
