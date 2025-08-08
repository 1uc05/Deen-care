import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'providers/navigation_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/texts_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/session_provider.dart';
import 'firebase_options.dart';
import 'core/utils/data_tools.dart';


void main() async {
  debugPrint('START APPLICATION');
  WidgetsFlutterBinding.ensureInitialized();

  // Chargement des variables d'environnement
  await dotenv.load(fileName: ".env");
  
  // Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialise les données de localisation avec gestion d'erreur
  try {
    await initializeDateFormatting('fr_FR');
  } catch (e) {
    debugPrint('Erreur localisation FR, utilisation locale par défaut: $e');
    await initializeDateFormatting(); // Locale système par défaut
  }

  // TODO: TEMPORAIRE - À supprimer après test
  // await DatabaseTools.resetTestData();
  // await DatabaseTools.clearCollection('sessions');
  // await DatabaseTools.clearCollection('slots');
  // await DatabaseTools.createTestSlots();
  // await DatabaseTools.clearAllTexts();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TextsProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: const DeenCareApp(),
    ),
  );
}