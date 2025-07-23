import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/calendar_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:intl/date_symbol_data_local.dart';
import 'core/utils/seed_data.dart';

void main() async {
  debugPrint('START APPLICATION');
  WidgetsFlutterBinding.ensureInitialized();

  // Chargement des variables d'environnement
  await dotenv.load(fileName: ".env");
  
  // Initialisation Firebase
  await Firebase.initializeApp();
  
  // Initialise les données de localisation avec gestion d'erreur
  try {
    await initializeDateFormatting('fr_FR');
    debugPrint('Localisation FR initialisée avec succès');
  } catch (e) {
    debugPrint('Erreur localisation FR, utilisation locale par défaut: $e');
    await initializeDateFormatting(); // Locale système par défaut
  }

  // ⚠️ TEMPORAIRE - À supprimer après test
  // await SeedData.createTestSlots();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
      ],
      child: const CaunvoApp(),
    ),
  );
}