import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/slot.dart';
import '../core/services/firebase/sessions_service.dart';
import 'dart:async';

class SessionProvider extends ChangeNotifier {
  final SessionsService _sessionsService = SessionsService();
  
  // État interne
  String? _currentUserId;
  String? _currentSessionId;
  Session? _userActiveSession;
  List<Session> _userSessionHistory = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Session?>? _activeSessionSubscription;
  StreamSubscription<List<Session>>? _historySubscription;

  // Getters publics
  Session? get userActiveSession => _userActiveSession;
  List<Session> get userSessionHistory => _userSessionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialise les streams pour un utilisateur
  Future<void> initialize(String userId, String currentSessionId) async {
    try {
      _currentUserId = userId;
      _currentSessionId = currentSessionId;

    } catch (e) {
      _setError('Erreur initialisation: $e');
    }
  }
  
  /// Initialise les streams pour un utilisateur
  Future<void> startListening() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Nettoyer les anciens streams
      await _disposeStreams();
      
      // Charger la session active initiale
      await _loadUserActiveSession();
      
      // Écouter les changements temps réel
      _listenToUserActiveSession();
      _listenToUserHistory();
      
    } catch (e) {
      _setError('Erreur initialisation: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Vérifie si l'utilisateur a une session active (scheduled ou active)
  bool hasUserActiveSession() {
    return _userActiveSession?.userId == _currentUserId && 
           (_userActiveSession!.isScheduled || _userActiveSession!.isActive);
  }
  
  /// Récupère la session active de l'utilisateur
  Session? getUserActiveSession() {
    return hasUserActiveSession() ? _userActiveSession : null;
  }
  
  /// Vérifie si l'utilisateur peut envoyer des messages (dès scheduled)
  bool canUserSendMessages() {
    final session = getUserActiveSession();
    return session != null;
  }
  
  /// Vérifie si l'utilisateur peut faire un appel vocal (seulement si active)
  bool canUserMakeVoiceCall() {
    final session = getUserActiveSession();
    return session?.isActive == true;
  }
  
  /// Vérifie si l'utilisateur peut démarrer un appel (si scheduled)
  bool canUserStartCall() {
    final session = getUserActiveSession();
    return session?.isScheduled == true;
  }

  /// Actions sur les sessions
  
  /// Démarre une session (scheduled → active)
  Future<void> startSession(String sessionId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _sessionsService.startSession(sessionId);
      
      // Le stream mettra à jour automatiquement _userActiveSession
      
    } catch (e) {
      _setError('Erreur démarrage session: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Termine une session (active → completed)
  Future<void> completeSession(String sessionId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _sessionsService.completeSession(sessionId);
      
      // Le stream mettra à jour automatiquement
      
    } catch (e) {
      _setError('Erreur fin session: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Envoie un message dans la session active
  Future<void> sendMessage(String sessionId, {
    required String text,
    required String senderId,
  }) async {
    try {
      await _sessionsService.addMessage(
        sessionId,
        text: text,
        senderId: senderId,
      );
    } catch (e) {
      _setError('Erreur envoi message: $e');
      rethrow;
    }
  }
  
  /// Charge la session active initiale
  Future<void> _loadUserActiveSession() async {
    try {
      _userActiveSession = await _sessionsService.getUserActiveSession(_currentUserId!);
      notifyListeners();
    } catch (e) {
      _setError('Erreur chargement session active: $e');
    }
  }
  
  /// Écoute les changements de la session active
  void _listenToUserActiveSession() {
    _activeSessionSubscription = _sessionsService
        .getUserActiveSessionStream(_currentUserId!)
        .listen(
      (session) {
        _userActiveSession = session;
        notifyListeners();
      },
      onError: (e) {
        _setError('Erreur stream session active: $e');
      },
    );
  }
  
  /// Écoute l'historique des sessions
  void _listenToUserHistory() {
    _historySubscription = _sessionsService
        .getUserSessions(_currentUserId!)
        .listen(
      (sessions) {
        _userSessionHistory = sessions;
        notifyListeners();
      },
      onError: (e) {
        _setError('Erreur stream historique: $e');
      },
    );
  }
  
  /// Nettoie les streams
  Future<void> _disposeStreams() async {
    await _activeSessionSubscription?.cancel();
    await _historySubscription?.cancel();
    _activeSessionSubscription = null;
    _historySubscription = null;
  }
  
  /// Gestion état loading/error
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }

  /// Nettoyage
  @override
  void dispose() {
    _disposeStreams();
    super.dispose();
  }

  /// Méthodes utilitaires pour debug
  @override
  String toString() {
    return 'SessionProvider(activeSession: $_userActiveSession, historyCount: ${_userSessionHistory.length})';
  }
}
