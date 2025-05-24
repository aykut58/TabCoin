import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcoin/pages/leaderboard.dart';
import 'package:tapcoin/pages/profile.dart';
import 'package:tapcoin/pages/store.dart';
import 'package:upgrader/upgrader.dart';

import '../constants/constants.dart';
import 'home.dart';
import 'levels.dart';
import 'on_board.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, required this.initialIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoadingContent = true;

  var _currentIndex = 0;
  late String userID;
  late String username;
  late String fullname;
  late String taps;
  late String email;
  late String fingers;
  late String tap_count;
  late String max_energy;
  late bool isLogin;

  late SharedPreferences prefs;

  void _reloadData() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadData(); // Reload data whenever dependencies change
  }

  getUser() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(USER_ID)) {
      userID = prefs.getString(USER_ID)!;
      username = prefs.getString(USERNAME)!;
      isLogin = prefs.getBool(IS_LOGIN)!;

      setState(() {
        isLoadingContent = false;
      });
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnBoard()),
          (Route<dynamic> route) => false);
    }
  }

  late final List<Widget> _children = [
    Home(
      userID: userID,
      username: username,
      isLogin: isLogin,
    ),
    Levels(
      userID: userID,
      username: username,
      isLogin: isLogin,
    ),
    Store(
      userID: userID,
      username: username,
      isLogin: isLogin,
    ),
    Leaderboard(userID: userID),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    getUser();
    _currentIndex = widget.initialIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;

    Future<bool> _onWillPop() async {
      bool shouldExit = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit?'),
              content: const Text('Do you want to exit the game?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          ) ??
          false;

      return shouldExit;
    }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Theme.of(context)
          .colorScheme
          .secondary, //or set color with: Color(0xFF0000FF)
      statusBarIconBrightness: Brightness.light,
    ));

    return isLoadingContent
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : WillPopScope(
            onWillPop: _onWillPop,
            child: Scaffold(
              body: UpgradeAlert(
                  showIgnore: false,
                  showLater: false,
                  child: _children[_currentIndex]),
              extendBody: true,
              bottomNavigationBar: SalomonBottomBar(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                currentIndex: _currentIndex,
                onTap: onTabTapped,
                items: [
                  /// Home
                  SalomonBottomBarItem(
                    icon: Icon(
                      Icons.circle_outlined,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    title: Text(
                      context.tr('tap'),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.tertiary),
                    ),
                    selectedColor: Theme.of(context).colorScheme.secondary,
                  ),

                  SalomonBottomBarItem(
                    icon: Icon(
                      Icons.timelapse,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    title: Text(context.tr('time_challenge'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary)),
                    selectedColor: Theme.of(context).colorScheme.secondary,
                  ),

                  SalomonBottomBarItem(
                    icon: Icon(
                      Icons.shopping_cart,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    title: Text(context.tr('store'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary)),
                    selectedColor: Theme.of(context).colorScheme.secondary,
                  ),

                  /// Likes
                  SalomonBottomBarItem(
                    icon: Icon(
                      Icons.leaderboard,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    title: Text(context.tr('leaderboard'),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.tertiary)),
                    selectedColor: Theme.of(context).colorScheme.secondary,
                  ),

                  /// Search

                  /// Profile
                ],
              ),
            ),
          );
  }
}
