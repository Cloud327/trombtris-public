import "gameMode.dart";

class DefaultMode extends GameMode {
  int _gameModeType = 0;

  @override
  int getGameModeType() {
    return _gameModeType;
  }
}
