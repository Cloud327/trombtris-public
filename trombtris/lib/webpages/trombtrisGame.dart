import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/rendering.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:trombtris/game/blocks/block.dart' as TBlock;
import 'package:trombtris/game/gameManager.dart';
import 'package:flame/components.dart';
import 'package:trombtris/game/board/board.dart';
import 'package:trombtris/game/gameMode/trombMode.dart';

import '../game/event/event.dart';

class SingleplayerTrombtrisGame extends TrombtrisGame {
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (gameManager.isDirty) {
      //renderPreviewBlock();

      renderBoard();
      renderUpcomingBlocks();
      renderHoldBlock();
      renderScores();
      gameManager.isDirty = false;
    }
  }
}

class TrombtrisGame extends FlameGame with HasKeyboardHandlerComponents {
  static late TrombtrisGame game;

  late GameManager gameManager;
  List<Component> components = [];
  StreamController<Event> eventStreamController = StreamController<Event>();
  late Stream<Event> eventStream = eventStreamController.stream;
  late PreviewBlock previewBlock;
  late Score score;
  late SpriteSheet darkTrombLogo;
  late SpriteSheet lightTrombLogo;
  int currentLetter = 0;

  double defaultBlur = 10;

  late final GameOverTextBox _resultBox = GameOverTextBox(
    'Game Over',
    canvasSize.x * 0.8,
    (canvasSize.y / 20) * 4,
    Anchor.center,
  )..position =
      Vector2(canvasSize.x * 0.1, canvasSize.y / 2 - 2 * canvasSize.y / 20);

  TrombtrisGame() {
    add(TimerComponent(
      period: 0.5,
      repeat: true,
      onTick: () => Tile.specialBlockColor = iterateSpecialBlock(),
    ));
  }

  int iterateSpecialBlock() {
    int colorInt = Random().nextInt(6);
    while (colorInt == Tile.specialBlockColor) {
      colorInt = Random().nextInt(6);
    }

    // Iterate current letter
    currentLetter++;
    if (currentLetter > 4) {
      currentLetter = 0;
    }

    return colorInt;
  }

  void setGameManager(String blockTypeDef) {
    gameManager = GameManager(blockTypeDef, "TrombMode");
  }

  @override
  Color backgroundColor() => Color.fromARGB(255, 17, 19, 21);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    game = this;

    // ignore: prefer_typing_uninitialized_variables, there are like 50 different image types dart omg
    var darkTrombSprite;
    // ignore: prefer_typing_uninitialized_variables
    var lightTrombSprite;
    await images
        .load('../../lib/game/assets/trombSpriteBlack.png')
        .then((img) => darkTrombSprite = img);

    await images
        .load('../../lib/game/assets/trombSpriteWhite.png')
        .then((img) => lightTrombSprite = img);

    darkTrombLogo =
        SpriteSheet(image: darkTrombSprite, srcSize: Vector2(74, 74));
    lightTrombLogo =
        SpriteSheet(image: lightTrombSprite, srcSize: Vector2(74, 74));

    // Load default blocks
    await rootBundle
        .loadString('lib/game/assets/blockTypeDefs/defaultBlocks.txt')
        .then((typeDef) => setGameManager(typeDef));
    add(gameManager.inputManager);

    previewBlock = PreviewBlock(gameManager);
    previewBlock.position = Vector2(0, 0);
    // score = Score(gameManager ); // Vector2(-canvasSize.x * 1.1, canvasSize.y * .75)

    RectComponent upcomingBlockBackground = createUpcomingBlocksBackground();
    add(upcomingBlockBackground);
    RectComponent scoresBackground = createScoresBackground();
    add(scoresBackground);
    RectComponent holdBackground = createHoldBlockBackground();
    add(holdBackground);
    // add(score);
    add(previewBlock);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    lateRender();
  }

  void lateRender() async {
    // Execute events from stream HERE ONLY
    try {
      eventStream.listen((event) {
        event.execute();
      });
    } catch (error) {
      // Event
    }
  }

  @override
  void update(double dt) {
    gameManager.update(dt);
    super.update(dt);
    if (gameManager.isDirty) {
      removeAll(components);
      components = [];
    }
  }

  void renderScores() {
    double tileSize = canvasSize[0] / 15;
    double xpos = -canvasSize[0] * 0.25 - tileSize * 1.5;
    double ypos = tileSize * 4.2;

    int score = gameManager.getScore();
    int level = gameManager.getLevel();
    int lines = gameManager.getLineClears();
    var gm = gameManager.getGamemode() as TrombMode;
    int trombs = gm.getTrombCount();
    List<String> scoreValues = [
      "Score",
      score.toString(),
      "Level",
      level.toString(),
      "Lines",
      lines.toString(),
      "Trombs",
      trombs.toString()
    ];
    for (int i = 0; i < scoreValues.length; i++) {
      // String scoreText = "Score:\n$score \nLevel:\n$level \nLines:\n$lines";
      var fontWeight = FontWeight.normal;
      if (i % 2 == 1) {
        fontWeight = FontWeight.bold;
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
            xpos + tileSize * 2.5,
            ypos +
                (0.1 + i) *
                    tileSize *
                    1.05), //-canvasSize.x * 1.1, canvasSize.y * .75
      );
      add(textBoxComponent);
      components.add(textBoxComponent);
    }
  }

  void renderBoard() {
    Board board = GameManager.getGameState(0);

    var shadowOpacity;
    var blur;

    for (int x = 0; x < board.getWidth(); x++) {
      for (int y = 0; y < board.getHeight(); y++) {
        int tileType = board.me[y][x];
        // why is y,x a thing?!
        if (tileType != 0) {
          if (tileType == 100) {
            shadowOpacity = 0.8;
            blur = 10.0;
          } else {
            shadowOpacity = 0.5;
            blur = 8.0;
          }

          Vector2 position =
              Vector2(x as double, y as double).scaled(canvasSize[0] / 10);
          Vector2 size = Vector2((canvasSize[0] / 10), (canvasSize[0] / 10));
          final square = Tile(position, size, canvasSize[1] * 0.0065,
              tileType: tileType, blur: blur, shadowOpacity: shadowOpacity);

          components.add(square);
          add(square);
        }
      }
    }
  }

  void renderHoldBlock() {
    var heldBlock = gameManager.getHeldBlock();

    double tileSize = canvasSize[0] / 15;

    // create the black background to the upcoming blocks

    // if we are holding a block, draw it over the black background tile
    if (heldBlock != null) {
      List<int> xValues = [
        heldBlock.rotation[0][0][0],
        heldBlock.rotation[0][1][0],
        heldBlock.rotation[0][2][0],
        heldBlock.rotation[0][3][0]
      ];
      List<int> yValues = [
        heldBlock.rotation[0][0][1],
        heldBlock.rotation[0][1][1],
        heldBlock.rotation[0][2][1],
        heldBlock.rotation[0][3][1]
      ];
      int height = (yValues.reduce(max) - yValues.reduce(min) + 1);
      int width = (xValues.reduce(max) - xValues.reduce(min) + 1);

      double xOffset = 0;
      double yOffset = 0;

      if (height % 2 == 1) {
        // blocks with uneved height (i) gets lowered half a tile so they are centered
        yOffset = tileSize / 2;
      }

      if (width % 2 == 1) {
        // blocks with uneven width (j,l,t,s,z) gets offset to right half a tile so they are centered
        xOffset = tileSize / 2;
      }

      for (int tile = 0; tile < heldBlock.rotation.length; tile++) {
        var opacity = 0.5;
        var blur = 10.0;
        if (heldBlock.tileType[tile] == 100) {
          opacity = 0.8;
          blur = 8.0;
        }

        double xpos = -canvasSize[0] * 0.25 +
            heldBlock.rotation[0][tile][0] * tileSize +
            xOffset;
        double ypos =
            tileSize + heldBlock.rotation[0][tile][1] * tileSize + yOffset;

        Vector2 position = Vector2(xpos, ypos);
        Vector2 size = Vector2(tileSize, tileSize);
        final square = Tile(position, size, canvasSize[1] * 0.0065,
            tileType: heldBlock.tileType[tile], shadowOpacity: opacity);
        components.add(square);
        add(square);
      }
    }
    final effect =
        ScaleEffect.by(Vector2.all(1.5), EffectController(duration: 0.3));
  }

  RectComponent createHoldBlockBackground() {
    double tileSize = canvasSize[0] / 15;
    double xpos = -canvasSize[0] * 0.25 - tileSize * 1.5;
    double ypos = 0;

    // create the black background to the upcoming blocks
    Vector2 position = Vector2(xpos, ypos);
    Vector2 size = Vector2(tileSize * 5, tileSize * 4);
    final background = RectComponent(position, size, canvasSize[1] * 0.0065, 10,
        Color.fromARGB(255, 17, 19, 21), Color(0xFF000000));

    return background;
  }

  RectComponent createScoresBackground() {
    double tileSize = canvasSize[0] / 15;

    double xpos = -canvasSize[0] * 0.25 - tileSize * 1.5;
    double ypos = tileSize * 4.2;

    // create the black background to the upcoming blocks
    Vector2 position = Vector2(xpos, ypos);
    Vector2 size = Vector2(tileSize * 5, tileSize * 8.8);
    double radius = canvasSize[1] * 0.0065;

    //Create the rectangle
    Color color = Color.fromARGB(255, 17, 19, 21);
    RectComponent background =
        RectComponent(position, size, radius, 10.0, color, color);

    return background;
  }

  RectComponent createUpcomingBlocksBackground() {
    double tileSize = canvasSize[0] / 15;

    double xpos = canvasSize[0] * 1.05 - tileSize / 2;
    double ypos = 0;

    // create the black background to the upcoming blocks
    Vector2 position = Vector2(xpos, ypos);
    Vector2 size = Vector2(tileSize * 5, tileSize * 13);
    double radius = canvasSize[1] * 0.0065;

    //Create the rectangle
    Color color = Color.fromARGB(255, 17, 19, 21);
    RectComponent background =
        RectComponent(position, size, radius, 10.0, color, color);

    return background;
  }

/*
Read the upcoming blocks from the gamemanager, and render them to the side of the gameboard.
 */
  void renderUpcomingBlocks() {
    double offset = 0;
    double tileSize = canvasSize[0] / 15;
    var upcomingBlocks = gameManager.getUpcomingBlocks();

    for (int i = 0; i < upcomingBlocks.length; i++) {
      TBlock.Block block = upcomingBlocks[i];

      List<int> xValues = [
        block.rotation[0][0][0],
        block.rotation[0][1][0],
        block.rotation[0][2][0],
        block.rotation[0][3][0]
      ];
      List<int> yValues = [
        block.rotation[0][0][1],
        block.rotation[0][1][1],
        block.rotation[0][2][1],
        block.rotation[0][3][1]
      ];
      int height = (yValues.reduce(max) - yValues.reduce(min) + 1);
      int width = (xValues.reduce(max) - xValues.reduce(min) + 1);

      double xOffset = 0;
      double yOffset = 0;

      if (height % 2 == 1) {
        // blocks with uneved height (i) gets lowered half a tile so they are centered
        yOffset = tileSize / 2;
      }

      if (width % 2 == 1) {
        // blocks with uneven width (j,l,t,s,z) gets offset to right half a tile so they are centered
        xOffset = tileSize / 2;
      }

      for (int i = 0; i < 4; i++) {
        double xpos = canvasSize[0] * 1.05 +
            block.rotation[0][i][0] * tileSize +
            tileSize +
            xOffset;
        double ypos =
            tileSize + offset + block.rotation[0][i][1] * tileSize + yOffset;

        Vector2 position = Vector2(xpos, ypos);
        Vector2 size = Vector2(tileSize, tileSize);
        double radius = canvasSize[1] * 0.0065;
        double blur;
        double shadowOpacity;
        if (block.tileType[i] == 100) {
          shadowOpacity = 0.8;
          blur = 10.0;
        } else {
          shadowOpacity = 0.5;
          blur = 8.0;
        }

        final square = Tile(position, size, radius,
            tileType: block.tileType[i],
            blur: blur,
            shadowOpacity: shadowOpacity);

        components.add(square);
        add(square);
      }

      offset += tileSize * 3;
    }
  }

  playPlaceAnimation(List position) {
    final placeBlockSound = AudioPlayer();
    placeBlockSound.setVolume(0.3);
    placeBlockSound.play(AssetSource('blockPlace.mp3'));

    // Add tiles on every position of a placed tile
    for (var i = 0; i < position[0].length; i++) {
      Vector2 p = Vector2(position[0][i] as double, position[1][i] as double)
          .scaled(canvasSize[0] / 10);
      Vector2 size = Vector2((canvasSize[0] / 10), (canvasSize[0] / 10));
      final tile = Tile(p, size, 5.0);
      tile.paint.color = Tile.getTileColor(position[2][i], false);
      tile.shadow.color = Colors.transparent;

      // Move tile anchor to center (makes the scaling appear to be from the center)
      tile.anchor = const Anchor(0.5, 0.5);
      tile.position += Vector2(tile.size.x / 2, tile.size.y / 2);

      // Add animation effects to each "placed tile"
      // Remember to always include a RemoveEffect
      tile.addAll([
        ScaleEffect.by(Vector2.all(2), EffectController(duration: 0.1)),
        ScaleEffect.by(
            Vector2.all(0), EffectController(startDelay: 0.1, duration: 0.1)),
        RemoveEffect(delay: 0.2),
      ]);

      add(tile);
    }
    placeBlockSound.dispose();
  }

  playInstantPlaceAnimation(List position, int dropHeight) {
    final hardDropSound = AudioPlayer();
    hardDropSound.setVolume(0.3);
    hardDropSound.play(AssetSource('hardDrop.wav'));

    // Add tiles on every position of a placed tile
    for (var i = 0; i < position[0].length; i++) {
      Vector2 p = Vector2(position[0][i] as double, position[1][i] as double)
          .scaled(canvasSize[0] / 10);
      Vector2 size = Vector2((canvasSize[0] / 10), (canvasSize[0] / 10));
      final tile = Tile(p, size, 5.0);
      tile.paint.color =
          Tile.getTileColor(position[2][i], false).withAlpha(200);

      tile.shadow.color = Colors.transparent;

      // Move tile anchor to bottom center
      tile.anchor = const Anchor(0.5, 1);
      tile.position += Vector2(tile.size.x / 2,
          0); // dont bother moving position in y-direction, blur will make it look proper anyway
      tile.scale = Vector2(
          0.5, dropHeight / 2); // Scale tiles to look stretched in y-direction

      tile.decorator.addLast(PaintDecorator.blur(20, 30)); // Add blur

      // Add animation effects to each "placed tile"
      // Remember to always include a RemoveEffect
      tile.addAll([
        ScaleEffect.to(Vector2(1, 1), EffectController(duration: 0.5)),
        OpacityEffect.fadeOut(EffectController(duration: 0.3)),
        RemoveEffect(delay: 0.5),
      ]);

      add(tile);
    }
    hardDropSound.dispose();
  }

  playLineClearAnim(List clearedLines) {
    final lineClearSound = AudioPlayer();
    lineClearSound.setVolume(0.2);
    lineClearSound.play(AssetSource('LineClear.wav'));

    gameManager.isPaused = true; // Pause the game momentarily
    var timer = Component();

    timer.add(RemoveEffect(
        delay: 0.25,
        onComplete: () => gameManager.isPaused = false)); // Unpause after 0.25s
    add(timer);

    // Create tiles on every x position on each cleared line's y position
    for (var x = 0; x < GameManager.getBoardState(0).getWidth(); x++) {
      for (var y = 0; y < clearedLines.length; y++) {
        Vector2 position = Vector2(x as double, clearedLines[y] as double)
            .scaled(canvasSize[0] / 10);
        Vector2 size = Vector2((canvasSize[0] / 10), (canvasSize[0] / 10));
        final tile = Tile(position, size, 5.0, priority: 2);
        tile.paint.color = Colors.white;

        // Move tile anchor to center (makes the scaling appear to be from the center)
        tile.anchor = const Anchor(0.5, 0.5);
        tile.position += Vector2(tile.size.x / 2, tile.size.y / 2);

        // Add animation effects to each "placed tile"
        // Remember to always include a RemoveEffect
        tile.addAll([
          ScaleEffect.to(Vector2.all(0.9), EffectController(duration: 0.25)),
          ScaleEffect.to(Vector2.all(0),
              EffectController(startDelay: x / 50, duration: 0.25)),
          RotateEffect.by(
              90, EffectController(startDelay: x / 50, duration: 0.3)),
          RemoveEffect(delay: x / 50 + 0.3),
        ]);

        add(tile);
      }
    }
    lineClearSound.dispose();
  }

  playTrombAnim(List position) {
    final trombBlockSound = AudioPlayer();
    trombBlockSound.setVolume(0.35);
    trombBlockSound.play(AssetSource(
        'trombBlock.wav')); //Sound Effect by Muzaproduction from Pixabay

    var width = GameManager.getBoardState(0).getWidth();
    var height = GameManager.getBoardState(0).getHeight();

    // First make a background animation for clearing the board
    for (var x = 0; x < width; x++) {
      for (var y = 0; y < height; y++) {
        Vector2 position =
            Vector2(x as double, y as double).scaled(canvasSize[0] / 10);
        Vector2 size = Vector2((canvasSize[0] / 10), (canvasSize[0] / 10));
        final tile = Tile(position, size, 5.0, priority: 2);
        tile.paint.color = Colors.black;

        // Move tile anchor to center (makes the scaling appear to be from the center)
        tile.anchor = const Anchor(0.5, 0.5);
        tile.position += Vector2(tile.size.x / 2, tile.size.y / 2);

        // Add animation effects to each "placed tile"
        // Remember to always include a RemoveEffect
        tile.addAll([
          ColorEffect(Colors.grey.shade700, const Offset(0, 1.0),
              EffectController(duration: 0.25)),
          ScaleEffect.to(Vector2.all(0.9), EffectController(duration: 0.25)),
          ScaleEffect.to(Vector2.all(0),
              EffectController(startDelay: (height - y) / 50, duration: 0.25)),
          RotateEffect.by(90,
              EffectController(startDelay: (height - y) / 50, duration: 0.3)),
          RemoveEffect(delay: (height - y) / 50 + 0.3),
        ]);

        add(tile);
      }
    }

    // Create holder for Tromb logo

    Vector2 p = Vector2(position[0][2] as double, position[1][2] as double)
        .scaled(canvasSize[0] / 10);
    Vector2 size = Vector2((canvasSize[0] / 10), (canvasSize[0] / 10));
    final bigRect = Tile(p, size, 5.0);
    bigRect.positionType = PositionType.widget;

    bigRect.paint.color = bigRect.shadow.color =
        Colors.transparent; // BigRect is meant to be an invisible holder

    // Move bigRect anchor to center (makes the scaling appear to be from the center)
    bigRect.anchor = const Anchor(0.5, 0.5);
    bigRect.position += size.scaled(0.5);

    // Add animation effects to the bigRect
    // Remember to always include a RemoveEffect
    bigRect.addAll([
      ScaleEffect.by(Vector2.all(1.2),
          CurvedEffectController(2, Curves.decelerate)), // Slow expansion
      ScaleEffect.to(
          Vector2.all(1), EffectController(startDelay: 0.1, duration: 0.1)),
      RemoveEffect(delay: 2),
    ]);

    // Create Tiles for each tile of the logo
    for (var i = 0; i < position[0].length; i++) {
      p = Vector2(position[0][i] as double, position[1][i] as double)
              .scaled(canvasSize[0] / 10) -
          bigRect.position +
          bigRect.size / 2;

      final tile = Tile(p, size, 5.0, priority: 2);
      tile.paint.color = Colors.black;

      // Move tile anchor to center (makes the scaling appear to be from the center)
      tile.anchor = const Anchor(0.5, 0.5);
      tile.position += Vector2(tile.size.x / 2, tile.size.y / 2);
      tile.scale = Vector2.all(0.5);

      // Add animation effects to each "placed tile"
      // Remember to always include a RemoveEffect
      tile.addAll([
        ColorEffect(
            Colors.white, // Could use a different color than white but idk :/
            const Offset(0.0, 1.0),
            EffectController(duration: 0.2)),
        ColorEffect(Colors.white, const Offset(1.0, 0.6),
            EffectController(startDelay: 0.2, duration: 2)),
        ScaleEffect.to(
            Vector2.all(1.05), CurvedEffectController(1, Curves.elasticOut)),
        ScaleEffect.to(
            Vector2.zero(),
            EffectController(
                startDelay: 1, duration: 1, curve: Curves.elasticIn)),
        RemoveEffect(delay: 2),
      ]);

      final trombLetter = SpriteComponent()
        ..sprite = darkTrombLogo.getSpriteById(4 - i)
        ..position = Vector2(position[0][i] as double, position[1][i] as double)
                .scaled(canvasSize[0] / 10) -
            bigRect.position +
            bigRect.size / 2
        ..size = Vector2((canvasSize[0] / 15), (canvasSize[0] / 15));

      // Move anchor to center
      trombLetter.anchor = const Anchor(0.5, 0.5);
      trombLetter.position += Vector2(tile.size.x / 2, tile.size.y / 2);
      trombLetter.scale = Vector2.all(0.5);

      trombLetter.addAll([
        ScaleEffect.to(
            Vector2.all(1.05), CurvedEffectController(1, Curves.elasticOut)),
        ScaleEffect.to(
            Vector2.zero(),
            EffectController(
                startDelay: 1, duration: 1, curve: Curves.elasticIn)),
        RemoveEffect(delay: 2),
      ]);

      bigRect.addAll([tile, trombLetter]);
    }
    add(bigRect);
    trombBlockSound.dispose();
  }

  playGameOverAnim() {
    add(_resultBox);
  }

  void setResult(bool isWinner) {
    if (isWinner) {
      _resultBox.text = "YOU WON! :DDD";
    } else {
      _resultBox.text = "YOU LOSE!! D:";
    }
  }

  static Vector2 getCanvasSize() {
    return game.canvasSize;
  }
}

class Score extends PositionComponent {
  late TextBoxComponent textBoxComponent;
  late int score;
  late int level;
  late int lines;
  late GameManager gameManager;
  late String scoreText;

  Score(this.gameManager, Vector2 position) {
    score = gameManager.getScore();
    level = gameManager.getLevel();
    lines = gameManager.getLineClears();
    scoreText = "Score: $score \nLevel: $level \nLines Cleared: $lines";
    super.position = position;

    textBoxComponent = TextBoxComponent(
        text: scoreText,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 40.0,
            fontFamily: 'Galano Grotesqe',
            color: Colors.white,
          ),
        ),
        size: Vector2(500, 300),
        position: position);
    textBoxComponent.addToParent(this);
  }

  @override
  void update(dt) {
    score = gameManager.getScore();
    level = gameManager.getLevel();
    lines = gameManager.getLineClears();
    scoreText = "Score: $score \nLevel: $level \nLines Cleared: $lines";
    textBoxComponent.text = scoreText;
  }

  @override
  void render(Canvas canvas) {
    //super.render(canvas);
    textBoxComponent.render(canvas);
  }
}

class PreviewBlock extends PositionComponent {
  late TBlock.Block preview;
  late GameManager gameManager;
  List<Tile> tiles = [];
  Vector2 canvasSize = TrombtrisGame.getCanvasSize();

  @override
  PreviewBlock(this.gameManager) {
    preview = gameManager.getPreview();

    for (int tile = 0;
        tile < preview.rotation[preview.currentRot].length;
        tile++) {
      Vector2 position = Vector2(preview.rotation[preview.currentRot][tile][0],
              preview.rotation[preview.currentRot][tile][1])
          .scaled(canvasSize[0] / 10);

      Vector2 size = Vector2((canvasSize[0] / 10), (canvasSize[0] / 10));
      double blur = 10.0;
      double radius = canvasSize[1] * 0.0065;
      Tile t = Tile(position, size, radius,
          tileType: preview.tileType[tile],
          blur: blur,
          colorOpacity: 0.2,
          shadowOpacity: 0.1);
      tiles.add(t);
      t.addToParent(this);
    }

    //print(positionString());

    super.position =
        Vector2(preview.originPos[0] as double, preview.originPos[1] as double)
            .scaled(canvasSize[0] / 10);
  }

  @override
  void render(Canvas canvas) {}

  @override
  void update(dt) {
    canvasSize = TrombtrisGame.getCanvasSize();
    size = Vector2((canvasSize[0] / 10), (canvasSize[0] / 10));
    preview = gameManager.getPreview();

    // if (tiles.length > preview.rotation[preview.currentRot].length) {
    //   tiles.removeRange(
    //       preview.rotation[preview.currentRot].length - 1, tiles.length - 1);
    // }

    int i = 0;

    for (var tile in children) {
      tile = tile as Tile;
      tile.setColorOpacity(0.2);
      if (preview.tileType[i] == 100) {
        tile.setShadowOpacity(0.5);
        tile.setBlur(7.0);
      } else {
        tile.setShadowOpacity(0.1);
        tile.setBlur(5.0);
      }

      tile.position = Vector2(preview.rotation[preview.currentRot][i][0],
              preview.rotation[preview.currentRot][i][1])
          .scaled(canvasSize[0] / 10);

      tile.updateTileType(preview.tileType[i]);
      i++;
    }

    // for (int i = 0; i < preview.rotation[preview.currentRot].length; i++) {
    //   tiles[i].setColorOpacity(0.2);
    //   if (preview.tileType[i] == 100) {
    //     tiles[i].setShadowOpacity(0.6);
    //   } else {
    //     tiles[i].setShadowOpacity(0.1);
    //   }

    //   tiles[i].position = Vector2(preview.rotation[preview.currentRot][i][0],
    //           preview.rotation[preview.currentRot][i][1])
    //       .scaled(canvasSize[0] / 10);
    // }

    super.position =
        Vector2(preview.originPos[0] as double, preview.originPos[1] as double)
            .scaled(canvasSize[0] / 10);

    //print(toString() + "\n");
  }

  @override
  String toString() {
    String s = "\nPreviewBlock: \n";
    for (int i = 0; i < tiles.length; i++) {
      s = s + tiles[i].toString();
    }
    s = s + positionString();
    return s;
  }

  String positionString() {
    String s = "\nPosition: \n";
    for (int i = 0; i < tiles.length; i++) {
      Vector2 p = Vector2(super.position[0] + tiles[i].position[0],
          super.position[1] + tiles[i].position[1]);
      s = s + p.toString();
    }
    return s;
  }
}

class RectComponent extends PositionComponent {
  late double radius;
  Paint color = Paint();
  Paint shadow = Paint();
  late double shadowOpacity;
  late double colorOpacity;
  late double blur;

  RectComponent(Vector2 position, Vector2 size, this.radius, this.blur,
      Color color, Color shadow,
      {this.colorOpacity = 1.0, this.shadowOpacity = 0.0}) {
    this.color.color = color;
    this.shadow.color = shadow;
    super.position = position;
    super.size = size;
    this.shadow.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  }

  @override
  void render(Canvas canvas) {
    Path path = Path();
    //Draw the shadow
    if (shadowOpacity > 0.0) {
      path.addRRect(RRect.fromRectAndRadius(
          size.toRect().inflate(-radius / 2), Radius.circular(radius)));
      canvas.drawPath(path, shadow);
    }
    //Draw the rectangles
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            size.toRect().inflate(-radius / 2), Radius.circular(radius)),
        color);
  }
}

// Contains all the information necessary for one tile
class Tile extends PositionComponent with HasPaint {
  late double radius;
  Paint shadow = Paint();
  static int specialBlockColor = Random().nextInt(6);
  late int tileType;
  late double shadowOpacity;
  late double colorOpacity;
  late double blur;
  static Vector2 canvasSize = TrombtrisGame.getCanvasSize();
  static Sprite? letterSprite;
  late int priority;

  Tile(Vector2 position, Vector2 size, this.radius,
      {this.blur = 10.0,
      this.tileType = 0,
      this.colorOpacity = 1.0,
      this.shadowOpacity = 0.5,
      this.priority = 1})
      : super(position: position, size: size, priority: priority) {
    paint.color = getTileColor(tileType, false).withOpacity(colorOpacity);
    shadow.color = getTileColor(tileType, true).withOpacity(shadowOpacity);
    shadow.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    if (tileType == 100) {
      final trombLetter = SpriteComponent()
        ..sprite = TrombtrisGame.game.lightTrombLogo
            .getSpriteById(TrombtrisGame.game.currentLetter)
        ..size = size.scaled(1.05);

      // Move anchor to center
      trombLetter.anchor = const Anchor(0.5, 0.5);
      trombLetter.position += Vector2(size.x / 2, size.y / 2);
      trombLetter.scale = Vector2.all(0.5);

      add(trombLetter);
    }
  }

  @override
  void render(Canvas canvas) {
    Path path = Path();
    //Draw the shadow
    path.addRRect(RRect.fromRectAndRadius(
        size.toRect().inflate(-radius / 2), Radius.circular(radius)));
    canvas.drawPath(path, shadow);

    //Draw the rectangles
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            size.toRect().inflate(-radius / 2), Radius.circular(radius)),
        paint);
  }

  @override
  void updateTileType(int tileType) {
    this.tileType = tileType;
    shadow.color = getTileColor(tileType, true).withOpacity(shadowOpacity);
    paint.color = getTileColor(tileType, false).withOpacity(colorOpacity);
  }

  // Only works if the correct tiletype is set.
  // If a color is set manually then the opacity must be set manually
  void setShadowOpacity(double opacity) {
    shadowOpacity = opacity;
    shadow.color = getTileColor(tileType, true).withOpacity(opacity);
  }

  // Only works if the correct tiletype is set.
  // If a color is set manually then the opacity must be set manually
  void setColorOpacity(double opacity) {
    colorOpacity = opacity;
    paint.color = getTileColor(tileType, false).withOpacity(opacity);
  }

  void setBlur(double blur) {
    this.blur = blur;
    shadow.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
  }

  static Color getTileColor(int tileType, isShadow) {
    List colors = [
      Color(0xff65d1e2),
      Color.fromARGB(255, 11, 145, 199),
      Color(0xfff4731c),
      Color(0xfff2aa00),
      Color.fromARGB(255, 31, 194, 36),
      Color(0xffc61471),
      Color.fromARGB(255, 125, 93, 190)
    ];
    Color tileColor;
    switch (tileType) {
      case 0: // Default grey tile, only used as placeholder
        {
          tileColor = const Color.fromARGB(255, 177, 177, 179);
        }
        break;
      case 1: //I tile
        {
          tileColor = const Color(0xff65d1e2);
        }
        break;
      case 2: //J tile
        {
          tileColor = const Color.fromARGB(255, 11, 145, 199);
        }
        break;
      case 3: //L tile
        {
          tileColor = const Color(0xfff4731c);
        }
        break;
      case 4: //O tile
        {
          tileColor = const Color(0xfff2aa00);
        }
        break;
      case 5: //S tile
        {
          tileColor = const Color.fromARGB(255, 31, 194, 36);
        }
        break;
      case 6: //T tile
        {
          tileColor = const Color(0xffc61471);
        }
        break;
      case 7: //Z tile
        {
          tileColor = const Color.fromARGB(255, 125, 93, 190);
        }
        break;
      default: // special
        {
          if (isShadow) {
            tileColor = colors[specialBlockColor];
          } else {
            tileColor = Color.fromARGB(255, 0, 0, 0);
          }
        }
        break;
    }
    return tileColor;
  }

  @override
  String toString() {
    return super.position.toString();
  }
}

class GameOverTextBox extends TextBoxComponent {
  GameOverTextBox(String text, double width, double height, Anchor alignment)
      : super(
            text: text,
            textRenderer: TextPaint(
              style: const TextStyle(
                  fontSize: 40.0,
                  fontFamily: 'Galano Grotesqe',
                  color: Colors.white),
            ),
            size: Vector2(width, height),
            align: alignment,
            priority: 4);

  final bgPaint = Paint()..color = Color.fromARGB(210, 50, 57, 63);

  @override
  void render(Canvas canvas) {
    Rect rect = Rect.fromLTWH(0, 0, width, height);
    RRect rrect = RRect.fromRectAndRadius(rect, Radius.elliptical(10, 10));
    canvas.drawRRect(rrect, bgPaint);
    super.render(canvas);
  }
}
