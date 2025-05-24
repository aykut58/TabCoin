import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otp_timer_button/otp_timer_button.dart';
import 'package:pinput/pinput.dart';
import 'package:tapcoin/pages/auth/reset_pass_new.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../../constants/api_service.dart';


class ResetPassOtp extends StatefulWidget {
  final String email;
  const ResetPassOtp({super.key, required this.email});

  @override
  State<ResetPassOtp> createState() => _ResetPassOtpState();
}

class _ResetPassOtpState extends State<ResetPassOtp> {
  bool _isLoading = false;
  final HttpService httpService = HttpService();

  Future<void> _sendPostRequest() async {
    try {
      final response = await httpService
          .post('auth/reset-password.php', {'email': widget.email});
      var jsonData = response;
      print(response);
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
        String email = jsonData["email"];

        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.info(message: "otp_sent".tr(args: [email])),
        );
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
  void initState() {
    // TODO: implement initState
    _sendPostRequest();
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
        color: Theme.of(context).colorScheme.secondary,
        child: SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 100,
                ),
                Text(context.tr('enter_otp'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Pinput(
                          validator: (s) {
                            return null;
                          },
                          pinputAutovalidateMode:
                              PinputAutovalidateMode.onSubmit,
                          showCursor: true,
                          length: 6,
                          onCompleted: (pin) async {
                            verifyOTP(pin, widget.email);

                            setState(() {
                              _isLoading = true;
                            });
                          },
                        ),
                ),
                const SizedBox(
                  height: 35,
                ),
                Text(context.tr('did_not_receive_otp'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(
                  height: 15,
                ),
                OtpTimerButton(
                  onPressed: () async {
                    _sendPostRequest();
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  text: Text(context.tr('resend_otp'),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  duration: 60,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> verifyOTP(String pin, String email) async {
    try {
      final response = await httpService.post('auth/verify-otp.php', {
        'email': email,
        'otp': pin,
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
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ResetPassNew(email: widget.email)));
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
}
