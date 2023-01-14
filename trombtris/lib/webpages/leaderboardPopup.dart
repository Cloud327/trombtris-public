import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:trombtris/webpages/multiplayerPage.dart';
import 'gameBoardPage.dart';
import 'loginPopup.dart';

import 'package:audioplayers/audioplayers.dart';

// Popup
class LeaderboardPopup extends StatefulWidget {
  const LeaderboardPopup({super.key});

  @override
  State<LeaderboardPopup> createState() => _LeaderboardPopup();
}

class _LeaderboardPopup extends State<LeaderboardPopup> {
  @override
  Widget build(BuildContext context) {
    var deviceData = MediaQuery.of(context);
    var leaderboardNameList = ["", "", "", "", "", "", "", "", "", ""];
    var leaderboardScoreList = ["", "", "", "", "", "", "", "", "", ""];

    String removeUnwantedText(var text) {
      text = text.toString();
      return text.substring(7, text.length - 1);
    }

    void fillLeaderboard() {
      network.frontPageLeaderboard().then((value) => {
            for (int i = 0; i < value[1].length; i++)
              {
                leaderboardNameList[i] = removeUnwantedText(value[1][i]),
                leaderboardScoreList[i] = value[0][i].toString(),
                setState(() {}),
              },
          });
    }

    Color blue = const Color.fromRGBO(50, 194, 216, 1); // sky blue crayola
    Color blueDarker = const Color(0xFF2095A7);
    //
    //
    // popup window
    var leaderboardWindow = Container(
      alignment: Alignment.center,
      child: SizedBox(
          width: deviceData.size.width * 0.23,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Leaderboard",
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
                child: Container(
                  margin: const EdgeInsets.all(1.0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5.0),
                      gradient: LinearGradient(
                        colors: [blueDarker, blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )),
                  child: FutureBuilder(
                      future: network.frontPageLeaderboard(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasError) {
                            return Text("An error has occured");
                          } else if (snapshot.hasData) {
                            var value = snapshot.data;
                            for (int i = 0; i < value?[1].length; i++) {
                              leaderboardNameList[i] =
                                  removeUnwantedText(value?[1][i]);
                              var score = value?[0][i];
                              leaderboardScoreList[i] = score.toString();
                            }
                          }
                        } else {
                          return Text("Loading leaderboard...");
                        }
                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          shrinkWrap: true,
                          children: <Widget>[
                                const SizedBox(height: 20),
                              ] +
                              leaderboardList(leaderboardNameList,
                                  leaderboardScoreList, deviceData)
                              //+[leaderboardRow(9999, "You", "333", false, deviceData)],
                              +
                              [const SizedBox(height: 20)],
                        );
                      }),
                ),
              ),
            ],
          )),
    );
    return leaderboardWindow;
  }
}

Widget leaderboardRow(number, textName, textScore, doAlignName, deviceData) {
  var textStyle = TextStyle(
    fontSize: deviceData.size.height * 0.022,
    overflow: TextOverflow.clip,
    color: Colors.white,
    fontFamily: 'Galano Grotesque',
  );

  var boldTextStyle = TextStyle(
    fontSize: deviceData.size.height * 0.022,
    overflow: TextOverflow.clip,
    color: Colors.white,
    fontFamily: 'Galano Grotesque',
    fontWeight: FontWeight.bold,
  );

  int numberFlex = 0;
  if (doAlignName) {
    numberFlex = 1;
  }

  return Container(
    height: deviceData.size.height * 0.04,
    margin: const EdgeInsets.symmetric(vertical: 4.0),
    padding: const EdgeInsets.symmetric(
      vertical: 1.0,
      horizontal: 6.0,
    ),
    child: Row(
      children: [
        Expanded(
            flex: numberFlex,
            child: Text("$number",
                textAlign: TextAlign.left, style: boldTextStyle)),
        Expanded(
          flex: 5,
          child: Text(textName, textAlign: TextAlign.left, style: textStyle),
        ),
        Expanded(
          flex: 3,
          child: Text("$textScore",
              textAlign: TextAlign.right, style: boldTextStyle),
        ),
      ],
    ),
  );
}

List<Widget> leaderboardList(
    leaderboardNameList, leaderboardScoreList, deviceData) {
  Color blue = const Color.fromRGBO(50, 194, 216, 1); // sky blue crayola

  return List.generate(leaderboardNameList.length, (index) {
    return Column(children: [
      leaderboardRow(index + 1, leaderboardNameList[index],
          leaderboardScoreList[index], true, deviceData),
      if (index != leaderboardNameList.length - 1)
        SizedBox(
          height: 2,
          child: Container(
            color: blue,
          ),
        ),
    ]);
  });
}
