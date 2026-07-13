# 2048 Live Advisor

A research prototype that analyzes a live 2048 game running on an Android device and recommends the best move using an Expectimax-based AI.

The project was created during a 24-hour programming challenge with approximately 6 hours of active development.

## Features

- Reads the game board from a connected Android device using ADB.
- Recognizes all 16 board cells using the built-in Windows OCR engine.
- Solves positions using the Expectimax algorithm.
- Generates natural swipe trajectories for future automation research.
- Written entirely in Dart.

## Project Structure

- `board.dart` — board representation and move logic.
- `move.dart` — move directions.
- `evaluator.dart` — board evaluation heuristic.
- `expectimax.dart` — search algorithm.
- `solver.dart` — public AI interface.
- `android_device.dart` — Android communication through ADB.
- `game_profile.dart` — board geometry description.
- `swipe_zone.dart` — swipe sampling zones.
- `human_swipe.dart` — natural swipe generation.
- `live_advisor.dart` — live OCR and move recommendation.

## Running

Run the built-in demo:

```bash
dart run main.dart
```

## Android Connection

With USB debugging enabled:

```bash
dart run device_check.dart
```

If `adb` is not available through your system PATH:

```bash
dart run device_check.dart "<path-to-adb>"
```

Example:

```bash
dart run device_check.dart "D:\Tools\adb\adb.exe"
```

To capture a calibration frame:

```bash
dart run capture_frame.dart "<path-to-adb>" purple-board.png
```

## Live Advisor

Start the live board analyzer:

```bash
dart run live_advisor.dart "<path-to-adb>"
```

The advisor continuously captures the game board, performs OCR, detects board changes, and prints the best move recommended by the Expectimax solver.

Stop the program with `Ctrl+C`.

## Current Limitations

- OCR may occasionally misread tiles.
- Processing a single frame currently takes several seconds.
- This is an experimental research prototype rather than a finished application.