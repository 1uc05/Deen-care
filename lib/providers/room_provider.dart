import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import '../models/session.dart';
import '../models/message.dart';
import '../core/services/agora_service.dart';
import '../core/services/firebase/sessions_service.dart';
import '../models/voice_call_state.dart';

class TMPP_RoomProvider extends ChangeNotifier {
  final AgoraService _agoraService = AgoraService();
  final SessionsService _sessionsService = SessionsService();
  
  // État métier
  Session? _currentSession;
  String? _currentUserId;
  List<Message> _messages = [];
  RoomConnectionState _connectionState = RoomConnectionState.disconnected;
  VoiceCallState _voiceCallState = VoiceCallState.idle;
  bool _isLoadingMessages = false;
  bool _isInitialized     = false;
  String? _error;
  
  // Subscriptions aux streams techniques
  StreamSubscription<ChatMessage>? _rawMessageSubscription;
  StreamSubscription<VoiceConnectionState>? _voiceStateSubscription;
  StreamSubscription<Session?>? _activeSessionSubscription;

  // Getters publics
  Session? get currentSession => _currentSession;
  String? get currentUserId => _currentUserId;
  List<Message> get messages => List.unmodifiable(_messages);
  RoomConnectionState get connectionState => _connectionState;
  VoiceCallState get voiceCallState => _voiceCallState;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;
  
  // Logique métier - Règles de validation
  bool get canSendMessages => _connectionState == RoomConnectionState.connected &&
                              (_currentSession?.isScheduled == true || 
                               _currentSession?.isInProgress == true);
  
  bool get canMakeVoiceCalls => _connectionState == RoomConnectionState.connected &&
                                _currentSession?.isInProgress == true;
  
  bool get isInVoiceCall => _voiceCallState == VoiceCallState.connected;
  
  String? get currentRoomId => _currentSession?.agoraChannelId;
  
  bool get hasActiveSession => _currentSession != null;
  
  // Identification utilisateur métier
  bool get isCoach => _currentUserId != null && 
                     _currentSession != null && 
                     _currentUserId == _currentSession!.coachId;
  
  bool get isClient => _currentUserId != null && 
                      _currentSession != null && 
                      _currentUserId == _currentSession!.userId;

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

  /// Initialise les streams pour un utilisateur
  Future<void> initialize(String userId, Session? currentSession) async {
    debugPrint('RoomProvider: Initialisation...');
    
    _currentSession = currentSession;
    _currentUserId = userId;
    
    _clearError();

    // S'il n'y a pas de session active, fin l'iniialisation
    if (_currentSession == null) return;
    if (!_currentSession!.isActive) return;

    try {
      // Initialize AgoraService and start
      await _activateSession(_currentSession!);

        // Écouter les changements temps réel
      _listenCurrentSession();

      _isInitialized = true;
    } catch (e) {
      _setError('RoomProvider: Échec d\'inittialisaion: $e');
    }
  }

  /// Charge la session et écoute les changements de la session active
  void _listenCurrentSession() {
    _activeSessionSubscription = _sessionsService
        .getActiveSessionStream()
        .listen(
      (session) async {
        await _handleSessionChange(_currentSession, session);
        _currentSession = session;
      },
      onError: (e) => _setError('Erreur stream session active: $e'),
    );
  }
  
  Future<void> _handleSessionChange(Session? previous, Session? current) async {
    // Session fermée/supprimée
    if (previous != null && current == null) {
      await _cleanupSession(previous);
      return;
    }
    
    // Nouvelle session ou changement de statut
    if (current != null) {
      final statusChanged = previous?.status != current.status;
      
      if (statusChanged) {
        if (current.isActive) {
          await _activateSession(current);
        } else {
          await _cleanupSession(current);
        }
      }
    }
  }

  Future<void> _activateSession(Session session) async {
    debugPrint('RoomProvider: Start activation session: ${session.status} - RoomId: ${session.agoraChannelId}');
    try {
      _connectionState = RoomConnectionState.connecting;
      notifyListeners();

      if (session.isScheduled) {
        await _agoraService.initializeChatSDK();
      }

      if (session.isInProgress) {
        await _agoraService.initializeRtcEngine();
      }

      if(!_isInitialized) {
        // Authentifier l'utilisateur
        await _agoraService.loginUser(_currentUserId!);

        // Rejoindre la room
        await _agoraService.joinChatGroup(session.agoraChannelId);

        // Initialiser les streams
        _initializeStreams();

        // Charger l'historique
        await loadMessages();
      }

      _connectionState = RoomConnectionState.connected;
      
    } catch (e) {
      _connectionState = RoomConnectionState.error;
      _setError('Échec d\'activation session: $e');
    }
    
    notifyListeners();
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

    try {
      debugPrint('RoomProvider: Sending message - Length: ${trimmedText.length}');
      debugPrint('Message: $text');
      
      // Appel technique pur
      await _agoraService.sendTextMessage(
        roomId: currentRoomId!,
        content: trimmedText,
      );
      
      debugPrint('RoomProvider: Message sent successfully');
      return true;
      
    } catch (e) {
      _setError('Échec envoi message: $e');
      return false;
    }
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

  /// Chargement historique des messages avec logique métier
  Future<void> loadMessages() async {
    if (_currentSession?.agoraChannelId == null) {
      debugPrint('RoomProvider: No room ID for loading messages');
      return;
    }

    if (_isLoadingMessages) {
      return; // Éviter les appels multiples
    }

    try {
      _setLoading(true);
      
      debugPrint('RoomProvider: Loading message history');
      
      // Appel technique
      final chatMessages = await _agoraService.fetchMessageHistory(
        conversationId: _currentSession!.agoraChannelId,
        limit: 50,
      );
      
      // Transformation métier
      final messages = _convertChatMessagesToBusinessMessages(chatMessages);
      
      // Mise à jour état métier
      _messages.clear();
      _messages.addAll(messages);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      debugPrint('RoomProvider: Loaded ${messages.length} messages');
      
    } catch (e) {
      _setError('Erreur chargement historique: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Nettoyage session précédente
  Future<void> _cleanupSession(Session session) async {
    try {
      debugPrint('RoomProvider: Cleaning up session ${session.id}');
      
      // Arrêter les streams
      await _rawMessageSubscription?.cancel();
      await _voiceStateSubscription?.cancel();
      
      // Quitter les canaux
      await _agoraService.leaveChatRoom(session.agoraChannelId);
      await _agoraService.leaveVoiceChannel();
      
      // Réinitialiser l'état
      _messages.clear();
      _voiceCallState = VoiceCallState.idle;
      _connectionState = RoomConnectionState.disconnected;
      
    } catch (e) {
      debugPrint('RoomProvider: Error cleaning up session: $e');
    }
  }

  /// Initialise les streams techniques
  void _initializeStreams() {
    // Stream des messages bruts → Transformation métier
    _rawMessageSubscription = _agoraService.rawMessageStream.listen(
      _handleRawMessage,
      onError: (error) => _setError('Erreur stream messages: $error'),
    );
    
    // Stream états vocaux → Transformation métier
    _voiceStateSubscription = _agoraService.voiceStateStream.listen(
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
        
        debugPrint('RoomProvider: New message received from ${message.senderId}');
        notifyListeners();
      }
      
    } catch (e) {
      debugPrint('RoomProvider: Error processing message: $e');
    }
  }

  /// Traitement changement état vocal
  void _handleVoiceStateChange(VoiceConnectionState voiceState) {
    final newCallState = _mapVoiceConnectionToCallState(voiceState);
    
    if (_voiceCallState != newCallState) {
      debugPrint('RoomProvider: Voice state changed: $_voiceCallState → $newCallState');
      _voiceCallState = newCallState;
      notifyListeners();
    }
  }

  /// Démarre un appel vocal
  Future<void> _startVoiceCall() async {
    debugPrint('RoomProvider: Starting voice call');
    _voiceCallState = VoiceCallState.calling;
    notifyListeners();
    
    await _agoraService.joinVoiceChannel(
      channelId: currentRoomId!,
    );
  }

  /// Termine un appel vocal
  Future<void> _endVoiceCall() async {
    debugPrint('RoomProvider: Ending voice call');
    await _agoraService.leaveVoiceChannel();
  }

  /// Transformations métier : ChatMessage → Message business
  Message? _convertChatMessageToBusinessMessage(ChatMessage chatMessage) {
    try {
      if (chatMessage.body is! ChatTextMessageBody) {
        return null;
      }
      
      final textBody = chatMessage.body as ChatTextMessageBody;
      final senderId = chatMessage.from ?? '';
      
      return Message(
        id: chatMessage.msgId,
        text: textBody.content,
        senderId: senderId,
        timestamp: DateTime.fromMillisecondsSinceEpoch(chatMessage.serverTime),
        isFromCoach: _isMessageFromCoach(senderId),
      );
      
    } catch (e) {
      debugPrint('RoomProvider: Error converting message: $e');
      return null;
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

  /// Logique métier : Vérification si message du coach
  bool _isMessageFromCoach(String senderId) {
    return _currentSession?.coachId != null && 
           senderId == _currentSession!.coachId;
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

  /// Gestion d'état et erreurs
  void _setLoading(bool loading) {
    _isLoadingMessages = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    debugPrint('RoomProvider Error: $error');
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }

  /// Remise à zéro complète
  Future<void> reset() async {
    debugPrint('RoomProvider: Full reset');
    
    await _cleanupSession(_currentSession!);
    
    _currentUserId = null;
    _currentSession = null;
    _connectionState = RoomConnectionState.disconnected;
    _clearError();
    _setLoading(false);
    
    notifyListeners();
  }

  /// Nettoyage final
  @override
  Future<void> dispose() async {
    debugPrint('RoomProvider: Disposing');
    
    await _rawMessageSubscription?.cancel();
    await _voiceStateSubscription?.cancel();
    await _activeSessionSubscription?.cancel();
    
    // Note: On ne dispose pas AgoraService car c'est un singleton
    // utilisé potentiellement par d'autres providers
    
    super.dispose();
  }

  @override
  String toString() {
    return 'RoomProvider(session: ${_currentSession?.id}, userId: $_currentUserId, '
           'messages: ${_messages.length}, state: $_connectionState)';
  }
}

/// États de connexion de la room (métier)
enum RoomConnectionState {
  disconnected,
  connecting, 
  connected,
  error,
}
