import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:trombtris/game/blocks/blockManager.dart';
import 'package:trombtris/game/board/board.dart';
import 'package:trombtris/game/board/boardManager.dart';
import 'package:trombtris/game/event/gameOverEvent.dart';
import 'package:trombtris/game/event/instantPlaceEvent.dart';
import 'package:trombtris/game/gameMode/gameMode.dart';
import 'package:trombtris/game/gameMode/multiplayerMode.dart';
import 'package:trombtris/game/gameMode/trombMode.dart';

import 'package:trombtris/game/input/inputManager.dart';
import 'package:trombtris/game/network/networkManager.dart';

import 'blocks/block.dart';

enum MoveDirection { none, left, right }

class GameManager {
  static late BoardManager _boardManager;
  static late BlockManager _blockManager;
  late InputManager inputManager = InputManager(this);
  late GameMode _gameMode;
  late double _tickRate; // Determines how fast a block moves downwards
  final _network = NetworkManager();

  late double _timeSinceLastTick;
  static const double _moveTickRate =
      0.14; // Determines how fast the blocks can move sideways
  static const double _placeDelay =
      0.5; // Determines how long a tetromino waits while on the ground before being placed down
  double _timeSinceLastMoveTick = 0;
  MoveDirection _moveDir = MoveDirection.none;
  double _topSpeed = 0.1;
  bool _softDrop = false;
  bool isDirty = false;
  static bool _gameOver = false;
  bool isPaused = false;

  GameManager(String blockTypeDef, [String gameMode = "TrombMode"]) {
    _gameOver = false; // Reset static game over state between games
    _boardManager = BoardManager();
    print(gameMode);
    _boardManager.createBoard();
    Random randomSeedGenerator = Random();
    _blockManager = BlockManager(randomSeedGenerator.nextInt(4294967296), 4,
        _boardManager.getWidth(0) ~/ 2 - 1, blockTypeDef,
        specialTileEveryX: 20);
    if (gameMode == "Multiplayer") {
      _gameMode = MultiplayerMode();
    } else {
      _gameMode = TrombMode();
    }
    //List testLine = [0, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    _tickRate = .5;
    _timeSinceLastTick = _tickRate;
  }

  update(double dt) {
    // Checks if it is time to move down the current block
    if (!isPaused) {
      if (!_gameOver) {
        _gameMode.update(dt);

        _timeSinceLastTick = _timeSinceLastTick + dt;

        // Checks if the block is on the ground
        if (!_allowDownwardsMove()) {
          if ((_timeSinceLastTick >= _placeDelay)) {
            tick();
          }
        } else if (_timeSinceLastTick >= _tickRate) {
          _timeSinceLastTick = _timeSinceLastTick - _tickRate;
          tick();
        }

        // Check if player is holding left/right
        switch (_moveDir) {
          case MoveDirection.left:
            _timeSinceLastMoveTick += dt;
            if (_timeSinceLastMoveTick > _moveTickRate) {
              _timeSinceLastMoveTick = _timeSinceLastMoveTick - _moveTickRate;
              if (_allowSidewaysMove(false)) {
                _blockManager.moveBlockSideways(false);
                isDirty = true;
              }
            }
            break;

          case MoveDirection.right:
            _timeSinceLastMoveTick += dt;
            if (_timeSinceLastMoveTick > _moveTickRate) {
              _timeSinceLastMoveTick = _timeSinceLastMoveTick - _moveTickRate;
              if (_allowSidewaysMove(true)) {
                _blockManager.moveBlockSideways(true);
                isDirty = true;
              }
            }
            break;

          default:
            _timeSinceLastMoveTick = 0;
            break;
        }
      } else {
        GameOverEvent();
        _gameMode.gameover();
        isPaused = true;
      }
    }
  }

  // Moves the current block down one tile
  tick() {
    if (_allowDownwardsMove()) {
      _blockManager.moveBlockDown();
    } else {
      _blockTransition();
    }

    //if _softDrop is active, increment points by 1 each tile as defined in _gameMode
    //if _softDrop isn't active, update tick time as defined _gameMode
    if (!_softDrop) {
      _tickRate = _gameMode.getTickTime();
    } else {
      _gameMode.dropPointIncrement(false);
    }

    isDirty = true;
  }

  handleInput(Controls control, bool isDown) {
    //print(key); // <-- Debug for checking name of key
    if (!_gameOver) {
      switch (control) {
        //case "W": // <-- In case you want more than one control to do the same thing, simply let cases go into eachother
        case Controls.rotate:
          if (!isDown) return;
          _rotateBlock(true);
          isDirty = true;
          break;

        case Controls.softDrop:
          if (isDown) {
            _softDrop = true;
            _tickRate = _topSpeed;
            _timeSinceLastTick = _timeSinceLastTick * _topSpeed;
          } else {
            _softDrop = false;
            _tickRate = _gameMode.getTickTime();
            _timeSinceLastTick = _timeSinceLastTick / _topSpeed;
          }
          break;

        case Controls.moveLeft:
          if (isDown) {
            _moveDir = MoveDirection.left;
            if (_allowSidewaysMove(false)) {
              _blockManager.moveBlockSideways(false);
              isDirty = true;
            }
          } else if (_moveDir == MoveDirection.left) {
            _moveDir = MoveDirection.none;
          }
          break;

        case Controls.moveRight:
          if (isDown) {
            _moveDir = MoveDirection.right;
            if (_allowSidewaysMove(true)) {
              _blockManager.moveBlockSideways(true);
              isDirty = true;
            }
          } else if (_moveDir == MoveDirection.right) {
            _moveDir = MoveDirection.none;
          }
          break;

        case Controls.instantPlace:
          if (!isDown) return;
          _instantPlace();
          _blockTransition();
          isDirty = true;
          break;

        case Controls.holdBlock:
          if (!isDown) return;
          _blockManager.holdBlock();
          isDirty = true;
          break;
      }
    }
  }

  _instantPlace() {
    int dropHeight = 0;
    bool moveDown = true;
    do {
      if (_allowDownwardsMove()) {
        _blockManager.moveBlockDown();
        dropHeight++;
      } else {
        moveDown = false;
      }
      _gameMode.dropPointIncrement(true);
    } while (moveDown);

    InstantPlaceEvent(_blockManager.getTilePositions(), dropHeight);
  }

  _blockTransition() {
    List pos = _blockManager.getTilePositions();
    try {
      _boardManager.updatePositions(0, pos);
    } on RangeError {
      // A block attempted to be placed outside the range of the board, game over
      triggerGameOver();
    }
    _gameMode.placeEvent(pos);
    List<int> rowsToBeCleared = [];
    for (int i in pos[1]) {
      if (_boardManager.isRowFull(0, i)) {
        bool exists = false;
        for (int row in rowsToBeCleared) {
          if (row == i) exists = true;
        }
        if (!exists) rowsToBeCleared.add(i);
      }
    }
    if (rowsToBeCleared.isNotEmpty) {
      _boardManager.clearRows(0, rowsToBeCleared);
      _gameMode.clearEvent(rowsToBeCleared);
    }

    _blockHasBeenPlaced();
  }

  bool _allowDownwardsMove() {
    List pos = _blockManager.getTilePositions();
    pos[1] = _blockManager.addToTileValues(pos[1], 1);

    return _boardManager.arePositionsFree(0, pos);
  }

  bool _allowSidewaysMove(bool side) {
    List pos = _blockManager.getTilePositions();
    int value = 1;
    if (!side) value = -1;

    pos[0] = _blockManager.addToTileValues(pos[0], value);
    return _boardManager.arePositionsFree(0, pos);
  }

  //TODO Split _rotateBlock into checkRotation and _rotateBlock.
  _rotateBlock(bool clockwise) {
    Block originalBlock = _blockManager.getCurrentBlock().copy();
    // Checks in what direction the rotation should be made
    if (clockwise == true) {
      _blockManager.rotateBlockClockwise();
    } else {
      _blockManager.rotateBlockCounterClockwise();
    }
    List pos = _blockManager.getTilePositions();
    for (int i = 0; i < pos[0].length; i++) {
      while (pos[0][i] < 0) {
        _blockManager.moveBlockSideways(true);
        pos = _blockManager.getTilePositions();
      }
      while (pos[0][i] > _boardManager.getWidth(0) - 1) {
        _blockManager.moveBlockSideways(false);
        pos = _blockManager.getTilePositions();
      }
      while (pos[1][i] < 0) {
        if (_allowDownwardsMove()) {
          _blockManager.moveBlockDown();
        } else {
          _blockTransition();
        }
        pos = _blockManager.getTilePositions();
      }
    }

    // This parts checks if the rotation positioned the block into a legal positon
    if (!_boardManager.arePositionsFree(0, pos)) {
      _blockManager
          .moveBlockUp(); // It will try to check if moving the block up one step will make the rotation legal
      pos = _blockManager.getTilePositions();
      if (!_boardManager.arePositionsFree(0, pos)) {
        // Otherwise it will set the falling block to its original position and rotation
        _blockManager.moveBlockDown();
        pos = _blockManager.getTilePositions();
        if (!_boardManager.arePositionsFree(0, pos)) {
          _blockManager.getCurrentBlock().originPos = originalBlock.originPos;
          _blockManager.getCurrentBlock().currentRot = originalBlock.currentRot;
        }
      }
    }

    for (int i = 0; i < pos[1].length; i++) {
      while (pos[1][i] > _boardManager.getHeight(0) - 1) {
        _blockManager.moveBlockUp();
        pos = _blockManager.getTilePositions();
      }
    }
  }

  //Funktion att kalla på när ett block har placerats
  //Hanterar att byta till ett nytt block och se om spelet borde ta slut
  _blockHasBeenPlaced() {
    _blockManager.nextBlock();
    _timeSinceLastTick = 0; // Reset tick timer
    List pos = _blockManager.getTilePositions();

    try {
      if (!_boardManager.arePositionsFree(0, pos)) {
        triggerGameOver();
        sendScoreToDataBase();
      }
    } on RangeError {}
  }

  sendScoreToDataBase() {
    _network.sendScoreData(_gameMode.getGameModeType(), _gameMode.getScore(),
        _gameMode.getLines());
  }

  void triggerGameOver() {
    _gameOver = true;
  }

  static bool isGameOver() {
    return _gameOver;
  }

  // Returns a board with the falling block and placed blocks
  static Board getGameState(int board) {
    Board boardWithFallingBlock = _boardManager.copy(board);
    List pos = _blockManager.getTilePositions();

    try {
      boardWithFallingBlock.updatePositions(pos[0], pos[1], pos[2]);
    } on RangeError {}

    return boardWithFallingBlock;
  }

// Returns the actual board, not a copy
// Finns det något bättre sätt att göra i trombMode så man slipper ge tillgång till boarden???
  static Board getBoardState(int board) {
    return _boardManager.getBoardState(board);
  }

  // Returns a copy of the list containing the upcoming blocks
  List<Block> getUpcomingBlocks() {
    List<Block> copy = [];
    List<Block> upcomingBlocks =
        _blockManager.getBlockGenerator().getUpcomingBlocks();

    for (int i = 0; i < upcomingBlocks.length; i++) {
      copy.add(upcomingBlocks[i].copy());
    }
    return copy;
  }

  int getScore() {
    return _gameMode.getScore();
  }

  Block getPreview() {
    Int32List currentPos = _blockManager.getCurrentBlock().originPos;
    int yMovement = 0;
    bool moveDown = true;
    do {
      if (_allowDownwardsMove()) {
        _blockManager.moveBlockDown();
        yMovement++;
      } else {
        moveDown = false;
      }
    } while (moveDown);

    Block currentPreview = _blockManager.getCurrentBlock().copy();
    for (int y = yMovement; y > 0; y--) {
      _blockManager.moveBlockUp();
    }

    return currentPreview;
  }

  Block? getHeldBlock() {
    return _blockManager.getHeldBlock();
  }

  int getLineClears() {
    return _gameMode.getLines();
  }

  GameMode getGamemode() {
    return _gameMode;
  }

  int getLevel() {
    return _gameMode.getLevel();
  }

  updateSeed(int seed) {
    _blockManager.getBlockGenerator().updateSeed(seed);
    _blockManager.nextBlock();
  }

  int getSeed(){
    return _blockManager.getBlockGenerator().getSeed();
  }
}
