import 'package:flutter/foundation.dart';

class AppConstants {
  // We added the /api prefix here so the Remote Data Sources don't have to!
  static const String baseUrl = kIsWeb 
      ? 'http://127.0.0.1:8000/api' 
      : 'http://192.168.1.8:8000/api';
}