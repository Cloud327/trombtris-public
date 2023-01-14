import 'board.dart';

class BoardManager {
  int _boardID = 0;
  static late Board _board;
  static late List<Board> _boardList;
  //Creates and returns a board object, takes height and width as arguments
  //but uses default values 20 and 10 if nothing is given

  BoardManager() {
    _boardList = [];
  }

  createBoard([int height = 20, int width = 10]) {
    _board = Board(height, width, _boardID);
    _boardID += 1;
    _boardList.add(_board);
    _boardList.add(Board(height, width));
  }

  updatePositions(int boardNum, List pos) {
    _boardList[boardNum].updatePositions(pos[0], pos[1], pos[2]);
  }

  clearRows(int boardNum, List<int> rowsToBeCleared) {
    _boardList[boardNum].clearRows(rowsToBeCleared);
  }

  Board copy(int boardNum) {
    return _boardList[boardNum].copy();
  }

  bool arePositionsFree(int boardNum, pos) {
    return _boardList[boardNum].arePositionsFree(pos[0], pos[1]);
  }

  bool isRowFull(int boardNum, int row) {
    return _boardList[boardNum].isRowFull(row);
  }

  int getWidth(int boardNum) {
    return _boardList[boardNum].getWidth();
  }

  int getHeight(int boardNum) {
    return _boardList[boardNum].getHeight();
  }

  Board getBoardState(int boardNum) {
    return _boardList[boardNum];
  }
}
