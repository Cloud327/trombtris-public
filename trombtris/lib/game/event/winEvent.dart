import 'package:trombtris/game/event/event.dart';
import 'package:trombtris/webpages/trombtrisGame.dart';

class WinEvent implements Event {
  late TrombtrisGame g;

  WinEvent() {
    execute();
  }

  @override
  execute() {
    g = TrombtrisGame.game;
    g.setResult(true);
  }
}
