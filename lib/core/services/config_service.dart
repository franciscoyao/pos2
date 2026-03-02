import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ConfigService {
  static const String _configFile = 'assets/config.json';
  static Map<String, dynamic> _config = {};

  static Future<void> load() async {
    try {
      final String jsonString = await rootBundle.loadString(_configFile);
      _config = json.decode(jsonString);
    } catch (e) {
      // Allow fallback if file missing in development
      debugPrint('Config file not found, using defaults');
    }
  }

  static String get baseUrl {
    return _config['baseUrl'] ?? 'http://localhost:3000';
  }
}
