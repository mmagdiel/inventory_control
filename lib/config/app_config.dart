import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _devApiUrl = 'http://127.0.0.1:8090';
  static const String _prodApiUrl = 'https://your-pocketbase-server.com/'; // TODO: Replace with your production URL

  static String get apiUrl {
    if (kDebugMode) {
      return _devApiUrl;
    }
    return _prodApiUrl;
  }
} 