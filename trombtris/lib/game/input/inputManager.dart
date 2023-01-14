import 'dart:js_util';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trombtris/game/gameManager.dart';

enum Controls { moveLeft, moveRight, rotate, softDrop, instantPlace, holdBlock }

const List<LogicalKeyboardKey> defaultKeybinds = [
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.shiftLeft
];

class InputManager extends Component with KeyboardHandler {
  late GameManager g;

  // _keybinds should be a list with the same length as the Controls enum, where
  // each LogicalKeyboardKey corresponds to the control with the same index
  final List<LogicalKeyboardKey> _keybinds = [];

  InputManager(this.g) {
    // Init _keybinds list
    for (var element in defaultKeybinds) {
      _keybinds.add(element);
    }

    // If saved keybinds exist, overwrite default
    _tryGetKeybinds();
  }

  // Override of onKeyEvent that simply receives keys and sends the first key
  // pressed to sendKey in gameManager (if the LogicalKey is in the
  // _keybinds list)
  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isKeyDown = event is RawKeyDownEvent;

    if (!event.repeat) {
      int control = _keybinds.indexOf(event.data.logicalKey);

      if (control != -1) {
        g.handleInput(Controls.values[control], isKeyDown);
      }
    }

    return false; // Do not allow any other input reading
  }

  // Asynchronously loads any saved keybinds to be set as the current keybinds
  // (if any saved keybinds are found)
  void _tryGetKeybinds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var savedKeybinds = prefs.getStringList("keybinds");

    if (savedKeybinds != null) {
      for (var i = 0; i < savedKeybinds.length; i++) {
        _keybinds[i] = LogicalKeyboardKey(int.parse(savedKeybinds[i]));
      }
    }
  }
}
