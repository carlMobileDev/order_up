import 'package:flutter/material.dart';

enum Animal {
  cat,
  dog,
  horse,
  cow,
  sheep,
}

Color lookupAnimalColor(Animal animal) {
  switch (animal) {
    case Animal.cat:
      return Colors.brown[500]!;
    case Animal.dog:
      return Colors.brown[200]!;
    case Animal.horse:
      return Colors.brown[800]!;
    case Animal.cow:
      return Colors.blueGrey;
    case Animal.sheep:
      return Colors.grey;
  }
}

int conpareAnimals(Animal one, Animal other) =>
    one.index.compareTo(other.index);
