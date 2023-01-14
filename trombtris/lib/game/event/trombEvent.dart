import 'package:trombtris/game/event/event.dart';
import 'package:trombtris/webpages/trombtrisGame.dart';

class TrombEvent implements Event {
  late TrombtrisGame g;
  late List position;

  TrombEvent(this.position) {
    g = TrombtrisGame.game;
    g.eventStreamController.add(this);
  }

  @override
  execute() {
    g.playTrombAnim(position);
  }
}
