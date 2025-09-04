import 'dart:async';
import 'dart:ffi';
import 'package:deen_care/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import '../models/session.dart';
import '../models/slot.dart';
import '../core/utils/date_utils.dart';
import '../core/services/firebase/sessions_service.dart';
import '../core/services/firebase/slots_service.dart';
import '../core/services/firebase/users_service.dart';
import '../core/services/firebase/cloud_functions_service.dart';
import '../core/services/agora_service.dart';
import '../models/voice_call_state.dart';
import '../models/message.dart';

class SessionProvider extends ChangeNotifier {
  final SessionsService _sessionsService = SessionsService();
  final SlotsService _slotsService = SlotsService();
  final UsersService _usersService = UsersService();
  final AgoraService _agoraService = AgoraService();
  final CloudFunctionsService _cloudFunctionsService = CloudFunctionsService();

  // État interne
  String? _currentUserId;
  String? _currentUserName;
  Session? _currentSession;
  List<Session> _userSessionHistory = [];
  bool _isLoading = false;
  String? _error;
  bool _historyLoaded = false;
  bool _isInitialized     = false;
  RoomConnectionState _connectionState = RoomConnectionState.disconnected;
  VoiceCallState _voiceCallState = VoiceCallState.idle;
  List<Message> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSpeakerOn = false;
  
  // Streams et subscriptions
  StreamSubscription<Session?>? _activeSessionStream;
  StreamSubscription<List<Session>>? _historyStream;
  StreamSubscription<ChatMessage>? _rawMessageStream;
  StreamSubscription<VoiceConnectionState>? _voiceStateSream;

  // Timers
  Timer? _statusTimer;        // Mise à jour auto du status de session
  Timer? _endVoiceCallTimer;  // Délais supplémentaire pour appel en fin de session

  // Getters publics
  Session? get currentSession => _currentSession;
  String? get currentSessionStatus => _currentSession?.effectiveStatus;
  List<Session> get userSessionHistory => _userSessionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get currentSessionStartTime => _currentSession?.startTime;
  DateTime? get currentSessionEndTime => _currentSession?.endTime;
  List<Message> get messages => List.unmodifiable(_messages);
  RoomConnectionState get connectionState => _connectionState;
  bool get isLoadingMessages => _isLoadingMessages;
  VoiceCallState get voiceCallState => _voiceCallState;
  bool get isSpeakerOn => _isSpeakerOn;

  // Logique métier - Règles de validation
  bool get canSendMessages => _connectionState == RoomConnectionState.connected &&
                              (_currentSession?.isActive == true);

  bool get canMakeVoiceCalls => _connectionState == RoomConnectionState.connected &&
                                _currentSession?.isInProgress == true;
  
  bool get isInVoiceCall => _voiceCallState == VoiceCallState.connected;

  String? get currentRoomId => _currentSession?.agoraChannelId;

  // Helpers UI
  String get voiceCallButtonText {
    switch (_voiceCallState) {
      case VoiceCallState.idle:
        return 'Démarrer appel';
      case VoiceCallState.calling:
        return 'Connexion...';
      case VoiceCallState.connected:
        return 'Raccrocher';
    }
  }
  
  bool get voiceCallButtonEnabled {
    return canMakeVoiceCalls && 
           (_voiceCallState == VoiceCallState.idle || 
            _voiceCallState == VoiceCallState.connected);
  }


  /// Initialise le provider
  Future<void> initialize(String userId, String userName) async {
    if(_isInitialized) return;
    
      _messages = [];
      _currentUserId = userId;
      _currentUserName = userName;

    _clearError();

    try {
      _setLoading(true);

      _connectionState = RoomConnectionState.connecting;
      notifyListeners();
      
      // Nettoyer les anciens streams
      await _cleanup();

      // Récupération de la session ou création si première connexion
      final currentSessionId = await _usersService.getCurrentSessionId();

      if(currentSessionId == null) {
        debugPrint('SessionProvider: Première connexion de l\'utilisateur');
        
        // Générer dès la première connexion d'un utilisateur
        await _cloudFunctionsService.createAgoraUser();
        _currentSession = await _createFirstSession();
      } else {
        // Session active, chargement et configuration de la sesson
        _currentSession = await _sessionsService.getSession(currentSessionId);
        if(_currentSession == null) {
          throw Exception('SessionProvider: Session active introuvable');
        }

        // Met à jour le statut de la session s'il a changé pendant déconnection
        if(_currentSession!.effectiveStatus != _currentSession!.status) {
          await _autoUpdateSessionStatus(_currentSession!.effectiveStatus);
        }

        // Initialiser Agora si la session est active
        if (_currentSession!.isActive) {

          // Initialise SDK
          await _agoraService.initializeChatSDK();

          // Authentifier l'utilisateur
          final chatToken = await _cloudFunctionsService.generateChatToken();
          await _agoraService.loginUser(_currentUserId!, chatToken);

          // Rejoindre la room
          await _agoraService.joinChatGroup(_currentSession!.agoraChannelId!);

          // Charger l'historique
          await _loadMessages();

          // Initialiser les streams
          _initializeStreams();

          _startStatusTimer();

          // Initialise RTC si session en cours
          if (_currentSession!.isInProgress) {
            await _agoraService.initializeRtcEngine();
          }

          _listenActiveSession();
        }

        _connectionState = RoomConnectionState.connected;
        notifyListeners();

        // Initialisé seulement si une session est active
        _isInitialized = true;
      }     
    } catch (e) {
      _connectionState = RoomConnectionState.error;
      notifyListeners();
      throw Exception('SessionProvider: Erreur initialisation: $e');
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
    Session? session;

    try {
      _setLoading(true);

      // Configuration d'une nouvelle session
      final agoraChannelId = await _agoraNewSession(slot.createdBy);

      if (agoraChannelId == null) {
        _setError('Échec de création de session Agora');
        return;
      }

      // Créer la session - currentSession est mis à jour par le listener
      session = await _createSession(slot, agoraChannelId);

      // Initialiser les streams
      _initializeStreams();

      // Réserver le créneau
      await _slotsService.bookSlot(slot.id!, session.id);

      // Écouter les changements de la nouvelle session
      _listenActiveSession();

      // Envoie du premier message
      await _sendFirstMessage(slot);

    } catch (e) {
      _rollbackBooking(session?.id, slot.id);
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

      // Nettoyage firebase
      await _slotsService.cancelBooking(_currentSession!.slotId!);
      await _sessionsService.deleteSession(_currentSession!.id);
      final currentSessionId = await _usersService.clearCurrentSessionId();

      if (currentSessionId == null) {
        _currentSession = await _createFirstSession();
        
      } else {
        // Récupérer dernière session complétée
        _currentSession = await _sessionsService.getSession(currentSessionId);
      }

      await _activeSessionStream?.cancel();

      // La déconnexion d'Agora est gérée par le listener

      // Nettoyer la session courante
      _currentSession = null;
    } catch (e) {
      _setError('Erreur suppression session: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Vérifie si l'utilisateur a une session active (scheduled ou active)
  bool hasActiveSession() {
    return _currentSession != null && (_currentSession!.isActive);
  }

  /// Logique métier : Gestion appel vocal
  Future<bool> toggleVoiceCall() async {
    if (!canMakeVoiceCalls || currentRoomId == null) {
      _setError('Appel vocal non disponible actuellement');
      return false;
    }

    try {
      if (_voiceCallState == VoiceCallState.idle) {
        await _startVoiceCall();
      } else if (_voiceCallState == VoiceCallState.connected) {
        await _endVoiceCall();
      }
      
    } catch (e) {
      _setError('Erreur appel vocal: $e');
      return false;
    }
    return true;
  }

  /// Logique métier : Envoi de message avec validation
  Future<bool> sendMessage(String text) async {
    // Validations métier
    if (!canSendMessages) {
      _setError('Messages non autorisés dans l\'état actuel de la session');
      return false;
    }
    
    if (_currentUserId == null || currentRoomId == null) {
      _setError('Session non initialisée');
      return false;
    }
    
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      _setError('Message vide non autorisé');
      return false;
    }
    
    if (trimmedText.length > 1000) {
      _setError('Message trop long (max 1000 caractères)');
      return false;
    }

    // Créer le message
    final optimisticMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: trimmedText,
      senderId: _currentUserId!,
      timestamp: DateTime.now(),
      isFromCoach: false,
    );

    try {
      debugPrint('SessionProvider: Sending message: $text');
      

      // Ajouter à la liste et notifier
      _messages.add(optimisticMessage);
      notifyListeners();

      // Appel technique pur
      await _agoraService.sendTextMessage(
        roomId: currentRoomId!,
        content: trimmedText,
      );
      
      debugPrint('SessionProvider: Message sent successfully');
      return true;
      
    } catch (e) {
      // En cas d'erreur, retirer le message
      _messages.removeWhere((msg) => msg.id == optimisticMessage.id);
      notifyListeners();

      _setError('Échec envoi message: $e');
      return false;
    }
  }

  /// ========== PRIVATE FUNCTION ==========
  /// ========== GENERIQUE ==========
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
    await _usersService.updateCurrentSessionId(sessionId);

    return session.copyWith(id: sessionId);
  }

  // Créer la première session si l'utilisateur n'en a pas
  Future<Session> _createFirstSession() async {
    final session = Session(
      id: '',
      userId: _currentUserId!,
      coachId: null,
      slotId: null,
      status: SessionStatus.undefined,
      startedAt: null,
      agoraChannelId: null,
      startTime: null,
      endTime: null,
    );

    final sessionId = await _sessionsService.createSession(session);
    await _usersService.updateCurrentSessionId(sessionId);

    return session.copyWith(id: sessionId);
  }

  /// Charge la session et écoute les changements de la session active
  Future<void> _listenActiveSession() async {

    try {
      debugPrint('SessionProvider: Start sreaming session');

      await _activeSessionStream?.cancel();

      _activeSessionStream = _sessionsService
          .getActiveSessionStream()
          .listen(
        (session) async {
          if(!_isInitialized) return;
          debugPrint('SessionProvider: Listener called');

          await _handleSessionChange(_currentSession, session);

          _currentSession = session;

          _startStatusTimer();

          notifyListeners();
        },
        onError: (e) {
          _setError('Erreur stream session active: $e');
        },
      );
    } catch (e) {
      _setError('Erreur chargement session: $e');
    }
  }
  
  Future<void> _handleSessionChange(Session? previous, Session? current) async {
    // Session fermée/supprimée
    if (previous != null && current == null) {
      debugPrint('SessionProvider: Call disconnect without delay');
      await _disconnectSession(previous);
      return;
    }
    
    // Nouvelle session ou changement de statut automatique
    if (current != null) {
      final statusChanged = previous?.status != current.status;
      
      if (statusChanged) {
        switch (current.status) {
          case SessionStatus.scheduled:
            // La config a été faite dans bookSlot
            break;
          case SessionStatus.inProgress:
            await _agoraService.initializeRtcEngine();
            break;
          case SessionStatus.completed:
            // Fin de session avec delais avant fin d'appel
            debugPrint('SessionProvider: Call disconnect with delay');
            if (previous == null) return;
            await _disconnectSession(previous);
            break;
        }
      }
    }
  }

  /// Nettoyage session précédente
  Future<void> _disconnectSession(Session session) async {
    try {
      debugPrint('SessionProvider: Cleaning up session ${session.id}');
      debugPrint('SessionProvider: Cleaning up session ${session.agoraChannelId}');

      // Arrêter les streams
      await _rawMessageStream?.cancel();
      await _voiceStateSream?.cancel();

      // Nettoyage complet via AgoraService
      await _agoraService.cleanupSession(
        session.agoraChannelId,  // Group ID
        session.agoraChannelId,  // Voice channel ID (même ID)
      );

      // Annuler le timer de fin d'appel
      _cancelEndVoiceCallTimer();

      // Déconnecte l'utilisateur Agora
      await _agoraService.logoutUser();

      // Réinitialiser l'état local
      _messages.clear();
      _voiceCallState = VoiceCallState.idle;
      _connectionState = RoomConnectionState.disconnected;

      debugPrint('SessionProvider: Session cleanup completed');

    } catch (e) {
      debugPrint('SessionProvider: Error cleaning up session: $e');
      // Continue l'exécution même en cas d'erreur
    }
  }

  // Annuler le timer de fin d'appel
  void _cancelEndVoiceCallTimer() {
    _endVoiceCallTimer?.cancel();
    _endVoiceCallTimer = null;
  }

  /// ========== PRIVATE: AGORA STREAMS ==========
  // Crée une nouvelle session Agora
  Future<String?> _agoraNewSession(String coachId) async {
    String? agoraChannelId;

    try {
      _connectionState = RoomConnectionState.connecting;
      notifyListeners();

      // Initialise SDK
      await _agoraService.initializeChatSDK();

      // Authentifier l'utilisateur
      final token = await _cloudFunctionsService.generateChatToken();
      await _agoraService.loginUser(_currentUserId!, token);

      agoraChannelId = await _agoraService.createChatGroup(coachId);

      // Rejoindre la room
      await _agoraService.joinChatGroup(agoraChannelId);

      // Iniialisé seulement si une session est active 
      _isInitialized = true;

      _connectionState = RoomConnectionState.connected;
      
    } catch (e) {
      _connectionState = RoomConnectionState.error;
      _setError('Échec d\'activation session: $e');
    }
    
    notifyListeners();
    
    return agoraChannelId;
  }

  /// Chargement historique des messages avec logique métier
  Future<void> _loadMessages() async {
    if (_currentSession?.agoraChannelId == null) {
      debugPrint('SessionProvider: No room ID for loading messages');
      return;
    }

    if (_isLoadingMessages) {
      return; // Éviter les appels multiples
    }

    try {
      _isLoadingMessages = true;
      
      debugPrint('SessionProvider: Loading message history');
      
      final chatMessages = await _agoraService.fetchMessageHistory(
        conversationId: _currentSession!.agoraChannelId!,
        limit: 50,
      );
      
      // Transformation métier
      final messages = _convertChatMessagesToBusinessMessages(chatMessages);
      
      // Mise à jour état métier
      _messages.clear();
      _messages.addAll(messages);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      debugPrint('SessionProvider: Loaded ${messages.length} messages');
      
    } catch (e) {
      _setError('Erreur chargement historique: $e');
    } finally {
      _isLoadingMessages = false;
    }
  }

  /// Initialise les streams techniques
  void _initializeStreams() {
    // Stream des messages bruts → Transformation métier
    _rawMessageStream = _agoraService.rawMessageStream.listen(
      _handleRawMessage,
      onError: (error) => _setError('Erreur stream messages: $error'),
    );
    
    // Stream états vocaux → Transformation métier
    _voiceStateSream = _agoraService.voiceStateStream.listen(
      _handleVoiceStateChange,
      onError: (error) => _setError('Erreur stream vocal: $error'),
    );
  }

  /// Traitement message brut → Logique métier
  void _handleRawMessage(ChatMessage chatMessage) {
    try {
      final message = _convertChatMessageToBusinessMessage(chatMessage);
      if (message != null && !_isDuplicateMessage(message)) {
        _messages.add(message);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        debugPrint('SessionProvider: New message received from ${message.senderId}');
        notifyListeners();
      }
      
    } catch (e) {
      debugPrint('SessionProvider: Error processing message: $e');
    }
  }

  /// Traitement changement état vocal
  void _handleVoiceStateChange(VoiceConnectionState voiceState) {
    final newCallState = _mapVoiceConnectionToCallState(voiceState);
    
    if (_voiceCallState != newCallState) {
      debugPrint('SessionProvider: Voice state changed: $_voiceCallState → $newCallState');
      _voiceCallState = newCallState;
      notifyListeners();
    }
  }

  /// Démarre un appel vocal
  Future<void> _startVoiceCall() async {
    debugPrint('SessionProvider: Starting voice call');
    _voiceCallState = VoiceCallState.calling;
    notifyListeners();
    
    try {
      final voiceToken = await _cloudFunctionsService.generateVoiceToken(_currentSession!.agoraChannelId!);

      await _agoraService.joinVoiceChannel(_currentSession!.agoraChannelId!, voiceToken);
    } catch (e) {
      _voiceCallState = VoiceCallState.idle;
      _setError('Erreur initialisation RTC: $e');
      return;
    }

  }

  /// Termine un appel vocal
  Future<void> _endVoiceCall() async {
    debugPrint('SessionProvider: Ending voice call');
    _cancelEndVoiceCallTimer();
    await _agoraService.leaveVoiceChannel();
  }

  /// Toggle haut-parleur
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      await _agoraService.setSpeakerphone(_isSpeakerOn);
      notifyListeners();
    } catch (e) {
      _setError('Erreur changement haut-parleur: $e');
    }
  }

  /// ========== PRIVATE: GESTION DES MESSAGES ==========
  /// Envoi du premier message
  Future<void> _sendFirstMessage(Slot slot) async {
    // if (_currentUserId == null || currentRoomId == null) {
    if (_currentUserId == null) {
      _setError('Session non initialisée');
    }

    final firstMessage = 'Bonjour $_currentUserName merci d\'avoir réservé un créneau de mentorat '
      'le ${AppDateUtils.formatDate(slot.startTime)} à ${AppDateUtils.formatTime(slot.startTime)}.\n'
      'Lors de cette première séance nous allons vous expliquer le fonctionnement du mentorat et '
      'comprendre vos attentes afin de vous choisir le mentor adapté à vos besoin In Sha Allah.\n'
      'Je suis à votre disposition à tout moment si vous avez des questions.\n'
      'Bonne journée.';
    
    // Créer le message
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: firstMessage,
      senderId: _currentUserId!,
      timestamp: DateTime.now(),
      isFromCoach: true,
    );

    try {
      debugPrint('SessionProvider: Sending message');

      // Ajouter à la liste et notifier
      _messages.add(message);
      notifyListeners();

      // Appel technique pur
      // await _agoraService.sendTextMessage(
      //   roomId: currentRoomId!,
      //   content: firstMessage,
      // );
    } catch (e) {
      // En cas d'erreur, retirer le message
      _messages.removeWhere((msg) => msg.id == message.id);
      notifyListeners();

      _setError('Échec envoi premier message: $e');
    }
  }

  /// Transformation multiple
  List<Message> _convertChatMessagesToBusinessMessages(List<ChatMessage> chatMessages) {
    return chatMessages
        .map(_convertChatMessageToBusinessMessage)
        .where((msg) => msg != null)
        .cast<Message>()
        .toList();
  }

  /// Transformations métier : ChatMessage → Message business
  Message? _convertChatMessageToBusinessMessage(ChatMessage chatMessage) {
    try {
      if (chatMessage.body is! ChatTextMessageBody) {
        return null;
      }
      
      final textBody = chatMessage.body as ChatTextMessageBody;
      final senderId = chatMessage.from ?? '';

      final isFromCoach = senderId == _currentSession?.coachId?.toLowerCase();
      
      return Message(
        id: chatMessage.msgId,
        text: textBody.content,
        senderId: senderId,
        timestamp: DateTime.fromMillisecondsSinceEpoch(chatMessage.serverTime),
        isFromCoach: isFromCoach,
      );
      
    } catch (e) {
      debugPrint('SessionProvider: Error converting message: $e');
      return null;
    }
  }

  /// Anti-doublons
  bool _isDuplicateMessage(Message message) {
    return _messages.any((existingMsg) => existingMsg.id == message.id);
  }

  /// Mapping état technique → état métier
  VoiceCallState _mapVoiceConnectionToCallState(VoiceConnectionState voiceState) {
    switch (voiceState) {
      case VoiceConnectionState.disconnected:
        return VoiceCallState.idle;
      case VoiceConnectionState.connecting:
        return VoiceCallState.calling;
      case VoiceConnectionState.connected:
        return VoiceCallState.connected;
    }
  }

  /// ========== PRIVATE: GESTION DES ETAT SESSION ==========
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
    debugPrint('SessionProvider: Status changed: ${_currentSession?.status}');
    _statusTimer?.cancel();
    
    if (_currentSession == null) return;
    if (_currentSession!.isInactive) return;
    
    final now = DateTime.now();
    Duration? nextTransition;
    String? nextStatus;
    
    // Calculer la prochaine transition et le nouveau status
    if (now.isBefore(_currentSession!.startTime!)) {
      nextTransition = _currentSession!.startTime!.difference(now);
      nextStatus = SessionStatus.inProgress;
    } else if (now.isBefore(_currentSession!.endTime!)) {
      nextTransition = _currentSession!.endTime!.difference(now);
      nextStatus = SessionStatus.completed;
    }
    
    if (nextTransition != null && nextStatus != null) {
      final timerDuration = nextTransition + Duration(seconds: 1);
      
      _statusTimer = Timer(timerDuration, () async {
        debugPrint('SessionProvider: Transition automatique vers: $nextStatus');

        // Si la session fini pendant un appel, laisse un délai supplémentaire de 5 minues
        if (nextStatus == SessionStatus.completed && isInVoiceCall) {
          debugPrint('SessionProvider: Fin de la session programmé dans ${AppConstants.voiceCallDelay}min');
          _endVoiceCallTimer = Timer(Duration(minutes: AppConstants.voiceCallDelay), () async {
          try {
            await _autoUpdateSessionStatus(nextStatus!);

            _isInitialized = false;
          } catch (e) {
            debugPrint('SessionProvider: Erreur dans la fin de session différé: $e');
          }
        });
        } else {
          await _autoUpdateSessionStatus(nextStatus!);
        }

        _startStatusTimer(); // Planifie la prochaine
      });
    }
  }

  /// Met à jour le statut de la session automatiquement
  Future<void> _autoUpdateSessionStatus(String newStatus) async {
    if (_currentSession == null) return;

    try {
      _currentSession = _currentSession!.copyWith(status: newStatus);

      await _sessionsService.updateSessionStatus(
        _currentSession!.id, 
        newStatus
      );
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
  
  /// ========== PRIVATE: CLEAN ET ERROR ==========
  /// Annule les modifications en cas d'erreur
  Future<void> _rollbackBooking(
    String? sessionId, 
    String? slotId
  ) async {
    try {
      // Supprimer la session créée
      if (sessionId != null) {
        await _sessionsService.deleteSession(sessionId);
        debugPrint('Session supprimée: $sessionId');

        // Supprimer le slot
        if (slotId != null) {
          await _slotsService.cancelBooking(slotId);
          debugPrint('Slot supprimé: $slotId');
        }

        // Supprime la session active
        await _usersService.clearCurrentSessionId();
        debugPrint('User CurrentSessionId clear');
      }
    } catch (e) {
      // Log mais ne pas lancer d'erreur pour éviter de masquer l'erreur originale
      debugPrint('Erreur rollback: $e');
    }
  }

  /// Gestion état loading/error
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    debugPrint('SessionProvider Error: $error');
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
    _isLoadingMessages = false;
    _isInitialized = false;
    _connectionState = RoomConnectionState.disconnected;
    _clearError();
    _setLoading(false);
    notifyListeners();
  }

  /// Nettoie les streams
  Future<void> _cleanup() async {
    _statusTimer?.cancel();
    await _activeSessionStream?.cancel();
    await _historyStream?.cancel();
    await _rawMessageStream?.cancel();
    await _voiceStateSream?.cancel();
    _cancelEndVoiceCallTimer();
    _activeSessionStream = null;
    _historyStream = null;
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

/// États de connexion de la room (métier)
enum RoomConnectionState {
  disconnected,
  connecting, 
  connected,
  error,
}
