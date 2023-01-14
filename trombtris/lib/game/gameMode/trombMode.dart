import '../event/trombEvent.dart';
import "gameMode.dart";
import 'package:trombtris/game/gameManager.dart';
import 'package:trombtris/game/board/board.dart';

class TrombMode extends GameMode {
  List _trombTilePos = [[], []];
  int _trombs = 0;
  @override
  placeEvent(List placedAt) {
    super.placeEvent(placedAt);
    //Hittar och lägger till trombTiles i en lista _trombTilePos
    for (int i = 0; i < placedAt[0].length; i++) {
      if (placedAt[2][i] == 100) {
        if (_trombTilePos[0].length > 0) {
          //Loopar igen listan för att lägga in trombTiles i ordning i y-led
          for (int j = 0; j < _trombTilePos[0].length; j++) {
            if (placedAt[1][i] < _trombTilePos[1][j]) {
              _trombTilePos[0].insert(j, placedAt[0][i]);
              _trombTilePos[1].insert(j, placedAt[1][i]);
              break;
            } else if (placedAt[1][i] == _trombTilePos[1][j]) {
              if (placedAt[0][i] < _trombTilePos[0][j]) {
                _trombTilePos[0].insert(j, placedAt[0][i]);
                _trombTilePos[1].insert(j, placedAt[1][i]);
                break;
              }
            }
            if (j == _trombTilePos[0].length - 1) {
              _trombTilePos[0].add(placedAt[0][i]);
              _trombTilePos[1].add(placedAt[1][i]);
              break;
            }
          }
        } else {
          _trombTilePos[0].add(placedAt[0][i]);
          _trombTilePos[1].add(placedAt[1][i]);
        }
        _trombShapeSearch();
      }
    }
  }

  /*Uppdaterar listan av trombTiles positioner när en line clearas
  Tar antingen bort trombTilen om linen den är på clearas eller
  flyttar ner tilen ett steg i y-led om en line clearas under den*/
  @override
  clearEvent(List whichLines) {
    super.clearEvent(whichLines);
    try {
      for (int i = 0; i < _trombTilePos[0].length; i++) {
        for (int j in whichLines) {
          if (_trombTilePos[1][i] == j) {
            _trombTilePos[0].removeAt(i);
            _trombTilePos[1].removeAt(i);
          } else if (_trombTilePos[1][i] < j) {
            _trombTilePos[1][i] = _trombTilePos[1][i] + 1;
          }
        }
      }
    } on RangeError {}
    _trombShapeSearch();
  }

  _trombShapeSearch() {
    Board board = GameManager.getBoardState(0);
    List boardState = board.me;

    //Loop through the list of trombtiles, check if the tromblogo is complete relative to the trombtile at the bottom
    for (int i = _trombTilePos[0].length - 1; i > 0; i--) {
      try {
        if (boardState[_trombTilePos[1][i] - 1][_trombTilePos[0][i]] == 100 &&
            boardState[_trombTilePos[1][i] - 1][_trombTilePos[0][i] + 1] ==
                100 &&
            boardState[_trombTilePos[1][i] - 2][_trombTilePos[0][i]] == 100 &&
            boardState[_trombTilePos[1][i] - 2][_trombTilePos[0][i] - 1] ==
                100) {
          //Tromb logo is found
          List pos = [
            [
              _trombTilePos[0][i],
              _trombTilePos[0][i] + 1,
              _trombTilePos[0][i],
              _trombTilePos[0][i],
              _trombTilePos[0][i] - 1
            ],
            [
              _trombTilePos[1][i],
              _trombTilePos[1][i] - 1,
              _trombTilePos[1][i] - 1,
              _trombTilePos[1][i] - 2,
              _trombTilePos[1][i] - 2
            ]
          ];
          TrombEvent(pos);
          _trombFound(board);
          //print("o kolla en tromblogga, neato");
          break;
        }
      } on RangeError {}
    }
  }

  //What happens when a tromblogo is found?
  _trombFound(Board board) {
    //Resets list of trombtiles
    _trombTilePos = [[], []];
    List<int> allRows = [];
    for (int i = board.getHeight(); i > 0; i--) {
      allRows.add(i - 1);
    }

    //Manually increase score and lines cleared
    super.addScore(5);
    //super.addLines(20);

    //Increases level twice (due to clearEvent not adding levels when clearing with tromb)
    super.levelIncrease();

    //clears all rows
    board.clearRows(allRows);

    //Count amount of trombs
    _trombs += 1;
  }

  int getTrombCount() {
    return _trombs;
  }
}
