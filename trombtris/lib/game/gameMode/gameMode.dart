import 'package:trombtris/game/event/lineClearEvent.dart';

import '../event/placeEvent.dart';

class GameMode {
  int _score;
  int _level;
  int _linesTotal;
  double _ticktime;
  late List<int> _scoreSheet;
  int _gameModeType = 100;

  GameMode(
      [this._score = 0,
      this._level = 0,
      this._linesTotal = 0,
      this._ticktime = 0.6]) {
    _scoreSheet = [0, 100, 300, 500, 1000, 10000];
  }

  update(double dt) {}

  gameover(){}

  //Saves the total amount of lines cleared and translates the lines to points
  clearEvent(List whichLines) {
    int numLinesCleared = whichLines.length;
    if (_linesTotal % 10 > (_linesTotal + numLinesCleared) % 10) {
      levelIncrease();
    }
    //to handle special clears, if its bigger than 5, use the value of 5 instead
    if (numLinesCleared > 5) {
      _score = _score + _scoreSheet[5] * (_level + 1);
    } else {
      _score = _score + _scoreSheet[numLinesCleared] * (_level + 1);
    }
    _linesTotal = _linesTotal + numLinesCleared;

    if (whichLines.isNotEmpty) {
      LineClearEvent(whichLines, 0);
    }
  }

  //Decreases the time required for a tick to happen to a certain limit (0.05)
  levelIncrease() {
    _level++;
    if (_ticktime > 0.1) {
      _ticktime = _ticktime - 0.05;
    }
  }

  dropPointIncrement(bool hardDrop) {
    if (hardDrop) {
      _score += 2;
    } else {
      _score += 1;
    }
  }

  placeEvent(List placedAt) {
    PlaceEvent(placedAt);
  }

  //Getter for ticktime
  double getTickTime() {
    return _ticktime;
  }

  //Getter for score
  int getScore() {
    return _score;
  }

  //Add score based on the scoresheet
  addScore(int type) {
    _score = _score + _scoreSheet[type];
  }

  addLines(int clearedLines) {
    _linesTotal += clearedLines;
  }

  //Getter for current level
  int getLevel() {
    return _level;
  }

  //Getter for linesTotal
  int getLines() {
    return _linesTotal;
  }

  int getGameModeType() {
    return _gameModeType;
  }
}
