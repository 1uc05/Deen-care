import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

abstract class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Accès protégé aux instances Firebase
  FirebaseFirestore get firestore => _firestore;
  firebase_auth.FirebaseAuth get auth => _auth;

  // Getter pour l'utilisateur actuel
  firebase_auth.User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Gestion centralisée des erreurs Firestore
  Exception handleFirestoreException(dynamic e, String operation) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return Exception('Accès refusé pour $operation');
        case 'unavailable':
          return Exception('Service temporairement indisponible');
        case 'cancelled':
          return Exception('Opération annulée');
        case 'deadline-exceeded':
          return Exception('Délai d\'attente dépassé');
        default:
          return Exception('Erreur Firestore ($operation): ${e.message}');
      }
    }
    debugPrint('Erreur lors de $operation: $e');
    return Exception('Erreur lors de $operation: $e');
  }

  void setError(String error) {
    debugPrint(error);
    throw Exception(error);
  }
  

  // Validation communes
  void validateUserId(String? userId) {
    if (userId == null || userId.isEmpty) {
      throw Exception('ID utilisateur requis');
    }
  }

  void validateCurrentUser() {
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }
  }
}
