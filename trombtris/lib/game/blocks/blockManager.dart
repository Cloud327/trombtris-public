import 'package:flutter/foundation.dart';
import 'package:trombtris/game/blocks/block.dart';
import 'package:trombtris/game/blocks/blockGenerator.dart';

class BlockManager {
  Block? _heldBlock;
  bool _hasHeld = false;
  late int _origPosX;
  late Block _currentBlock;
  late BlockGenerator _blockGenerator;

  BlockManager(
      int seed, int numIncomingBlocks, this._origPosX, String blockTypeDef,
      {Map<String, dynamic>? customBlocks,
      int specialTileEveryX = 0,
      List<int>? specialTiles}) {
    if (specialTileEveryX > 0) {
      _blockGenerator = BlockGenerator(seed, numIncomingBlocks, blockTypeDef,
          specialTileEveryX: specialTileEveryX, newSpecialTiles: specialTiles);
    } else {
      _blockGenerator = BlockGenerator(seed, numIncomingBlocks, blockTypeDef);
    }
    _currentBlock = _blockGenerator.newBlock();
    _currentBlock.originPos[0] =
        _origPosX; // Position the first block in the middle
  }

  // Sets the current block to become the next generated block from the BlockGenerator
  nextBlock() {
    _hasHeld = false;
    _currentBlock = _blockGenerator.newBlock();
    _currentBlock.originPos[0] = _origPosX;
  }

  holdBlock() {
    if (_hasHeld) return;

    if (_heldBlock == null) {
      // Put the current block in hold space and spawn new block
      _heldBlock = _currentBlock;
      nextBlock();
    } else {
      var temp = _currentBlock; // save current block

      // Exchange current block with held block
      _currentBlock = _heldBlock!;

      // Move current block to spawn position
      _currentBlock.originPos = Int32List.fromList([
        _origPosX,
        0
      ]); // Default: [_origPosX, 0], may need generalization for initial y pos
      _heldBlock = temp;
    }

    _hasHeld = true;
  }

  // Rotates the current block clockwise
  rotateBlockClockwise() {
    if (_currentBlock.currentRot == _currentBlock.rotation.length - 1) {
      _currentBlock.currentRot = 0;
    } else {
      _currentBlock.currentRot++;
    }
  }

  // Rotates the current block counter-clockwise
  rotateBlockCounterClockwise() {
    if (_currentBlock.currentRot == 0) {
      _currentBlock.currentRot = _currentBlock.rotation.length - 1;
    } else {
      _currentBlock.currentRot--;
    }
  }

  // Moves the block sideways
  moveBlockSideways(bool right) {
    if (right) {
      _currentBlock.originPos[0]++; // Moves origin x position 1 step to right
    } else {
      _currentBlock.originPos[0]--;
    }
  }

  // Move the current block down 1 step
  moveBlockDown() {
    _currentBlock.originPos[1]++; // Moves origin y position 1 step down
  }

  // Move the current block up 1 step (should probably only be used to avoid intersects)
  moveBlockUp() {
    _currentBlock.originPos[1]--; // Moves origin y position 1 step down
  }

  List addToTileValues(List pos, int value) {
    for (int i = 0; i < pos.length; i++) {
      pos[i] = pos[i] + value;
    }
    return pos;
  }

  // Returns a list of absolute positions for all tiles in the current block
  List getTilePositions() {
    List tilepos = _currentBlock.rotation[_currentBlock.currentRot];
    List xyt = [[], [], []];
    List temp = [[], []];

    for (int i = 0; i < tilepos.length; i++) {
      temp[0].add(tilepos[i][0] + _currentBlock.originPos[0]);
      temp[1].add(tilepos[i][1] + _currentBlock.originPos[1]);
    }

    for (int i = 0; i < tilepos.length; i++) {
      xyt[0].add(temp[0][i]);
      xyt[1].add(temp[1][i]);
    }

    for (int i in _currentBlock.tileType) {
      xyt[2].add(i);
    }

    return [...xyt];
  }

  BlockGenerator getBlockGenerator() {
    return _blockGenerator;
  }

  Block getCurrentBlock() {
    return _currentBlock;
  }

  // Returns the currently held block
  // NOTE: Block will be null until first time holdBlock() is called
  Block? getHeldBlock() {
    return _heldBlock;
  }
}
