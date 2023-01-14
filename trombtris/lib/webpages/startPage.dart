import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:trombtris/webpages/controlsPopup.dart';
import 'package:trombtris/webpages/leaderboardPopup.dart';
import 'package:trombtris/webpages/multiplayerPage.dart';
import 'gameBoardPage.dart';
import 'loginPopup.dart';

import 'package:audioplayers/audioplayers.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => StartPageState();
}

class StartPageState extends State<StartPage> {
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
    double logoWidth;
    double logoHeight;
    if (isDesktop(context)) {
      buttonFontSize = deviceData.size.width * 0.015;
      buttonWidth = deviceData.size.width * 0.25;
      buttonHeight = deviceData.size.height * 0.07;
      logoWidth = deviceData.size.width * 0.45;
      logoHeight = deviceData.size.height * 0.2;
    } else {
      buttonFontSize = deviceData.size.width * 0.07;
      buttonWidth = deviceData.size.width * 0.7;
      buttonHeight = deviceData.size.height * 0.15;
      logoWidth = deviceData.size.width * 0.6;
      logoHeight = deviceData.size.height * 0.6;
    }

    Color magenta = const Color.fromRGBO(192, 20, 113, 1); // magenta
    Color magentaShade = const Color(0xFFEB3995);
    Color orange = const Color(0xFFF4721C);
    Color orangeShade = const Color(0xFFF4721C);
    double sizeFactor = 0.92;

    // Left side features a logo and buttons to reach game modes
    Widget centerSide = Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo image
          SizedBox(
            width: logoWidth,
            height: logoHeight,
            child: Text(
              "Trombtris",
              style: TextStyle(
                fontSize: deviceData.size.width * 0.07,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: deviceData.size.height * 0.01),

          // First game button - Single Player
          gameModeButton(
              buttonWidth,
              buttonHeight,
              "Single Player",
              buttonFontSize,
              magenta,
              magentaShade,
              context,
              const GameBoardPage(),
              false),

          SizedBox(height: deviceData.size.height * 0.015),

          // Second game button - VS Multiplayer
          gameModeButton(
              buttonWidth,
              buttonHeight,
              "VS - Multiplayer",
              buttonFontSize,
              magenta,
              magentaShade,
              context,
              const MultiplayerPage(),
              false),

          SizedBox(height: deviceData.size.height * 0.13),
        ],
      ),
    );

    return MaterialApp(
        title: 'Trombtris',
        theme: ThemeData(
          fontFamily: 'Galano Grotesque',
        ),
        home: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/trombtrisbackground.png"),
                  fit: BoxFit.cover),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(children: <Widget>[
                Positioned(
                    // alignment: Alignment(-0.94, -0.88),
                    top: 50,
                    left: 50,
                    child: Image(
                      height: deviceData.size.height * 0.2,
                      image: AssetImage("assets/tromb_logo_magenta_dye.png"),
                    )),
                centerSide,
                Positioned(
                    // alignment: Alignment(-0.94, -0.88),
                    top: 50,
                    right: 50,
                    child: Column(
                      children: [
                        // gameModeButton(
                        //     buttonWidth / 1.5,
                        //     buttonHeight,
                        //     "Profile",
                        //     buttonFontSize,
                        //     orange,
                        //     orangeShade,
                        //     context,
                        //     LoginPopup(),
                        //     true),
                        // SizedBox(height: deviceData.size.height * 0.015),
                        gameModeButton(
                            buttonWidth / 1.5,
                            buttonHeight,
                            "Leaderboard",
                            buttonFontSize,
                            orange,
                            orangeShade,
                            context,
                            LeaderboardPopup(),
                            true),
                        SizedBox(height: deviceData.size.height * 0.015),
                        gameModeButton(
                            buttonWidth / 1.5,
                            buttonHeight,
                            "Change keybinds",
                            buttonFontSize,
                            orange,
                            orangeShade,
                            context,
                            ControlsPopup(),
                            true),
                      ],
                    )),
              ]),
            ) // Scaffold
            ));

    /// MaterialApp
  }

  Widget gameModeButton(buttonWidth, buttonHeight, buttonText, buttonFontSize,
      buttonColor, buttonShade, buildContext, targetPage, useDialog) {
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
              setState(() {});
              if (useDialog) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return targetPage;
                  },
                );
              } else {
                Navigator.push(
                  buildContext,
                  MaterialPageRoute(builder: (buildContext) => targetPage),
                );
              }
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

  @override
  bool get wantKeepAlive => true;
}
