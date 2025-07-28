import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session.dart';
import '../models/slot.dart';
import '../core/services/firebase/sessions_service.dart';
import '../core/services/firebase/slots_service.dart';
import '../core/services/firebase/users_service.dart';

class SessionProvider extends ChangeNotifier {
  final SessionsService _sessionsService = SessionsService();
  final SlotsService _slotsService = SlotsService();
  final UsersService _usersService = UsersService();

  // État interne
  String? _currentUserId;
  Session? _currentSession;
  List<Session> _userSessionHistory = [];
  bool _isLoading = false;
  String? _error;
  bool _historyLoaded = false;

  // Streams et subscriptions
  StreamSubscription<Session?>? _activeSessionSubscription;
  StreamSubscription<List<Session>>? _historySubscription;

  // Timer pour refresh automatique
  Timer? _statusTimer;

  // Getters publics
  Session? get currentSession => _currentSession;
  String? get currentSessionStatus => _currentSession?.effectiveStatus;
  List<Session> get userSessionHistory => _userSessionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get currentSessionStartTime => _currentSession?.startTime;
  DateTime? get currentSessionEndTime => _currentSession?.endTime;

  /// Initialise les streams pour un utilisateur
  Future<void> initialize(String userId) async {
      _currentUserId = userId;

    _clearError();

    try {
      _setLoading(true);
      
      // Nettoyer les anciens streams
      await _cleanup();
      
      // Écouter les changements temps réel
      _listenToUserActiveSession();
      
    } catch (e) {
      throw Exception('Erreur initialisation: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Réserve un créneau
  Future<void> bookSlot(Slot slot) async {
    // Vérifier qu'aucune session n'est déjà active
    if (hasActiveSession()) {
      _setError('Une session est déjà programmée');
    }

    // Vérifications préalables
    if (slot.status != SlotStatus.available) {
      _setError('Ce créneau n\'est plus disponible');
    }

    // Vérification ID non-null
    if (slot.id!.isEmpty) {
      _setError('Identifiant du créneau invalide');
    }
    
    _clearError();

    try {
      _setLoading(true);
      // Générer un channel Agora unique
      //TODO: à compléter
      final agoraChannelId = 'session_${DateTime.now().millisecondsSinceEpoch}';
 
      // Créer la session
      _currentSession = await _createSession(slot, agoraChannelId);

      if(_currentSession != null) {
      // Réserver le créneau
        await _slotsService.bookSlot(slot.id!, _currentSession!.id);

        // Mettre à jour currentSessionId dans user
        await _usersService.updateCurrentSessionId(_currentSession!.id);
      } else {
        _setError('Echec de création de session');
      }
    } catch (e) {
      _setError('Réservation échouée: $e');
      rethrow;
    }
    finally {
      _setLoading(false);
    }
  }

  /// Annule une réservation
  Future<void> cancelSlot() async {
    // Vérifier qu'une  session est active
    if (!hasActiveSession()) {
      _setError('Aucune session active à annuler');
    }

    _clearError();
    try {
      _setLoading(true);
      await _slotsService.cancelBooking(_currentSession!.slotId);
      await _sessionsService.deleteSession(_currentSession!.id);

      // Nettoyer la session courante
      _currentSession = null;
      
      // Mettre à jour l'utilisateur
      await _usersService.updateCurrentSessionId('');
    } catch (e) {
      _setError('Erreur suppression session: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Vérifie si l'utilisateur a une session active (scheduled ou active)
  bool hasActiveSession() {
    return _currentSession != null && (_currentSession!.isScheduled || _currentSession!.isInProgress);
  }

  /// Démarre une session (scheduled → inProgress)
  Future<void> startSession() async {
    if (_currentSession == null || !_currentSession!.isScheduled) {
      _setError('Aucune session active à démarrer');
    }

    try {
      _setLoading(true);
      _clearError();

      await _sessionsService.updateSessionStatus(_currentSession!.id, SessionStatus.inProgress);

      // Le stream mettra à jour automatiquement _currentSession
      
    } catch (e) {
      _setError('Erreur démarrage session: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Termine une session (inProgress → completed)
  Future<void> completeSession() async {
    if (_currentSession == null || !_currentSession!.isInProgress) {
      _setError('Aucune session active à terminer');
    }

    try {
      _setLoading(true);
      _clearError();

      await _sessionsService.updateSessionStatus(_currentSession!.id, SessionStatus.completed);


    _onSessionCompleted(_currentSession!);
    _currentSession = null;

      // Le stream mettra à jour automatiquement _currentSession

    } catch (e) {
      _setError('Erreur fin session: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Envoie un message dans la session active
  Future<void> sendMessage({
    required String text,
    required String senderId,
  }) async {
    if (!hasActiveSession()) {
      _setError('Aucune session active à envoyer un message');
    }

    try {
      await _sessionsService.addMessage(
        _currentSession!.id,
        text: text,
        senderId: senderId,
      );
    } catch (e) {
      _setError('Erreur envoi message: $e');
      rethrow;
    }
  }

  /// Charge l'historique des sessions
  Future<void> loadUserHistory() async {
    if(_currentSession == null) {
      _setError('Aucune session active pour charger l\'historique');
    }

    if (_historyLoaded) return;
    
    try {
      _userSessionHistory = await _sessionsService.getUserSessions();
      notifyListeners();
    } catch (e) {
      _setError('Erreur chargement historique: $e');
    }
  }

  /// Crée une nouvelle session
  Future<Session> _createSession(Slot slot, String agoraChannelId) async {
    if (_currentUserId == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    final session = Session(
      id: '', // Sera généré par Firestore
      userId: _currentUserId!,
      coachId: slot.createdBy,
      slotId: slot.id!,
      status: SessionStatus.scheduled,
      startedAt: Timestamp.fromDate(slot.startTime),
      agoraChannelId: agoraChannelId,
      startTime: slot.startTime,
      endTime: slot.endTime,
    );

    final sessionId = await _sessionsService.createSession(session);

    return session.copyWith(id: sessionId);
  }

  /// Charge la session et écoute les changements de la session active
  void _listenToUserActiveSession() {
    _activeSessionSubscription = _sessionsService
        .getUserActiveSessionStream()
        .listen(
      (session) {
        _currentSession = session;

        if (session?.needsStatusSync() == true) {
          _autoCompleteExpiredSession(session!);
        }

        _startStatusTimer();

        notifyListeners();
      },
      onError: (e) {
        _setError('Erreur stream session active: $e');
      },
    );
  }

  /// Auto-completion des sessions expirées
  Future<void> _autoCompleteExpiredSession(Session session) async {
    try {
      debugPrint('Auto-completion session expirée: ${session.id}');
      await _sessionsService.updateSessionStatus(
        session.id, 
        SessionStatus.completed
      );

    _currentSession = session.copyWith(status: SessionStatus.completed);

      // Le stream recevra automatiquement la mise à jour
    } catch (e) {
      debugPrint('Erreur auto-completion: $e');
      // Pas critique, l'UI affiche quand même le bon status
    }
  }

  /// Timer pour refresh l'UI aux transitions
  void _startStatusTimer() {
    _statusTimer?.cancel();
    
    if (_currentSession == null) return;
    
    final now = DateTime.now();
    Duration? nextTransition;
    String? nextStatus;
    
    // Calculer la prochaine transition ET le nouveau status
    if (now.isBefore(_currentSession!.startTime)) {
      nextTransition = _currentSession!.startTime.difference(now);
      nextStatus = SessionStatus.inProgress;
    } else if (now.isBefore(_currentSession!.endTime)) {
      nextTransition = _currentSession!.endTime.difference(now);
      nextStatus = SessionStatus.completed;
    }
    
    if (nextTransition != null && nextStatus != null) {
    final timerDuration = nextTransition + Duration(seconds: 1);
    
    _statusTimer = Timer(timerDuration, () {
      debugPrint('Transition automatique vers: $nextStatus');
      
      _autoUpdateSessionStatus(nextStatus!);
      
      _startStatusTimer(); // Planifie la prochaine
    });
  }
  }

  /// Met à jour le statut de la session automatiquement
  Future<void> _autoUpdateSessionStatus(String newStatus) async {
    if (_currentSession == null) return;
    
    try {
      await _sessionsService.updateSessionStatus(
        _currentSession!.id, 
        newStatus
      );
      _currentSession = _currentSession!.copyWith(status: newStatus);
    } catch (e) {
      debugPrint('Erreur auto-update status: $e');
      // Même si ça échoue, l'UI reste cohérente avec effectiveStatus
    }
  }

  /// Ajoute une nouvelle session à l'historique quand elle se termine
  void _onSessionCompleted(Session completedSession) {
    if (_historyLoaded) {
      _userSessionHistory.insert(0, completedSession); // Ajoute en premier
      notifyListeners();
    }
  }
  
  /// Gestion état loading/error
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    debugPrint(error);
    _error = error;
    notifyListeners();
    throw Exception(error);
  }
  
  void _clearError() {
    _error = null;
  }
  
  /// Remet à zéro l'état du provider
  Future<void> reset() async {
    await _cleanup();
    _currentUserId = null;
    _currentSession = null;
    _userSessionHistory.clear();
    _historyLoaded = false;
    _clearError();
    _setLoading(false);
    notifyListeners();
  }

  /// Nettoie les streams
  Future<void> _cleanup() async {
    _statusTimer?.cancel();
    await _activeSessionSubscription?.cancel();
    await _historySubscription?.cancel();
    _activeSessionSubscription = null;
    _historySubscription = null;
    _statusTimer = null;
  }

  /// Nettoyage
  @override
  Future<void> dispose() async {
    await _cleanup();
    super.dispose();
  }

  /// Méthodes utilitaires pour debug
  @override
  String toString() {
    return 'SessionProvider(activeSession: $_currentSession, historyCount: ${_userSessionHistory.length})';
  }
}
