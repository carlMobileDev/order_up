import 'dart:math';

import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:order_up/src/sprite_loader/sprite_loader.dart';
import 'package:provider/provider.dart';
import 'package:order_up/src/play_session/play_session_screen.dart';

enum AnimalType {
  cat,
  dog,
  horse,
  cow,
  sheep,
}

class Animal {
  AnimalType type;
  late GlobalKey key;
  late Direction direction;
  late int isMoving;

  Animal(
      {required this.type,
      Direction? startingDirection,
      GlobalKey? startingKey,
      int? startingIsMoving}) {
    key = startingKey ?? GlobalKey();
    isMoving = startingIsMoving ?? 0;
    final Random random = Random();
    direction = startingDirection ??
        Direction.values[random.nextInt(Direction.values.length)];
  }

  Sprite getSprite(SpriteLoader loader) {
    switch (isMoving) {
      case 0:
        return loader.lookupAnimalSprite(AnimalSpriteType.standing, direction);
      case 1:
        return loader.lookupAnimalSprite(AnimalSpriteType.standing, direction);
      case 2:
        return loader.lookupAnimalSprite(AnimalSpriteType.standing, direction);
      case -1:
        return loader.lookupAnimalSprite(AnimalSpriteType.standing, direction);
      default:
        return loader.lookupAnimalSprite(AnimalSpriteType.standing, direction);
    }
  }
}

Color lookupAnimalColor(AnimalType animal) {
  switch (animal) {
    case AnimalType.cat:
      return Colors.brown[500]!;
    case AnimalType.dog:
      return Colors.brown[200]!;
    case AnimalType.horse:
      return Colors.brown[800]!;
    case AnimalType.cow:
      return Colors.blueGrey;
    case AnimalType.sheep:
      return Colors.grey;
  }
}

int conpareAnimals(Animal one, Animal other) =>
    one.type.index.compareTo(other.type.index);
