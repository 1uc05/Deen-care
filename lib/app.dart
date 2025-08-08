import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

class DeenCareApp extends StatelessWidget {
  const DeenCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    final router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoading = authProvider.state == AuthState.loading;
        final currentRoute = state.matchedLocation;

        if (isLoading) return null;

        // Navigation simple, sans initialisation des providers
        if (isLoggedIn && currentRoute == '/login') {
          return '/main';
        }
        
        if (!isLoggedIn && currentRoute != '/login') {
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
      title: 'Deen.care',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
