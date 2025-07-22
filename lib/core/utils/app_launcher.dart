// import 'package:url_launcher/url_launcher.dart';
// import '../constants/app_constants.dart';

// class AppLauncher {
//   /// Tente de lancer Clash Royale. Retourne true si réussi, false sinon.
//   static Future<bool> launchClashRoyale() async {
//     // Méthode Android : schéma d'URL. Peut aussi adapter si besoin pour iOS.
//     // ATTENTION : À tester sur device ! Le schéma peut varier selon versions/régions.
//     final androidScheme = 'intent://'; // À remplacer par le vrai package si besoin
//     final iosScheme = 'clashroyale://';

//     final uriAndroid = Uri.parse('intent://arena#Intent;scheme=clashroyale;package=${AppConstants.clashRoyaleUrlScheme};end');
//     final uriIOS = Uri.parse(iosScheme);

//     try {
//       // Pour iOS : on tente d'abord le schéma custom. 
//       if (await canLaunchUrl(uriIOS)) {
//         await launchUrl(uriIOS);
//         return true;
//       }
//       // Pour Android : intent explicite
//       if (await canLaunchUrl(uriAndroid)) {
//         await launchUrl(uriAndroid);
//         return true;
//       }
//     } catch (e) {
//       // Log si besoin sur crashlytics ou équivalent
//     }
//     return false;
//   }
// }
