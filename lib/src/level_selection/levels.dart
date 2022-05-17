// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final gameLevels = [
  GameLevel(
    number: 1,
    name: 'Easy',
    moveSpeed: 500,
    screenSizeX: 15,
    screenSizeY: 10,
    orderSpeed: 7000,
    maxAnimals: 2,
    maxVeggies: 5,
    goal: 10,
    failureAmount: 10,
    endCondition: (int numComplete, int numOrders) {
      return numComplete == 10 || numOrders == 10;
    },
    // TODO: When ready, change these achievement IDs.
    // You configure this in App Store Connect.
    achievementIdIOS: 'first_win',
    // You get this string when you configure an achievement in Play Console.
    achievementIdAndroid: 'NhkIwB69ejkMAOOLDb',
  ),
  GameLevel(
    number: 2,
    name: 'Hard',
    moveSpeed: 240,
    screenSizeX: 15,
    screenSizeY: 10,
    orderSpeed: 5000,
    maxAnimals: 4,
    maxVeggies: 4,
    goal: 15,
    failureAmount: 8,
    endCondition: (int numComplete, int numOrders) {
      return numComplete == 15 || numOrders == 8;
    },
    // TODO: When ready, change these achievement IDs.
    // You configure this in App Store Connect.
    achievementIdIOS: 'first_win',
    // You get this string when you configure an achievement in Play Console.
    achievementIdAndroid: 'NhkIwB69ejkMAOOLDb',
  ),
  GameLevel(
    number: 3,
    name: 'Endless',
    moveSpeed: 300,
    screenSizeX: 15,
    screenSizeY: 10,
    orderSpeed: 5000,
    maxAnimals: 4,
    maxVeggies: 4,
    goal: -1,
    failureAmount: 10,
    endCondition: (int numComplete, int numOrders) {
      return numOrders == 10;
    },
    // TODO: When ready, change these achievement IDs.
    // You configure this in App Store Connect.
    achievementIdIOS: 'first_win',
    // You get this string when you configure an achievement in Play Console.
    achievementIdAndroid: 'NhkIwB69ejkMAOOLDb',
  ),
  // GameLevel(
  //   number: 2,
  //   difficulty: 42,
  // ),
  // GameLevel(
  //   number: 3,
  //   difficulty: 100,
  //   achievementIdIOS: 'finished',
  //   achievementIdAndroid: 'CdfIhE96aspNWLGSQg',
  // ),
];

class GameLevel {
  final int number;
  final String name;

  final int moveSpeed;
  final int orderSpeed;
  final int screenSizeX;
  final int screenSizeY;

  final int goal;
  final int failureAmount;

  final int maxAnimals;
  final int maxVeggies;
  // A function that returns a function that will return a bool of whether the end condition has been reached
  bool Function(int, int) endCondition;

  /// The achievement to unlock when the level is finished, if any.
  final String? achievementIdIOS;

  final String? achievementIdAndroid;

  bool get awardsAchievement => achievementIdAndroid != null;

  GameLevel({
    required this.goal,
    required this.failureAmount,
    required this.number,
    required this.name,
    required this.screenSizeX,
    required this.screenSizeY,
    required this.moveSpeed,
    required this.orderSpeed,
    required this.maxAnimals,
    required this.maxVeggies,
    required this.endCondition,
    this.achievementIdIOS,
    this.achievementIdAndroid,
  }) : assert(
            (achievementIdAndroid != null && achievementIdIOS != null) ||
                (achievementIdAndroid == null && achievementIdIOS == null),
            'Either both iOS and Android achievement ID must be provided, '
            'or none');
}
