import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../constants/api_service.dart';
import '../constants/constants.dart';
import '../constants/onboarding_manager.dart';
import 'auth/sign_up.dart';
import 'homepage.dart';


class OnBoard extends StatefulWidget {
  const OnBoard({super.key});

  @override
  State<OnBoard> createState() => _OnBoardState();
}

class _OnBoardState extends State<OnBoard> {
  bool _isLoading = false;

  final Color kDarkBlueColor = const Color(0xFF053149);

  _onFinishedOnboarding() async {
    await OnboardingManager.setOnboardingShown(true);
  }

  final HttpService httpService = HttpService();

  Future<void> _guestSignUp() async {
    try {
      final response = await httpService.post('auth/guest-sign-up.php', {
        'guest_signup': '',
      });
      var jsonData = response;
      setState(() {
        _isLoading = false;
      });
      if (jsonData["error"]) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: jsonData["message"],
          ),
        );
      } else if (jsonData["success"]) {
        _onFinishedOnboarding();

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool(IS_LOGIN, false);
        prefs.setString(USER_ID, jsonData["uid"]);
        prefs.setString(USERNAME, jsonData["username"]);
        prefs.setString(TAPS, jsonData["taps"]);
        prefs.setString(TAP_COUNT, jsonData["tap_counts"]);
        prefs.setString(TAP_ENERGY, jsonData["energy"]);
        prefs.setString(FINGERS, jsonData["fingers"]);
        prefs.setString(MAX_ENERGY, jsonData["max_energy"]);
        prefs.setString(RECHARGING_SPEED, jsonData["boost_count"]);
        prefs.setString(BOT_LEVEL, jsonData["bot_level"]);

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const HomePage(
                      initialIndex: 0,
                    )),
            (Route<dynamic> route) => false);
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
        _isLoading = false;
      });
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: error.toString(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;
    return _isLoading
        ? Scaffold(
            body: Container(
              height: _height,
              width: _width,
              color: Theme.of(context).colorScheme.secondary,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          )
        : OnBoardingSlider(
            finishButtonText: 'Play',
            onFinish: () {
              setState(() {
                _isLoading = true;
              });
              _guestSignUp();
            },
            finishButtonStyle: FinishButtonStyle(
              backgroundColor: kDarkBlueColor,
            ),
            skipTextButton: Text(
              'Skip',
              style: TextStyle(
                fontSize: 16,
                color: kDarkBlueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Text(
              'Login',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailingFunction: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const SignUp(
                    tapCoin: 0,
                    tapFingers: 2,
                    tapCount: 1,
                    rechargeSpeed: 1,
                    maxEnergy: 1000,
                    botLevel: 0,
                  ),
                ),
              );
            },
            controllerColor: kDarkBlueColor,
            totalPage: 3,
            headerBackgroundColor: Colors.black,
            pageBackgroundColor: Colors.black,
            background: [
              Image.asset(
                'assets/images/tap-device.png',
                height: 300,
              ),
              Image.asset(
                'assets/images/coin.png',
                height: 300,
              ),
              Image.asset(
                'assets/images/trophy-8.png',
                height: 300,
              ),
            ],
            centerBackground: true,
            speed: 1.8,
            pageBodies: [
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      height: 380,
                    ),
                    Text(
                      context.tr('onboard_1'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    /*Text(
                context.tr('onboard_2'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black26,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),*/
                  ],
                ),
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      height: 380,
                    ),
                    Text(
                      context.tr('onboard_2'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    /*const Text(
                'Sliding with animation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black26,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),*/
                  ],
                ),
              ),
              Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      height: 380,
                    ),
                    Text(
                      context.tr('onboard_3'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    /*const Text(
                'Where everything is possible and customize your onboarding.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black26,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),*/
                  ],
                ),
              ),
            ],
          );
  }
}
