import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/user.dart';
import 'http_helper.dart';

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_profile';

  static Future<User?> login(String username, String password) async {
    try {
      final response = await HttpHelper.post('/auth/login', {
        'username': username,
        'password': password,
      });

      if (response['success']) {
        final userData = response['data'];
        final user = User.fromJson(userData);
        
        // Store token if present
        if (userData['access_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, userData['access_token']);
          await prefs.setString(_userKey, jsonEncode(userData));
        }
        
        return user;
      } else {
        throw Exception(response['error'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        return User.fromJson(jsonDecode(userJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
