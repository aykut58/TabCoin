import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api_service.dart';

// Replace with your admin URL
var BASE_URL = "https://tap.tapcoin.live";

var API_DATA = "/api/v2/";
var API_KEY = "1234567890";

var IS_LOGIN = "isLogin";
var USER_ID = "userID";
var USERNAME = "userName";
var EMAIL = "emailAddress";

var TAPS = "taps";
var TAP_COUNT = "tap_count";
var TAP_ENERGY = "tapEnergy";
var MAX_ENERGY = "max_energy";
var FINGERS = "fingers";
var RECHARGING_SPEED = "rechargingSpeed";
var BOT_LEVEL = "bot_level";

// Ads units

var ADMOB_REWARD_BONUS_UNIT_ANDROID = "ca-app-pub-3940256099942544/5224354917";
var ADMOB_REWARD_BONUS_UNIT_IOS = "ca-app-pub-3940256099942544/1712485313";

var ADMOB_REWARD_ENERGY_UNIT_ANDROID = "ca-app-pub-3940256099942544/5224354917";
var ADMOB_REWARD_ENERGY_UNIT_IOS = "ca-app-pub-3940256099942544/1712485313";

var ADMOB_REWARD_LEVEL_UNIT_ANDROID = "ca-app-pub-3940256099942544/5224354917";
var ADMOB_REWARD_LEVEL_UNIT_IOS = "ca-app-pub-3940256099942544/1712485313";

var ADMOB_INTERSTITIAL_RETRY_UNIT_ANDROID = "ca-app-pub-3940256099942544/1033173712";
var ADMOB_INTERSTITIAL_RETRY_UNIT_IOS = "ca-app-pub-3940256099942544/4411468910";

var ADMOB_INTERSTITIAL_UNIT_ANDROID_SUCCESS = "ca-app-pub-3940256099942544/1033173712";
var ADMOB_INTERSTITIAL_UNIT_IOS_SUCCESS = "ca-app-pub-3940256099942544/4411468910";

//Onesignal App ID

String oneSignalAppId = "f26c5bda-de9d-47aa-9ae1-9e7f899d6e26";
String oneSignalAppIdIos = "f26c5bda-de9d-47aa-9ae1-9e7f899d6e26";

String formatNumberLeaderboard(int number) {
  final NumberFormat format = NumberFormat.compact();
  return format.format(number);
}

String formatNumber(int number) {
  final NumberFormat formatter = NumberFormat('#,###,###');

  if (number >= 1e9) {
    return '${(number / 1e9).toStringAsFixed(1)}B';
  } else {
    return formatter.format(number);
  }
}


// Define level thresholds and names
const List<int> levelThresholds = [
  0,        // Starter level
  15000,
  50000,
  150000,
  350000,
  750000,
  1000000,
  5000000,
];

const List<String> levelNames = [
  "Starter",    // Name for 0 to 15000 points
  "Apprentice",
  "Expert",
  "Master",
  "Grandmaster",
  "Legend",
  "Virtuoso",
  "Maestro",
  "Level max"
];

const List<String> levelImages = [
  "assets/images/trophy-1.png",  // Image for Starter
  "assets/images/trophy-2.png",
  "assets/images/trophy-3.png",
  "assets/images/trophy-4.png",
  "assets/images/trophy-5.png",
  "assets/images/trophy-6.png",
  "assets/images/trophy-7.png",
  "assets/images/trophy-8.png",  // Existing image for Maestro
  "assets/images/trophy-max.png", // New trophy image for max level
];

int getLevel(int count) {
  // Check for the highest level first
  for (int i = 0; i < levelThresholds.length; i++) {
    if (count < levelThresholds[i]) {
      return levelThresholds[i];
    }
  }
  return levelThresholds.last + 10000000; // Return a level above the max
}


int getPreviousLevel(int count) {
  // Special case for Starter level
  if (count < levelThresholds[1]) {
    return levelThresholds[0]; // Return 0 for Starter
  }

  // Find the previous level
  for (int i = 1; i < levelThresholds.length; i++) {
    if (count < levelThresholds[i]) {
      return levelThresholds[i - 1];
    }
  }
  return levelThresholds.last; // Return the highest level if above all thresholds
}

double getProgressRatio(int count) {
  int previousLevel = getPreviousLevel(count);
  int nextLevel = getLevel(count);
  return (count - previousLevel) / (nextLevel - previousLevel);
}

Widget getLevelProgress(int count) {
  int prevLevel = getPreviousLevel(count);
  int nextLevel = getLevel(count);

  // Get the index for previous and next levels
  String prevLevelName = levelNames[levelThresholds.indexOf(prevLevel)];
  String nextLevelName = levelNames[levelThresholds.indexOf(nextLevel)];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(prevLevelName, style: const TextStyle(color: Colors.white, fontSize: 15)),
      Text(nextLevelName, style: const TextStyle(color: Colors.white, fontSize: 15)),
    ],
  );
}

Widget getLevelName(int count) {
  int levelIndex;

  // Determine the level index based on the count
  if (count < levelThresholds[1]) {
    levelIndex = 0; // Starter level
  } else {
    levelIndex = levelThresholds.indexWhere((threshold) => count < threshold);
    if (levelIndex == -1) levelIndex = levelNames.length - 1; // For max level
  }

  // Use the appropriate trophy image
  String imagePath = levelImages[levelIndex];

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        imagePath,
        height: 20,
        width: 20,
      ),
      Text(levelNames[levelIndex], style: const TextStyle(color: Colors.white, fontSize: 15)),
    ],
  );
}




String formatDuration(int seconds) {
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  int remainingSeconds = seconds % 60;

  String hoursStr = hours.toString().padLeft(2, '0');
  String minutesStr = minutes.toString().padLeft(2, '0');
  String secondsStr = remainingSeconds.toString().padLeft(2, '0');

  return "$hoursStr:$minutesStr:$secondsStr";
}


List<int> rewards = [];
List<int> requiredPoints = [];

List<int> generateRewards(int numberOfLevels, int minReward, int maxReward) {
  List<int> rewards = [];
  int rewardStep = ((maxReward - minReward) / (numberOfLevels - 1)).round();

  for (int i = 0; i < numberOfLevels; i++) {
    rewards.add(minReward + (i * rewardStep));
  }

  return rewards;
}

List<int> generateRequiredPoints(
    int numberOfLevels, int minPoints, int maxPoints) {
  List<int> points = [];
  int pointsStep = ((maxPoints - minPoints) / (numberOfLevels - 1)).round();

  for (int i = 0; i < numberOfLevels; i++) {
    points.add(minPoints + (i * pointsStep));
  }

  return points;
}

