import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    // Couleurs selon qui parle
    final isCoach = message.isFromCoach;
    final primaryColor = Theme.of(context).primaryColor;
    
    // Couleur différence coach/client
    final backgroundColor = isCoach 
        ? const Color(0xFF2196F3)      // Bleu pour coach
        : const Color(0xFF4CAF50);     // Vert pour client
    
    // Couleur si c'est le message de l'utilisateur actuel
    final actualBackgroundColor = isFromCurrentUser
        ? primaryColor                  // Couleur du thème si c'est nous
        : backgroundColor;
    
    final textColor = Colors.white;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar côté gauche (messages des autres)
          if (!isFromCurrentUser) ...[
            _buildAvatar(isCoach),
            const SizedBox(width: 8),
          ],
          
          // Bulle de message
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                // Nom de l'expéditeur (seulement pour les autres)
                if (!isFromCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 12),
                    child: Text(
                      isCoach ? 'Coach' : 'Client',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                // Bulle avec le message
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                    minWidth: 60,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: actualBackgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isFromCurrentUser ? 16 : 4),
                      bottomRight: Radius.circular(isFromCurrentUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Texte du message
                      Text(
                        message.text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Timestamp
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Avatar côté droit (nos messages)
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(isCoach),
          ],
        ],
      ),
    );
  }

  /// Construit l'avatar de l'expéditeur
  Widget _buildAvatar(bool isCoach) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCoach ? Colors.blue[100] : Colors.green[100],
        shape: BoxShape.circle,
        border: Border.all(
          color: isCoach ? Colors.blue[300]! : Colors.green[300]!,
          width: 1,
        ),
      ),
      child: Icon(
        isCoach ? Icons.person : Icons.person_outline,
        size: 18,
        color: isCoach ? Colors.blue[700] : Colors.green[700],
      ),
    );
  }

  /// Formate le timestamp du message
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDate == today) {
      // Aujourd'hui : afficher seulement l'heure
      return DateFormat('HH:mm').format(timestamp);
    } else {
      // Autre jour : afficher date + heure
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }
}
