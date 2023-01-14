import 'package:trombtris/game/event/event.dart';
import 'package:trombtris/webpages/trombtrisGame.dart';

class GameOverEvent implements Event {
  late TrombtrisGame g;

  GameOverEvent() {
    g = TrombtrisGame.game;
    g.eventStreamController.add(this); // Event should be executed in lateRender
  }

  @override
  execute() {
    g.playGameOverAnim();
  }
}
