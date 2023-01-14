import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';

import 'block.dart';

class BlockGenerator {
  late int _seed;
  late Random _rdGen;
  late List<Block> _blockTypes;
  late List<int> _blockTypeProb;
  List<Block> _upcomingBlocks = [];
  late final int _specialTileEveryX;
  late int _specialCounter;
  late final List<int> _specialTiles;
  late int _trombTileCounter;

  BlockGenerator(this._seed, int numIncomingBlocks, String blockTypeDef,
      {specialTileEveryX = 0, List<int>? newSpecialTiles}) {
    // If custom values for specialTiles are not given, use default value
    if (newSpecialTiles == null) {
      _specialTiles = [100]; // Default special tile value: 100
    } else {
      _specialTiles = newSpecialTiles;
    }

    _specialTileEveryX = specialTileEveryX;
    _specialCounter = specialTileEveryX;
    _rdGen = Random(_seed);

    _blockTypes = _parseBlockTypeDef(blockTypeDef);

    // TODO: Make blocktypes become parsed before game starts
    //parseBlockTypeDef().then((customBlocks) => _blockTypes = customBlocks);

    // Init block type probability list to length of block type list
    _blockTypeProb = List<int>.filled(_blockTypes.length, 0, growable: false);

    _trombTileCounter = 0;

    // Populate upcoming block list
    if (numIncomingBlocks > 0) {
      for (var i = 0; i < numIncomingBlocks; i++) {
        _upcomingBlocks.add(_generateBlock());
      }
    }
  }

  updateSeed(int seed) {
    _specialCounter = _specialTileEveryX;
    _rdGen = Random(seed);
    _blockTypeProb = List<int>.filled(_blockTypes.length, 0, growable: false);

    for (Block i in _upcomingBlocks) {
      newBlock();
    }
  }

  int getSeed(){
    return _seed;
  }

  // Function used internally for generating new blocks
  Block _generateBlock() {
    // Pick a random block from StandardBlocks enum
    Block genBlock = _blockTypes[_determineBlockType()].copy();

    /// _specialTileEveryX is used to define how often blocks with special tiles
    /// are generated, for example: 1 makes every block have a special tile,
    /// 2 makes every other block have one, and 0 or less means that blocks
    /// should never have special tiles
    ///

    //print("specialCounter: $_specialCounter");
    //print("trombTileCounter: $_trombTileCounter");

    if (_specialTileEveryX <= 0) {
      // Do nothing
    } else if (_specialCounter > 1) {
      // Decrement counter
      _specialCounter--;
    } else {
      /// If _specialCounter is 0: replace a random tile in generated block with
      /// a special tile and reset counter

      _trombTileCounter++;
      double spawnRate = 0.5;
      int specialTileType = _rdGen.nextInt(_specialTiles.length);
      for (int i = 0; i < genBlock.tileType.length; i++) {
        double temp = _rdGen.nextDouble();
        if (temp < spawnRate) {
          genBlock.tileType[i] = _specialTiles[specialTileType];
          spawnRate = spawnRate + 0.1;
        }
      }

      if (_trombTileCounter >= 4) {
        _specialCounter = _specialTileEveryX;
        _trombTileCounter = 0;
      }

      // int tileIndex = _rdGen.nextInt(genBlock.tileType.length);

      // genBlock.tileType[tileIndex] = _specialTiles[specialTileType];
      /*if ((tileIndex + 1) >= genBlock.tileType.length){
          genBlock.tileType[tileIndex-1] = _specialTiles[specialTileType];
      }else{
          genBlock.tileType[tileIndex+1] = _specialTiles[specialTileType];
      }*/

    }

    return genBlock;
  }

  /// Adds a new block to the tail of the upcoming blocks list and returns the
  /// head after popping
  Block newBlock() {
    _upcomingBlocks.add(_generateBlock());
    return _upcomingBlocks.removeAt(0);
  }

  List<Block> getUpcomingBlocks() {
    return _upcomingBlocks;
  }

  /// Function for determining the next block type as well as updating
  /// the probabilities of generating each block type.
  ///
  /// The probability algorithm works similar to a lottery scheduler, alotting
  /// tickets to each block type which increases their probability of being
  /// generated until they are chosen, at which point their tickets are nulled.
  int _determineBlockType() {
    // Deal tickets while getting the total amount of tickets
    int tickets = 0;
    for (int i = 0; i < _blockTypeProb.length; i++) {
      _blockTypeProb[i]++;
      tickets += _blockTypeProb[i];
    }

    // Declare a winning ticket number
    int winnerTicket = _rdGen.nextInt(tickets);
    tickets = 0;

    /// Find which block type that has the winning ticket number by summing up
    /// the tickets of all block types until the sum is greater or equal to the
    /// winning ticket number
    for (int i = 0; i < _blockTypeProb.length; i++) {
      tickets += _blockTypeProb[i];
      if (tickets >= winnerTicket) {
        // Reset tickets of winner and return number
        _blockTypeProb[i] = 0;
        return i;
      }
    }

    return 0; // Should not be reachable
  }

  /// Function for loading and parsing txt-files containing
  /// definitions for custom blocks
  ///
  /// Expected format for blocks are:
  ///
  /// -0--
  /// -1--
  /// -2--
  /// -3--
  ///
  /// where indices for tiles are marked by numerical values among filler
  /// symbols
  ///
  /// ----
  /// -0--  <-- In this block, 0 resides in the block origin, while 1 is at
  /// ----      position [2, -2]
  /// ---1
  ///
  List<Block> _parseBlockTypeDef(String blockTypeDef) {
    List<Block> customBlockTypes = [];

    List<String> blockDefs = blockTypeDef.split("block {");
    for (var i = 1; i < blockDefs.length; i++) {
      customBlockTypes.add(_parseBlockDef(blockDefs[i].trim()));
    }

    return customBlockTypes;
  }

  /// Function for parsing individual block type definitions
  Block _parseBlockDef(String typeDef) {
    Block parsedBlock = Block();
    var rotations = typeDef.split("rot {");
    for (var i = 0; i < rotations.length; i++) {
      rotations[i] = rotations[i].trim();
    }

    // Expected first line: "tiles = [x, x, x, ...]" containing the tileTypes
    // of each tile in the block (note that each rotation needs to have the
    // same amount of tiles)
    var tileDef = rotations.removeAt(0);

    // Reduce "tiles = [x, x, x, ...]" to "x, x, x, ..."
    tileDef = tileDef.substring(tileDef.indexOf("[") + 1, tileDef.indexOf("]"));

    // Convert string "array" to int array
    var tiles = tileDef.split(",");
    List<int> tileType = [];
    for (var i = 0; i < tiles.length; i++) {
      tileType.add(int.parse(tiles[i].trim()));
    }
    parsedBlock.tileType = tileType;

    // Init rotation to a list with a length corresponding to the number of rotations,
    // each rotation containing a list with a length corresponding to the number of tiles
    parsedBlock.rotation = List<List>.generate(rotations.length,
        (index) => List<List>.generate(tileType.length, (index) => []));

    /// Expected input is rotations defined by placement of tile indices among
    /// some type of filler
    for (var i = 0; i < rotations.length; i++) {
      // Separate each line and trim whitespace for parsing of positions
      var rotLines = rotations[i].replaceAll("}", "").split("\n");
      for (var j = 0; j < rotLines.length; j++) {
        rotLines[j] = rotLines[j].trim();
      }

      // Look through each line to find indices
      for (var y = 0; y < rotLines.length; y++) {
        // If a line is mere whitespace, skip line
        if (rotLines[y] == "") {
          continue;
        } else {
          // Else, search through line iteratively for numerical values
          int x = 0;
          do {
            x = rotLines[y].indexOf(RegExp(r'\d'), x);
            if (x != -1) {
              // An index was found, place coordinates at found index in block rotation definition
              parsedBlock.rotation[i]
                  [int.parse(rotLines[y][x])] = [x - 1, y - 1];
              x++;
            } else {
              break;
            }
          } while (x != -1);
        }
      }
    }

    return parsedBlock;
  }
}
