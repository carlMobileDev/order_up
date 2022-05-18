import 'package:flutter/material.dart';

enum VeggieType {
  carrot,
  eggplant,
  lettuce,
  tomato,
}

class Veggie {
  late GlobalKey key;
  VeggieType type;
  Veggie({required this.type}) {
    key = GlobalKey();
  }
}

Color lookupVeggieColor(VeggieType type) {
  switch (type) {
    case VeggieType.carrot:
      return Colors.orange;
    case VeggieType.eggplant:
      return Colors.purple;
    case VeggieType.lettuce:
      return Colors.green;
    case VeggieType.tomato:
      return Colors.red;
  }
}

int compareVeggies(Veggie one, Veggie other) =>
    one.type.index.compareTo(other.type.index);
