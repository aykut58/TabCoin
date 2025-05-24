import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:animated_gradient/animated_gradient.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';
import 'package:tapcoin/pages/profile.dart';

import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../constants/api_service.dart';
import '../constants/constants.dart';
import '../constants/points_service.dart';
import 'homepage.dart';
import 'package:particle_background/particle_background.dart';

class Home extends StatefulWidget {
  final String userID;
  final String username;
  final bool isLogin;

  const Home(
      {super.key,
      required this.userID,
      required this.username,
      required this.isLogin});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final List<TapData> _tapDataList = [];
  final Map<int, Offset> _pointerPositions =
      {}; // Store positions by pointer ID
  double _tiltAngleX = 0.0;
  double _tiltAngleY = 0.0;

  bool activeBot = false;
  bool botSwitch = false;

  int _tapCount = 0;
  int bot_level = 0;
  int _perTap = 0;
  int _maxTapsFinger = 0; // Maximum number of simultaneous taps

  int boostCount = 1;

  // Timer? _timer;
  Timer? _energyTimer;
  Timer? _adTimer;

  int tapEnergy = 0;
  int maxTapEnergy = 1;

  final bool _isLoadingPurchase = false;

  RewardedAd? _rewardedAd;
  RewardedAd? _rewardedAdBonus;
  int _numRewardedLoadAttempts = 0;

  bool _isLoadingTaps = true;

  late AnimationController _controller;
  double _rotationSpeed = 1.0;
  DateTime? _lastTapTime;
  Timer? _decelerationTimer;
  bool _isRotating = false;

  late AnimationController _shakecontroller;
  late Animation<double> _animation;

  final HttpService httpService = HttpService();

  final PointsService pointsService = PointsService();

  void _addPoints(String userID, int amount) {
    pointsService.addPoints(userID, amount, widget.isLogin).then((_) {
      print('Points added successfully');
      _fetchTaps();
    }).catchError((error) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: error.toString(),
        ),
      );
    });
  }

  Future<void> _fetchTaps() async {
    if (widget.isLogin) {
      try {
        final response = await httpService
            .post('user/fetch-taps.php', {'userID': widget.userID});
        var jsonData = response;
        setState(() {
          _isLoadingTaps = false;
        });
        if (jsonData["error"]) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
              message: jsonData["message"],
            ),
          );
        } else if (jsonData["success"]) {
          setState(() {
            _tapCount = int.parse(jsonData["taps"]);
            _perTap = int.parse(jsonData["tap_counts"]);
            _maxTapsFinger = int.parse(jsonData["fingers"]);
            tapEnergy = int.parse(jsonData["energy"]);
            boostCount = int.parse(jsonData["boost_count"]);
            maxTapEnergy = int.parse(jsonData["max_energy"]);
          });
          bot_level = int.parse(jsonData["bot_level"]);
          if (bot_level > 0) {
            setState(() {
              activeBot = true;
              botSwitch = true;
            });
            botTapFunction();
          }
          //  _startTimer();
          if (tapEnergy < maxTapEnergy) {
            _startTimerEnergy();
          }
        } else {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.error(
              message: "Unknown error",
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
              message: error.toString(),
            ),
          );
        }
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _tapCount = int.parse(prefs.getString(TAPS)!);
        _perTap = int.parse(prefs.getString(TAP_COUNT)!);
        _maxTapsFinger = int.parse(prefs.getString(FINGERS)!);
        tapEnergy = int.parse(prefs.getString(TAP_ENERGY)!);
        boostCount = int.parse(prefs.getString(RECHARGING_SPEED)!);
        maxTapEnergy = int.parse(prefs.getString(MAX_ENERGY)!);
        bot_level = int.parse(prefs.getString(BOT_LEVEL)!);
      });
      if (bot_level > 0) {
        setState(() {
          activeBot = true;
          botSwitch = true;
        });
        botTapFunction();
      }
      if (tapEnergy < maxTapEnergy) {
        _startTimerEnergy();
      }
      setState(() {
        _isLoadingTaps = false;
      });
    }
  }

  botTapFunction() {
    Timer _botTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      for (int i = 0; i < bot_level; i++) {
        if (tapEnergy < 1 || !botSwitch) {
          _onTapEnd();
          setState(() {
            botSwitch = false;
          });
          timer.cancel();
        } else {
          _onTapDown();
          setState(() {
            _tapCount += _perTap;
            tapEnergy--;
          });
          _startShakeAnimation();
        }
      }
    });
  }

  Future<void> _updateTaps() async {
    if (_tapCount > 0) {
      if (widget.isLogin) {
        try {
          final response = await httpService.post('user/update-taps.php', {
            'taps': _tapCount.toString(),
            'userID': widget.userID,
            'energy': tapEnergy.toString(),
          });
          var jsonData = response;
          if (jsonData["error"]) {
            showTopSnackBar(
              Overlay.of(context),
              CustomSnackBar.error(
                message: jsonData["message"],
              ),
            );
          } else if (jsonData["success"]) {
            if (kDebugMode) {
              print("Post taps success");
            }
          } else {
            showTopSnackBar(
              Overlay.of(context),
              const CustomSnackBar.error(
                message: "Unknown error",
              ),
            );
          }
        } catch (error) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
              message: error.toString(),
            ),
          );
        }
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(TAPS, _tapCount.toString());
        prefs.setString(TAP_ENERGY, tapEnergy.toString());
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointerPositions.length < _maxTapsFinger) {
      if (tapEnergy > 0) {
        _onTapDown();
        setState(() {
          _pointerPositions[event.pointer] = event.localPosition;
          _tapCount += _perTap;
          tapEnergy--;
          // Create and start the animation controller
          AnimationController controller = AnimationController(
            duration: const Duration(seconds: 1),
            vsync: this,
          );
          Animation<Offset> animation = Tween<Offset>(
            begin: const Offset(0, 0),
            end: const Offset(0, -100),
          ).animate(controller);

          TapData tapData = TapData(
            position: event.localPosition,
            controller: controller,
            animation: animation,
          );
          _tapDataList.add(tapData);

          controller.forward().then((_) {
            setState(() {
              _tapDataList.remove(tapData);
            });
          });

          _updateTiltAngle();
        });
      } else {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.info(message: context.tr('energy_low')),
        );
      }
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    setState(() {
      if (_pointerPositions.containsKey(event.pointer)) {
        _pointerPositions[event.pointer] = event.localPosition;
        _updateTiltAngle();
      }
    });
  }

  void _handlePointerUpOrCancel(PointerEvent event) {
    _onTapEnd();
    if (tapEnergy < maxTapEnergy) {
      _startTimerEnergy();
    }
    setState(() {
      _pointerPositions.remove(event.pointer);
      if (_pointerPositions.isEmpty) {
        _tiltAngleX = 0.0;
        _tiltAngleY = 0.0;
      }
      _updateTiltAngle();
    });
  }

  void _updateTiltAngle() {
    if (_pointerPositions.isEmpty) {
      _tiltAngleX = 0.0;
      _tiltAngleY = 0.0;
      return;
    }

    double centerX = context.size!.width / 2;
    double centerY = context.size!.height / 2;
    double dx = 0.0;
    double dy = 0.0;

    for (var pos in _pointerPositions.values) {
      dx += pos.dx - centerX;
      dy += pos.dy - centerY;
    }

    dx /= _pointerPositions.length;
    dy /= _pointerPositions.length;

    _tiltAngleX = dx * 0.0008; // Adjust the factor to control tilt intensity
    _tiltAngleY = dy * 0.0008; // Adjust the factor to control tilt intensity
  }

  void _startTimerEnergy() {
    _energyTimer?.cancel();
    _energyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (tapEnergy < maxTapEnergy) {
          tapEnergy += boostCount;
        } else if (tapEnergy >= maxTapEnergy) {
          tapEnergy = maxTapEnergy;
          _energyTimer?.cancel();
        } else {
          _energyTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    for (var tapData in _tapDataList) {
      tapData.controller.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    _updateTaps();
    _controller.dispose();
    _decelerationTimer?.cancel();
    _energyTimer?.cancel();
    _rewardedAd?.dispose();
    _rewardedAdBonus?.dispose();
    _shakecontroller.dispose();
    _adTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _updateTaps();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addObserver(this);
    _fetchTaps();
    _createRewardedAd();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..stop(); // Initialize in stopped state

    _shakecontroller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 10)
        .chain(
          CurveTween(curve: Curves.elasticIn),
        )
        .animate(_shakecontroller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakecontroller.reverse();
        }
      });

    _startAdTimer();
    _createRewardedAdBonus();

    super.initState();
  }

  void _startAdTimer() {
    _adTimer = Timer(const Duration(minutes: 10), _showAdDialog);
  }

  void _showAdDialog() {
    if (_rewardedAdBonus != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('watch_ads_bonus'.tr()),
            content: Text('watch_ads_text'.tr()),
            actions: [
              TextButton(
                child: Text('no_thanks'.tr()),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('watch_ads'.tr()),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showRewardedAdBonus();
                },
              ),
            ],
          );
        },
      );
    } else {
      // Retry loading the ad if it failed initially
      _createRewardedAd();
      _startAdTimer();
    }
  }

  void _startShakeAnimation() {
    if (!_shakecontroller.isAnimating) {
      _shakecontroller.forward();
    }
  }

  void _stopShakeAnimation() {
    if (_shakecontroller.isAnimating) {
      _shakecontroller.stop();
    }
  }

  void _updateRotationSpeed() {
    if (_lastTapTime != null) {
      DateTime now = DateTime.now();
      int difference = now.difference(_lastTapTime!).inMilliseconds;
      double tapSpeed = max(1.0, 500.0 / difference);
      _rotationSpeed = tapSpeed;

      int durationMs = max(1, (1000 / _rotationSpeed).round());
      _controller.duration = Duration(milliseconds: durationMs);

      if (!_isRotating) {
        _controller.repeat(); // Start rotating
        _isRotating = true;
      }

      // Reset deceleration timer
      _decelerationTimer?.cancel();
    }
  }

  void _onTapDown() {
    _lastTapTime = DateTime.now();
    _updateRotationSpeed();
  }

  void _onTapEnd() {
    _decelerationTimer?.cancel(); // Cancel any existing timer
    _decelerationTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _controller.stop();
        // _lastTapTime = null;
        _isRotating = false;
      });
      //_startDeceleration();
    });
  }

  void _createRewardedAd() {
    RewardedAd.load(
        adUnitId: Platform.isAndroid
            ? ADMOB_REWARD_ENERGY_UNIT_ANDROID
            : ADMOB_REWARD_ENERGY_UNIT_IOS,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts < 3) {
              _createRewardedAd();
            }
          },
        ));
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      print('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      setState(() {
        tapEnergy = maxTapEnergy;
      });
      print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
      _updateTaps();
      _createRewardedAd();
    });
    _rewardedAd = null;
  }

  void _createRewardedAdBonus() {
    RewardedAd.load(
        adUnitId: Platform.isAndroid
            ? ADMOB_REWARD_BONUS_UNIT_ANDROID
            : ADMOB_REWARD_BONUS_UNIT_IOS,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            _rewardedAdBonus = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            _rewardedAdBonus = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts < 3) {
              _createRewardedAd();
            }
          },
        ));
  }

  void _showRewardedAdBonus() {
    if (_rewardedAdBonus == null) {
      print('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAdBonus!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );

    _rewardedAdBonus!.setImmersiveMode(true);
    _rewardedAdBonus!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      _addPoints(widget.userID, 20000);
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(message: context.tr('bonus_granted')),
      );
      print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
      _fetchTaps();
    });
    _rewardedAdBonus = null;
  }

  /* void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _updateTaps();
    });
  }
  */

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.secondary,
        child: AnimatedGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary
          ],
          child: Stack(children: [
            ParticleBackground(
              maxLineLength: 100,
              maxSpeed: 100,
              minSpeed: 50,
              sideStrength: 50,
              lineColor: Theme.of(context).colorScheme.primary,
              dotColor: Colors.orangeAccent,
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(30, 5, 10, 5),
                    height: 50,
                    width: _width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Profile(
                                          username: widget.username,
                                          userID: widget.userID,
                                          isLogin: widget.isLogin)));
                            },
                            child: Text(widget.username,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16))),
                        GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Profile(
                                            username: widget.username,
                                            userID: widget.userID,
                                            isLogin: widget.isLogin,
                                          )));
                            },
                            child: CircleAvatar(
                              backgroundImage: widget.isLogin
                                  ? const AssetImage("assets/images/people.png")
                                  : const AssetImage("assets/images/unknown.png"),
                            ))
                      ],
                    ),
                  ),
                  _isLoadingTaps
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/images/coin.png",
                                  height: 30,
                                  width: 30,
                                ),
                                Text(' ${formatNumber(_tapCount)}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 28)),
                              ],
                            ),
                            getLevelName(_tapCount),
                          ],
                        ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 25, 40, 20),
                    child: Center(
                      child: SizedBox(
                        height: 250,
                        width: 250,
                        child: Listener(
                          onPointerDown: _handlePointerDown,
                          onPointerMove: _handlePointerMove,
                          onPointerUp: _handlePointerUpOrCancel,
                          onPointerCancel: _handlePointerUpOrCancel,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform(
                                alignment: FractionalOffset.center,
                                transform: Matrix4.identity()
                                  ..rotateX(_tiltAngleY)
                                  ..rotateY(_tiltAngleX),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                   RotationTransition(
                                            turns: _controller.drive(Tween<
                                                double>(
                                              begin: 0.0,
                                              end:
                                                  -1.0, // Negative value for counter-clockwise rotation
                                            ).chain(CurveTween(
                                                curve: Curves
                                                    .linear))), // Negative value for counter-clockwise rotation
                                            child: CircleImage(
                                              imageUrl: 'assets/images/outer-ring.png',
                                              size: 230,
                                            ),
                                          )
                                        ,
                                    CircleImage(
                                      imageUrl: 'assets/images/tap-coin.png',
                                      size: 170,
                                    ),
                                  ],
                                ),
                              ),
                              for (var tapData in _tapDataList)
                                AnimatedBuilder(
                                  animation: tapData.controller,
                                  builder: (context, child) {
                                    return Positioned(
                                      left: tapData.position.dx,
                                      top: tapData.position.dy +
                                          tapData.animation.value.dy,
                                      child: Opacity(
                                        opacity: 1 - tapData.controller.value,
                                        child: Text(
                                          "+$_perTap",
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 25),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      children: [
                        Text(context.tr('tap_energy'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SimpleAnimationProgressBar(
                              height: 15,
                              width: _width * 0.7,
                              backgroundColor: Colors.grey.shade800,
                              foregroundColor: Colors.purple,
                              ratio: tapEnergy / maxTapEnergy,
                              direction: Axis.horizontal,
                              curve: Curves.fastLinearToSlowEaseIn,
                              duration: const Duration(seconds: 3),
                              borderRadius: BorderRadius.circular(10),
                              gradientColor: LinearGradient(colors: [
                                Theme.of(context).colorScheme.secondary,
                                Theme.of(context).colorScheme.primary
                              ]),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.yellow,
                                  offset: Offset(
                                    2.0,
                                    2.0,
                                  ),
                                  blurRadius: 2.0,
                                  spreadRadius: 2.0,
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 15,
                            ),
                            GestureDetector(
                              onTap: _showRewardedAd,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Column(
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        color: Colors.yellow,
                                        size: 35,
                                      ),
                                      const Text("refill",
                                              style: TextStyle(
                                                  color: Colors.yellow,
                                                  fontSize: 10))
                                          .tr()
                                    ],
                                  ),
                                  Positioned(
                                      bottom: 35,
                                      left: 18,
                                      child: Container(
                                          height: 18,
                                          width: 18,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color: Colors.red),
                                          child: const Center(
                                              child: Text('Ad',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10))))),
                                ],
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("$tapEnergy/$maxTapEnergy",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(context.tr('level_progress'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16)),
                        Center(
                            child: SimpleAnimationProgressBar(
                          height: 20,
                          width: _width,
                          backgroundColor: Colors.grey.shade800,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          ratio: getProgressRatio(_tapCount),
                          direction: Axis.horizontal,
                          curve: Curves.fastLinearToSlowEaseIn,
                          duration: const Duration(seconds: 3),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(
                                3.0,
                                3.0,
                              ),
                              blurRadius: 5.0,
                              spreadRadius: 1.0,
                            ),
                          ],
                        )),
                        getLevelProgress(_tapCount),
                        const SizedBox(
                          height: 30,
                        ),
                        _isLoadingPurchase
                            ? const CircularProgressIndicator()
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomePage(
                                                    initialIndex: 2,
                                                  )),
                                          (Route<dynamic> route) => false);
                                    },
                                    child:
                                        Stack(clipBehavior: Clip.none, children: [
                                      Container(
                                        height: 60,
                                        width: 60,
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Image.asset(
                                              "assets/images/tap-one.png",
                                              width: 30,
                                              height: 30,
                                            ),
                                            Text(
                                              'per_tap',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary,
                                                  fontWeight: FontWeight.bold),
                                            ).tr(),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                          bottom: 45,
                                          left: 45,
                                          child: Container(
                                              height: 22,
                                              width: 22,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10.0),
                                                  color: Colors.red),
                                              child: Center(
                                                  child: Text("x$_perTap",
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12))))),
                                    ]),
                                  ),
                                  const SizedBox(
                                    width: 15,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomePage(
                                                    initialIndex: 2,
                                                  )),
                                          (Route<dynamic> route) => false);
                                    },
                                    child:
                                        Stack(clipBehavior: Clip.none, children: [
                                      Container(
                                        height: 60,
                                        width: 60,
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Image.asset(
                                              "assets/images/tap-multi.png",
                                              width: 30,
                                              height: 30,
                                            ),
                                            Text(
                                              "fingers",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary,
                                                  fontWeight: FontWeight.bold),
                                            ).tr(),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                          bottom: 45,
                                          left: 45,
                                          child: Container(
                                              height: 20,
                                              width: 20,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10.0),
                                                  color: Colors.red),
                                              child: Center(
                                                  child: Text("x$_maxTapsFinger",
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13))))),
                                    ]),
                                  ),
                                  const SizedBox(
                                    width: 15,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const HomePage(
                                                    initialIndex: 2,
                                                  )),
                                          (Route<dynamic> route) => false);
                                    },
                                    child:
                                        Stack(clipBehavior: Clip.none, children: [
                                      Container(
                                        height: 60,
                                        width: 60,
                                        padding:
                                            const EdgeInsets.fromLTRB(1, 5, 1, 3),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Image.asset(
                                              "assets/images/power.png",
                                              width: 28,
                                              height: 26,
                                            ),
                                            Flexible(
                                              child: Text(
                                                'recharging_speed',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 9,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary,
                                                    fontWeight: FontWeight.bold),
                                              ).tr(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                          bottom: 45,
                                          left: 45,
                                          child: Container(
                                              height: 22,
                                              width: 22,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10.0),
                                                  color: Colors.red),
                                              child: Center(
                                                  child: Text("x$boostCount",
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12))))),
                                    ]),
                                  ),
                                  const SizedBox(
                                    width: 15,
                                  ),
                                  activeBot
                                      ? GestureDetector(
                                          onTap: () {
                                            if (botSwitch) {
                                              setState(() {
                                                botSwitch = false;
                                              });
                                            } else {
                                              setState(() {
                                                botSwitch = true;
                                              });
                                              botTapFunction();
                                            }
                                            _stopShakeAnimation();
                                          },
                                          child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Container(
                                                  height: 60,
                                                  width: 60,
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          1, 5, 1, 3),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5.0),
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      AnimatedBuilder(
                                                        animation: _animation,
                                                        builder:
                                                            (context, child) {
                                                          return Transform
                                                              .translate(
                                                            offset: Offset(
                                                                _animation.value,
                                                                0),
                                                            child: child,
                                                          );
                                                        },
                                                        child: Image.asset(
                                                          "assets/images/bot.png",
                                                          width: 28,
                                                          height: 26,
                                                        ),
                                                      ),
                                                      Flexible(
                                                        child: Text(
                                                          'bot'.tr(),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .tertiary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ).tr(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Positioned(
                                                    bottom: 45,
                                                    left: 45,
                                                    child: Container(
                                                        height: 22,
                                                        width: 22,
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10.0),
                                                            color: Colors.red),
                                                        child: Center(
                                                            child: Text(
                                                                "L$bot_level",
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        12))))),
                                                Positioned(
                                                    bottom: 20,
                                                    left: 20,
                                                    right: 20,
                                                    top: 30,
                                                    child: botSwitch
                                                        ? Container(
                                                            height: 22,
                                                            width: 22,
                                                            decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50.0),
                                                                color:
                                                                    Colors.green),
                                                          )
                                                        : Container(
                                                            height: 22,
                                                            width: 22,
                                                            decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50.0),
                                                                color:
                                                                    Colors.red),
                                                          )),
                                              ]),
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class TapData {
  final Offset position;
  final AnimationController controller;
  final Animation<Offset> animation;

  TapData({
    required this.position,
    required this.controller,
    required this.animation,
  });
}

class CircleImage extends StatelessWidget {
  final String imageUrl;
  final double size;

  CircleImage({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
