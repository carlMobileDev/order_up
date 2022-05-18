import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/semantics.dart';
import 'package:order_up/src/game_internals/animal.dart';
import 'package:order_up/src/game_internals/veggie.dart';
import 'package:order_up/src/play_session/play_session_screen.dart';

class SpriteLoader {
  late List<Sprite> sprites;
  String characterSpriteSheetName = 'characters.png';
  String groundSpriteSheetName = 'ground.png';
  String cowSpriteSheetName = 'cow.png';

  late SpriteSheet characterSpriteSheet;
  late SpriteSheet groundSpriteSheet;
  late SpriteSheet cowSpriteSheet;

  init() async {
    Image characterImage = await Flame.images.load(characterSpriteSheetName);
    characterSpriteSheet =
        SpriteSheet(srcSize: Vector2.all(32), image: characterImage);

    Image groundImage = await Flame.images.load(groundSpriteSheetName);
    groundSpriteSheet =
        SpriteSheet(srcSize: Vector2.all(16), image: groundImage);

    Image cowImage = await Flame.images.load(cowSpriteSheetName);
    cowSpriteSheet = SpriteSheet(srcSize: Vector2.all(32), image: cowImage);
  }

  Sprite lookupGroundSprite(int index, int _x, int _y) {
    int x = 0;
    int y = 0;

    if (index == 0) {
      //Top Left Corner
      x = 0;
      y = 0;
    } else if (index == _x - 1) {
      //Top Right Corner
      x = 0;
      y = 2;
    } else if (index == (_x * _y) - _x) {
      //Bottom Left Corner
      x = 2;
      y = 0;
    } else if (index == (_x * _y) - 1) {
      //Bottom Right Corner
      x = 2;
      y = 2;
    } else if (index < _x) {
      //Top Border
      x = 0;
      y = 1;
    } else if (index > (_x * _y) - _x) {
      //Bottom Border

      x = 2;
      y = 1;
    } else if (index % _x == (_x - 1)) {
      //Right Border!
      x = 1;
      y = 2;
    } else if (index % _x == 0) {
      //Left Border!
      x = 1;
      y = 0;
    } else {
      x = 1;
      y = 1;
    }
    return groundSpriteSheet.getSprite(x, y);
  }

  Sprite lookupCharacterSprite(Direction direction) {
    return characterSpriteSheet.getSprite(0, 0);
  }

  Sprite lookupVeggieSprite(Veggie veggie) {
    return groundSpriteSheet.getSprite(
        groundSpriteSheet.rows - 1, groundSpriteSheet.columns - 2);
  }

  Sprite lookupAnimalSprite(AnimalSpriteType type, Direction direction) {
    Sprite sprite;
    switch (type) {
      case AnimalSpriteType.standing:
        sprite = cowSpriteSheet.getSprite(0, 0);
        break;
      case AnimalSpriteType.walking1:
        sprite = cowSpriteSheet.getSprite(1, 0);
        break;
      case AnimalSpriteType.walking2:
        sprite = cowSpriteSheet.getSprite(1, 1);
        break;
      case AnimalSpriteType.resting:
        sprite = cowSpriteSheet.getSprite(0, 1);
        break;
    }
    return sprite;
  }
}

enum AnimalSpriteType { standing, walking1, walking2, resting }
