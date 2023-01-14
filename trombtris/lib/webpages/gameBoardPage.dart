import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:trombtris/webpages/trombtrisGame.dart';
import 'package:trombtris/webpages/loginPopup.dart';
import 'package:audioplayers/audioplayers.dart';

class GameBoardPage extends StatefulWidget {
  const GameBoardPage({super.key});

  @override
  State<GameBoardPage> createState() => _GameBoardPageState();
}

class _GameBoardPageState extends State<GameBoardPage> {
  final player = AudioPlayer();
  ValueNotifier<double> volume = ValueNotifier<double>(1.0);

  @override
  void initState() {
    super.initState();
  }

  bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  bool _startPrompt = true;
  bool isPlaying = false;
  String nickname = "";
  var guestNicknameTEC = TextEditingController();

  void start() {
    setState(() {
      _startPrompt = false;
      //Starts the music when playing the game
      player.play(AssetSource('Tetris.mp3'));
      player.onPlayerComplete.listen((event) {
        player.play(AssetSource('Tetris.mp3'));
      });
      isPlaying = true;
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var deviceData = MediaQuery.of(context); // this is useful now!
    SingleplayerTrombtrisGame trombtrisGame = SingleplayerTrombtrisGame();

    double sizeFactor = 0.92;
    double buttonFontSize;
    double buttonWidth;
    double buttonHeight;
    //double logoWidth;
    //double logoHeight;
    double instructionsFontSize;
    double blockSize;

    if (isDesktop(context)) {
      buttonFontSize = deviceData.size.width * 0.015;
      buttonWidth = deviceData.size.width * 0.3;
      buttonHeight = deviceData.size.height * 0.08;
      //logoWidth = deviceData.size.width * 0.45;
      //logoHeight = deviceData.size.height * 0.45;
      instructionsFontSize =
          min(deviceData.size.width * 0.013, deviceData.size.height * 0.026);
      blockSize =
          min(deviceData.size.width * 0.03, deviceData.size.height * 0.04);
    } else {
      buttonFontSize = deviceData.size.width * 0.045;
      buttonWidth = deviceData.size.width * 0.7;
      buttonHeight = deviceData.size.height * 0.15;
      //logoWidth = deviceData.size.width * 0.6;
      //logoHeight = deviceData.size.height * 0.6;
      instructionsFontSize = deviceData.size.width * 0.03;
      blockSize = deviceData.size.width * 0.04;
    }

    Widget leftSide = Container(
        width: (deviceData.size.width / 2 -
                deviceData.size.height * sizeFactor / 2.5)
            .abs(),
        child: Stack(
          children: [
            Positioned(
                // alignment: Alignment(-0.76, -0.88),
                top: 50,
                left: 50,
                child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        onTap: () => {
                              player.stop(),
                              Navigator.pop(context),
                            },
                        child: Image(
                          height: deviceData.size.height * 0.2,
                          image:
                              AssetImage("assets/tromb_logo_magenta_dye.png"),
                        )))),
            Positioned(
                top: deviceData.size.height / 3.2,
                left: 50,
                child: Text(
                  "Volume",
                  style: TextStyle(
                    fontSize: instructionsFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                )),
            Positioned(
              top: deviceData.size.height / 3,
              left: 25,
              child: ValueListenableBuilder<double>(
                valueListenable: volume,
                builder: (BuildContext context, double value, Widget? child) {
                  return Slider(
                    value: value,
                    min: 0.0,
                    max: 1.0,
                    activeColor: const Color(0xfff2aa00),
                    inactiveColor: const Color.fromARGB(140, 242, 169, 0),
                    onChanged: (newVolume) {
                      volume.value = newVolume;
                      player.setVolume(volume.value);
                    },
                  );
                },
              ),
            ),
          ],
        ));

    Widget block(bool visible) {
      return SizedBox(
        width: blockSize,
        height: blockSize,
        child: Container(
          margin: EdgeInsets.all(deviceData.size.width * 0.001),
          decoration: BoxDecoration(
            color: (visible) ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(deviceData.size.width * 0.006),
            boxShadow: [
              BoxShadow(
                  blurRadius: .5,
                  color: (visible)
                      ? const Color.fromARGB(255, 50, 194, 216)
                      : Colors.transparent),
            ],
          ),
        ),
      );
    }

    Widget logo() {
      return Expanded(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.topLeft,
                child: Column(
                  children: [
                    //Expanded(flex: 1, child: Container()),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Tromb Logo →",
                        style: TextStyle(
                          fontSize: instructionsFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(flex: 1, child: Container()),
                  ],
                ),
              ),
            ),
            Expanded(flex: 1, child: Container()),
            Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Column(
                    children: [
                      Row(children: [block(true), block(true), block(false)]),
                      Row(children: [block(false), block(true), block(true)]),
                      Row(children: [block(false), block(true), block(false)]),
                    ],
                  ),
                ))
          ],
        ),
      );
    }

    Widget instructions() {
      String instructionText = """Controls: 
    Left/Right arrow key to move.
    Up arrow key to rotate.
    Down arrow key to fall faster.
    Space bar to instantly place.
    Shift to hold.

Special rules:
    Use the special tiles to assemble
    the Tromb logo for a nice reward!
""";

      TextStyle textStyle = TextStyle(
        fontSize: instructionsFontSize,
        color: Colors.white,
      );

      Color shade1A = const Color(0xFFC7CED3);
      Color shade1B = const Color(0xFF252A2F);
      Color shade1D = const Color(0xFF191C1F);
      Color shade1C = const Color(0xFF0C0E10);

      return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [shade1D, shade1B, shade1B, shade1B, shade1B, shade1B],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            backgroundBlendMode: BlendMode.luminosity,
            border: Border(
              left: BorderSide(color: shade1C, width: 2.5),
              top: BorderSide(color: shade1C, width: 2.5),
              right: BorderSide(color: shade1A, width: 2.0),
              bottom: BorderSide(color: shade1A, width: 2.0),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: buttonWidth,
                child: Text(
                  instructionText,
                  style: textStyle,
                ),
              ),
              // logo(),
            ],
          ));
    }

    Widget prompt(buttonWidth, buttonHeight, buttonText, buttonFontSize,
        buttonColor, buttonShade, buildContext) {
      return Row(
        children: [
          Expanded(flex: isDesktop(context) ? 5 : 1, child: leftSide),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(flex: 6, child: Container()),
                Expanded(
                    flex: 3,
                    child: SizedBox(
                      width: buttonWidth,
                      child: TextField(
                        maxLength: 13,
                        controller: guestNicknameTEC,
                        obscureText: false,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          hintText: "Enter Nickname",
                          counterText: "",
                        ),
                      ),
                    )),
                Expanded(flex: 0, child: Container()), // Spacer
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        alignment: Alignment.center,
                        backgroundColor:
                            MaterialStateProperty.all<Color>(buttonColor),
                        elevation: MaterialStateProperty.all(10),
                        shadowColor:
                            MaterialStateProperty.all<Color>(buttonShade),
                      ),
                      onPressed: () {
                        nickname = guestNicknameTEC.text;
                        try {
                          network.setUsername(nickname);
                        } catch (e) {
                          print(
                              "Failed to send username to server, no connection?");
                        }
                        start();
                      },
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(flex: 2, child: Container()), // Spacer
                Expanded(
                  flex: 2,
                  child: Text(
                    "Instructions",
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(flex: 17, child: instructions()),
                Expanded(flex: 5, child: Container()), // Spacer
              ],
            ),
          ),
          Expanded(flex: isDesktop(context) ? 5 : 1, child: Container()),
        ],
      );
    }

    Widget gameBoard = Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo image
          SizedBox(
              height: deviceData.size.height * sizeFactor,
              width: deviceData.size.height * sizeFactor / 2,
              child: GameWidget(game: trombtrisGame)),
        ],
      ),
    );

    Widget layout = Stack(children: <Widget>[
      leftSide,
      gameBoard,
    ]);

    return MaterialApp(
        title: 'Trombtris',
        home: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/trombtrisbackground.png"),
                fit: BoxFit.cover),
          ),
          child: Scaffold(
              backgroundColor: Colors.transparent,
              body: FocusScope(
                child: (!_startPrompt)
                    ? layout
                    : prompt(
                        buttonWidth,
                        buttonHeight,
                        "Start New Game",
                        buttonFontSize,
                        const Color.fromRGBO(192, 20, 113, 1),
                        Color(0xFFEB3995),
                        context,
                      ),
                // this is only the button currently
              )),
        ));
  }
}
