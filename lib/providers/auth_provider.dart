import 'package:flutter/foundation.dart';
import '../core/services/firebase/users_service.dart';
import '../models/user.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final UsersService _usersService = UsersService();
  
  // Etat interne
  AuthState _state = AuthState.initial;
  User? _user;
  String? _error;
  // String? _currentSessionId;


  // Getters
  AuthState get state => _state;
  User? get user => _user;
  String? get error => _error;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;

  AuthProvider() {
    _initAuthListener();
  }

  /// Initialise l'écoute des changements d'état d'authentification
  void _initAuthListener() {
    _usersService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        try {
          final user = await _usersService.getCurrentUser();
          if (user != null) {
            _setAuthenticated(user);

          // _currentSessionId = await _usersService.getCurrentSessionId();
          } else {
            _setUnauthenticated();
          }
        } catch (e) {
          _setError('Erreur lors de la récupération des données utilisateur');
        }
      } else {
        _setUnauthenticated();
      }
    });
  }

  /// Inscription
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading();
    
    try {
      // Inscription via Firebase Service
      final user = await _usersService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      
      if (user != null) {
        // Définir l'utilisateur directement sans appeler getCurrentUser
        _user = user;
        _state = AuthState.authenticated;
        _error = null;
        notifyListeners();
        
        debugPrint('Inscription réussie pour: ${user.email}');
      } else {
        throw Exception('Échec de création du compte');
      }
    } catch (e) {
      debugPrint('Erreur signUp: $e');
      _setError(e.toString());
      
      // Si l'utilisateur Firebase existe mais pas le document Firestore,
      // on peut essayer de se déconnecter pour éviter un état incohérent
      if (_usersService.currentFirebaseUser != null) {
        await _usersService.signOut();
      }
    }
  }


  /// Connexion
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();
    
    try {
      final user = await _usersService.signInWithEmail(
        email: email,
        password: password,
      );
      
      if (user != null) {
        _setAuthenticated(user);
      } else {
        _setError('Erreur lors de la connexion');
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    _setLoading();
    
    try {
      await _usersService.signOut();
      _setUnauthenticated();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // États privés
  void _setLoading() {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();
  }

  void _setAuthenticated(User user) {
    _state = AuthState.authenticated;
    _user = user;
    _error = null;
    notifyListeners();
  }

  void _setUnauthenticated() {
    _state = AuthState.unauthenticated;
    _user = null;
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _state = AuthState.error;
    _error = error;
    notifyListeners();
  }
}
