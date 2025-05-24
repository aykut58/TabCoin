import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tapcoin/pages/auth/sign_up.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../constants/api_service.dart';


class ResetPassNew extends StatefulWidget {
  final String email;

  const ResetPassNew({super.key, required this.email});

  @override
  State<ResetPassNew> createState() => _ResetPassNewState();
}

class _ResetPassNewState extends State<ResetPassNew> {
  final _passWordController = TextEditingController();
  final _passWord2Controller = TextEditingController();

  bool _isLoading = false;
  final _newPassKey = GlobalKey<FormState>();

  bool _passObscure = true;

  void _toggleObscured() {
    setState(() {
      _passObscure = !_passObscure;
      if (textFieldFocusNode.hasPrimaryFocus)
        return; // If focus is on text field, dont unfocus
      textFieldFocusNode.canRequestFocus =
          false; // Prevents focus if tap on eye
    });
  }

  final textFieldFocusNode = FocusNode();

  final HttpService httpService = HttpService();

  Future<void> _newPassRequest() async {
    try {
      final response = await httpService.post('auth/new-password.php', {
        'email': widget.email,
        'password': _passWordController.text,
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
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(
            message: "Password reset successful please login",
          ),
        );

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const SignUp(
                      tapCoin: 0,
                      tapFingers: 2,
                      tapCount: 1,
                      rechargeSpeed: 1,
                      maxEnergy: 1000,
                      botLevel: 0,
                    )),
            (Route<dynamic> route) => false);
      } else {}
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
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Container(
          height: _height,
          width: _width,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 75,
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
                    child: Container(
                      width: _width,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.5)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(30, 60, 30, 30),
                        child: Form(
                            key: _newPassKey,
                            child: Column(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      ('reset_password_page').tr(),
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
                                      ('enter_new_password').tr(),
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
                                  controller: _passWordController,
                                  validator: (val) {
                                    if (val!.isEmpty) {
                                      return context.tr('password_empty');
                                    } else if (val.length < 6) {
                                      return context.tr('invalid_password');
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.visiblePassword,
                                  obscureText: _passObscure,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintStyle: const TextStyle(fontSize: 16),
                                    prefixIcon: const Icon(Icons.password),
                                    suffixIcon: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 0, 4, 0),
                                      child: GestureDetector(
                                        onTap: _toggleObscured,
                                        child: Icon(
                                          _passObscure
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    border: const OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(15)),
                                      borderSide: BorderSide(
                                        width: 0,
                                        style: BorderStyle.none,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: context.tr('enter_password'),
                                    labelText: context.tr('enter_password'),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        10, 20, 10, 20),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                TextFormField(
                                  controller: _passWord2Controller,
                                  validator: (val) {
                                    if (val!.isEmpty) {
                                      return context.tr('password_empty_2');
                                    } else if (_passWordController.text !=
                                        val) {
                                      return context.tr('invalid_password_2');
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.visiblePassword,
                                  obscureText: _passObscure,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintStyle: const TextStyle(fontSize: 16),
                                    prefixIcon: const Icon(Icons.password),
                                    suffixIcon: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 0, 4, 0),
                                      child: GestureDetector(
                                        onTap: _toggleObscured,
                                        child: Icon(
                                          _passObscure
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    border: const OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(15)),
                                      borderSide: BorderSide(
                                        width: 0,
                                        style: BorderStyle.none,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: context.tr('enter_password_2'),
                                    labelText: context.tr('enter_password_2'),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        10, 20, 10, 20),
                                  ),
                                ),
                                const SizedBox(
                                  height: 25,
                                ),
                                SizedBox(
                                  height: 60,
                                  width: _width * 0.8,
                                  child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              if (_newPassKey.currentState!
                                                  .validate()) {
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                _newPassRequest();
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
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : Text(context.tr('submit'),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ))),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                              ],
                            )),
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
