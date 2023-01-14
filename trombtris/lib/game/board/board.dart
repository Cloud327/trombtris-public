class Board {
  //Initialize list of lists, this is the board
  List<List<int>> me = [];
  final int _height;
  final int _width;
  final int _id;
  //Constructor for the board, fills the board with empty lines, default height/width is 20/10
  Board([this._height = 20, this._width = 10, this._id = 0]) {
    for (int i = 0; i < _height; i++) {
      me = [...me, _lineCreation(_width)];
    }
  }

  // Decodes a board from a map
  factory Board.fromJson(Map<String, dynamic> json) {
    final boardList = json["board"] as List<dynamic>;
    Board board = Board(boardList.length, boardList[0].length);

    boardList.asMap().forEach((key, value) {
      board.me[key] = value.cast<int>();
    });
    /*board.hight = boardList.length;
    board.width = boardList[0].length;
    */
    return board;
  }

  // Encodes the board to a map
  Map<String, dynamic> toJson() => {
        '"board"': me,
      };

  //Creates a new line to be inserted into a board
  //Used whenever we need to create a new line
  List<int> _lineCreation(int width, [int type = 0]) {
    List<int> line = [];
    for (int i = 0; i < width; i++) {
      line = [...line, type];
    }
    return line;
  }

  //Checks if the row at the given position is full or not, returns true if full; false if not
  bool isRowFull(int row) {
    for (int i in me[row]) {
      if (i == 0) {
        return false;
      }
    }
    return true;
  }

  //Clears the rows at the indexes given in the list "rows" and refills the list by adding empty rows at the top
  clearRows(List<int> rows) {
    rows.sort();
    for (int i in rows) {
      if (i != 0) {
        me[i].clear();
        me.replaceRange(0, i + 1, [_lineCreation(_width), ...me.sublist(0, i)]);
      } else {
        me[i] = _lineCreation(_width);
      }
    }
  }

  //Updates boardvalues at positions given in y, x to value given in type
  //FOR USE WHEN PLACING A BLOCK ONTO THE BOARD
  updatePositions(List x, List y, List type) {
    var j = 0;
    for (int i in y) {
      me[i][x[j]] = type[j];
      j++;
    }
  }

  /*
   Checks whether positions in the board free or not, X AND Y HAVE TO BE SAME SIZE
   returns TRUE if all positions are free, FALSE if ANY position is filled
   Also returns false if any of the positions are outside of the board
  */
  arePositionsFree(List x, List y) {
    var j = 0;
    for (int i in y) {
      if (i < 0) {
        break;
      } else if (i == _height) {
        return false;
      } else {
        if (x[j] <= _width - 1 && x[j] >= 0) {
          if (me[i][x[j]] != 0) {
            return false;
          }
        } else {
          return false;
        }
        j++;
      }
    }
    return true;
  }

  Board copy() {
    Board copy = Board(_height, _width);
    for (int y = 0; y < me.length; y++) {
      for (int x = 0; x < me[y].length; x++) {
        copy.me[y][x] = me[y][x];
      }
    }
    return copy;
  }

  //FOR TESTING PURPOSES, sets given rows to given values
  setRows(List rows, int values) {
    for (int i in rows) {
      me[i] = _lineCreation(_width, values);
    }
  }

  int getWidth() {
    return _width;
  }

  int getHeight() {
    return _height;
  }
}
