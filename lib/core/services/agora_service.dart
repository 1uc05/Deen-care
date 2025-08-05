import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_constants.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  // Clients Agora
  ChatClient? _chatClient;
  RtcEngine? _rtcEngine;
  
  // État technique
  bool _isChatInitialized = false;
  bool _isRtcInitialized = false;
  
  // Streams techniques purs
  final StreamController<ChatMessage> _rawMessageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<VoiceConnectionState> _voiceStateController =
      StreamController<VoiceConnectionState>.broadcast();
  
  VoiceConnectionState _voiceState = VoiceConnectionState.disconnected;

  // Getters publics
  Stream<ChatMessage> get rawMessageStream => _rawMessageController.stream;
  Stream<VoiceConnectionState> get voiceStateStream => _voiceStateController.stream;
  VoiceConnectionState get voiceState => _voiceState;
  bool get isChatInitialized => _isChatInitialized;
  bool get isRtcInitialized => _isRtcInitialized;

  /// Initialise le SDK Chat Agora
  Future<void> initializeChatSDK() async {
    if (_isChatInitialized) return;

    try {
      final options = ChatOptions(
        appKey: AppConstants.agoraAppKey,
        autoLogin: false,
      );
      
      _chatClient = ChatClient.getInstance;
      await _chatClient!.init(options);
      // await ChatClient.getInstance.startCallback();  //TODO: à valider, c'est indiqué dans la doc
      
      // Handler pour les messages entrants
      _chatClient!.chatManager.addEventHandler(
        'MAIN_HANDLER',
        ChatEventHandler(
          onMessagesReceived: (messages) {
            for (final msg in messages) {
              _rawMessageController.add(msg);
            }
          },
        ),
      );
      
      _isChatInitialized = true;
      debugPrint('AgoraService: Chat SDK initialized');
      
    } catch (e) {
      debugPrint('AgoraService: Failed to initialize Chat SDK: $e');
      rethrow;
    }
  }

  /// Initialise le moteur RTC Agora
  Future<void> initializeRtcEngine() async {
    if (_isRtcInitialized) return;

    try {
      _rtcEngine = createAgoraRtcEngine();
      await _rtcEngine!.initialize(RtcEngineContext(
        appId: AppConstants.agoraAppID,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      await _rtcEngine!.enableAudio();
      await _rtcEngine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      
      // Handler pour les événements RTC
      _rtcEngine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _updateVoiceState(VoiceConnectionState.connected);
        },
        onLeaveChannel: (connection, stats) {
          _updateVoiceState(VoiceConnectionState.disconnected);
        },
        onError: (err, msg) {
          debugPrint('AgoraService RTC Error: $err - $msg');
          _updateVoiceState(VoiceConnectionState.disconnected);
        },
      ));
      
      _isRtcInitialized = true;
      debugPrint('AgoraService: RTC Engine initialized');
      
    } catch (e) {
      debugPrint('AgoraService: Failed to initialize RTC Engine: $e');
      rethrow;
    }
  }

  /// Connexion utilisateur au Chat
  Future<void> loginUser(String userId, String token) async {
    if (!_isChatInitialized) {
      throw Exception('Chat SDK not initialized');
    }

    await logoutUser();
    
    final agoraUserId = userId.toLowerCase();
        
    try {
      await _chatClient!.loginWithToken(agoraUserId, token);
      debugPrint('AgoraService: User logged in: $agoraUserId');
      
    } on ChatError catch (e) {
      if (e.code == 200) {
        debugPrint('AgoraService: User already logged in: $agoraUserId');
        return;
      }
      throw Exception('Login failed: ${e.code} - ${e.description}');
    }
  }

  /// Déconnexion utilisateur
  Future<void> logoutUser() async {
    if (!_isChatInitialized || _chatClient == null) return;

    try {
      await _chatClient!.logout();
      debugPrint('AgoraService: User logged out');
      
    } catch (e) {
      debugPrint('AgoraService: Logout error: $e');
    }
  }

  /// Crée une room de chat
  Future<String> createChatGroup(String coachId) async {
    if (!_isChatInitialized) {
      throw Exception('Chat SDK not initialized');
    }

    try {
      // TODO: à optimiser
      final name = 'Group_${DateTime.now().millisecondsSinceEpoch}';
      final description = 'Group created at ${DateTime.now()}';
      // final List<String> listMember = [coachId];
      final List<String> listMember = [];

      final group = await _chatClient!.groupManager.createGroup(
        groupName: name,
        desc: description,
        inviteMembers: listMember, // Liste des membres à inviter
        inviteReason: 'Coach',
        options: ChatGroupOptions(
          style: ChatGroupStyle.PrivateOnlyOwnerInvite,
          maxCount: 2,
          inviteNeedConfirm: false,
          ext: ''
        ),
      );
      
      debugPrint('AgoraService: Group created: ${group.groupId}');
      return group.groupId;
      
    } on ChatError catch (e) {
      throw Exception('Group creation failed: ${e.code} - ${e.description}');
    }
  }

  /// Rejoint une room de chat
  Future<void> joinChatGroup(String roomId) async {
    if (!_isChatInitialized) {
      throw Exception('Chat SDK not initialized');
    }

    try {
      // Vérifier si on est déjà membre du groupe
      final groups = await _chatClient!.groupManager.getJoinedGroups();
      final isAlreadyMember = groups.any((group) => group.groupId == roomId);
      
      if (isAlreadyMember) {
        debugPrint('AgoraService: Already member of group: $roomId');
        return;
      }

      await _chatClient!.groupManager.joinPublicGroup(roomId);
      debugPrint('AgoraService: Joined chat room: $roomId');
      
    } on ChatError catch (e) {
      throw Exception('Failed to join group: ${e.code} - ${e.description}');
    }
  }

  /// Quitte une room de chat
  Future<void> leaveChatRoom(String roomId) async {
    if (!_isChatInitialized) return;

    try {
      await _chatClient!.chatRoomManager.leaveChatRoom(roomId);
      debugPrint('AgoraService: Left chat room: $roomId');
      
    } catch (e) {
      debugPrint('AgoraService: Failed to leave room: $e');
    }
  }

  /// Supprime une room de chat
  Future<void> deleteChatRoom(String roomId) async {
    if (!_isChatInitialized) {
      throw Exception('Chat SDK not initialized');
    }

    try {
      await _chatClient!.chatRoomManager.destroyChatRoom(roomId);
      debugPrint('AgoraService: Room deleted: $roomId');
      
    } on ChatError catch (e) {
      throw Exception('Room deletion failed: ${e.code} - ${e.description}');
    }
  }

  /// Envoie un message texte brut
  Future<void> sendTextMessage({
    required String roomId,
    required String content,
  }) async {
    if (!_isChatInitialized) {
      throw Exception('Chat SDK not initialized');
    }

    try {
      final message = ChatMessage.createTxtSendMessage(
        targetId: roomId,
        content: content,
      );
      message.chatType = ChatType.GroupChat;

      await _chatClient!.chatManager.sendMessage(message);
      debugPrint('AgoraService: Message sent to $roomId');
      
    } on ChatError catch (e) {
      throw Exception('Message send failed: ${e.code} - ${e.description}');
    }
  }

  /// Récupère l'historique des messages
  Future<List<ChatMessage>> fetchMessageHistory({
    required String conversationId,
    int limit = 50,
    String? startMessageId,
  }) async {
    if (!_isChatInitialized) {
      throw Exception('Chat SDK not initialized');
    }

    try {
      final result = await _chatClient!.chatManager.fetchHistoryMessagesByOption(
        conversationId,
        ChatConversationType.GroupChat,
      );

      debugPrint('AgoraService: Fetched ${result.data.length} messages');
      return result.data;
      
    } on ChatError catch (e) {
      throw Exception('History fetch failed: ${e.code} - ${e.description}');
    }
  }

  /// Rejoint un canal vocal RTC
  Future<void> joinVoiceChannel({
    required String channelId,
    String? token,
    int uid = 0,
  }) async {
    if (!_isRtcInitialized) {
      throw Exception('RTC Engine not initialized');
    }

    if (_voiceState == VoiceConnectionState.connecting || 
        _voiceState == VoiceConnectionState.connected) {
      throw Exception('Already in voice channel');
    }

    try {
      // Vérifier la permission microphone
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        throw Exception('Microphone permission required');
      }

      _updateVoiceState(VoiceConnectionState.connecting);

      await _rtcEngine!.joinChannel(
        token: token ?? '',
        channelId: channelId,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      
      debugPrint('AgoraService: Joining voice channel: $channelId');
      
    } catch (e) {
      _updateVoiceState(VoiceConnectionState.disconnected);
      debugPrint('AgoraService: Failed to join voice channel: $e');
      rethrow;
    }
  }

  /// Quitte le canal vocal RTC
  Future<void> leaveVoiceChannel() async {
    if (!_isRtcInitialized || _voiceState == VoiceConnectionState.disconnected) {
      return;
    }

    try {
      await _rtcEngine!.leaveChannel();
      debugPrint('AgoraService: Left voice channel');
      
    } catch (e) {
      _updateVoiceState(VoiceConnectionState.disconnected);
      debugPrint('AgoraService: Failed to leave voice channel: $e');
    }
  }

  /// Met à jour l'état vocal et notifie les listeners
  void _updateVoiceState(VoiceConnectionState newState) {
    if (_voiceState != newState) {
      _voiceState = newState;
      _voiceStateController.add(newState);
    }
  }

  /// Nettoyage complet du service
  Future<void> dispose() async {
    try {
      // Fermer les streams
      await _rawMessageController.close();
      await _voiceStateController.close();

      // Nettoyer Chat SDK
      if (_chatClient != null) {
        await logoutUser();
        _chatClient!.chatManager.removeEventHandler('MAIN_HANDLER');
        _chatClient = null;
      }

      // Nettoyer RTC Engine
      if (_rtcEngine != null) {
        await _rtcEngine!.leaveChannel();
        await _rtcEngine!.release();
        _rtcEngine = null;
      }

      _isChatInitialized = false;
      _isRtcInitialized = false;
      _voiceState = VoiceConnectionState.disconnected;
      
      debugPrint('AgoraService: Disposed completely');
      
    } catch (e) {
      debugPrint('AgoraService: Error during disposal: $e');
    }
  }
}

/// États de connexion vocale
enum VoiceConnectionState {
  disconnected,
  connecting,
  connected,
}
