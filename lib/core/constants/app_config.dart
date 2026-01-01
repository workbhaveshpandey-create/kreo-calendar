import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App Configuration
/// Store sensitive keys securely - in production, use environment variables
class AppConfig {
  // AI Model to use (free tier compatible)
  static const String aiModel = 'google/gemma-3-4b-it:free';

  // App Info
  static const String appName = 'Kreo Calendar';
  static const String appVersion = '1.0.0';
}
