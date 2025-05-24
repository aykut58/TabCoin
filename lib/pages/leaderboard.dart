import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../constants/api_service.dart';
import '../constants/constants.dart';


class Leaderboard extends StatefulWidget {
  final String userID;
  const Leaderboard({super.key, required this.userID});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard>
    with SingleTickerProviderStateMixin {
  bool _isLoadingTaps = true;
  bool _isLoadingTapsDaily = true;
  bool _isLoadingTapsWeekly = true;

  int page = 1;

  int totalPage = 0;

  var jsonData;

  bool _isLoading = false;

  List<String> name = [];
  List<String> coin = [];


  final HttpService httpService = HttpService();

  Future<void> _fetchBoard() async {
    try {
      final response = await httpService.post('user/leaderboard.php', {
        'userID': widget.userID,
        'page': page.toString(),
      });
      jsonData = response;
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
        for (int i = 0; i < jsonData['data'].length; i++) {
          name.add(jsonData['data'][i]['username']);
          coin.add(jsonData['data'][i]['taps']);
        }

        totalPage = jsonData["pages"];
      } else {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "Unknown error",
          ),
        );
      }
    } catch (error) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: error.toString(),
        ),
      );
    }
  }


  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    _fetchBoard();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        if (page != totalPage) {
          page += 1;
          _fetchBoard();
          setState(() {
            _isLoading = true;
          });
        } else {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.info(
              message: "no_more_item".tr(),
            ),
          );
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    super.dispose();
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
        child: Column(
          children: [
            Text(context.tr('leaderboard'),
                style: const TextStyle(color: Colors.white, fontSize: 22)),
            Expanded( // Use Expanded to fill the remaining space
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
                child: _isLoadingTaps
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                    controller: _scrollController,
                    itemCount: name.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == name.length) {
                        return _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : const SizedBox.shrink();
                      }

                      Color itemColor;
                      if (index == 0) {
                        itemColor = Color(0xffCD7F32); // Color for the first item
                      } else if (index == 1) {
                        itemColor = Colors.blue; // Color for the second item
                      } else if (index == 2) {
                        itemColor = Colors.green; // Color for the third item
                      } else {
                        itemColor = Theme.of(context).primaryColor; // Default color for other items
                      }

                      return Column(
                        children: [
                          Container(
                            height: 70,
                            width: _width,
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: itemColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 1), // changes position of shadow
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text("${index + 1}",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                const SizedBox(width: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      backgroundImage: AssetImage("assets/images/people.png"),
                                    ),
                                    const SizedBox(width: 20),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(truncateWithEllipsis(10, name[index]),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                        getLevelName(int.parse(coin[index]))
                                      ],
                                    ),
                                    const SizedBox(width: 20),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                    formatNumberLeaderboard(int.parse(coin[index])),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),
              ),
            )
          ],
        ),
      ),
    );
  }


  String truncateWithEllipsis(int cutoff, String myString) {
    return (myString.length <= cutoff) ? myString : '${myString.substring(0, cutoff)}...';
  }
}
