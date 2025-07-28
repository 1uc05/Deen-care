import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import '../../../models/session.dart';
import '../../../models/message.dart';

class SessionsService extends FirebaseService {
  static final SessionsService _instance = SessionsService._internal();
  factory SessionsService() => _instance;
  SessionsService._internal();

  static const String _sessionsCollection = 'sessions';
  static const String _messagesCollection = 'messages';

  /// Crée une nouvelle session
  Future<String> createSession(Session session) async {
    try {
      validateCurrentUser();
      
      final docRef = await firestore
          .collection(_sessionsCollection)
          .add(session.toMap());
      
      return docRef.id;
    } catch (e) {
      throw handleFirestoreException(e, 'création de session');
    }
  }

  /// Récupère une session par ID
  Future<Session?> getSession(String sessionId) async {
    try {
      validateCurrentUser();
      _validateSessionId(sessionId);
      
      final doc = await firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (!doc.exists) return null;
      
      return Session.fromFirestore(doc);
    } catch (e) {
      throw handleFirestoreException(e, 'récupération de session');
    }
  }

  /// Récupère les sessions d'un utilisateur
  Future<List<Session>> getUserSessions() async {
    try {
      validateCurrentUser();

      final snapshot = await firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: currentUserId)
          .orderBy('startedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return Session.fromFirestore(doc);
      }).toList();
      
    } catch (e) {
      throw handleFirestoreException(e, 'récupération sessions utilisateur');
    }
  }

  /// Stream de la session active d'un utilisateur  
  Stream<Session?> getUserActiveSessionStream() {
    try {
      validateCurrentUser();
      return _getUserActiveSessionQuery()
          .snapshots()
          .map((snapshot) => snapshot.docs.isEmpty 
              ? null 
              : Session.fromFirestore(snapshot.docs.first));
              
    } catch (e) {
      throw handleFirestoreException(e, 'stream session active utilisateur');
    }
  }

  /// Met à jour le statut d'une session
  Future<void> updateSessionStatus(String sessionId, String newStatus) async {
    try {
      validateCurrentUser();
      _validateSessionId(sessionId);
      
      // Vérifier que le statut est valide
      if (!_isValidStatus(newStatus)) {
        throw ArgumentError('Statut de session invalide: $newStatus');
      }

      await firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .update({
        'status': newStatus,
      });
    } catch (e) {
      throw handleFirestoreException(e, 'mise à jour statut session');
    }
  }

  /// Supprime une session (pour annulations)
  Future<void> deleteSession(String sessionId) async {
    try {
      validateCurrentUser();
      _validateSessionId(sessionId);
      
      // Supprimer tous les messages de la session
      await _deleteSessionMessages(sessionId);
      
      // Supprimer la session
      await firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .delete();
    } catch (e) {
      throw handleFirestoreException(e, 'suppression de session');
    }
  }

  /// Ajoute un message à une session
  Future<void> addMessage(String sessionId, {
    required String text,
    required String senderId,
  }) async {
    try {
      validateCurrentUser();
      _validateSessionId(sessionId);
      
      if (text.trim().isEmpty) {
        throw ArgumentError('Le message ne peut pas être vide');
      }

      await firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_messagesCollection)
          .add({
        'text': text.trim(),
        'senderId': senderId,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      throw handleFirestoreException(e, 'envoi de message');
    }
  }

  /// Stream des messages d'une session
  Stream<List<Message>> getSessionMessages(String sessionId) {
    try {
      _validateSessionId(sessionId);
      
      return firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Message.fromFirestore(doc);
        }).toList();
      });
    } catch (e) {
      throw handleFirestoreException(e, 'récupération messages');
    }
  }

  /// Query commune pour éviter la duplication
  Query<Map<String, dynamic>> _getUserActiveSessionQuery() {
    try {
      validateCurrentUser();

      return firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: currentUserId)
          .where('status', whereIn: [SessionStatus.scheduled, SessionStatus.inProgress])
          .limit(1);
    } catch (e) {
      throw handleFirestoreException(e, 'query session active utilisateur');
    }
  }

  /// Vérifie si un statut est valide
  bool _isValidStatus(String status) {
    return [
      SessionStatus.scheduled,
      SessionStatus.inProgress,
      SessionStatus.completed,
    ].contains(status);
  }

  /// Supprime tous les messages d'une session
  Future<void> _deleteSessionMessages(String sessionId) async {
    final messagesQuery = await firestore
        .collection(_sessionsCollection)
        .doc(sessionId)
        .collection(_messagesCollection)
        .get();

    final batch = firestore.batch();
    for (final doc in messagesQuery.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Validation spécifique session
  void _validateSessionId(String sessionId) {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('ID de session requis');
    }
  }
}
