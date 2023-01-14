import 'dart:html';
import 'dart:convert';

import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'package:flame/components.dart';
import 'package:nakama/nakama.dart';
import 'package:trombtris/game/board/board.dart';
import 'package:trombtris/game/event/loseEvent.dart';
import 'package:trombtris/game/event/winEvent.dart';
import 'package:trombtris/game/gameManager.dart';
import 'package:trombtris/game/gameMode/multiplayerMode.dart';
import 'package:trombtris/webpages/trombtrisGame.dart';

class MultiplayerTrombtrisGame extends TrombtrisGame
    with HasKeyboardHandlerComponents {
  Board board = Board();
  int opponentScore = 0;
  int opponentLines = 0;
  String matchId = "";
  String enemyUsername = "oskar";

  MultiplayerTrombtrisGame(this.matchId);

  @override
  void setGameManager(String customBlockTypeDef) {
    gameManager = GameManager(customBlockTypeDef, "Multiplayer");
    multiplayerSetup();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    double tileSize = canvasSize.x / 12; // a bit smaller than the player

    Vector2 boardOffset = Vector2(canvasSize.x * 1.7,
        tileSize * 1.50 + canvasSize.x / 15 * 0.2 + tileSize / 10);

    // create the black background to the oppopnents name
    Color color = Color.fromARGB(255, 17, 19, 21);
    Vector2 bgPosition = Vector2(canvasSize.x * 1.7 - tileSize / 10, 0);
    Vector2 bgSize = Vector2(tileSize * 10.2, tileSize * 1.5);
    RectComponent opponentNameBg = RectComponent(
        bgPosition, bgSize, canvasSize[1] * 0.0065, 10.0, color, color);
    add(opponentNameBg);

    String text = (gameManager.getGamemode() as MultiplayerMode).opponentName;
    // text = "lllll llllll";

    // create the black background to the oppopnent board
    Vector2 position = Vector2(-tileSize / 10, -tileSize / 10) + boardOffset;
    Vector2 size = Vector2(tileSize * 10.2, tileSize * 20.2);
    final opponentBackground = RectComponent(
        position, size, canvasSize[1] * 0.0065, 10.0, color, color);
    add(opponentBackground);

    // create the black background to the oppopnent score
    Vector2 opponentScorePos = Vector2(-tileSize / 10,
            tileSize * 20.2 + canvasSize.x / 15 * 0.2 - tileSize / 10) +
        boardOffset;
    Vector2 opponentScoreSize =
        Vector2(tileSize * 10.2, tileSize * 1.5 + canvasSize.x / 15 * .5);
    final opponentScoreBG = RectComponent(opponentScorePos, opponentScoreSize,
        canvasSize[1] * 0.0065, 10.0, color, color);
    add(opponentScoreBG);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    super.render(canvas);

    renderBoard();
    renderUpcomingBlocks();
    renderHoldBlock();
    renderScores();

    renderOpponentBoard();
    renderMultiplayerInformation();
  }

  void setOpponentBoard(Board opponent) {
    board = opponent;
  }

  void setOpponentScore(List entries) {
    opponentScore = entries[0];
    opponentLines = entries[1];
  }

  void setOpponentName(String name) {
    enemyUsername = name;
  }

  String getMatchId() {
    return matchId;
  }

  void leaveGame() {
    MultiplayerMode.announceLeaveGame();
    MultiplayerMode.leaveGame();
    MultiplayerMode.setMatchStarted(false);
    pauseEngine();
  }

  Future<String> createGame() async {
    matchId = await MultiplayerMode.createGame();
    return matchId;
  }

  Future<bool> listenJoin() async {
    var event = await MultiplayerMode.listenJoin().skip(1).first;
    return true;
  }

  void multiplayerSetup() {
    MultiplayerMode gamemode = gameManager.getGamemode() as MultiplayerMode;

    if (matchId == "") {
      playGame(gamemode);
      listenJoin();
      gamemode.sendData(
          gameManager.getSeed().toString(), OpCode.gameInfo.index);
    } else {
      gamemode.joinGame(matchId).then((value) => {playGame(gamemode)});
    }
  }

  void playGame(MultiplayerMode gamemode) {
    MultiplayerMode.setMatchStarted(true);
    gamemode.opponentAlive = true;
    gamemode.imAlive = true;
    gamemode.listenLeave();
    gamemode.listenMatch().listen((event) {
      setOpponentName(event.presence.username);
      if (event.opCode == OpCode.boardData.index) {
        setOpponentBoard(Board.fromJson(jsonDecode(utf8.decode(event.data))));
      } else if (event.opCode == OpCode.playerLeave.index) {
        stopGame();
      } else if (event.opCode == OpCode.gameOver.index) {
        gamemode.opponentAlive = false;
        gamemode.opponentPoints = opponentScore;
        gamemode.opponentLines = opponentLines;

        if (gamemode.imAlive == false) {
          gamemode.compareScore(opponentScore);
        }
        //stopGame();
      } else if (event.opCode == OpCode.scoreData.index) {
        setOpponentScore(
            gamemode.scoreNLinesFromJson(jsonDecode(utf8.decode(event.data))));
      } else if (event.opCode == OpCode.gameInfo.index) {
        print("Got opponent username ${event.presence.username}");
      } else {
        print("Recieved unknown opcode ${event.opCode}");
      }
    });
  }

  void stopGame() {
    pauseEngine();
    MultiplayerMode.leaveGame();
    MultiplayerMode.setMatchStarted(false);
  }

  void renderOpponentBoard() {
    double tileSize = canvasSize.x / 12; // a bit smaller than the player

    var shadowOpacity;
    var blur;

    Vector2 boardOffset = Vector2(canvasSize.x * 1.7,
        tileSize * 1.5 + canvasSize.x / 15 * 0.2 + tileSize / 10);

    // add tiles for the opponents board
    for (int x = 0; x < board.getWidth(); x++) {
      for (int y = 0; y < board.getHeight(); y++) {
        // why is y,x a thing?!
        int tileType = board.me[y][x];
        if (tileType != 0) {
          if (tileType == 100) {
            shadowOpacity = 0.8;
            blur = 10.0;
          } else {
            shadowOpacity = 0.5;
            blur = 8.0;
          }

          Vector2 position =
              Vector2(x as double, y as double).scaled(tileSize) + boardOffset;
          Vector2 size = Vector2(tileSize, tileSize);
          final square = Tile(position, size, canvasSize[1] * 0.0065,
              tileType: tileType, blur: blur, shadowOpacity: shadowOpacity);
          components.add(square);
          add(square);
        }
      }
    }
  }

  void renderMultiplayerInformation() {
    double tileSize = canvasSize.x / 12; // a bit smaller than the player
    Vector2 bgPosition = Vector2(canvasSize.x * 1.7 - tileSize / 10, 0);
    Vector2 bgSize = Vector2(tileSize * 10.2, tileSize * 1.5);
    String text = enemyUsername;
    TextBoxComponent opponentNameTextBox = TextBoxComponent(
      text: text,
      // anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: TextStyle(
            letterSpacing: 0.0,
            fontSize: canvasSize[0] / 17,
            fontFamily: 'Galano Grotesque',
            color: Colors.white),
      ),
      size: bgSize,
      position: bgPosition +
          Vector2(
              bgSize.x * 0.5 -
                  text.length * (0.0 + canvasSize[0] / 17 * 0.70) / 2,
              0),
    );
    add(opponentNameTextBox);
    components.add(opponentNameTextBox);

    tileSize = canvasSize.x / 17;

    Vector2 boardOffset = Vector2(canvasSize.x * 1.7,
        tileSize * 1.5 + canvasSize.x / 15 * 0.2 + tileSize / 10);

    var xpos = -tileSize / 10 + boardOffset.x;
    var ypos = tileSize * 29.4 + boardOffset.y;

    List<String> scoreValues = [
      "Score",
      "Lines",
      opponentScore.toString(),
      opponentLines.toString()
    ];

    for (int i = 0; i < scoreValues.length; i++) {
      // String scoreText = "Score:\n$score \nLevel:\n$level \nLines:\n$lines";
      var fontWeight = FontWeight.normal;
      double yOffset = 0;
      if (i >= 2) {
        fontWeight = FontWeight.bold;
        yOffset = 1;
      }
      TextComponent textBoxComponent = TextComponent(
        text: scoreValues[i],
        anchor: Anchor.topCenter,
        textRenderer: TextPaint(
          style: TextStyle(
            fontWeight: fontWeight,
            fontSize: canvasSize[0] / 17,
            fontFamily: 'Galano Grotesque',
            color: Colors.white,
          ),
        ),
        size: Vector2(tileSize * 5, tileSize * 8.8),
        position: Vector2(
            xpos + tileSize * 5.05 * (i % 2 + 1),
            ypos +
                (0.1 + yOffset) *
                    tileSize *
                    1.05), //-canvasSize.x * 1.1, canvasSize.y * .75
      );
      add(textBoxComponent);
      components.add(textBoxComponent);
    }
  }
}
