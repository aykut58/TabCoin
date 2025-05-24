import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'constants.dart';

class PointsService {

  PointsService();
  final HttpService httpService = HttpService();

  Future<void> addPoints(String userId, int points, bool isLogin) async {
    if (isLogin) {
      try {
        final response = await httpService.post('user/add-points.php', {
          'userID': userId,
          'taps': points.toString()
        });
        // Handle the response if needed
        if (kDebugMode) {
          print('Points added successfully: $response');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to add points: $e');
        }
        throw e;
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int balance = int.parse(prefs.getString(TAPS)!);
      balance = balance+points;
      prefs.setString(TAPS, balance.toString());
      if (kDebugMode) {
        print('Points added successfully');
      }

    }
  }

  Future<void> subtractPoints(String userId, int points, bool isLogin) async {
    if (isLogin) {
      try {
        final response = await httpService.post('user/remove-points.php', {
          'userID': userId,
          'taps': points.toString()
        });
        // Handle the response if needed
        if (kDebugMode) {
          print('Points subtracted successfully: $response');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to subtract points: $e');
        }
        throw e;
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int balance = int.parse(prefs.getString(TAPS)!);
      balance = balance-points;
      prefs.setString(TAPS, balance.toString());
      print('Points added successfully');
    }
  }
}