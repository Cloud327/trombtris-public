import 'package:trombtris/game/event/event.dart';
import 'package:trombtris/webpages/trombtrisGame.dart';

class PlaceEvent implements Event {
  late TrombtrisGame g;
  late List position;

  PlaceEvent(this.position) {
    g = TrombtrisGame.game;
    g.eventStreamController.add(this);
  }

  @override
  execute() {
    g.playPlaceAnimation(position);
  }
}
