import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  /// Cloud: "157.173.222.91"
  static const String? _customServerIP =
      "157.173.222.91"; // "157.173.222.91"; // Set specific IP if needed

  static String get baseUrl {
    if (_customServerIP != null) return "http://$_customServerIP:8006";

    if (kIsWeb) return "http://localhost:8006";
    try {
      if (Platform.isAndroid) return "http://10.0.2.2:8006"; // Android Emulator
    } catch (e) {
      // Ignored for web compatibility if Platform check fails unexpectedly
    }
    return "http://localhost:8006"; // Windows/Linux/macOS
  }

  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get headers {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }
}
