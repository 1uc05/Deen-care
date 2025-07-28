import 'package:flutter/material.dart';
import 'package:caunvo/screens/home_screen.dart';
import 'package:caunvo/screens/calendar_screen.dart';
import 'package:caunvo/screens/salon_screen.dart';
import 'package:caunvo/core/constants/app_colors.dart';
import 'package:caunvo/providers/navigation_provider.dart';
import 'package:caunvo/providers/auth_provider.dart';
import 'package:caunvo/providers/session_provider.dart';
import 'package:caunvo/providers/calendar_provider.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isInitialized = false;
  
  final List<Widget> _pages = [
    const HomeScreen(),
    const CalendarScreen(), 
    const SalonScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  Future<void> _initializeProviders() async {
    if (_isInitialized) return;
    
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;
      
      if (userId != null) {
        final sessionProvider = context.read<SessionProvider>();
        final calendarProvider = context.read<CalendarProvider>();

        debugPrint('Initialisation des providers pour user: ${authProvider.user?.name}');

        // Initialisation des providers  et démarrage des streams
        await sessionProvider.initialize(userId);
        await calendarProvider.initialize(userId);

        // Chargement des créneaux disponibles
        await calendarProvider.loadAvailableSlots();
        
        setState(() {
          _isInitialized = true;
        });
        
        debugPrint('Providers initialisés avec succès');
      }
    } catch (e) {
      debugPrint('Erreur initialisation providers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un loader pendant l'initialisation
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationProvider.currentIndex,
            onTap: (index) => navigationProvider.setIndex(index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.highLight,
            unselectedItemColor: AppColors.textGrey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Réservation'),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Salon'),
            ],
          ),
        );
      },
    );
  }
}
