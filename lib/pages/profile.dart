import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_service.dart';
import '../constants/constants.dart';
import 'auth/sign_up.dart';
import 'homepage.dart';

class Profile extends StatefulWidget {
  final String username;
  final String userID;
  final bool isLogin;

  const Profile(
      {super.key,
      required this.username,
      required this.userID,
      required this.isLogin});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _isLoadingTaps = true;
  String tapBalance = "";
  int tapFingers = 0;
  int tapCount = 0;
  int rechargeSpeed = 0;
  int maxTapEnergy = 0;
  int botLevel = 0;
  String refLink = "";
  late Locale _selectedLocale;
  bool isSettingsLoading = true;
  var settingsJson;

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
            tapBalance = jsonData["taps"];
            refLink = widget.userID;
            tapCount = int.parse(jsonData["tap_counts"]);
            tapFingers = int.parse(jsonData["fingers"]);
            rechargeSpeed = int.parse(jsonData["boost_count"]);
          });
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
        tapBalance = prefs.getString(TAPS)!;
        tapCount = int.parse(prefs.getString(TAP_COUNT)!);
        tapFingers = int.parse(prefs.getString(FINGERS)!);
        rechargeSpeed = int.parse(prefs.getString(RECHARGING_SPEED)!);
        maxTapEnergy = int.parse(prefs.getString(MAX_ENERGY)!);
        botLevel = int.parse(prefs.getString(BOT_LEVEL)!);
      });
      setState(() {
        _isLoadingTaps = false;
      });
    }
  }

  Future<void> _fetchSettings() async {
    try {
      final response = await httpService
          .post('user/fetch-settings.php', {'userID': widget.userID});

      if (response["status"]=="success") {
        settingsJson = response;
        print(settingsJson);
        setState(() {
          isSettingsLoading = false;
        });
      } else if (response['status']=="error") {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: response["message"],
          ),
        );
      }


      /*boosts = (response['boosts'] as List)
          .map((boost) => Boost.fromJson(boost))
          .toList();*/

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
  }

  Future<void> _deleteAccount(String userID) async {
    try {
      final response =
          await httpService.post('auth/delete-account.php', {'userID': userID});
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
        SharedPreferences prefs = await SharedPreferences.getInstance();
        setState(() {
          prefs.setBool(IS_LOGIN, false);
          prefs.clear();
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const HomePage(initialIndex: 0)),
              (r) => false);
        });
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(
            message: jsonData["message"],
          ),
        );
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
  }

  _loadSelectedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String localeCode = prefs.getString('selected_language') ?? 'en';
    setState(() {
      _selectedLocale = Locale(localeCode);
    });
  }

  _saveSelectedLanguage(String localeCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', localeCode);
    context.setLocale(Locale(localeCode));
  }

  @override
  void initState() {
    // TODO: implement initState
    _fetchTaps();
    _loadSelectedLanguage();
    _fetchSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;
    _selectedLocale = context.locale;

    return Scaffold(
      body: Container(
        height: _height,
        width: _width,
        color: Theme.of(context).colorScheme.secondary,
        child: SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 50, 30, 80),
            child: isSettingsLoading? const CircularProgressIndicator() : Column(
              children: [
                _isLoadingTaps
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          CircleAvatar(
                            backgroundImage: widget.isLogin
                                ? const AssetImage("assets/images/people.png")
                                : const AssetImage("assets/images/unknown.png"),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Text(widget.username,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 25)),
                          const SizedBox(
                            height: 10,
                          ),
                          getLevelName(int.parse(tapBalance)),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/coin.png",
                                height: 20,
                                width: 20,
                              ),
                              Text(formatNumber(int.parse(tapBalance)),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20)),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          widget.isLogin
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(context.tr('referral_code'),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                    const SizedBox(
                                      width: 15,
                                    ),
                                    Text(refLink,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                    IconButton(
                                        onPressed: () async {
                                          await Clipboard.setData(
                                              ClipboardData(text: refLink));
                                        },
                                        icon: const Icon(Icons.copy))
                                  ],
                                )
                              : const SizedBox(),
                          widget.isLogin
                              ? Text('refer_details'.tr(args: [settingsJson['settings']['referral_coin']]),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15))
                              : const SizedBox(),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(context.tr('language'),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15)),
                              const SizedBox(
                                width: 15,
                              ),
                              DropdownButton<Locale>(
                                value: _selectedLocale,
                                onChanged: (Locale? newLocale) {
                                  setState(() {
                                    _selectedLocale = newLocale!;
                                  });
                                  _saveSelectedLanguage(
                                      newLocale!.languageCode);
                                },
                                dropdownColor: Colors.blueGrey,
                                items: const [
                                  DropdownMenuItem(
                                    value: Locale('en'),
                                    child: Text('English',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                  ),
                                  DropdownMenuItem(
                                    value: Locale('fr'),
                                    child: Text('Français',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                  ),
                                  DropdownMenuItem(
                                    value: Locale('de'),
                                    child: Text('Deutsch',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                  ),
                                  DropdownMenuItem(
                                    value: Locale('hi'),
                                    child: Text('हिन्दी',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                  ),
                                  DropdownMenuItem(
                                    value: Locale('pt'),
                                    child: Text('Português',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                  ),
                                  DropdownMenuItem(
                                    value: Locale('ar'),
                                    child: Text('العربية',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                  ),
                                  DropdownMenuItem(
                                    value: Locale('es'),
                                    child: Text('Español',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                  ),
                                  DropdownMenuItem(
                                    value: Locale('vi'),
                                    child: Text('Tiếng Việt.',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                  ),
                                  DropdownMenuItem(
                                    value: Locale('th'),
                                    child: Text('ภาษาไทย',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                  ),
                                  DropdownMenuItem(
                                    value: Locale('tl'),
                                    child: Text('Filipino ',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 15)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          widget.isLogin
                              ? Column(
                                  children: [
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors
                                              .white, // foreground (text) color
                                          backgroundColor:
                                              Colors.red, // background color
                                        ),
                                        onPressed: () async {
                                          showDialog(
                                              builder: (ctxt) {
                                                return AlertDialog(
                                                    title: Text(
                                                        "delete_account_confirm"
                                                            .tr()),
                                                    content: SizedBox(
                                                      height: 150,
                                                      child: Center(
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                                "delete_account_confirm2"
                                                                    .tr()),
                                                            const SizedBox(
                                                              height: 20,
                                                            ),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceAround,
                                                              children: [
                                                                ElevatedButton(
                                                                  child: Text(
                                                                      "cancel"
                                                                          .tr()),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                ),
                                                                ElevatedButton(
                                                                  child: Text(
                                                                      "confirm"
                                                                          .tr()),
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      _isLoadingTaps =
                                                                          true;
                                                                    });
                                                                    Navigator.pop(
                                                                        context);

                                                                    _deleteAccount(
                                                                        widget
                                                                            .userID);
                                                                  },
                                                                )
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ));
                                              },
                                              context: context);
                                        },
                                        child: Text(
                                            context.tr('delete_my_account'),
                                            style:
                                                const TextStyle(fontSize: 15))),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors
                                              .white, // foreground (text) color
                                          backgroundColor: Theme.of(context)
                                              .primaryColor, // background color
                                        ),
                                        onPressed: () async {
                                          SharedPreferences prefs =
                                              await SharedPreferences
                                                  .getInstance();
                                          setState(() {
                                            prefs.setBool(IS_LOGIN, false);
                                            prefs.clear();
                                            Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const HomePage(
                                                            initialIndex: 0)),
                                                (r) => false);
                                          });
                                        },
                                        child: Text(context.tr('logout'),
                                            style:
                                                const TextStyle(fontSize: 20))),
                                  ],
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor:
                                        Colors.white, // foreground (text) color
                                    backgroundColor: Theme.of(context)
                                        .primaryColor, // background color
                                  ),
                                  onPressed: () async {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => SignUp(
                                                tapCoin: int.parse(tapBalance),
                                                tapFingers: tapFingers,
                                                tapCount: tapCount,
                                                rechargeSpeed: rechargeSpeed,
                                                maxEnergy: maxTapEnergy,
                                                botLevel: botLevel,
                                              )),
                                    );
                                  },
                                  child: Text(context.tr('sign_in'),
                                      style: const TextStyle(fontSize: 20))),
                          const SizedBox(
                            height: 50,
                          ),
                          InkWell(
                              onTap: isSettingsLoading ? null : () {
                                launchUrl(Uri.parse(settingsJson['settings']['website']));
                              },
                              child: Text(settingsJson['settings']['website'],
                                style: TextStyle(color: Colors.white),
                              )),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                  onTap: isSettingsLoading ? null : () {
                                    launchUrl(Uri.parse(settingsJson['settings']['telegram_link']));
                                  },
                                  child: Image.asset(
                                    "assets/images/telegram.png",
                                    width: 30,
                                    height: 30,
                                  )),
                              const SizedBox(
                                width: 20,
                              ),
                              InkWell(
                                  onTap: isSettingsLoading ? null : () {
                                    launchUrl(Uri.parse(settingsJson['settings']['x_link']));
                                  },
                                  child: Image.asset(
                                    "assets/images/twitter.png",
                                    width: 30,
                                    height: 30,
                                  )),
                              const SizedBox(
                                width: 20,
                              ),
                              InkWell(
                                  onTap: isSettingsLoading ? null : () {
                                    launchUrl(Uri.parse(
                                        settingsJson['settings']['youtube_link']));
                                  },
                                  child: Image.asset(
                                    "assets/images/youtube.png",
                                    width: 30,
                                    height: 30,
                                  )),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          InkWell(
                              onTap: isSettingsLoading ? null : () {
                                launchUrl(Uri.parse(
                                    settingsJson['settings']['privacy_policy']));
                              },
                              child: const Text("Privacy Policy"))
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
