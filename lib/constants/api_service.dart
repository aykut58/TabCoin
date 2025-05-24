import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';

class HttpService {
  HttpService();
  String baseUrl = BASE_URL+API_DATA;

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    data.addAll({
      'apikey': API_KEY,
    });

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw Exception('no_internet'.tr());
    }
    final response = await http
        .post(
      Uri.parse('$baseUrl$endpoint'),
      body: data,
    )
        .timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw Exception('request_timeout'.tr);
      },
    );
    print(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('failed_post'.tr);
    }
  }
}
