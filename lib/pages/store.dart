import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:once/once.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapcoin/pages/tap_frenzy.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/api_service.dart';
import '../constants/constants.dart';
import '../constants/points_service.dart';


class Store extends StatefulWidget {
  final String userID;
  final String username;
  final bool isLogin;

  const Store(
      {super.key,
      required this.userID,
      required this.username,
      required this.isLogin});

  @override
  State<Store> createState() => _StoreState();
}

class _StoreState extends State<Store> with SingleTickerProviderStateMixin {
  int tapCount = 0;
  int tapFingers = 0;
  int maxEnergy = 0;
  int tapBalance = 0;
  int boostCount = 0;
  int botLevel = 0;
  bool _isLoadingTaps = true;

  String isCollectTelegram = "iscollecttelegram";
  String isCollectTwitter = "iscollecttwitter";
  late TabController _tabController;

  int _countdown = 240; // 60 seconds
  int _countdown24 = 86400; // 60 seconds
  int _countdownShare24 = 86400; // 60 seconds
  Timer? _timer;
  Timer? _timer24;
  bool _isButtonEnabled = true;
  bool _isButtonEnabled24 = true;
  bool _isShareButtonEnabled24 = true;

  Timer? timerDaily;

  bool isLoadingTask = true;
  bool isShareLoadingTask = true;
  bool isStoreItem = true;
  bool isSettingsLoading = true;

  List<String> title = [];
  List<String> description = [];
  List<String> url = [];
  List<String> reward = [];
  List<String> icon = [];
  List<String> id = [];
  List<String> savedItems = [];
  List<String> questions = [];
  List<String> answers = [];

  List<String> titleDaily = [];
  List<String> descriptionDaily = [];
  List<String> urlDaily = [];
  List<String> rewardDaily = [];
  List<String> iconDaily = [];
  List<String> idDaily = [];
  List<String> savedItemsDaily = [];
  List<String> questionsDaily = [];
  List<String> answersDaily = [];

  List<Duration> itemRemainingTimes = [];


  // List<Boost> boosts = [];
  var storeItems;
  var settingsJson;

  RewardedAd? _rewardedAd;
  int _numRewardedLoadAttempts = 0;

  final HttpService httpService = HttpService();

  final PointsService pointsService = PointsService();

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
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString(TAP_COUNT, jsonData["tap_counts"]);
          prefs.setString(FINGERS, jsonData["fingers"]);
          prefs.setString(MAX_ENERGY, jsonData["max_energy"]);
          prefs.setString(TAPS, jsonData["taps"]);

          setState(() {
            tapBalance = int.parse(jsonData["taps"]);
            tapCount = int.parse(jsonData["tap_counts"]);
            tapFingers = int.parse(jsonData["fingers"]);
            maxEnergy = int.parse(jsonData["max_energy"]);
            boostCount = int.parse(jsonData["boost_count"]);
          });
          botLevel = int.parse(jsonData["bot_level"]);
        } else {
          showTopSnackBar(
            Overlay.of(context),
            const CustomSnackBar.error(
              message: "Unknown error",
            ),
          );
        }
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
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        tapBalance = int.parse(prefs.getString(TAPS)!);
        tapCount = int.parse(prefs.getString(TAP_COUNT)!);
        tapFingers = int.parse(prefs.getString(FINGERS)!);
        maxEnergy = int.parse(prefs.getString(MAX_ENERGY)!);
        boostCount = int.parse(prefs.getString(RECHARGING_SPEED)!);
        botLevel = int.parse(prefs.getString(BOT_LEVEL)!);
      });

      setState(() {
        _isLoadingTaps = false;
      });
    }
  }

  Future<void> _fetchTask() async {
    try {
      final response = await httpService
          .post('user/fetch-task.php', {'userID': widget.userID});
      var taskItems = response;

      setState(() {
        isLoadingTask = false;
      });

      if (taskItems["error"]) {
        print(taskItems["message"]);
      } else if (taskItems["success"]) {
        for (int i = 0; i < taskItems['data'].length; i++) {
          title.add(taskItems['data'][i]['title']);
          description.add(taskItems['data'][i]['description']);
          url.add(taskItems['data'][i]['url']);
          icon.add(taskItems['data'][i]['icon']);
          reward.add(taskItems['data'][i]['coin_reward']);
          id.add(taskItems['data'][i]['id']);
          questions.add(taskItems['data'][i]['question']);
          answers.add(taskItems['data'][i]['answer']);
        }
      } else {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "Unknown error",
          ),
        );
      }
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

  Future<void> _fetchStore() async {
    try {
      final response = await httpService
          .post('user/fetch-store.php', {'userID': widget.userID});

      if (response["status"]=="success") {
        storeItems = response;
        print(storeItems);
        setState(() {
          isStoreItem = false;
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

  Future<void> _fetchDailyTask() async {
    try {
      final response = await httpService
          .post('user/fetch-task-daily.php', {'userID': widget.userID});
      var taskItems = response;

      setState(() {
        isShareLoadingTask = false;
      });

      if (taskItems["error"]) {
        print(taskItems["message"]);
      } else if (taskItems["success"]) {
        for (int i = 0; i < taskItems['data'].length; i++) {
          titleDaily.add(taskItems['data'][i]['title']);
          descriptionDaily.add(taskItems['data'][i]['description']);
          urlDaily.add(taskItems['data'][i]['url']);
          iconDaily.add(taskItems['data'][i]['icon']);
          rewardDaily.add(taskItems['data'][i]['coin_reward']);
          idDaily.add(taskItems['data'][i]['id']);
          questionsDaily.add(taskItems['data'][i]['question']);
          answersDaily.add(taskItems['data'][i]['answer']);
        }
      } else {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.error(
            message: "Unknown error",
          ),
        );
      }
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

  Future<void> shareNetworkImage(
      String imageUrl, String text, int reward) async {
    final http.Response response = await http.get(Uri.parse(imageUrl));
    final Directory directory = await getTemporaryDirectory();
    final File file = await File('${directory.path}/Image.jpg')
        .writeAsBytes(response.bodyBytes);
    await Share.shareXFiles(
      [
        XFile(file.path),
      ],
      subject: "Join MiniTaps",
      text: text,
    );
    // _showShareDialog(context, reward);
  }

  Future<void> _addTapCounts() async {
    if (tapCount < storeItems['boosts'][0]['levels'].length) {
      setState(() {
        _isLoadingTaps = true;
      });
      _removePoints(widget.userID, storeItems['boosts'][0]['levels'][tapCount]['required_points']);
      if (widget.isLogin) {
        try {
          final response = await httpService.post('user/add-taps.php', {
            'userID': widget.userID,
          });
          var jsonData = response;
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
              CustomSnackBar.success(message: context.tr('purchase_success')),
            );

            _fetchTaps();
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
        int mytapCount = int.parse(prefs.getString(TAP_COUNT)!);
        mytapCount = mytapCount + 1;
        prefs.setString(TAP_COUNT, mytapCount.toString());
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: context.tr('purchase_success')),
        );

        _fetchTaps();
      }
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: context.tr('max_reached')),
      );
    }
  }

  Future<void> _addFingersCounts() async {
    if (tapFingers < storeItems['boosts'][1]['levels'].length) {
      setState(() {
        _isLoadingTaps = true;
      });
      _removePoints(widget.userID, storeItems['boosts'][1]['levels'][tapFingers]['required_points']);

      if (widget.isLogin) {
        try {
          final response = await httpService
              .post('user/add-finger.php', {'userID': widget.userID});
          var jsonData = response;
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
              CustomSnackBar.success(message: context.tr('purchase_success')),
            );

            _fetchTaps();
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
        int myFingerCount = int.parse(prefs.getString(FINGERS)!);
        myFingerCount = myFingerCount + 1;
        prefs.setString(FINGERS, myFingerCount.toString());
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: context.tr('purchase_success')),
        );

        _fetchTaps();
      }
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: context.tr('max_reached')),
      );
    }
  }

  Future<void> _addBoostCounts() async {
    if (boostCount < storeItems['boosts'][2]['levels'].length) {
      setState(() {
        _isLoadingTaps = true;
      });
      _removePoints(widget.userID, storeItems['boosts'][2]['levels'][boostCount]['required_points']);
      if (widget.isLogin) {
        try {
          final response = await httpService
              .post('user/add-boost.php', {'userID': widget.userID});
          var jsonData = response;
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
              CustomSnackBar.success(message: context.tr('purchase_success')),
            );

            _fetchTaps();
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
        int mytapCount = int.parse(prefs.getString(RECHARGING_SPEED)!);
        mytapCount = mytapCount + 1;
        prefs.setString(RECHARGING_SPEED, mytapCount.toString());
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: context.tr('purchase_success')),
        );

        _fetchTaps();
      }
    } else {
      setState(() {
        _isLoadingTaps = false;
      });
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: context.tr('max_reached'),
        ),
      );
    }
  }

  Future<void> _addMaxEnergy() async {
    if (maxEnergy < storeItems['boosts'][3]['levels'][storeItems['boosts'][3]['levels'].length-1]['level']) {
      setState(() {
        _isLoadingTaps = true;
      });
      _removePoints(widget.userID, storeItems['boosts'][3]['levels'][getMaxEnergyLevel(maxEnergy)]['required_points']);
      if (widget.isLogin) {
        try {
          final response = await httpService
              .post('user/add-max-energy.php', {'userID': widget.userID});
          var jsonData = response;
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
              CustomSnackBar.success(message: context.tr('purchase_success')),
            );

            _fetchTaps();
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
        int mytapCount = int.parse(prefs.getString(MAX_ENERGY)!);
        mytapCount = mytapCount + 500;
        prefs.setString(MAX_ENERGY, mytapCount.toString());
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: context.tr('purchase_success')),
        );

        _fetchTaps();
      }
    } else {
      setState(() {
        _isLoadingTaps = false;
      });
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: context.tr('max_reached'),
        ),
      );
    }
  }

  Future<void> _addTappingBot() async {
    if (botLevel < storeItems['boosts'][4]['levels'].length+1) {
      setState(() {
        _isLoadingTaps = true;
      });
      _removePoints(widget.userID, storeItems['boosts'][4]['levels'][botLevel]['required_points']);
      if (widget.isLogin) {
        try {
          final response = await httpService
              .post('user/add-tap-bot.php', {'userID': widget.userID});
          var jsonData = response;
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
              CustomSnackBar.success(message: context.tr('purchase_success')),
            );

            _fetchTaps();
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
        int mytapCount = int.parse(prefs.getString(BOT_LEVEL)!);
        mytapCount = mytapCount + 1;
        prefs.setString(BOT_LEVEL, mytapCount.toString());
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(message: context.tr('purchase_success')),
        );

        _fetchTaps();
      }
    } else {
      setState(() {
        _isLoadingTaps = false;
      });
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: context.tr('max_reached'),
        ),
      );
    }
  }

  void _addPoints(String userID, int amount) {
    pointsService.addPoints(userID, amount, widget.isLogin).then((_) {
      print('Points added successfully');
      _fetchTaps();
    }).catchError((error) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: error.toString(),
        ),
      );
    });
  }

  void _removePoints(String userID, int amount) {
    pointsService.subtractPoints(userID, amount, widget.isLogin).then((_) {
      print('Points added successfully');
    }).catchError((error) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: error.toString(),
        ),
      );
    });
  }

  void _loadTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? startTime = prefs.getInt('start_time');
    int? duration = prefs.getInt('duration');

    if (startTime != null && duration != null) {
      int elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
      int remaining = duration - (elapsed ~/ 1000);
      if (remaining > 0) {
        setState(() {
          _countdown = remaining;
          _isButtonEnabled = false;
        });
        _startTimer();
      } else {
        setState(() {
          _isButtonEnabled = true;
        });
      }
    }
  }

  void _startTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('start_time', DateTime.now().millisecondsSinceEpoch);
    prefs.setInt('duration', _countdown);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _createRewardedAd();
        setState(() {
          _isButtonEnabled = true;
        });
        _timer?.cancel();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _countdown = 240;
      _isButtonEnabled = false;
    });
    _startTimer();
  }

  void _loadTimer24() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? startTime = prefs.getInt('start_time24');
    int? duration = prefs.getInt('duration24');
    if (startTime != null && duration != null) {
      int elapsed = DateTime.now().millisecondsSinceEpoch - startTime;
      int remaining = duration - (elapsed ~/ 1000);
      if (remaining > 0) {
        setState(() {
          _countdown24 = remaining;
          _isButtonEnabled24 = false;
        });
        _startTimer24();
      } else {
        setState(() {
          _isButtonEnabled24 = true;
        });
      }
    }
  }

  void _startTimer24() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('start_time24', DateTime.now().millisecondsSinceEpoch);
    prefs.setInt('duration24', _countdown24);

    _timer24 = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown24 > 0) {
        setState(() {
          _countdown24--;
        });
      } else {
        setState(() {
          _isButtonEnabled24 = true;
        });
        _timer24?.cancel();
      }
    });
  }

  void _resetTimer24() {
    setState(() {
      _countdown24 = 86400;
      _isButtonEnabled24 = false;
    });
    _startTimer24();
  }


  @override
  void dispose() {
    _timer?.cancel();
    _timer24?.cancel();
    _tabController.dispose();
    _rewardedAd?.dispose();
    timerDaily?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    _tabController = TabController(length: 2, vsync: this);
    _fetchTaps();
    _fetchTask();
    _fetchStore();
    _fetchSettings();
    _fetchDailyTask();
    _loadTimer();
    _loadTimer24();
    _loadSavedItems();
    _loadSavedItemsDaily();
    _createRewardedAd();
    Once.runWeekly(
      "ratingDialog",
      callback: () async {
        final InAppReview inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          inAppReview.requestReview();
        }
      },
      fallback: () {
        /* Thanks */
      },
    );
    super.initState();
  }

  Future<void> _loadSavedItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> loadedItems = prefs.getStringList('saved_items') ?? [];
    setState(() {
      savedItems = loadedItems;
    });
  }

  Future<void> _saveItem(String item) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!savedItems.contains(item)) {
      setState(() {
        savedItems.add(item);
      });
      await prefs.setStringList('saved_items', savedItems);
    }
  }

// Load saved daily items and their remaining times from SharedPreferences
  Future<void> _loadSavedItemsDaily() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load the saved items and timestamps map
    Map<String, String> savedItemsWithTimestamps = Map<String, String>.from(
        prefs.getString('saved_items_daily_with_timestamps') != null
            ? jsonDecode(prefs.getString('saved_items_daily_with_timestamps')!)
            : {}
    );

    // Clear existing lists to avoid duplication
    savedItemsDaily.clear();
    itemRemainingTimes.clear();

    // Iterate through the saved items and filter expired ones
    savedItemsWithTimestamps.forEach((itemID, expirationTimestamp) {
      DateTime expirationTime = DateTime.parse(expirationTimestamp);
      Duration timeLeft = expirationTime.difference(DateTime.now());

      if (timeLeft.inSeconds > 0) {
        savedItemsDaily.add(itemID);
        itemRemainingTimes.add(timeLeft);
      }
    });

    // Update the UI with the remaining items and their times
    setState(() {});

    // Start the countdown timer for each item
    _startTimerDaily();
  }


// Save an item and set a 24-hour expiration time
  Future<void> _saveItemDaily(String itemID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load existing map of IDs and timestamps (initialize an empty map if none exist)
    Map<String, String> savedItemsWithTimestamps = Map<String, String>.from(
        prefs.getString('saved_items_daily_with_timestamps') != null
            ? jsonDecode(prefs.getString('saved_items_daily_with_timestamps')!)
            : {}
    );

    // Add the new item with its expiration time (if it's not already saved)
    if (!savedItemsWithTimestamps.containsKey(itemID)) {
      DateTime expirationTime = DateTime.now().add(Duration(hours: 24));

      // Add the item and its corresponding expiration time to the map
      savedItemsWithTimestamps[itemID] = expirationTime.toIso8601String();

      // Save the updated map back to SharedPreferences
      await prefs.setString(
        'saved_items_daily_with_timestamps',
        jsonEncode(savedItemsWithTimestamps),
      );

      // Reload items to ensure state is updated
      _loadSavedItemsDaily();
    }
  }


  void _startTimerDaily() {
    timerDaily = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        for (int i = 0; i < itemRemainingTimes.length; i++) {
          // Decrease remaining time by one second
          itemRemainingTimes[i] = itemRemainingTimes[i] - const Duration(seconds: 1);

          // Remove the item if the time has expired
          if (itemRemainingTimes[i].inSeconds <= 0) {
            savedItemsDaily.removeAt(i);
            itemRemainingTimes.removeAt(i);
            i--; // Adjust the index after removing an item
          }
        }
      });
    });
  }



  void _createRewardedAd() {
    RewardedAd.load(
        adUnitId: Platform.isAndroid
            ? ADMOB_REWARD_BONUS_UNIT_ANDROID
            : ADMOB_REWARD_BONUS_UNIT_IOS,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$ad loaded.');
            _rewardedAd = ad;
            _numRewardedLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedAd failed to load: $error');
            _rewardedAd = null;
            _numRewardedLoadAttempts += 1;
            if (_numRewardedLoadAttempts < 3) {
              _createRewardedAd();
            }
          },
        ));
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) {
      print('Warning: attempt to show rewarded before loaded.');
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedAd();
      },
    );
    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      _resetTimer();
      _addPoints(widget.userID, int.parse(settingsJson['settings']['reward_ads']));
      print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
    });
    _rewardedAd = null;
  }

  @override
  Widget build(BuildContext context) {
    double _height = MediaQuery.of(context).size.height;
    double _width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.secondary,
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 30,
            ),
            ButtonsTabBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              unselectedBackgroundColor: Colors.white,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              borderWidth: 1,
              unselectedBorderColor: Theme.of(context).colorScheme.primary,
              radius: 50,
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.local_grocery_store_outlined),
                  text: "store".tr(),
                ),
                Tab(
                  icon: const Icon(Icons.task_rounded),
                  text: "tasks".tr(),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  Container(
                    height: _height,
                    width: _width,
                    color: Theme.of(context).colorScheme.secondary,
                    child: SingleChildScrollView(
                      physics: const ScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(30, 40, 30, 10),
                        child: _isLoadingTaps
                            ? const Center(child: CircularProgressIndicator())
                            : isStoreItem ? const Center(child: CircularProgressIndicator()) : Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        "assets/images/coin.png",
                                        height: 20,
                                        width: 20,
                                      ),
                                      Text(formatNumber(tapBalance),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20)),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  BuyItemWidget(
                                    title: "coin_per_tap".tr(),
                                    amount:  tapCount >= storeItems['boosts'][0]['levels'].length ? "max_reached".tr() : formatNumber(
                                        storeItems['boosts'][0]['levels'][tapCount]['required_points'])
                                        .toString(),
                                    assetImage: 'assets/images/tap-one.png',
                                    onTap: tapCount >= storeItems['boosts'][0]['levels'].length ? null : () {
                                      if (tapBalance <
                                          storeItems['boosts'][0]['levels'][tapCount]['required_points']) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            message: context.tr('low_balance'),
                                          ),
                                        );
                                      } else {
                                        _addTapCounts();
                                      }
                                    },
                                    value: tapCount >= storeItems['boosts'][0]['levels'].length
                                        ? "max_reached".tr()
                                        : "x${tapCount+1}",
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  BuyItemWidget(
                                    title: "multi_tap_fingers".tr(),
                                    amount: tapFingers >= storeItems['boosts'][1]['levels'].length ? "max_reached".tr() : formatNumber(storeItems['boosts'][1]['levels'][tapFingers]['required_points'])
                                        .toString(),
                                    assetImage: 'assets/images/tap-multi.png',
                                    onTap: tapFingers >= storeItems['boosts'][1]['levels'].length ? null : () {
                                      if (tapBalance < storeItems['boosts'][1]['levels'][tapFingers]['required_points']) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            message: context.tr('low_balance'),
                                          ),
                                        );
                                      } else {
                                        _addFingersCounts();
                                      }
                                    },
                                    value: tapFingers >= storeItems['boosts'][1]['levels'].length
                                        ? "max_reached".tr()
                                        : "x${tapFingers+1}",
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  BuyItemWidget(
                                    title: "recharging_speed".tr(),
                                    amount: boostCount >= storeItems['boosts'][2]['levels'].length ? "max_reached".tr() : formatNumber(storeItems['boosts'][2]['levels'][boostCount]['required_points'])
                                        .toString(),
                                    assetImage: 'assets/images/power.png',
                                    onTap: boostCount >= storeItems['boosts'][2]['levels'].length ? null : () {
                                      if (tapBalance < storeItems['boosts'][2]['levels'][boostCount]['required_points']) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            message: context.tr('low_balance'),
                                          ),
                                        );
                                      } else {
                                        _addBoostCounts();
                                      }
                                    },
                                    value: boostCount >= storeItems['boosts'][2]['levels'].length
                                        ? "max_reached".tr()
                                        : "x${boostCount+1}",
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  BuyItemWidget(
                                    title: "max_tap_energy".tr(),
                                    amount: getMaxEnergyLevel(maxEnergy) >= storeItems['boosts'][3]['levels'].length ?
                                    "max_reached".tr() : formatNumber(storeItems['boosts'][3]['levels'][getMaxEnergyLevel(maxEnergy)]['required_points'])
                                        .toString(),
                                    assetImage: 'assets/images/energy.png',
                                    onTap:  getMaxEnergyLevel(maxEnergy) >= storeItems['boosts'][3]['levels'].length ?
                                    null : () {
                                      if (tapBalance < storeItems['boosts'][3]['levels'][getMaxEnergyLevel(maxEnergy)]['required_points']) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            message: context.tr('low_balance'),
                                          ),
                                        );
                                      } else {
                                        _addMaxEnergy();
                                      }
                                    },
                                    value: getMaxEnergyLevel(maxEnergy) >= storeItems['boosts'][3]['levels'].length
                                        ? "max_reached".tr()
                                        : "x${maxEnergy+500}",
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  BuyItemWidget(
                                    title: "tapping_bot".tr(),
                                    amount: botLevel >= storeItems['boosts'][4]['levels'].length
                                        ? "max_reached".tr()
                                        : formatNumber(storeItems['boosts'][4]['levels'][botLevel]['required_points'])
                                        .toString(),
                                    assetImage: 'assets/images/bot.png',
                                    onTap: botLevel >= storeItems['boosts'][4]['levels'].length
                                        ? null
                                        : () {
                                      if (tapBalance <
                                          storeItems['boosts'][4]['levels'][botLevel]['required_points']) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            message: context.tr('low_balance'),
                                          ),
                                        );
                                      } else {
                                        _addTappingBot();
                                      }
                                    },
                                    value: "level".tr(args: [
                                      botLevel < storeItems['boosts'][4]['levels'].length
                                          ? "${botLevel + 1}"
                                          : "max_reached".tr()
                                    ]),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  BuyItemWidget(
                                    title: context.tr('one_min_tap'),
                                    amount: formatNumber(storeItems['boosts'][5]['levels'][0]['required_points']),
                                    assetImage: 'assets/images/tap-device.png',
                                    onTap: () {
                                      if (tapBalance < storeItems['boosts'][5]['levels'][0]['required_points']) {
                                        showTopSnackBar(
                                          Overlay.of(context),
                                          CustomSnackBar.error(
                                            message: context.tr('low_balance'),
                                          ),
                                        );
                                      } else {
                                        _removePoints(widget.userID, storeItems['boosts'][5]['levels'][0]['required_points']);
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => TapFrenzy(
                                                      userID: widget.userID,
                                                      username: widget.username,
                                                      isLogin: widget.isLogin,
                                                    )));
                                      }
                                    },
                                    value: 'frenzy'.tr(),
                                  ),
                                  const SizedBox(
                                    height: 80,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  Container(
                    height: _height,
                    width: _width,
                    color: Theme.of(context).colorScheme.secondary,
                    child: SingleChildScrollView(
                      physics: const ScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(30, 40, 30, 10),
                        child: _isLoadingTaps
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        "assets/images/coin.png",
                                        height: 20,
                                        width: 20,
                                      ),
                                      Text(formatNumber(tapBalance),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20)),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  FreeItemWidget(
                                    title: _isButtonEnabled
                                        ? isSettingsLoading ? "Loading" : "ads_coin".tr(args: [formatNumber(int.parse(settingsJson['settings']['reward_ads']))])
                                        : _countdown.toString(),
                                    amount: 'free_ads'.tr(),
                                    assetImage: 'assets/images/coin.png',
                                    onTap: isSettingsLoading ? null : _isButtonEnabled
                                        ? _showRewardedAd
                                        : null,
                                    color: _isButtonEnabled
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    isOnline: false,
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  FreeItemWidget(
                                    title: _isButtonEnabled24
                                        ? context.tr('daily_bonus')
                                        : formatDuration(_countdown24)
                                            .toString(),
                                    amount: isSettingsLoading ? "Loading" : formatNumber(int.parse(settingsJson['settings']['login_bonus'])),
                                    assetImage: 'assets/images/coin.png',
                                    onTap: isSettingsLoading ? null : _isButtonEnabled24
                                        ? () {
                                            _resetTimer24();
                                            _addPoints(
                                                widget.userID,
                                                int.parse(settingsJson['settings']['login_bonus']));
                                          }
                                        : () {
                                            showTopSnackBar(
                                              Overlay.of(context),
                                              CustomSnackBar.error(
                                                message:
                                                    "come_back_in ${formatDuration(_countdown24)}"
                                                        .tr(),
                                              ),
                                            );
                                          },
                                    color: _isButtonEnabled24
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    isOnline: false,
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  const Text("Daily Tasks", style: TextStyle(
                                    fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold
                                  ),),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  // Build the UI with the daily tasks and handle countdown and actions
                        isShareLoadingTask
                            ? const CircularProgressIndicator()
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 20),
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: titleDaily.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return Column(
                                    children: [
                                      FreeItemWidget(
                                        isOnline: true,
                                        title: titleDaily[index],
                                        amount: savedItemsDaily.contains(idDaily[index])
                                            ? _formatDuration(itemRemainingTimes[savedItemsDaily.indexOf(idDaily[index])])
                                            : formatNumber(int.parse(rewardDaily[index])),
                                        assetImage: '$BASE_URL/public/assets/images/task/${iconDaily[index]}',
                                        onTap: savedItemsDaily.contains(idDaily[index])
                                            ? null
                                            : () async {
                                          _showQuestionDialog(
                                              context,
                                              descriptionDaily[index],
                                              questionsDaily[index],
                                              answersDaily[index],
                                              int.parse(rewardDaily[index]),
                                              idDaily[index],
                                              urlDaily[index],
                                              true
                                          );
                                        },
                                        color: savedItemsDaily.contains(idDaily[index])
                                            ? Colors.grey
                                            : Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  );
                                }
                            )
                        ,
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  const Text("New Tasks", style: TextStyle(
                                      fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold
                                  ),),
                                  isLoadingTask
                                      ? const CircularProgressIndicator()
                                      : ListView.builder(
                                          padding:
                                              const EdgeInsets.only(top: 20),
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: title.length,
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            return Column(
                                              children: [
                                                FreeItemWidget(
                                                  isOnline: true,
                                                  title: title[index],
                                                  amount: formatNumber(
                                                      int.parse(reward[index])),
                                                  assetImage:
                                                      '$BASE_URL/public/assets/images/task/${icon[index]}',
                                                  onTap: savedItems
                                                          .contains(id[index])
                                                      ? null
                                                      : () async {
                                                          _showQuestionDialog(
                                                              context,
                                                              description[
                                                                  index],
                                                              questions[index],
                                                              answers[index],
                                                              int.parse(reward[
                                                                  index]),
                                                              id[index],
                                                              url[index],
                                                          false);
                                                        },
                                                  color: savedItems
                                                          .contains(id[index])
                                                      ? Colors.grey
                                                      : Theme.of(context)
                                                          .primaryColor,
                                                ),
                                                const SizedBox(
                                                  height: 20,
                                                ),
                                              ],
                                            );
                                          }),
                                  const SizedBox(
                                    height: 80,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuestionDialog(BuildContext context, String description,
      String question, String answer, int reward, String id, String link, bool isDaily) {
    final TextEditingController _controller = TextEditingController();
    final String correctAnswer = answer; // You can set your correct answer here

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text(description)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton(
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
                  const Size(150, 50), //////// HERE
                ),
                  onPressed: () {
                launchUrl(Uri.parse(link));
              }, child: const Text("Start", style: TextStyle(),)),

              const SizedBox(height: 15,),
              Text(question, style: const TextStyle(
                fontSize: 15
              ),),
              const SizedBox(height: 15,),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'type_your_answer'.tr(),
                  border: const OutlineInputBorder(
                    borderRadius:
                    BorderRadius.all(Radius.circular(15)),
                    borderSide: BorderSide(
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),


              ),

            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('submit'.tr()),
              onPressed: () {
                if (isDaily) {
                  if (_controller.text.toLowerCase() == correctAnswer) {
                    Navigator.of(context).pop();
                    _saveItemDaily(id);
                    _addPoints(widget.userID, reward);
                  }
                  else if (correctAnswer == "" && _controller.text != "") {
                    Navigator.of(context).pop();
                    _saveItemDaily(id);
                    _addPoints(widget.userID, reward);
                  }
                  else if (_controller.text == "") {
                    //  Navigator.of(context).pop();
                    showTopSnackBar(
                      Overlay.of(context),
                      CustomSnackBar.error(
                        message: 'answer_is_empty'.tr(),
                      ),
                    );
                  }
                  else {
                    //  Navigator.of(context).pop();
                    showTopSnackBar(
                      Overlay.of(context),
                      CustomSnackBar.error(
                        message: 'incorrect_answer'.tr(),
                      ),
                    );
                  }
                }
                else {
                  if (_controller.text.toLowerCase() == correctAnswer) {
                    Navigator.of(context).pop();
                    _saveItem(id);
                    _addPoints(widget.userID, reward);
                  }
                  else if (correctAnswer == "" && _controller.text != "") {
                    Navigator.of(context).pop();
                    _saveItem(id);
                    _addPoints(widget.userID, reward);
                  }
                  else if (_controller.text == "") {
                    //  Navigator.of(context).pop();
                    showTopSnackBar(
                      Overlay.of(context),
                      CustomSnackBar.error(
                        message: 'answer_is_empty'.tr(),
                      ),
                    );
                  }
                  else {
                    //  Navigator.of(context).pop();
                    showTopSnackBar(
                      Overlay.of(context),
                      CustomSnackBar.error(
                        message: 'incorrect_answer'.tr(),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));

    return "$hours:$minutes:$seconds";
  }



  int getMaxEnergyLevel(int maxEnergy) {
    // Ensure the maxEnergy is within the valid range (1000 to 5000)
    if (maxEnergy < 1000 || maxEnergy > 5000 || (maxEnergy % 500 != 0)) {
      return 1; // Default level
    }

    // Calculate the energy level
    return ((maxEnergy - 1000) ~/ 500) + 1;
  }
}

class BuyItemWidget extends StatelessWidget {
  final String title;
  final String amount;
  final String assetImage;
  final String value;
  final VoidCallback? onTap;

  const BuyItemWidget({
    super.key,
    required this.title,
    required this.amount,
    required this.assetImage,
    required this.onTap,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: Theme.of(context).primaryColor,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              assetImage,
              height: 40,
              width: 40,
            ),
            Column(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Image.asset(
                      "assets/images/coin.png",
                      height: 20,
                      width: 20,
                    ),
                    Text(
                      amount,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.normal),
                    ),
                  ],
                )
              ],
            ),
            Container(
              width: 70,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Theme.of(context).colorScheme.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1), // changes position of shadow
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  context.tr('buy'),
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FreeItemWidget extends StatelessWidget {
  final String title;
  final String amount;
  final String assetImage;
  final VoidCallback? onTap;
  final Color color;
  final bool isOnline;

  const FreeItemWidget({
    super.key,
    required this.title,
    required this.amount,
    required this.assetImage,
    required this.onTap,
    required this.color,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: color,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            isOnline
                ? Image.network(
                    assetImage,
                    height: 40,
                    width: 40,
                  )
                : Image.asset(
                    assetImage,
                    height: 40,
                    width: 40,
                  ),
            Column(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: [
                    Image.asset(
                      "assets/images/coin.png",
                      height: 20,
                      width: 20,
                    ),
                    Text(
                      amount,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              ],
            ),
            Container(
              width: 70,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Theme.of(context).colorScheme.secondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1), // changes position of shadow
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  context.tr('claim'),
                  style: const TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
