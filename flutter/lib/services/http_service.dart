import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  final http.Client _client = http.Client();
  String? _accessToken;
  String? _refreshToken;

  factory HttpService() {
    return _instance;
  }

  HttpService._internal();

  http.Client get client => _client;

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  String? getAccessToken() {
    return _accessToken;
  }

  String? getRefreshToken() {
    return _refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      debugPrint("No refresh token available.");
      return false;
    }

    try {
      var response = await _client.post(
        Uri.parse('http://10.0.2.2:8000/api/token/refresh/'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'refresh': _refreshToken}),
      );

      debugPrint("Refresh Token Response Status: ${response.statusCode}");
      debugPrint("Refresh Token Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String newAccessToken = data['access'];
        _accessToken = newAccessToken;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', newAccessToken);
        debugPrint("Access token refreshed successfully: $newAccessToken");
        return true;
      } else {
        debugPrint("Failed to refresh token: ${response.body}");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        clearTokens();
        return false;
      }
    } catch (e) {
      debugPrint("Error refreshing token: $e");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      clearTokens();
      return false;
    }
  }

  Future<http.Response?> makeRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    headers ??= {};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    String? bodyString;
    if (body != null) {
      if (headers['Content-Type']?.contains('application/json') == true) {
        if (body is String) {
          bodyString = body;
        } else {
          bodyString = jsonEncode(body);
        }
      } else {
        bodyString = body.toString();
      }
    }

    debugPrint('Request Headers: $headers');
    debugPrint('Request Body: $bodyString');

    http.Response response;
    if (method.toUpperCase() == 'GET') {
      response = await _client.get(url, headers: headers);
    } else if (method.toUpperCase() == 'POST') {
      response = await _client.post(url, headers: headers, body: bodyString);
    } else if (method.toUpperCase() == 'PUT') {
      response = await _client.put(url, headers: headers, body: bodyString);
    } else if (method.toUpperCase() == 'DELETE') {
      response = await _client.delete(url, headers: headers);
    } else {
      throw Exception('Unsupported HTTP method');
    }

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 401) {
      debugPrint("Access token expired, attempting to refresh...");
      bool refreshed = await refreshAccessToken();
      if (refreshed) {
        headers['Authorization'] = 'Bearer $_accessToken';
        if (body != null) {
          if (headers['Content-Type']?.contains('application/json') == true) {
            if (body is String) {
              bodyString = body;
            } else {
              bodyString = jsonEncode(body);
            }
          } else {
            bodyString = body.toString();
          }
        }
        debugPrint('Retrying Request Headers: $headers');
        debugPrint('Retrying Request Body: $bodyString');
        if (method.toUpperCase() == 'GET') {
          response = await _client.get(url, headers: headers);
        } else if (method.toUpperCase() == 'POST') {
          response = await _client.post(url, headers: headers, body: bodyString);
        } else if (method.toUpperCase() == 'PUT') {
          response = await _client.put(url, headers: headers, body: bodyString);
        } else if (method.toUpperCase() == 'DELETE') {
          response = await _client.delete(url, headers: headers);
        } else {
          throw Exception('Unsupported HTTP method');
        }
        debugPrint('Retry Response Status: ${response.statusCode}');
        debugPrint('Retry Response Body: ${response.body}');
      } else {
        return null;
      }
    }

    return response;
  }
}