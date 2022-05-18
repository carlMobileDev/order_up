// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:order_up/src/game_internals/animal.dart';
import 'package:order_up/src/game_internals/order.dart';
import 'package:order_up/src/game_internals/veggie.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:order_up/src/sprite_loader/sprite_loader.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../ads/ads_controller.dart';
import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../games_services/games_services.dart';
import '../games_services/score.dart';
import '../in_app_purchase/in_app_purchase.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/confetti.dart';
import '../style/palette.dart';

enum Direction {
  left,
  right,
  up,
  down,
}

class PlaySessionScreen extends StatefulWidget {
  final GameLevel level;

  const PlaySessionScreen(this.level, {super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreen');
  late Timer gameTimer;
  late Timer newOrderTimer;
  bool paused = false;

  static const _celebrationDuration = Duration(milliseconds: 2000);

  static const _preCelebrationDuration = Duration(milliseconds: 500);

  bool _duringCelebration = false;
  late int _x = widget.level.screenSizeX;
  late int _y = widget.level.screenSizeY;
  late int _gameSpeed = widget.level.moveSpeed;
  late int _newOrderSpeed = widget.level.orderSpeed;
  late int _maxAnimals = widget.level.maxAnimals;
  late int _maxVeggies = widget.level.maxVeggies;
  int _points = 0;
  int _ordersComplete = 0;
  late DateTime _startOfPlay;
  late List<int> _playerPositions;
  late Map<int, Animal> _animalPositions;
  bool shouldAnimalsMove = true;
  late List<Veggie> _collectedVeggies;
  late Map<int, Veggie> _veggiePositions;
  late List<Tuple2<Order, bool>> _orders;

  Direction _currentPlayerDirection = Direction.down;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    final spriteLoader = context.read<SpriteLoader>();
    //print(widget.level.toString());
    return IgnorePointer(
      ignoring: _duringCelebration,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (_currentPlayerDirection != Direction.up && details.delta.dy > 0) {
            _currentPlayerDirection = Direction.down;
          } else if (_currentPlayerDirection != Direction.down &&
              details.delta.dy < 0) {
            _currentPlayerDirection = Direction.up;
          }
        },
        onHorizontalDragUpdate: (details) {
          if (_currentPlayerDirection != Direction.left &&
              details.delta.dx > 0) {
            _currentPlayerDirection = Direction.right;
          } else if (_currentPlayerDirection != Direction.right &&
              details.delta.dx < 0) {
            _currentPlayerDirection = Direction.left;
          }
        },
        child: Scaffold(
          backgroundColor: palette.backgroundPlaySession,
          body: Stack(
            children: [
              //Background
              Container(
                padding: EdgeInsets.only(top: 10),
                child: SafeArea(
                    bottom: false,
                    child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _x,
                          childAspectRatio: 1,
                        ),
                        itemCount: _x * _y,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return SpriteWidget(
                              sprite: spriteLoader.lookupGroundSprite(
                                  index, _x, _y));
                        })),
              ),
              //Top Layer
              Column(
                children: [
                  SizedBox(height: 10),

                  SafeArea(
                    bottom: false,
                    child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _x,
                          childAspectRatio: 1,
                        ),
                        itemCount: _x * _y,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          //Draw Player
                          if (_playerPositions.contains(index)) {
                            //print('Drawing character at: $index');
                            return SpriteWidget(
                                sprite: spriteLoader.lookupCharacterSprite(
                                    _currentPlayerDirection));
                          }
                          //Draw Veggies
                          else if (_veggiePositions.containsKey(index)) {
                            //print("Drawing veggie at: $index");

                            return SpriteWidget(
                              key: _veggiePositions[index]!.key,
                              sprite: spriteLoader
                                  .lookupVeggieSprite(_veggiePositions[index]!),
                            );
                          }
                          //Draw Animals
                          else if (_animalPositions.containsKey(index)) {
                            //print("Drawing animal at: $index");
                            print(
                                'Drawing animal at: $index : ${_animalPositions[index]?.isMoving}');
                            return SpriteWidget(
                              key: _animalPositions[index]!.key,
                              sprite: _animalPositions[index]!
                                  .getSprite(spriteLoader),
                            );
                          } else {
                            return Container(color: Colors.transparent);
                          }
                        }),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final veggie in _collectedVeggies)
                        Container(
                          height: 15,
                          width: 15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: lookupVeggieColor(veggie.type),
                          ),
                        ),
                    ],
                  ),
                  //Draw Orders
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final order in _orders)
                        Visibility(
                          visible: !order.item1.isComplete,
                          child: GestureDetector(
                            onTap: () => completeOrder(order.item1),
                            child: Container(
                              color: Colors.grey,
                              padding: EdgeInsets.all(8),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (VeggieType veggie
                                        in order.item1.veggies)
                                      Container(
                                        height: 15,
                                        width: 15,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: lookupVeggieColor(veggie),
                                        ),
                                      ),
                                    Visibility(
                                      child: Icon(Icons.star),
                                      visible: order.item2,
                                    )
                                  ]),
                            ),
                          ),
                        )
                    ],
                  ),
                  SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                          "Complete: ${_ordersComplete}/${(widget.level.goal > 0) ? widget.level.goal.toString() : '∞'}",
                          style: TextStyle(color: Colors.black, fontSize: 12)),
                      Text(
                          "Open Orders: ${_orders.length}/${widget.level.failureAmount.toString()}",
                          style: TextStyle(color: Colors.black, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Align(
                  alignment: Alignment.topRight,
                  child: Text(_points.toString(),
                      style: TextStyle(color: Colors.black, fontSize: 24))),
              SizedBox.expand(
                child: Visibility(
                  visible: _duringCelebration,
                  child: IgnorePointer(
                    child: Confetti(
                      isStopped: !_duringCelebration,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _startOfPlay = DateTime.now();

    // Preload ad for the win screen.
    final adsRemoved =
        context.read<InAppPurchaseController?>()?.adRemoval.active ?? false;
    if (!adsRemoved) {
      final adsController = context.read<AdsController?>();
      adsController?.preloadAd();
    }

    _playerPositions = [27];
    _animalPositions = Map();
    _veggiePositions = Map();
    _collectedVeggies = [];
    _orders = [];

    Duration duration = Duration(milliseconds: _gameSpeed);
    Duration orderDuration = Duration(milliseconds: _newOrderSpeed);
    if (!paused) {
      gameTimer = Timer.periodic(duration, (Timer timer) {
        update();
      });

      newOrderTimer = Timer.periodic(orderDuration, (Timer timer) {
        generateNewOrder();
      });
    }
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }

  void update() {
    setState(() {
      if (widget.level.endCondition(_ordersComplete, _orders.length)) {
        _gameOver();
      }
      handlePlayerMovement();
      checkPlayerCollision();
      spawnAnimals();
      moveAnimals();
      checkPlayerCollision();
      spawnVeggie();
      _orders = _orders.where((element) => !element.item1.isComplete).toList();
    });
  }

  void handlePlayerMovement() {
    switch (_currentPlayerDirection) {
      case Direction.left:
        if (_playerPositions.first % _x == 0) {
          _collectedVeggies = [];
        } else {
          _playerPositions.add(_playerPositions.last - 1);
          _playerPositions.remove(_playerPositions.first);
        }
        break;
      case Direction.right:
        if (_playerPositions.first % _x == _x - 1) {
          _collectedVeggies = [];
        } else {
          _playerPositions.add(_playerPositions.last + 1);
          _playerPositions.remove(_playerPositions.first);
        }
        break;
      case Direction.up:
        if (_playerPositions.first < _x) {
          _collectedVeggies = [];
        } else {
          _playerPositions.add(_playerPositions.last - _x);
          _playerPositions.remove(_playerPositions.first);
        }
        break;
      case Direction.down:
        if (_playerPositions.first >= _x * (_y - 1)) {
          _collectedVeggies = [];
        } else {
          _playerPositions.add(_playerPositions.last + _x);
          _playerPositions.remove(_playerPositions.first);
        }
        break;
    }
  }

  void spawnVeggie() {
    if (_veggiePositions.length < _maxVeggies) {
      final random = Random();
      final randomNumber = random.nextInt(_x * _y);

      if (randomNumber != 0 && !_veggiePositions.containsKey(randomNumber)) {
        _veggiePositions.putIfAbsent(
            randomNumber,
            () => Veggie(
                  type: VeggieType
                      .values[random.nextInt(VeggieType.values.length)],
                ));
      }
    }
  }

  void checkPlayerCollision() {
    //animals
    if (_animalPositions.containsKey(_playerPositions.first)) {
      _animalPositions.remove(_playerPositions.first);
      _collectedVeggies = [];
    }
    //veggies
    else if (_veggiePositions.containsKey(_playerPositions.first)) {
      _collectedVeggies.add(_veggiePositions[_playerPositions.first]!);
      _collectedVeggies.sort((a, b) => compareVeggies(a, b));
      _veggiePositions.remove(_playerPositions.first);
    }
    //out of bounds
    else if (_playerPositions.first % _x == 0 &&
        _currentPlayerDirection == Direction.down) {}
  }

  /// Spawns a single animal at a random position
  void spawnAnimals() {
    if (_animalPositions.length < _maxAnimals) {
      final random = Random();
      final randomNumber = random.nextInt(_x * _y);

      if (randomNumber != 0 && !_animalPositions.containsKey(randomNumber)) {
        _animalPositions.putIfAbsent(
          randomNumber,
          () => Animal(
              type:
                  AnimalType.values[random.nextInt(AnimalType.values.length)]),
        );
      }
    }
  }

  /// Moves or turns animals based on their direction once every two cycles
  /// Generates a random num < 10.
  /// If num 0-6 move the animal in the direction it is facing
  /// If num  7 - 9, turn the animal
  /// If num == 10, do nothing and rest
  void moveAnimals() {
    final random = Random();

    Map<int, Animal> _newAnimalPositions = Map.from(_animalPositions);

    _animalPositions.forEach((key, value) {
      Direction newDirection =
          Direction.values[random.nextInt(Direction.values.length)];
      int actionNum = random.nextInt(10);
      if (shouldAnimalsMove && actionNum != 10) {
        if (actionNum < 7) {
          switch (value.direction) {
            case Direction.left:
              if (key % _x != 0 && !_veggiePositions.containsKey(key - 1)) {
                _newAnimalPositions.remove(key);
                value.isMoving = value.isMoving + 1;
                if (value.isMoving > 2) {
                  value.isMoving = 1;
                }
                _newAnimalPositions.putIfAbsent(key - 1, () => value);
              }
              break;
            case Direction.right:
              if (key % _x != _x - 1 &&
                  !_veggiePositions.containsKey(key + 1)) {
                _newAnimalPositions.remove(key);
                value.isMoving = value.isMoving + 1;
                if (value.isMoving > 2) {
                  value.isMoving = 1;
                }
                _newAnimalPositions.putIfAbsent(key + 1, () => value);
              }
              break;
            case Direction.up:
              if (key >= _x && !_veggiePositions.containsKey(key - _x)) {
                _newAnimalPositions.remove(key);
                value.isMoving = value.isMoving + 1;
                if (value.isMoving > 2) {
                  value.isMoving = 1;
                }
                _newAnimalPositions.putIfAbsent(key - _x, () => value);
              }
              break;
            case Direction.down:
              if (key < _x * (_y - 1) &&
                  !_veggiePositions.containsKey(key + _x)) {
                _newAnimalPositions.remove(key);
                value.isMoving = value.isMoving + 1;
                if (value.isMoving > 2) {
                  value.isMoving = 1;
                }
                _newAnimalPositions.putIfAbsent(key + _x, () => value);
              }
              break;
          }
        } else {
          _newAnimalPositions[key]!.direction = newDirection;
          _newAnimalPositions[key]!.isMoving = 0;
        }
      } else {
        _newAnimalPositions[key]!.isMoving = 0;
      }
    });
    _animalPositions = _newAnimalPositions;
    //shouldAnimalsMove = !shouldAnimalsMove;
  }

  void completeOrder(Order order) {
    final Map<VeggieType, int> orderItems = {};
    final Map<VeggieType, int> veggieItems = {};
    _collectedVeggies.forEach((item) {
      veggieItems.putIfAbsent(item.type, () => 0);
      veggieItems[item.type] = veggieItems[item.type]! + 1;
    });

    order.veggies.forEach((item) {
      orderItems.putIfAbsent(item, () => 0);
      orderItems[item] = orderItems[item]! + 1;
    });

    bool contains = true;

    orderItems.forEach((key, value) {
      print("Completing Order: ${orderItems} in ${veggieItems}");
      if (!veggieItems.containsKey(key) || (veggieItems[key] ?? 0) < value) {
        contains = false;
      }
    });

    if (contains) {
      _points = _points + order.veggies.length;
      order.isComplete = true;
      order.veggies.forEach((element) {
        _collectedVeggies.remove(_collectedVeggies
            .firstWhere((Veggie veggie) => veggie.type == element));
      });
      _ordersComplete = _ordersComplete + 1;
    }
  }

  void generateNewOrder() {
    _orders.add(Tuple2(new Order(tick: newOrderTimer.tick), false));
  }

  Future<void> _gameOver() async {
    _log.info('Level ${widget.level.number} won');

    final score = Score(
      widget.level.number,
      _points,
      DateTime.now().difference(_startOfPlay),
    );

    final playerProgress = context.read<PlayerProgress>();
    playerProgress.setLevelReached(widget.level.number);

    // Let the player see the game just after winning for a bit.
    await Future<void>.delayed(_preCelebrationDuration);
    if (!mounted) return;

    setState(() {
      _duringCelebration = true;
    });

    final audioController = context.read<AudioController>();
    audioController.playSfx(SfxType.congrats);

    final gamesServicesController = context.read<GamesServicesController?>();
    if (gamesServicesController != null) {
      // Award achievement.
      if (widget.level.awardsAchievement) {
        await gamesServicesController.awardAchievement(
          android: widget.level.achievementIdAndroid!,
          iOS: widget.level.achievementIdIOS!,
        );
      }

      // Send score to leaderboard.
      await gamesServicesController.submitLeaderboardScore(score);
    }

    /// Give the player some time to see the celebration animation.
    await Future<void>.delayed(_celebrationDuration);
    if (!mounted) return;

    GoRouter.of(context).go('/play/won', extra: {'score': score});
  }
}
