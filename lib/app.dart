import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

class CaunvoApp extends StatelessWidget {
  const CaunvoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    final router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider, // Écoute les changements
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoading = authProvider.state == AuthState.loading;
        final currentRoute = state.matchedLocation;

        debugPrint('Redirect: isLoggedIn=$isLoggedIn, isLoading=$isLoading, currentRoute=$currentRoute');

        if (isLoading) {
          debugPrint('En cours de chargement, pas de redirection');
          return null;
        }

        if (isLoggedIn && currentRoute == '/login') {
          debugPrint('Redirection vers /main');
          return '/main';
        }
        
        if (!isLoggedIn && currentRoute != '/login') {
          debugPrint('Redirection vers /login');
          return '/login';
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/main',
          builder: (context, state) => const MainScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Caunvo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
