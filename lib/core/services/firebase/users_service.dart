import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '/models/user.dart' as app_models;
import '../firebase_service.dart';

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
  Future<void> clearCurrentSessionId() async {
    try {
      validateCurrentUser();
      await firestore.collection(_collection).doc(currentUserId).update({
        'currentSessionId': null,
      });
    } catch (e) {
      throw handleFirestoreException(e, 'suppression ID de session');
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
