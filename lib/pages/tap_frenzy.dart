import 'dart:async';
import 'dart:io';

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../constants/api_service.dart';
import '../constants/constants.dart';
import '../constants/points_service.dart';
import 'home.dart';
import 'homepage.dart';

class TapFrenzy extends StatefulWidget {
  final String userID;
  final String username;
  final bool isLogin;

  const TapFrenzy({
    super.key,
    required this.userID,
    required this.username,
    required this.isLogin,
  });

  @override
  State<TapFrenzy> createState() => _TapFrenzyState();
}

class _TapFrenzyState extends State<TapFrenzy>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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

  bool isLoading = true;
  bool _isLoadingTaps = true;

  final PointsService pointsService = PointsService();
  final HttpService httpService = HttpService();

  Future<void> _fetchTaps() async {

    if (widget.isLogin) {
      try {
        final response = await httpService.post('user/fetch-taps.php', {
          'userID': widget.userID
        });
        var jsonData = response;
        setState(() {
          _isLoadingTaps = false;
        });
        if (jsonData["error"]) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.error(
              message:
              jsonData["message"],
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
              message:
              "Unknown error",
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
            message:
            error.toString(),
          ),
        );
      }
    }
    else {

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

  void _addPoints(String userID, int amount) {
    pointsService
        .addPoints(userID, amount, widget.isLogin)
        .then((_) {})
        .catchError((error) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: error.toString(),
        ),
      );
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointerPositions.length < _maxTaps) {
      setState(() {
        _pointerPositions[event.pointer] = event.localPosition;
        _tapCount += _perTap;

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

  @override
  void dispose() {
    for (var tapData in _tapDataList) {
      tapData.controller.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    _fetchTaps();
    WidgetsBinding.instance.addObserver(this);
    loadAd();
    super.initState();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_startTime > 0) {
          _startTime--;
        } else {
          _timer?.cancel();
          _addPoints(widget.userID, _tapCount);
          _interstitialAd?.show();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(
                initialIndex: 2,
              ),
            ),
            (Route<dynamic> route) => false,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;

    return Material(
      child: SafeArea(
          child: Container(
        height: _height,
        color: Theme.of(context).colorScheme.secondary,
        child: _isLoadingTaps ? const SizedBox(
          height: 50,
            width: 50,
            child: CircularProgressIndicator()) : SingleChildScrollView(
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(30, 100, 30, 10),
                  child: CircularCountDownTimer(
                    duration: 3,
                    initialDuration: 0,
                    controller: CountDownController(),
                    width: MediaQuery.of(context).size.width / 3,
                    height: MediaQuery.of(context).size.height / 3,
                    ringColor: Colors.grey[300]!,
                    ringGradient: null,
                    fillColor: Theme.of(context).colorScheme.primary,
                    fillGradient: null,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
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
                        return "Start";
                      } else {
                        return Function.apply(
                            defaultFormatterFunction, [duration]);
                      }
                    },
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(30, 5, 10, 5),
                      height: 50,
                      width: _width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.username,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          const CircleAvatar()
                        ],
                      ),
                    ),
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
                                color: Colors.white, fontSize: 25)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
                      child: Center(
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
                                child: SimpleShadow(
                                  opacity: 0.6, // Default: 0.5
                                  color: Colors.black, // Default: Black
                                  offset: Offset(5, 3), // Default: Offset(2, 2)
                                  sigma: 7,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child:
                                        Image.asset('assets/images/tap3.png'),
                                  ), // Default: 2
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
                                          "+${_perTap}",
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 25),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: Column(
                        children: [
                          Text("Timer",
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      )),
    );
  }
}
