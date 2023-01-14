import 'dart:convert';

import 'package:nakama/rtapi.dart' as rt;
import 'package:trombtris/game/board/board.dart';
import 'package:trombtris/game/event/gameOverEvent.dart';
import 'package:trombtris/game/event/winEvent.dart';
import 'package:trombtris/game/event/loseEvent.dart';
import 'package:trombtris/game/gameManager.dart';
import 'package:trombtris/game/gameMode/trombMode.dart';
import 'package:trombtris/game/network/networkManager.dart';
import 'package:trombtris/webpages/trombtrisGame.dart';

import "gameMode.dart";

enum WinCondition { highScore, timeLimit, lineLimit, scoreLimit, trombLogo }

enum OpCode { boardData, playerLeave, gameOver, playerWin, scoreData, gameInfo }

class MultiplayerMode extends TrombMode {
  static const int _gameModeType = 2;
  static final _network = NetworkManager();
  double _timeSinceLastTick = 0;
  String opponentName = "No opponent";
  int opponentPoints = 0;
  int opponentLines = 0;
  bool opponentAlive = false;
  bool imAlive = false;
  static bool matchStarted = false;
  static const double
      _sendDataTickRate = // Determines how often the data should be sent to the server
      0.5;
  WinCondition _winCondition = WinCondition.highScore;
  double timeLimit = 120; // Default time limit = 2 minutes
  int lineLimit = 40;
  int scoreLimit = 10000;

  @override
  update(double dt) {
    _timeSinceLastTick = _timeSinceLastTick + dt;
    if (_timeSinceLastTick >= _sendDataTickRate && matchStarted) {
      // Only sends data to the network with a certain interval
      _timeSinceLastTick = _timeSinceLastTick - _sendDataTickRate;
      _network.sendData(GameManager.getGameState(0).toJson().toString(),
          OpCode.boardData.index);
    }
  }

  @override
  gameover() {
    imAlive = false;
    //print("gameover! sending data to opponent");
    _network.sendData("i lost :/", OpCode.gameOver.index);
    if (opponentAlive == false) {
      //print("opponent is also dead, checking wincon");
      if (_winCondition == WinCondition.highScore) {
        //print("wincon is score, comparing scores");
        compareScore(opponentPoints);
      }
      //_network.leaveMatch();
    } else {
      //print("opponent is still alive, awaiting gameover opcode");
      //Wait for opponent to lose aswell
    }
  }

  @override
  int getGameModeType() {
    return _gameModeType;
  }

  compareScore(int oppScore) {
    if (oppScore < super.getScore()) {
      announceWin();
    } else if (oppScore > super.getScore()) {
      announceLoss();
    } else { //draw
      announceLoss();
    }
  }

  Future<List<String>> enterMatchmakeQue() async {
    _network.startMatchmake();
    List<String> response = await _network.listenMatchmake();
    return response;
  }

  static setMatchStarted(bool state) {
    matchStarted = state;
  }

  leaveMatchmakeQue() {
    _network.stopMatchMake();
  }

  sendData(String data, int opCode){
    _network.sendData(data, opCode);
  }

  //Returns a stream of the match network data
  Stream<rt.MatchData> listenMatch() {
    return _network.listenMatch();
  }

  //Stream for players joining/leaving
  static Stream<rt.MatchPresenceEvent> listenJoin() {
    return _network.listenPresence();
  }

  //Waits for one opponent to join the game
  listenLeave() async {
    _network.listenPresence().listen((event) {
      if (event.leaves.isNotEmpty) {
        //print("I am the last player in the game");
        setMatchStarted(false);
        leaveGame();
      }
    });
  }

  //Creates a game and returns the matchId, also listens for people joining/leaving
  static Future<String> createGame() async {
    _network.listenPresenceEvents();
    return await _network.createMatch();
  }

  //Joins a given matchID, also listens for people joining/leaving
  Future<bool> joinGame(String matchId) async {
    _network.listenPresenceEvents();
    await _network.joinMatch(matchId);
    return true;
  }

  static void announceLeaveGame() {
    _network.sendData("i game over'd :/", OpCode.playerLeave.index);

    // Should also invoke some method that sends score and lines for score/line comparison depending on WinCondition
  }

  void announceWin() {
    WinEvent();
  }

  void announceLoss() {
    LoseEvent();
  }

  _setWinCondition(WinCondition condition) {
    _winCondition = condition;
  }

  // Override for relevant win condition
  @override
  clearEvent(List whichLines) {
    super.clearEvent(whichLines);
    sendScoreData();
    if (_winCondition == WinCondition.lineLimit && getLines() >= lineLimit) {
      GameOverEvent();
      announceWin();
    } else if (_winCondition == WinCondition.scoreLimit &&
        getScore() >= scoreLimit) {
      GameOverEvent();
      announceWin();
    }
  }

  // Override for relevant win condition
  @override
  dropPointIncrement(bool hardDrop) {
    super.dropPointIncrement(hardDrop);
    sendScoreData();
    if (_winCondition == WinCondition.scoreLimit && getScore() >= scoreLimit) {
      WinEvent();
    }
  }

  static void leaveGame() {
    _network.leaveMatch();
  }

  List scoreNLinesFromJson(Map<String, dynamic> json) {
    final score = json["score"] as int;
    final lines = json["lines"] as int;

    return [score, lines];
  }

  Map<String, dynamic> scoreNLinesToJson() => {
        '"score"': super.getScore(),
        '"lines"': super.getLines(),
      };

  sendScoreData() {
    _network.sendData(scoreNLinesToJson().toString(), OpCode.scoreData.index);
  }
}
