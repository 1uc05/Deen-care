import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../providers/calendar_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Accueil'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _signOut(context),
            ),
          ],
        ),
        Expanded(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.user;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Bienvenue ${user?.name ?? 'Utilisateur'} !'),
                    const SizedBox(height: 20),
                    const Text('Écran d\'accueil - À implémenter'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
  try {
    // Nettoyer les providers avant la déconnexion
    debugPrint('Nettoyage des providers avant la déconnexion');

    await context.read<SessionProvider>().reset();
    await context.read<CalendarProvider>().reset();

    await context.read<AuthProvider>().signOut();
    
  } catch (e) {
    debugPrint('Erreur déconnexion: $e');
  }
}
}
