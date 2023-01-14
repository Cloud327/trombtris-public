import 'package:trombtris/game/event/event.dart';
import 'package:trombtris/webpages/trombtrisGame.dart';

class LineClearEvent implements Event {
  late TrombtrisGame g;
  late List clearedLines; // A list of the lines that have been cleared
  late int
      boardIndex; // Index of the board on which a LineClearEvent has happened

  LineClearEvent(this.clearedLines, this.boardIndex) {
    g = TrombtrisGame.game;
    g.eventStreamController.add(this);
  }

  @override
  execute() {
    g.playLineClearAnim(clearedLines);
  }
}
