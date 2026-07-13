import 'swipe_zone.dart';

/// A screen rectangle whose coordinates are fractions of the phone display.
class RelativeRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const RelativeRect(this.left, this.top, this.width, this.height);

  ScreenRect onScreen(int screenWidth, int screenHeight) => ScreenRect(
        left * screenWidth,
        top * screenHeight,
        width * screenWidth,
        height * screenHeight,
      );
}

class ScreenRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const ScreenRect(this.left, this.top, this.width, this.height);

  double get right => left + width;
  double get bottom => top + height;
}

/// Geometry for one visual version of a 2048 game.
///
/// It deliberately contains no colour rules. The grid position is sufficient
/// for swipe placement and later digit recognition.
class GameProfile {
  final String name;
  final RelativeRect boardArea;
  final int rows;
  final int columns;

  const GameProfile({
    required this.name,
    required this.boardArea,
    this.rows = 4,
    this.columns = 4,
  });

  ScreenRect boardOnScreen(int width, int height) => boardArea.onScreen(width, height);

  List<SwipeZone> swipeZones(int width, int height) {
    final board = boardOnScreen(width, height);
    return const RightSideSwipePolicy().forBoard(
      boardLeft: board.left,
      boardTop: board.top,
      boardWidth: board.width,
      boardHeight: board.height,
    );
  }
}

/// The purple interface with the cat shown in the supplied screenshots.
/// These proportions tolerate normal scrcpy window scaling because they are
/// calculated from the phone's native screenshot dimensions.
const purpleCat2048 = GameProfile(
  name: 'Purple Cat 2048',
  // Calibrated from purple-board.png (1080 × 2400): cell grid only.
  boardArea: RelativeRect(.111, .324, .779, .352),
);
