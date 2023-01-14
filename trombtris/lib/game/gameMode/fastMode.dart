import "gameMode.dart";

class FastMode extends GameMode {
  int _gameModeType = 1;

  @override
  int getGameModeType() {
    return _gameModeType;
  }
}
