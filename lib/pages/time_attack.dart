import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';
import 'package:tapcoin/pages/profile.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../constants/api_service.dart';
import '../constants/constants.dart';
import '../constants/egg_widget.dart';
import '../constants/points_service.dart';
import 'home.dart';

class TimeAttack extends StatefulWidget {
  final String userID;
  final String username;
  final int requiredTaps;
  final int reward;
  final int index;
  final bool isLogin;

  const TimeAttack(
      {super.key,
      required this.userID,
      required this.username,
      required this.requiredTaps,
      required this.index,
      required this.reward,
      required this.isLogin});

  @override
  State<TimeAttack> createState() => _TimeAttackState();
}

class _TimeAttackState extends State<TimeAttack> with TickerProviderStateMixin {
  final List<TapData> _tapDataList = [];
  final Map<int, Offset> _pointerPositions =
      {}; // Store positions by pointer ID
  double _tiltAngleX = 0.0;
  double _tiltAngleY = 0.0;
  int _tapCount = 0;
  int _perTap = 0;
  int _maxTaps = 0; // Maximum number of simultaneous taps
  Timer? _timer;
  int _startTime = 60;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;
  bool _isLoadingTaps = true;

  bool _isCracked = false;
  bool _showEgg = false;

  int bonusCoins = 0;

  final List<int> _coinRewards =
      List.generate(100, (index) => 100 + index * 100);

  bool isLoading = true;

  int levelNum = 0;

  void _createRewardedAd() {
    RewardedAd.load(
        adUnitId: Platform.isAndroid
            ? ADMOB_REWARD_LEVEL_UNIT_ANDROID
            : ADMOB_REWARD_LEVEL_UNIT_IOS,
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

  void _showRewardedAd(int myReward) {
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
      _addPoints(widget.userID, myReward);
      ad.dispose();
      Navigator.pop(context);
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(message: context.tr('bonus_granted')),
      );
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TimeAttack(
              userID: widget.userID,
              username: widget.username,
              requiredTaps: requiredPoints[widget.index + 1],
              index: widget.index + 1,
              reward: rewards[widget.index + 1],
              isLogin: widget.isLogin,
            ),
          ));
    });
    _rewardedAd = null;
  }

  reloadLevel() {
    Navigator.of(context).pop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => TimeAttack(
              userID: widget.userID,
              username: widget.username,
              requiredTaps: widget.requiredTaps,
              index: widget.index,
              reward: widget.reward,
              isLogin: widget.isLogin)),
    );
  }

  List<bool> _unlockedLevels = List<bool>.generate(100, (index) => index == 0);

  Future<void> _saveUnlockedLevels() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> unlockedStringList =
        _unlockedLevels.map((bool value) => value.toString()).toList();
    await prefs.setStringList('unlockedLevels', unlockedStringList);
  }

  void _unlockNextLevel(int index) {
    setState(() {
      if (index < _unlockedLevels.length - 1) {
        _unlockedLevels[index + 1] = true;
      }
    });
    _saveUnlockedLevels();
  }

  Future<void> _loadUnlockedLevels() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? unlockedStringList = prefs.getStringList('unlockedLevels');
    if (unlockedStringList != null) {
      setState(() {
        _unlockedLevels =
            unlockedStringList.map((string) => string == 'true').toList();
      });
    }
  }

  final HttpService httpService = HttpService();

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
            //  _tapCount = int.parse(jsonData["taps"]);
            _perTap = int.parse(jsonData["tap_counts"]);
            _maxTaps = int.parse(jsonData["fingers"]);
          });
          //  _startTimer();
        } else {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.error(
              message: "Unknown error",
            ),
          );
        }
      } catch (error) {
        setState(() {
          _isLoadingTaps = false;
        });
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: error.toString(),
          ),
        );
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _perTap = int.parse(prefs.getString(TAP_COUNT)!);
        _maxTaps = int.parse(prefs.getString(FINGERS)!);
      });
      setState(() {
        _isLoadingTaps = false;
      });
    }
  }

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

  void _showLevelCompleteDialog(int level, int reward, int bonus) {
    _unlockNextLevel(level - 1);
    _addPoints(widget.userID, reward + bonus);
    _showLevelDialog(
        context, level, reward, bonus, true, _rewardedAd != null ? true : false,
        () {
      Navigator.pop(context);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TimeAttack(
              userID: widget.userID,
              username: widget.username,
              requiredTaps: requiredPoints[widget.index + 1],
              index: widget.index + 1,
              reward: rewards[widget.index + 1],
              isLogin: widget.isLogin,
            ),
          ));

      //  _unlockNextLevel(level - 1); // Unlock the next level
    });
  }

  void _showLevelFailedDialog(int level, int reward, int bonus) {
    _showLevelDialog(context, level, reward, bonus, false, false, () {
      if (_interstitialAd != null) {
        _interstitialAd?.show();
      } else {
        reloadLevel();
      }
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointerPositions.length < _maxTaps) {
      setState(() {
        _pointerPositions[event.pointer] = event.localPosition;
        _tapCount += _perTap;

        if (_tapCount >= widget.requiredTaps) {
          _tapCount = widget.requiredTaps;
          _timer?.cancel();
          bonusCoins += _startTime;
          _showLevelCompleteDialog(widget.index + 1, widget.reward, bonusCoins);
        }

        // Create and start the animation controller
        AnimationController controller = AnimationController(
          duration: const Duration(seconds: 1),
          vsync: this,
        );
        Animation<Offset> animation = Tween<Offset>(
          begin: Offset(0, 0),
          end: Offset(0, -100),
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

    _tiltAngleX = dx * 0.001; // Adjust the factor to control tilt intensity
    _tiltAngleY = dy * 0.001; // Adjust the factor to control tilt intensity
  }

  final adUnitId = Platform.isAndroid
      ? ADMOB_INTERSTITIAL_RETRY_UNIT_ANDROID
      : ADMOB_INTERSTITIAL_RETRY_UNIT_IOS;

  void loadAd() {
    InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  reloadLevel();
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  reloadLevel();
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});

            debugPrint('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }

  InterstitialAd? _interstitialAdSuccess;

  // TODO: replace this test ad unit with your own ad unit.
  final adUnitIdSuccess = Platform.isAndroid
      ? ADMOB_INTERSTITIAL_UNIT_ANDROID_SUCCESS
      : ADMOB_INTERSTITIAL_UNIT_IOS_SUCCESS;

  /// Loads an interstitial ad.
  void loadAdSuccess() {
    InterstitialAd.load(
        adUnitId: adUnitIdSuccess,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TimeAttack(
                          userID: widget.userID,
                          username: widget.username,
                          requiredTaps: requiredPoints[widget.index + 1],
                          index: widget.index + 1,
                          reward: rewards[widget.index + 1],
                          isLogin: widget.isLogin,
                        ),
                      ));
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  ad.dispose();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TimeAttack(
                          userID: widget.userID,
                          username: widget.username,
                          requiredTaps: requiredPoints[widget.index + 1],
                          index: widget.index + 1,
                          reward: rewards[widget.index + 1],
                          isLogin: widget.isLogin,
                        ),
                      ));
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});
            debugPrint('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            _interstitialAdSuccess = ad;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }

  @override
  void dispose() {
    for (var tapData in _tapDataList) {
      tapData.controller.dispose();
    }
    // _updateTaps();
    _timer?.cancel();
    _interstitialAd?.dispose();
    _interstitialAdSuccess?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    _fetchTaps();
    _loadUnlockedLevels();
    loadAd();
    loadAdSuccess();
    _createRewardedAd();
    levelNum = widget.index + 1;
    super.initState();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_startTime > 0) {
          _startTime--;
          _maybeShowEgg();
        } else {
          _timer?.cancel();
          _showLevelFailedDialog(widget.index + 1, widget.reward, _startTime);
        }
      });
    });
  }

  void _maybeShowEgg() {
    if (!_showEgg && Random().nextDouble() < 0.1) {
      // 10% chance each second to show egg
      _showEgg = true;
    }
  }

  void _onEggCrack() {
    setState(() {
      _isCracked = true;
      bonusCoins += _coinRewards[widget.index + 1 - 1];
      _showEgg = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;

    return Scaffold(
        body: Container(
      height: _height,
      width: _width,
      color: Theme.of(context).colorScheme.secondary,
      child: _isLoadingTaps
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(30, 100, 30, 10),
                      child: Column(
                        children: [
                          Text("level".tr(args: [levelNum.toString()]),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 25)),
                          const SizedBox(
                            height: 30,
                          ),
                          CircularCountDownTimer(
                            duration: 3,
                            initialDuration: 0,
                            controller: CountDownController(),
                            width: MediaQuery.of(context).size.width / 3,
                            height: MediaQuery.of(context).size.height / 3,
                            ringColor: Colors.grey[300]!,
                            ringGradient: null,
                            fillColor: Theme.of(context).colorScheme.primary,
                            fillGradient: null,
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            backgroundGradient: null,
                            strokeWidth: 20.0,
                            strokeCap: StrokeCap.round,
                            textStyle: const TextStyle(
                                fontSize: 33.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            textFormat: CountdownTextFormat.S,
                            isReverse: true,
                            isReverseAnimation: true,
                            isTimerTextShown: true,
                            autoStart: true,
                            onStart: () {
                              debugPrint('Countdown Started');
                            },
                            onComplete: () {
                              _startTimer();
                              setState(() {
                                isLoading = false;
                              });
                            },
                            onChange: (String timeStamp) {
                              debugPrint('Countdown Changed $timeStamp');
                            },
                            timeFormatterFunction:
                                (defaultFormatterFunction, duration) {
                              if (duration.inSeconds == 0) {
                                return "start".tr();
                              } else {
                                return Function.apply(
                                    defaultFormatterFunction, [duration]);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(30, 5, 10, 5),
                          height: 50,
                          width: _width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("level".tr(args: [levelNum.toString()]),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16)),
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
                                  child: const CircleAvatar(
                                    backgroundImage:
                                        AssetImage("assets/images/selfie.png"),
                                  ))
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/double-tap.png",
                              height: 30,
                              width: 30,
                            ),
                            Text(
                                ' ${formatNumber(_tapCount)}/${widget.requiredTaps}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 25)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 5, 30, 5),
                          child: Center(
                              child: SimpleAnimationProgressBar(
                            height: 20,
                            width: _width,
                            backgroundColor: Colors.grey.shade800,
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            ratio: _tapCount / widget.requiredTaps,
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
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 30, 40, 30),
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
                                      child: ClipOval(
                                          child: Image.asset(
                                        'assets/images/tap3.png',
                                        width: 250,
                                        height: 250,
                                      )),
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
                                              opacity:
                                                  1 - tapData.controller.value,
                                              child: Text(
                                                "+${_perTap}",
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 25),
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
                        SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          height: 80,
                          width: _width,
                          child: Stack(
                            children: [
                              const Column(
                                children: [
                                  /*   Text('Level: $_currentLevel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Coins: $_totalCoins', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Time: $_remainingTime', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),*/
                                ],
                              ),
                              if (_showEgg)
                                EggWidget(
                                  onCrack: _onEggCrack,
                                  level: widget.index + 1,
                                  coins: _coinRewards[widget.index + 1 - 1],
                                ),
                              if (_isCracked)
                                EggWidget(
                                  onCrack: () {},
                                  level: widget.index + 1,
                                  coins: _coinRewards[widget.index + 1 - 1],
                                ), // This line keeps the cracked egg moving
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                          child: Column(
                            children: [
                              Text(context.tr('timer'),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SimpleAnimationProgressBar(
                                    height: 25,
                                    width: _width * 0.8,
                                    backgroundColor: Colors.grey.shade800,
                                    foregroundColor: Colors.purple,
                                    ratio: _startTime / 60,
                                    direction: Axis.horizontal,
                                    curve: Curves.fastLinearToSlowEaseIn,
                                    duration: const Duration(seconds: 3),
                                    borderRadius: BorderRadius.circular(10),
                                    gradientColor: LinearGradient(colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary
                                    ]),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.yellowAccent,
                                        offset: Offset(
                                          2.0,
                                          2.0,
                                        ),
                                        blurRadius: 2.0,
                                        spreadRadius: 2.0,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_startTime.toString(),
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15)),
                                  const Text("60",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 15)),
                                ],
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            height: 50,
                                            width: 50,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                            child: Image.asset(
                                                "assets/images/tap-one.png"),
                                          ),
                                          Positioned(
                                              bottom: 35,
                                              left: 35,
                                              child: Container(
                                                  height: 20,
                                                  width: 20,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                      color: Colors.red),
                                                  child: Center(
                                                      child: Text(
                                                          _perTap.toString(),
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 15))))),
                                        ]),
                                  ),
                                  GestureDetector(
                                    child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            height: 50,
                                            width: 50,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                            child: Image.asset(
                                                "assets/images/tap-multi.png"),
                                          ),
                                          Positioned(
                                              bottom: 35,
                                              left: 35,
                                              child: Container(
                                                  height: 20,
                                                  width: 20,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                      color: Colors.red),
                                                  child: Center(
                                                      child: Text(
                                                          _maxTaps.toString(),
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      15))))),
                                        ]),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
    ));
  }

  void _showLevelDialog(BuildContext context, int level, int reward, int bonus,
      bool isComplete, bool adsReady, VoidCallback onNextLevel) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: SizedBox(
              height: 320,
              child: isComplete
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            backgroundImage:
                                AssetImage('assets/images/checked.png'),
                            radius: 30,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "level_complete".tr(args: [level.toString()]),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "earned_reward".tr(args: [reward.toString()]),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20),
                          ),
                          Text(
                            "earned_bonus".tr(args: [bonus.toString()]),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      Colors.white, // foreground (text) color
                                  backgroundColor: Theme.of(context)
                                      .primaryColor, // background color
                                ),
                                onPressed: onNextLevel,
                                child: Text(context.tr('next_level')),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              adsReady
                                  ? ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors
                                            .white, // foreground (text) color
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .secondary, // background color
                                      ),
                                      onPressed: () {
                                        _showRewardedAd(reward);
                                      },
                                      child: Text(
                                        "reward_x2".tr(),
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              backgroundImage:
                                  AssetImage('assets/images/failed.png'),
                              radius: 30,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "level_failed".tr(args: [level.toString()]),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              context.tr('level_time_up'),
                              style: const TextStyle(fontSize: 20),
                            ),
                            Text(
                              context.tr('please_retry'),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor:
                                    Colors.white, // foreground (text) color
                                backgroundColor: Theme.of(context)
                                    .primaryColor, // background color
                              ),
                              onPressed: onNextLevel,
                              child: Text(context.tr('retry_level')),
                            ),
                          ],
                        ),
                      ),
                    ),
            ));
      },
    );
  }
}
