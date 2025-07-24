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
      validateSessionId(sessionId);
      
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

  /// Stream d'une session (pour updates temps réel)
  Stream<Session?> getSessionStream(String sessionId) {
    try {
      validateSessionId(sessionId);
      
      return firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        return Session.fromFirestore(doc);
      });
    } catch (e) {
      throw handleFirestoreException(e, 'stream de session');
    }
  }

  /// Récupère les sessions d'un utilisateur
  Stream<List<Session>> getUserSessions(String userId) {
    try {
      validateUserId(userId);
      
      return firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('startedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Session.fromFirestore(doc);
        }).toList();
      });
    } catch (e) {
      throw handleFirestoreException(e, 'récupération sessions utilisateur');
    }
  }

  /// Récupère la session active d'un utilisateur (scheduled ou active)
  Future<Session?> getUserActiveSession(String userId) async {
    try {
      final querySnapshot = await _getUserActiveSessionQuery(userId).get();
      
      return querySnapshot.docs.isEmpty 
          ? null 
          : Session.fromFirestore(querySnapshot.docs.first);
          
    } catch (e) {
      throw handleFirestoreException(e, 'récupération session active utilisateur');
    }
  }

  /// Stream de la session active d'un utilisateur  
  Stream<Session?> getUserActiveSessionStream(String userId) {
    try {
      return _getUserActiveSessionQuery(userId)
          .snapshots()
          .map((snapshot) => snapshot.docs.isEmpty 
              ? null 
              : Session.fromFirestore(snapshot.docs.first));
              
    } catch (e) {
      throw handleFirestoreException(e, 'stream session active utilisateur');
    }
  }

  /// Récupère uniquement le slotId d'une session spécifique
  Future<String?> getSessionSlotId(String sessionId) async {
    try {
      final sessionDoc = await firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) return null;

      // Récupère slotId ou null si absent
      return sessionDoc.data()?['slotId'] as String?;
      
    } catch (e) {
      throw handleFirestoreException(e, 'récupération slotId de la session');
    }
  }


  /// Met à jour le statut d'une session
  Future<void> updateSessionStatus(String sessionId, String newStatus) async {
    try {
      validateCurrentUser();
      validateSessionId(sessionId);
      
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

  /// Démarre une session (passe de scheduled à active)
  Future<void> startSession(String sessionId) async {
    try {
      validateCurrentUser();
      
      // Vérifier que la session existe et est programmée
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session introuvable');
      }
      
      if (!session.isScheduled) {
        throw Exception('La session ne peut pas être démarrée (statut: ${session.status})');
      }

      await updateSessionStatus(sessionId, SessionStatus.active);
    } catch (e) {
      throw handleFirestoreException(e, 'démarrage de session');
    }
  }

  /// Termine une session (passe à completed)
  Future<void> completeSession(String sessionId) async {
    try {
      validateCurrentUser();
      
      // Vérifier que la session existe et est active
      final session = await getSession(sessionId);
      if (session == null) {
        throw Exception('Session introuvable');
      }
      
      if (!session.isActive) {
        throw Exception('Seules les sessions actives peuvent être terminées');
      }

      // Nettoyer currentSessionId des participants
      await _cleanupUsersSessions(session);

      await updateSessionStatus(sessionId, SessionStatus.completed);
    } catch (e) {
      throw handleFirestoreException(e, 'fin de session');
    }
  }

  /// Supprime une session (pour annulations)
  Future<void> deleteSession(String sessionId) async {
    try {
      validateCurrentUser();
      validateSessionId(sessionId);
      
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
      validateSessionId(sessionId);
      
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
      validateSessionId(sessionId);
      
      return firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Message.fromFirestore(doc); // ✅ Assumons ce constructeur
        }).toList();
      });
    } catch (e) {
      throw handleFirestoreException(e, 'récupération messages');
    }
  }

  /// Query commune pour éviter la duplication
  Query<Map<String, dynamic>> _getUserActiveSessionQuery(String userId) {
    validateUserId(userId);
    
    return firestore
        .collection(_sessionsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [SessionStatus.scheduled, SessionStatus.active])
        .limit(1);
  }

  /// Vérifie si un statut est valide
  bool _isValidStatus(String status) {
    return [
      SessionStatus.scheduled,
      SessionStatus.active,
      SessionStatus.completed,
    ].contains(status);
  }

  /// Nettoie currentSessionId des utilisateurs participants
  Future<void> _cleanupUsersSessions(Session session) async {
    final batch = firestore.batch();
    
    // Nettoyer pour le client
    final clientRef = firestore.collection('users').doc(session.userId);
    batch.update(clientRef, {'currentSessionId': null});
    
    // Nettoyer pour le coach
    final coachRef = firestore.collection('users').doc(session.coachId);
    batch.update(coachRef, {'currentSessionId': null});
    
    await batch.commit();
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
  void validateSessionId(String sessionId) {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('ID de session requis');
    }
  }
}
