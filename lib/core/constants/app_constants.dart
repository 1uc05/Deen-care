import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Configuration
  static const String appName = 'Caunvo';
  static const String appVersion = '1.0.0';

  // UX
  static const Duration sessionDuration = Duration(hours: 1);

  // Date Formats
  static const String dateFormat      = 'dd/MM/yyyy';
  static const String timeFormat      = 'HH:mm';
  static const String dateTimeFormat  = 'dd/MM/yyyy à HH:mm';

  // Calendly
  // static const String calendlyBaseUrl       = 'https://api.calendly.com/v2';
  // static String get   calendlyAccessToken   => dotenv.env['CALENDLY_ACCESS_TOKEN'] ?? '';
  // static const String calendlyEventTypeUuid = 'YOUR_EVENT_TYPE_UUID';
}