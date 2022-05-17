import 'dart:math';

import 'package:order_up/src/game_internals/veggie.dart';

class Order {
  late List<Veggie> veggies;
  final int tick;
  bool isComplete = false;

  Order({required this.tick}) {
    final random = Random();
    int numVeggies = random.nextInt(3) + 1;
    veggies = List.generate(
        numVeggies, (i) => Veggie.values[random.nextInt(Veggie.values.length)]);
  }

  int compareOrder(Order other) {
    return this.tick.compareTo(other.tick);
  }
}
