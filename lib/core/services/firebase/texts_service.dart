import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import '../../../models/text.dart';
import '../../../models/user_progress.dart';

class TextsService extends FirebaseService {
  static TextsService? _instance;
  
  // Singleton pattern comme les autres services
  static TextsService get instance {
    _instance ??= TextsService._();
    return _instance!;
  }
  
  TextsService._();

  // Collections refs
  CollectionReference get textsCollection => 
      firestore.collection('texts');
  
  CollectionReference textsProgressCollection(String userId) => 
      firestore.collection('users').doc(userId).collection('textsProgress');

  // LECTURE TEXTES
  
  /// Récupère tous les textes disponibles
  Future<List<ArabicText>> getAllTexts() async {
    try {
      final querySnapshot = await textsCollection
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ArabicText.fromFirestore(doc))
          .toList();
    } catch (e) {
      setError('Échec de récupération des textes: $e');
      return [];
    }
  }

  /// Stream de tous les textes pour mise à jour temps réel
  Stream<List<ArabicText>> watchTexts() {
    try {
      return textsCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ArabicText.fromFirestore(doc))
              .toList());
    } catch (e) {
      setError('Échec de récupération des textes en temps réel: $e');
      return Stream.value([]);
    }
  }

  /// Récupère un texte spécifique par son ID
  Future<ArabicText?> getTextById(String textId) async {
    try {
      final docSnapshot = await textsCollection.doc(textId).get();
      
      if (docSnapshot.exists) {
        return ArabicText.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      setError('Échec de récupération du texte par ID : $e');
      return null;
    }
  }

  // GESTION PROGRESSION UTILISATEUR

  /// Récupère la progression de l'utilisateur pour tous ses textes
  Future<List<UserProgress>> getUserProgress(String userId) async {
    try {
      final querySnapshot = await textsProgressCollection(userId)
          .orderBy('lastAccessedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      setError('Échec de récupération de la progression utilisateur: $e');
      return [];
    }
  }

  /// Stream de la progression utilisateur pour mise à jour temps réel
  Stream<List<UserProgress>> watchUserProgress(String userId) {
    try {
      return textsProgressCollection(userId)
          .orderBy('lastAccessedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UserProgress.fromFirestore(doc))
              .toList());
    } catch (e) {
      setError('Échec de récupération de la progression utilisateur en temps réel: $e');
      return Stream.value([]);
    }
  }

  /// Sauvegarde ou met à jour la progression d'un utilisateur sur un texte
  Future<void> saveProgress(
    String userId, 
    String textId, 
    int currentSegment, 
    String title
  ) async {
    try {
      final progressData = UserProgress(
        textId: textId,
        title: title,
        currentSegment: currentSegment,
        lastAccessedAt: DateTime.now(),
      );

      await textsProgressCollection(userId)
          .doc(textId)
          .set(progressData.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      setError('Échec de sauvegarde de la progression: $e');
      rethrow;
    }
  }

  /// Remet à zéro la progression d'un utilisateur sur un texte
  Future<void> resetProgress(String userId, String textId) async {
    try {
      final docRef = textsProgressCollection(userId).doc(textId);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        final currentData = docSnapshot.data() as Map<String, dynamic>;
        final resetData = {
          ...currentData,
          'currentSegment': 0,
          'lastAccessedAt': Timestamp.fromDate(DateTime.now()),
        };
        
        await docRef.update(resetData);
      }
    } catch (e) {
      setError('Échec de réinitialisation de la progression: $e');
      rethrow;
    }
  }

  /// Supprime complètement un texte du suivi utilisateur
  Future<void> removeFromProgress(String userId, String textId) async {
    try {
      await textsProgressCollection(userId).doc(textId).delete();
    } catch (e) {
      setError('Échec de suppression de la progression: $e');
      rethrow;
    }
  }

  // VALIDATION LIMITE 3 TEXTES

  /// Vérifie si l'utilisateur peut ajouter un nouveau texte (limite de 3)
  Future<bool> canAddNewText(String userId) async {
    try {
      final count = await getTrackedTextsCount(userId);
      return count < 3;
    } catch (e) {
      setError('Échec de vérification de la limite de textes: $e');
      return false;
    }
  }

  /// Compte le nombre de textes actuellement suivis par l'utilisateur
  Future<int> getTrackedTextsCount(String userId) async {
    try {
      final querySnapshot = await textsProgressCollection(userId).get();
      return querySnapshot.docs.length;
    } catch (e) {
      setError('Échec de récupération du nombre de textes suivis: $e');
      return 0;
    }
  }

  /// Méthode utilitaire pour obtenir les IDs des textes suivis
  Future<List<String>> getTrackedTextIds(String userId) async {
    try {
      final querySnapshot = await textsProgressCollection(userId).get();
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      setError('Échec de récupération des IDs des textes suivis: $e');
      return [];
    }
  }

  /// Méthode utilitaire pour vérifier si un texte est déjà suivi
  Future<bool> isTextTracked(String userId, String textId) async {
    try {
      final docSnapshot = await textsProgressCollection(userId).doc(textId).get();
      return docSnapshot.exists;
    } catch (e) {
      setError('Échec de vérification du suivi du texte: $e');
      return false;
    }
  }
}
