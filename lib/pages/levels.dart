import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcoin/pages/time_attack.dart';

import '../constants/constants.dart';


class Levels extends StatefulWidget {
  final String userID;
  final String username;
  final bool isLogin;

  const Levels(
      {super.key,
      required this.userID,
      required this.username,
      required this.isLogin});

  @override
  State<Levels> createState() => _LevelsState();
}

class _LevelsState extends State<Levels> {
  final List<int> items = List<int>.generate(100, (int index) => index + 1);
  List<bool> _unlockedLevels = List<bool>.generate(100, (index) => index == 0);

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadUnlockedLevels();
    rewards = generateRewards(100, 1000, 100000);
    requiredPoints = generateRequiredPoints(100, 500, 40000);
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
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
            child: Column(
              children: [
                Text(context.tr('levels'),
                    style: const TextStyle(color: Colors.white, fontSize: 22)),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: _height * 0.8,
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        children: [
                          Container(
                            width: _width,
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: _unlockedLevels[index]
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(
                                      0, 1), // changes position of shadow
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: _unlockedLevels[index]
                                  ? const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                    )
                                  : const Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                    ),
                              title: Text(
                                  "level".tr(args: [items[index].toString()]),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20)),
                              subtitle: Row(
                                children: [
                                  Text(context.tr('reward'),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 15)),
                                  Image.asset(
                                    "assets/images/coin.png",
                                    height: 15,
                                    width: 15,
                                  ),
                                  Text(formatNumber(rewards[index]),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 15)),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                              onTap: _unlockedLevels[index]
                                  ? () {
                                      // Handle level tap
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => TimeAttack(
                                                userID: widget.userID,
                                                username: widget.username,
                                                requiredTaps:
                                                    requiredPoints[index],
                                                index: index,
                                                reward: rewards[index],
                                                isLogin: widget.isLogin),
                                          ));
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
