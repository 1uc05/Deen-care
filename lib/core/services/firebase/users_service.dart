import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '/models/user.dart' as app_models;
import '../../../models/text_progress.dart';
import '../../../models/arabic_text.dart';
import '../firebase_service.dart';
import '../../constants/app_constants.dart';

class UsersService extends FirebaseService {
  static final UsersService _instance = UsersService._internal();
  factory UsersService() => _instance;
  UsersService._internal();

  static const String _collection = 'users';

  // Getters spécifiques
  Stream<firebase_auth.User?> get authStateChanges => auth.authStateChanges();

  /// Inscription avec email/password
  Future<app_models.User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('Échec de création du compte');

      await firebaseUser.updateDisplayName(name);

      final user = app_models.User(
        id: firebaseUser.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        role: app_models.UserRole.client, // Par défaut, rôle client
      );

      await firestore
          .collection(_collection)
          .doc(firebaseUser.uid)
          .set(user.toJson());

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw handleFirestoreException(e, 'inscription');
    }
  }

  /// Connexion avec email/password
  Future<app_models.User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('Échec de connexion');

      final userDoc = await firestore
          .collection(_collection)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Données utilisateur introuvables');
      }

      return app_models.User.fromJson({
        ...userDoc.data()!,
        'id': firebaseUser.uid,
      });
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw handleFirestoreException(e, 'connexion');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      throw handleFirestoreException(e, 'déconnexion');
    }
  }

  /// Récupération de l'utilisateur actuel depuis Firestore
  Future<app_models.User?> getCurrentUser() async {
    try {
      final firebaseUser = currentUser;
      if (firebaseUser == null) return null;

      final userDoc = await firestore
          .collection(_collection)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) return null;

      return app_models.User.fromJson({
        ...userDoc.data()!,
        'id': firebaseUser.uid,
      });
    } catch (e) {
      throw handleFirestoreException(e, 'récupération utilisateur');
    }
  }

  /// Récupération de l'utilisateur actuel depuis Firestore
  Future<String?> getCurrentSessionId() async {
    try {
      final firebaseUser = currentUser;
      if (firebaseUser == null) return null;

      final userDoc = await firestore
          .collection(_collection)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      return userData['currentSessionId'] as String?;
      
    } catch (e) {
      throw handleFirestoreException(e, 'récupération session ID');
    }
  }

  /// Mise à jour des données utilisateur
  Future<void> updateUser(app_models.User user) async {
    try {
      validateUserId(user.id);
      await firestore
          .collection(_collection)
          .doc(user.id)
          .update(user.toJson());
    } catch (e) {
      throw handleFirestoreException(e, 'mise à jour utilisateur');
    }
  }

  /// Mise à jour de l'ID de session actuelle de l'utilisateur
  Future<void> updateCurrentSessionId(String sessionId) async {
    try {
      validateCurrentUser();
      await firestore.collection(_collection).doc(currentUserId).update({
        'currentSessionId': sessionId,
      });
    } catch (e) {
      throw handleFirestoreException(e, 'mise à jour ID de session');
    }
  }

  /// Supprime la session en cours de l'utilisateur
  Future<String?> clearCurrentSessionId() async {
    try {
      validateCurrentUser();
      await firestore.collection(_collection).doc(currentUserId).update({
        'currentSessionId': null,
      });

      // Retourne l'ancien ID de session
      return await getCurrentSessionId();
    } catch (e) {
      throw handleFirestoreException(e, 'suppression ID de session');
    }
  }

  // GESTION TEXTS
  /// Récupère la progression de l'utilisateur (max 3 éléments)
  Future<List<TextProgress>> getUserProgress() async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .doc(currentUserId)
          .collection('textsProgress')
          .orderBy('lastAccessedAt', descending: true)
          .limit(AppConstants.maxTrackedTexts)
          .get();
          
      return snapshot.docs
          .map((doc) => TextProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      setError('Erreur lors du chargement de la progression: $e');
      return [];
    }
  }

  /// Ajoute un texte au suivi de l'utilisateur (vérification limite 3)
  Future<void> addTextToProgress(String textId) async {
    try {
      // Vérification de la limite côté service
      final currentProgressSnapshot = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('textsProgress')
          .get();

      if (currentProgressSnapshot.docs.length >= 3) {
        setError('Vous ne pouvez suivre que 3 textes maximum');
        throw Exception('Limite de 3 textes atteinte');
      }

      // Vérifier si le texte n'est pas déjà suivi
      final existingDoc = await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('textsProgress')
          .doc(textId)
          .get();

      if (existingDoc.exists) {
        setError('Ce texte est déjà dans votre suivi');
        throw Exception('Texte déjà suivi');
      }

      // Ajouter le nouveau texte avec progression à 0
      final newProgress = TextProgress(
        textId: textId,
        currentSentence: 0,
        lastAccessedAt: DateTime.now(),
      );

      await firestore
          .collection(_collection)
          .doc(currentUserId)
          .collection('textsProgress')
          .doc(textId)
          .set(newProgress.toFirestore());
    } catch (e) {
      if (e.toString().contains('Limite de 3 textes atteinte') || 
          e.toString().contains('Texte déjà suivi')) {
        rethrow;
      }
      setError('Erreur lors de l\'ajout du texte: $e');
      rethrow;
    }
  }

  /// Retire un texte du suivi de l'utilisateur
  Future<void> removeTextFromProgress(String textId) async {
    try {
      await firestore
          .collection(_collection)
          .doc(currentUserId)
          .collection('textsProgress')
          .doc(textId)
          .delete();
    } catch (e) {
      setError('Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// Sauvegarde ou met à jour la progression d'un texte
  Future<void> saveProgress(String textId, int currentSentence) async {
    try {
      final updatedProgress = TextProgress(
        textId: textId,
        currentSentence: currentSentence,
        lastAccessedAt: DateTime.now(),
      );

      await firestore
          .collection(_collection)
          .doc(currentUserId)
          .collection('textsProgress')
          .doc(textId)
          .set(updatedProgress.toFirestore());
    } catch (e) {
      setError('Erreur lors de la sauvegarde: $e');
      rethrow;
    }
  }

  /// Remet à zéro la progression d'un texte spécifique
  Future<void> resetTextProgress(String textId) async {
    try {
      final progressRef = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('textsProgress')
          .doc(textId);

      final doc = await progressRef.get();
      if (!doc.exists) {
        setError('Progression non trouvée pour ce texte');
        throw Exception('Progression non trouvée');
      }

      final currentProgress = TextProgress.fromFirestore(doc);
      final resetProgress = currentProgress.copyWith(
        currentSentence: 0,
        lastAccessedAt: DateTime.now(),
      );

      await progressRef.set(resetProgress.toFirestore());
    } catch (e) {
      if (e.toString().contains('Progression non trouvée')) {
        rethrow;
      }
      setError('Erreur lors de la remise à zéro: $e');
      rethrow;
    }
  }

  /// Gestion des erreurs Firebase Auth (spécifique aux users)
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cette adresse email';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cette adresse email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'operation-not-allowed':
        return 'Connexion par email/mot de passe désactivée';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}
