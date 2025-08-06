import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseTools {
  static final _firestore = FirebaseFirestore.instance;

  /// Vide une collection spécifiée
  /// [collectionName] : 'users', 'sessions', 'slots', etc.
  static Future<void> clearCollection(String collectionName) async {
    if (collectionName != 'users' && collectionName != 'sessions' && collectionName != 'slots') {
      debugPrint('Base de données inexistante');
      return;
    }
    
    try {
      final collection = _firestore.collection(collectionName);
      final snapshot = await collection.get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ Collection "$collectionName" déjà vide');
        return;
      }

      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('✅ Collection "$collectionName" vidée (${snapshot.docs.length} documents supprimés)');
      
    } catch (e) {
      debugPrint('❌ Erreur lors du vidage de "$collectionName": $e');
      rethrow;
    }
  }

  /// Crée 3 slots de test avec des heures pile/demi et durée 30min
  static Future<void> createTestSlots() async {
    try {
      final now = Timestamp.now();
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final dayAfter = DateTime.now().add(Duration(days: 2));
      
      final slots = [
        // Demain 14h00-14h30
        {
          'startTime': Timestamp.fromDate(
            DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0)
          ),
          'endTime': Timestamp.fromDate(
            DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 30)
          ),
          'status': 'available',
          'reservedBy': null,
          'createdBy': 'admin',
          'sessionId': null,
          'createdAt': now,
          'reservedAt': null,
        },
        // Demain 16h30-17h00
        {
          'startTime': Timestamp.fromDate(
            DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 16, 30)
          ),
          'endTime': Timestamp.fromDate(
            DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 17, 0)
          ),
          'status': 'available',
          'reservedBy': null,
          'createdBy': 'admin',
          'sessionId': null,
          'createdAt': now,
          'reservedAt': null,
        },
        // Après-demain 10h00-10h30
        {
          'startTime': Timestamp.fromDate(
            DateTime(dayAfter.year, dayAfter.month, dayAfter.day, 10, 0)
          ),
          'endTime': Timestamp.fromDate(
            DateTime(dayAfter.year, dayAfter.month, dayAfter.day, 10, 30)
          ),
          'status': 'available',
          'reservedBy': null,
          'createdBy': 'admin',
          'sessionId': null,
          'createdAt': now,
          'reservedAt': null,
        },
      ];

      final batch = _firestore.batch();
      
      for (final slot in slots) {
        final docRef = _firestore.collection('slots').doc();
        batch.set(docRef, slot);
      }
      
      await batch.commit();
      debugPrint('✅ ${slots.length} créneaux de test créés avec succès !');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la création des slots: $e');
      rethrow;
    }
  }

  /// Supprime tous les champs currentSessionId de la collection users
  static Future<void> clearAllCurrentSessions() async {
    try {
      final usersCollection = _firestore.collection('users');
      final snapshot = await usersCollection.get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ Aucun utilisateur trouvé');
        return;
      }

      final batch = _firestore.batch();
      int updatedCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Vérifier si le champ currentSessionId existe
        if (data.containsKey('currentSessionId')) {
          batch.update(doc.reference, {'currentSessionId': FieldValue.delete()});
          updatedCount++;
        }
      }
      
      if (updatedCount == 0) {
        debugPrint('⚠️ Aucune session active à nettoyer');
        return;
      }
      
      await batch.commit();
      debugPrint('✅ Sessions actives nettoyées ($updatedCount utilisateurs mis à jour)');
      
    } catch (e) {
      debugPrint('❌ Erreur lors du nettoyage des sessions: $e');
      rethrow;
    }
  }

  /// Fonction helper pour nettoyer et recréer les données de test
  static Future<void> resetTestData() async {
    debugPrint('🧹 Nettoyage des données...');
    
    await clearCollection('sessions');
    await clearCollection('slots');
    // Note: on évite de vider 'users' pour conserver les comptes de test
    await clearAllCurrentSessions();
    
    // debugPrint('📝 Création des données de test...');
    // await createTestSlots();
    
    debugPrint('✨ Reset terminé !');
  }


  /// Nettoie les textes
  static Future<void> clearAllTexts() async {
    try {
      final textsCollection = _firestore.collection('texts');
      final snapshot = await textsCollection.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ Aucun texte trouvé');
        return;
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Textes nettoyés avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors du nettoyage des textes: $e');
      rethrow;
    }
  }
}
