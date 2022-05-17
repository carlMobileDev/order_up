import 'package:flutter/material.dart';

enum Veggie {
  carrot,
  eggplant,
  lettuce,
  tomato,
}

Color lookupVeggieColor(Veggie veggie) {
  switch (veggie) {
    case Veggie.carrot:
      return Colors.orange;
    case Veggie.eggplant:
      return Colors.purple;
    case Veggie.lettuce:
      return Colors.green;
    case Veggie.tomato:
      return Colors.red;
  }
}

int compareVeggies(Veggie one, Veggie other) =>
    one.index.compareTo(other.index);
