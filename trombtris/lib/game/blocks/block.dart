import 'package:flutter/foundation.dart';

class Block {
  // The placement that the origin has on the board
  Int32List originPos = Int32List(2);

  // Array defining all possible rotations this block can have
  // NOTE: Block origin should always be first element in each list
  List<List> rotation = [];

  // The current rotation that the block has
  int currentRot = 0;

  // Array defining which type of tile each index should have
  List<int> tileType = [];

  // Creates a copy of a block with the internal values being actual copies and not references
  Block copy() {
    Block copy = Block();
    copy.originPos[0] = originPos[0];
    copy.originPos[1] = originPos[1];
    for (int i = 0; i < rotation.length; i++) {
      copy.rotation.add(rotation[
          i]); // The internal rotaion lists are not real copies, only references, this might become a problem?
    }
    copy.currentRot = currentRot;
    for (int i = 0; i < tileType.length; i++) {
      copy.tileType.add(tileType[i]);
    }
    return copy;
  }
}
