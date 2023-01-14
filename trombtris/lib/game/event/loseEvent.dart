import 'package:trombtris/game/event/event.dart';
import 'package:trombtris/webpages/trombtrisGame.dart';

class LoseEvent implements Event {
  late TrombtrisGame g;

  LoseEvent() {
    execute();
  }

  @override
  execute() {
    g = TrombtrisGame.game;
    g.setResult(false);
  }
}
