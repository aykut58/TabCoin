import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:tapcoin/pages/auth/reset_pass_otp.dart';

class ResetPass extends StatefulWidget {
  const ResetPass({super.key});

  @override
  State<ResetPass> createState() => _ResetPassState();
}

class _ResetPassState extends State<ResetPass> {
  final _emailController = TextEditingController();
  final _resetPassKey = GlobalKey<FormState>();

  bool _isLoading = false;

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
                            key: _resetPassKey,
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
                                      context.tr('enter_email_reset'),
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
                                    } else if (!EmailValidator.validate(val)) {
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
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(15)),
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
                                    contentPadding:
                                        EdgeInsets.fromLTRB(10, 20, 10, 20),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                  height: 60,
                                  width: _width * 0.8,
                                  child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              if (_resetPassKey.currentState!
                                                  .validate()) {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            ResetPassOtp(
                                                                email:
                                                                    _emailController
                                                                        .text)));
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
                                          : Text(context.tr('reset_password'),
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
