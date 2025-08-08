import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Configuration
  static const String appName = 'Care.deen';
  static const String appVersion = '1.0.0';

  // UX
  static const Duration sessionDuration = Duration(minutes: 30);

  // Date Formats
  static const String dateFormat      = 'dd/MM/yyyy';
  static const String timeFormat      = 'HH:mm';
  static const String dateTimeFormat  = 'dd/MM/yyyy à HH:mm';

  // Agora
  static String get   agoraDevToken   => dotenv.env['AGORA_USR_DEV_TOKEN'] ?? '';
  static const String agoraAppID      = '38cea02d0d594ca1956bb1301d7e9676';
  static const String agoraAppKey     = '711376348#1582345';

  // Logique métier
  static const int maxTrackedTexts    = 3;
  static const int voiceCallDelay     = 5;
  
}