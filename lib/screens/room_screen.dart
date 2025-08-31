import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/session_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/room/message_bubble.dart';
import '../widgets/room/voice_call_button.dart';
import '../widgets/room/message_input.dart';
import '../models/session.dart';
import '../../models/voice_call_state.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isFirstLoad = true;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Maintenir l'appel vocal même en arrière-plan
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        debugPrint('App going to background - voice call remains active');
        break;
      case AppLifecycleState.resumed:
        debugPrint('App resumed - voice call still active');
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(context),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Consumer<SessionProvider>(
          builder: (context, sessionProvider, child) {
            // Vérifier si une session est active
            if (sessionProvider.currentSession == null) {
              return const _NoSessionView();
            }

            // Auto-scroll vers le bas lors du premier chargement ou nouveaux messages
            final currentMessageCount = sessionProvider.messages.length;
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Premier chargement OU nouveau message reçu
              if ((_isFirstLoad && sessionProvider.messages.isNotEmpty) ||
                  (currentMessageCount > _previousMessageCount)) {
                _scrollToBottom();
                if (_isFirstLoad) _isFirstLoad = false;
              }
              _previousMessageCount = currentMessageCount; // Mise à jour du compteur
            });

            return Column(
              children: [
                // Indicateur de connexion
                _buildConnectionStatus(sessionProvider),

                // Zone des messages
                Expanded(
                  child: _buildMessagesArea(sessionProvider),
                ),

                // Bouton d'appel + champ de saisie
                _buildBottomSection(context, sessionProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  /// AppBar avec informations de la session
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: false,
      title: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          final session = sessionProvider.currentSession;
          
          if (session == null || session.status == SessionStatus.undefined) {
            return const Text('Salon');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mentor Coranique',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatSessionTime(session),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Indicateur du statut de la session
        Consumer<SessionProvider>(
          builder: (context, sessionProvider, child) {
            final session = sessionProvider.currentSession;
            if (session == null || session.status == SessionStatus.undefined) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(session.effectiveStatus),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              child: Text(
                _getStatusText(session.effectiveStatus),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Indicateur de l'état de connexion
  Widget _buildConnectionStatus(SessionProvider sessionProvider) {
    if (sessionProvider.connectionState == RoomConnectionState.connected) {
      return const SizedBox.shrink(); // Pas d'indicateur si tout va bien
    }

    Color backgroundColor;
    String message;
    IconData icon;

    switch (sessionProvider.connectionState) {
      case RoomConnectionState.connecting:
        backgroundColor = AppColors.accent;
        message = 'Connexion en cours...';
        icon = Icons.sync;
        break;
      case RoomConnectionState.error:
        backgroundColor = AppColors.error;
        message = 'Erreur de connexion';
        icon = Icons.error_outline;
        break;
      case RoomConnectionState.disconnected:
      default:
        backgroundColor = AppColors.noStatus;
        message = 'Non connecté';
        icon = Icons.cloud_off;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Zone d'affichage des messages
  Widget _buildMessagesArea(SessionProvider sessionProvider) {
    if (sessionProvider.isLoadingMessages && sessionProvider.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des messages...'),
          ],
        ),
      );
    }

    if (!sessionProvider.hasActiveSession()) {
      return const _NoSessionView();
    }

    if (sessionProvider.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.noStatus,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun message',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.noStatus,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Commencez la conversation !',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.noStatus,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sessionProvider.messages.length,
      itemBuilder: (context, index) {
        final message = sessionProvider.messages[index];
        final currentUserId = context.read<AuthProvider>().currentUserId;
        return MessageBubble(
          message: message,
          isFromCurrentUser: !message.isFromCoach,
          // isFromCurrentUser: message.senderId.toLowerCase() == currentUserId?.toLowerCase(),
        );
      },
    );
  }

  /// Section du bas (bouton appel + champ de saisie)
  Widget _buildBottomSection(BuildContext context, SessionProvider sessionProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: AppColors.boxShadow,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton d'appel vocal (visible uniquement si session en cours)
              if (sessionProvider.canMakeVoiceCalls) ...[
                VoiceCallButton(
                  state: sessionProvider.voiceCallState,
                  onPressed: _handleVoiceCallAction,
                  enabled: sessionProvider.voiceCallButtonEnabled,
                  isSpeakerOn: sessionProvider.isSpeakerOn,
                  onSpeakerToggle: () => sessionProvider.toggleSpeaker(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Champ de saisie des messages
              MessageInput(
                enabled: sessionProvider.canSendMessages,
                onSendMessage: (text) => _handleSendMessage(context, text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gère les actions du bouton d'appel vocal
  Future<void> _handleVoiceCallAction() async {
    final sessionProvider = context.read<SessionProvider>();
    
    if (sessionProvider.voiceCallState == VoiceCallState.connected) {
      // Raccrocher
      await sessionProvider.toggleVoiceCall();
    } else if (sessionProvider.voiceCallState == VoiceCallState.idle) {
      // Démarrer l'appel
      final success = await sessionProvider.toggleVoiceCall();
      
      if (!success && mounted) {
        _showErrorSnackBar('Impossible de démarrer l\'appel vocal');
      }
    }
  }

  /// Gère l'envoi d'un message
  Future<void> _handleSendMessage(BuildContext context, String text) async {
    final sessionProvider = context.read<SessionProvider>();
    
    final success = await sessionProvider.sendMessage(text);
    
    if (success) {
      // Auto-scroll vers le bas après envoi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else if (mounted) {
      _showErrorSnackBar('Impossible d\'envoyer le message');
    }
  }

  /// Scrolle automatiquement vers le bas de la liste
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Affiche un SnackBar d'erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.boxShadow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Formate l'heure de la session pour l'AppBar
  String _formatSessionTime(Session session) {
    if(session.status == SessionStatus.undefined) {
      return 'Heure inconnue';
    }
    final startTime = session.startTime;
    final endTime = session.endTime;

    return '${_formatTime(startTime!)} - ${_formatTime(endTime!)}';
  }

  /// Formate une heure au format HH:mm
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Obtient la couleur du statut de la session
  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return AppColors.primary;
      case 'inProgress':
        return AppColors.secondary;
      case 'completed':
        return AppColors.noStatus;
      default:
        return AppColors.accent;
    }
  }

  /// Obtient le texte du statut de la session
  String _getStatusText(String status) {
    switch (status) {
      case 'undefined':
        return 'Aucune session';
      case 'scheduled':
        return 'Programmée';
      case 'inProgress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      default:
        return 'Inconnue';
    }
  }
}

/// Vue affichée quand aucune session n'est active
class _NoSessionView extends StatelessWidget {
  const _NoSessionView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.textGrey,
          ),
          SizedBox(height: 16),
          Text(
            'Aucun mentor actif',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Réservez une session de mentorat pour accèder au salon',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
