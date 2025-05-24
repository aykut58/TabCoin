import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:tapcoin/pages/auth/register.dart';
import 'package:tapcoin/pages/auth/reset_pass.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import '../../constants/api_service.dart';
import '../../constants/onboarding_manager.dart';
import 'login.dart';

class SignUp extends StatefulWidget {
  final int tapCoin;
  final int tapFingers;
  final int tapCount;
  final int rechargeSpeed;
  final int maxEnergy;
  final int botLevel;

  const SignUp(
      {super.key,
      required this.tapCoin,
      required this.tapFingers,
      required this.tapCount,
      required this.rechargeSpeed,
      required this.maxEnergy,
      required this.botLevel});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final _signUpKey = GlobalKey<FormState>();

  final HttpService httpService = HttpService();

  Future<void> _sendPostRequest() async {
    try {
      final response = await httpService
          .post('auth/sign-up.php', {'email': _emailController.text});
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
      } else if (jsonData["isUser"]) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Login(
                      emailAddress: _emailController.text,
                    )));
      } else {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Register(
                      emailAddress: _emailController.text,
                      tapCoin: widget.tapCoin,
                      tapFingers: widget.tapFingers,
                      tapCount: widget.tapCount,
                      rechargeSpeed: widget.rechargeSpeed,
                      maxEnergy: widget.maxEnergy,
                      botLevel: widget.botLevel,
                    )));
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

  _onFinishedOnboarding() async {
    await OnboardingManager.setOnboardingShown(true);
  }

  @override
  void initState() {
    // TODO: implement initState
    _onFinishedOnboarding();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        height: _height,
        width: _width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
        ),
        child: SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 20,
                child: Center(
                    child: Container(
                  height: 400,
                  width: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Image.asset("assets/images/login_hand.png"),
                )),
              ),
              Center(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Center(
                      child: Container(
                        width: _width,
                        height: _height,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.5)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(30, 60, 30, 10),
                          child: Form(
                              key: _signUpKey,
                              child: Column(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        context.tr('welcome'),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        context.tr('welcome_please'),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                    ],
                                  ),
                                  TextFormField(
                                    controller: _emailController,
                                    validator: (val) {
                                      if (val!.isEmpty) {
                                        return context.tr('email_empty');
                                      } else if (!EmailValidator.validate(
                                          val)) {
                                        return context.tr('invalid_email');
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(fontSize: 16),
                                    decoration: InputDecoration(
                                      hintStyle: const TextStyle(fontSize: 16),
                                      prefixIcon:
                                          const Icon(Icons.email_outlined),
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(15)),
                                        borderSide: BorderSide(
                                          width: 0,
                                          style: BorderStyle.none,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: context.tr('enter_email'),
                                      labelText: context.tr('enter_email'),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          10, 20, 10, 20),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 40,
                                  ),
                                  SizedBox(
                                    height: 60,
                                    width: _width * 0.8,
                                    child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () async {
                                                if (_signUpKey.currentState!
                                                    .validate()) {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });
                                                  _sendPostRequest();
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          shadowColor: Colors.grey,
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15.0)),
                                          minimumSize:
                                              const Size(100, 40), //////// HERE
                                        ),
                                        child: _isLoading
                                            ? const CircularProgressIndicator()
                                            : Text(context.tr('sign_in'),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ))),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ResetPass()));
                                      },
                                      child: Text(context.tr('forgot_password'),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white)))
                                ],
                              )),
                        ),
                      ),
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
}
