import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../constants/api_service.dart';
import '../../constants/constants.dart';
import '../homepage.dart';


class Login extends StatefulWidget {
  final String emailAddress;
  const Login({super.key, required this.emailAddress});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _isLoading = false;
  bool _passObscure = true;

  final _signInKey = GlobalKey<FormState>();
  final TextEditingController _passWordController = TextEditingController();

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

  Future<void> _sendPostRequest() async {
    try {
      final response = await httpService.post('auth/login.php', {
        'email': widget.emailAddress,
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
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool(IS_LOGIN, true);
        prefs.setString(USER_ID, jsonData["uid"]);
        prefs.setString(USERNAME, jsonData["username"]);
        prefs.setString(EMAIL, jsonData["email"]);
        prefs.setString(TAPS, jsonData["taps"]);
        prefs.setString(TAP_COUNT, jsonData["tap_counts"]);
        prefs.setString(FINGERS, jsonData["fingers"]);
        prefs.setString(MAX_ENERGY, jsonData["max_energy"]);

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
                top: 95,
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
                    filter: ImageFilter.blur(
                      sigmaX: 10.0,
                      sigmaY: 10.0,
                    ),
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
                            key: _signInKey,
                            child: Column(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      context.tr('welcome_back'),
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
                                      context.tr('please_enter_password'),
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
                                  height: 25,
                                ),
                                SizedBox(
                                  height: 60,
                                  width: _width * 0.8,
                                  child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              if (_signInKey.currentState!
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
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : Text(context.tr('sign_in'),
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
