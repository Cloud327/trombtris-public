import 'package:trombtris/game/event/event.dart';
import 'package:trombtris/webpages/trombtrisGame.dart';

class InstantPlaceEvent implements Event {
  late TrombtrisGame g;
  late List position;
  late int dropHeight;

  InstantPlaceEvent(this.position, this.dropHeight) {
    g = TrombtrisGame.game;
    g.eventStreamController.add(this);
  }

  @override
  execute() {
    g.playInstantPlaceAnimation(position, dropHeight);
  }
}
