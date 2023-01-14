import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trombtris/game/input/inputManager.dart';
import 'package:trombtris/webpages/startPage.dart';

class ControlsPopup extends StatefulWidget {
  ControlsPopup({super.key});
  final List<BindButtonState> buttonStates =
      []; // good luck updating state of buttons without this bad boy

  @override
  State<ControlsPopup> createState() => ControlsPopupState();
}

class ControlsPopupState extends State<ControlsPopup> {
  late FocusScope _controlBoard;
  List<BindButton> _bindButtons = [];
  List<Widget> _buttons = [];
  late final List<LogicalKeyboardKey> _keybinds = [];

  bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 700;

  bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  @override
  Widget build(BuildContext context) {
    var deviceData = MediaQuery.of(context);
    double buttonFontSize;
    double buttonWidth;
    double buttonHeight;
    //double logoWidth;
    //double logoHeight;

    if (isDesktop(context)) {
      buttonFontSize = deviceData.size.width * 0.013;
      buttonWidth = deviceData.size.width * 0.08;
      buttonHeight = deviceData.size.height * 0.09;
      //logoWidth = deviceData.size.width * 0.45;
      //logoHeight = deviceData.size.height * 0.45;
    } else {
      buttonFontSize = deviceData.size.width * 0.03;
      buttonWidth = deviceData.size.width * 0.7;
      buttonHeight = deviceData.size.height * 0.15;
      //logoWidth = deviceData.size.width * 0.6;
      //logoHeight = deviceData.size.height * 0.6;
    }

    Color blue = const Color.fromRGBO(50, 194, 216, 1); // sky blue crayola
    Color blueDarker = const Color(0xFF2095A7);

    // Init keybinds
    for (var bind in defaultKeybinds) {
      _keybinds.add(bind);
    }

    // Try to get saved keybinds asynchronously
    _tryGetKeybinds();

    Widget buttonWidget(BindButton btn) {
      return Container(
        height: buttonHeight,
        decoration: BoxDecoration(
          color: blue,
          borderRadius: BorderRadius.circular(5.0),

        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(
          vertical: 1.0,
          horizontal: 6.0,
        ),
        child: btn,
      );
    }

    // Create a button for each control
    _bindButtons = [];
    _buttons = [];
    for (var i = 0; i < Controls.values.length; i++) {
      BindButton btn = BindButton(
        this,
        _camelCaseToTitleCase(Controls.values[i].name),
        _keyName(_keybinds[i]),
        i,
        buttonWidth,
        buttonHeight,
        buttonFontSize,
        Colors.transparent,
        Colors.transparent,
      );

      _bindButtons.add(btn);
      _buttons.add(buttonWidget(btn));
    }

    Widget layout() {
      TextStyle textStyle = TextStyle(
        color: Colors.white,
      );

      return Container(
        alignment: Alignment.center,
        child: SizedBox(
            width: deviceData.size.width * 0.23,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Controls",
                  style: TextStyle(
                    fontSize: deviceData.size.width * 0.018,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Galano Grotesque',
                    decoration: TextDecoration.none,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Card(
                  elevation: 15,
                  color: blueDarker,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    shrinkWrap: true,
                    children: <Widget> 
                    [const SizedBox(height: 15)] 
                    + _buttons
                    + [const SizedBox(height: 15)]
                  ),
                  
                ),
              ],
            )),
      );
    }

/*
    Widget layout = ButtonBar(
      alignment: MainAxisAlignment.center,
      children: _bindButtons,
    );
*/
    _controlBoard = FocusScope(
      autofocus: true,
      canRequestFocus: true,
      child: layout(),
    );

    return _controlBoard;
  }

  /// Asynchronously loads any saved keybinds to be set as the current keybinds
  /// (if any saved keybinds are found)
  void _tryGetKeybinds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var savedKeybinds = prefs.getStringList("keybinds");

    if (savedKeybinds != null) {
      for (var i = 0; i < savedKeybinds.length; i++) {
        _keybinds[i] = LogicalKeyboardKey(int.parse(savedKeybinds[i]));
        _bindButtons[i].buttonKey = _keyName(_keybinds[i]);
        widget.buttonStates[i]
            .setState(() {}); // Update state so button shows new bind
      }
    }
  }

  /// Converts the current array of keybinds to a string array and saves it
  /// to SharedPreferences
  void _saveKeybinds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> newKeybinds = [];
    for (var bind in _keybinds) {
      newKeybinds.add(bind.keyId.toString());
    }
    prefs.setStringList("keybinds", newKeybinds);
  }

  /// Changes a given keybind to another key, potentially swapping keybinds
  /// with another control that may have had the key already assigned to it
  ///
  /// Also returns a string holding a proper name of the key (useful for writing on buttons)
  String? rebindKey(int bindIndex, LogicalKeyboardKey key) {
    // If the key is already bound to another control, swap keybinds
    if (_keybinds.contains(key)) {
      // Grab index of previous keybind the key was used for
      int oldIndex = _keybinds.indexOf(key);
      // Swap keys
      _keybinds[oldIndex] = _keybinds[bindIndex];
      widget.buttonStates[oldIndex].setState(() {
        widget.buttonStates[oldIndex].widget.buttonKey =
            _keyName(_keybinds[oldIndex]);
      }); // Update state of other keybind's button
    }

    _keybinds[bindIndex] = key;
    _saveKeybinds();
    return _keyName(key);
  }

  /// Wacky way of converting lowercaseCamelCase into Title Case
  /// Handy for converting names of enum values into more read-friendly strings
  String _camelCaseToTitleCase(String camelCase) {
    String titleCase =
        camelCase.splitMapJoin(RegExp(r'[A-Z]'), onMatch: (p0) => " ${p0[0]!}");
    titleCase =
        titleCase.substring(0, 1).toUpperCase() + titleCase.substring(1);
    return titleCase;
  }

  /// Converts some keyLabels into a more readable form
  /// For example: Space's keyLabel is converted from ' ' to 'Space'
  String _keyName(LogicalKeyboardKey key) {
    ///
    ///                No switches?
    ///     ⠀⣞⢽⢪⢣⢣⢣⢫⡺⡵⣝⡮⣗⢷⢽⢽⢽⣮⡷⡽⣜⣜⢮⢺⣜⢷⢽⢝⡽⣝
    ///     ⠸⡸⠜⠕⠕⠁⢁⢇⢏⢽⢺⣪⡳⡝⣎⣏⢯⢞⡿⣟⣷⣳⢯⡷⣽⢽⢯⣳⣫⠇
    ///     ⠀⠀⢀⢀⢄⢬⢪⡪⡎⣆⡈⠚⠜⠕⠇⠗⠝⢕⢯⢫⣞⣯⣿⣻⡽⣏⢗⣗⠏⠀
    ///     ⠀⠪⡪⡪⣪⢪⢺⢸⢢⢓⢆⢤⢀⠀⠀⠀⠀⠈⢊⢞⡾⣿⡯⣏⢮⠷⠁⠀⠀
    ///     ⠀⠀⠀⠈⠊⠆⡃⠕⢕⢇⢇⢇⢇⢇⢏⢎⢎⢆⢄⠀⢑⣽⣿⢝⠲⠉⠀⠀⠀⠀
    ///     ⠀⠀⠀⠀⠀⡿⠂⠠⠀⡇⢇⠕⢈⣀⠀⠁⠡⠣⡣⡫⣂⣿⠯⢪⠰⠂⠀⠀⠀⠀
    ///     ⠀⠀⠀⠀⡦⡙⡂⢀⢤⢣⠣⡈⣾⡃⠠⠄⠀⡄⢱⣌⣶⢏⢊⠂⠀⠀⠀⠀⠀⠀
    ///     ⠀⠀⠀⠀⢝⡲⣜⡮⡏⢎⢌⢂⠙⠢⠐⢀⢘⢵⣽⣿⡿⠁⠁⠀⠀⠀⠀⠀⠀⠀
    ///     ⠀⠀⠀⠀⠨⣺⡺⡕⡕⡱⡑⡆⡕⡅⡕⡜⡼⢽⡻⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ///     ⠀⠀⠀⠀⣼⣳⣫⣾⣵⣗⡵⡱⡡⢣⢑⢕⢜⢕⡝⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ///     ⠀⠀⠀⣴⣿⣾⣿⣿⣿⡿⡽⡑⢌⠪⡢⡣⣣⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ///     ⠀⠀⠀⡟⡾⣿⢿⢿⢵⣽⣾⣼⣘⢸⢸⣞⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    ///     ⠀⠀⠀⠀⠁⠇⠡⠩⡫⢿⣝⡻⡮⣒⢽⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    /// ⠀⠀⠀
    /// YOU CAN'T USE A SWITCH FOR LOGICALKEYBOARDKEY BECAUSE
    /// THEY'VE OVERRIDDEN THE '==' OPERATOR
    /// and also keys have no const that you can compare
    if (key == LogicalKeyboardKey.space) {
      return "Space";
    } else if (key == LogicalKeyboardKey.shiftLeft) {
      return "Left Shift";
    } else if (key == LogicalKeyboardKey.shiftRight) {
      return "Right Shift";
      // Feel free to add more keys with bad keyLabels
    } else {
      return key.keyLabel;
    }
  }
}

Widget Button(buttonWidth, buttonHeight, buttonText, buttonFontSize,
    buttonColor, buttonShade, buildContext, targetPage) {
  return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        gradient: LinearGradient(
          colors: [buttonShade, buttonColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(buttonColor),
            elevation: MaterialStateProperty.all(10),
            shadowColor: MaterialStateProperty.all<Color>(buttonColor),
          ),
          onPressed: () {
            Navigator.push(
              buildContext,
              MaterialPageRoute(builder: (buildContext) => targetPage),
            );
          },
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: buttonFontSize,
              color: Colors.white,
            ),
          ),
        ),
      ));
}

// ignore: must_be_immutable
class BindButton extends StatefulWidget {
  late final ControlsPopupState c;
  late String buttonBind; // The bind that this button holds
  late String buttonKey; // The key for this button's bind/control
  late int buttonIndex;
  late double buttonWidth;
  late double buttonHeight;
  late double buttonFontSize;
  late Color buttonColor;
  late Color buttonShade;

  BindButton(
      this.c,
      this.buttonBind,
      this.buttonKey,
      this.buttonIndex,
      this.buttonWidth,
      this.buttonHeight,
      this.buttonFontSize,
      this.buttonColor,
      this.buttonShade,
      {super.key});

  @override
  BindButtonState createState() => BindButtonState();
}

class BindButtonState extends State<BindButton> {
  @override
  Widget build(BuildContext context) {
    Widget bindButton = Focus(onKeyEvent: (node, event) {
      /// This Focus onKeyEvent allows the button to handle a single keyEvent
      /// whenever it has become focused, at which point it removes focus and
      /// thus ignores further keyEvents
      setState(() {
        String? keyName =
            widget.c.rebindKey(widget.buttonIndex, event.logicalKey);
        widget.buttonKey = keyName!;
      });
      FocusManager.instance.primaryFocus!.unfocus();
      return KeyEventResult.handled;
    }, child: Builder(builder: (BuildContext context) {
      final FocusNode focusNode = Focus.of(context);
      final bool hasFocus = focusNode.hasFocus;

      /// All the rest here can be replaced with something that's nicer to look
      /// at, as long as it contains a button with a similar onPressed function.
      return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.0),
            gradient: LinearGradient(
              colors: [widget.buttonShade, widget.buttonColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SizedBox(
            width: widget.buttonWidth,
            height: widget.buttonHeight,
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(widget.buttonColor),
                elevation: MaterialStateProperty.all(10),
                shadowColor:
                    MaterialStateProperty.all<Color>(widget.buttonColor),
              ),
              onPressed: () {
                // Give this button the focus, so it can handle the next key press
                if (!hasFocus) {
                  focusNode.requestFocus();
                }
              },
              child: Text(
                hasFocus
                    ? "Press any key"
                    : "${widget.buttonBind}\n${widget.buttonKey}",
                style: TextStyle(
                  fontSize: widget.buttonFontSize,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ));
    }));

    /// Add this button state to the ControlPage buttonState list so that
    /// the ControlPage can update the state of this button in case saved binds
    /// are loaded
    widget.c.widget.buttonStates.add(this);
    return bindButton;
  }
}
