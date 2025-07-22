// import 'package:flutter/material.dart';

// // Singleton navigation service pour navigation globale
// class NavigationService {
//   static final NavigationService _instance = NavigationService._internal();
//   factory NavigationService() => _instance;
//   NavigationService._internal();

//   final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//   Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
//     return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
//   }

//   Future<dynamic>? navigateAndReplace(String routeName, {Object? arguments}) {
//     return navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
//   }

//   void goBack() {
//     navigatorKey.currentState?.pop();
//   }
// }
