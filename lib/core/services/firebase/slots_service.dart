import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firebase_service.dart';
import '../../../models/slot.dart';

class SlotsService extends FirebaseService {
  static final SlotsService _instance = SlotsService._internal();
  factory SlotsService() => _instance;
  SlotsService._internal();

  static const String _slotsCollection = 'slots';

  /// Récupère les créneaux disponibles (non réservés et futurs)
  Stream<List<Slot>> getAvailableSlots({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      Query query = firestore.collection(_slotsCollection);

      // Filtrer par période si spécifiée
      if (startDate != null) {
        query = query.where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      // Filtrer seulement les créneaux disponibles et à partir de demain
      query = query
          .where('status', isEqualTo: 'available')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(tomorrow))
          .orderBy('startTime');

      // // Filtrer seulement les créneaux disponibles et futurs
      // query = query
      //     .where('status', isEqualTo: 'available')
      //     .where('startTime', isGreaterThan: Timestamp.now())
      //     .orderBy('startTime');

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return Slot.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).where((slot) {
          // Double vérification côté client
          return slot.isAvailable && !slot.isPast;
        }).toList();
      });
    } catch (e) {
      throw handleFirestoreException(e, 'récupération des créneaux');
    }
  }

  /// Récupère les créneaux disponibles pour un jour spécifique
  Stream<List<Slot>> getAvailableSlotsForDay(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getAvailableSlots(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  /// Réserve un créneau
  Future<void> bookSlot(String slotId, String sessionId) async {
    
    final now = DateTime.now();

    try {
      validateCurrentUser();

      await firestore.runTransaction<void>((transaction) async {
        // 1. Récupérer le slot
        final slotRef = firestore.collection(_slotsCollection).doc(slotId);
        final slotDoc = await transaction.get(slotRef);

        if (!slotDoc.exists) {
          setError('Créneau introuvable');
        }

        final slot = Slot.fromMap(slotDoc.data()!, slotId);

        // 2. Vérifications
        if (!slot.isAvailable) {
          setError('Créneau déjà réservé');
        }
        
        if (slot.isPast) {
          setError('Créneau dans le passé');
        }

        // 3. Vérifier qu'il n'a pas déjà une réservation active
        final existingReservations = await firestore
            .collection(_slotsCollection)
            .where('reservedBy', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'reserved')
            .where('startTime', isGreaterThan: Timestamp.now())
            .limit(1)
            .get();

        if (existingReservations.docs.isNotEmpty) {
          setError('Vous avez déjà une réservation active');
        }

        // 4. Réserver le slot avec sessionId
        transaction.update(slotRef, {
          'status': 'reserved',
          'reservedBy': currentUserId,
          'sessionId': sessionId,
          'reservedAt': Timestamp.fromDate(now),
        });
      });
    } catch (e) {
      throw handleFirestoreException(e, 'réservation du créneau');
    }
  }

  /// Annule une réservation et supprime la session
  Future<bool> cancelBooking(String slotId) async {
    validateCurrentUser();
    
    final userId = currentUserId;

    try {
      return await firestore.runTransaction<bool>((transaction) async {
        final slotRef = firestore.collection(_slotsCollection).doc(slotId);
        final slotDoc = await transaction.get(slotRef);

        if (!slotDoc.exists) {
          setError('Créneau introuvable');
        }

        final slot = Slot.fromMap(slotDoc.data()!, slotId);

        if (slot.reservedBy != userId) {
          setError('Vous ne pouvez pas annuler cette réservation');
        }

        // Libérer le slot
        transaction.update(slotRef, {
          'status': 'available',
          'reservedBy': null,
          'sessionId': null,
          'reservedAt': null,
        });

        // // Nettoyer currentSessionId dans user
        // final userRef = firestore.collection('users').doc(userId);
        // transaction.update(userRef, {
        //   'currentSessionId': null,
        // });

        return true;
      });
    } catch (e) {
      throw handleFirestoreException(e, 'annulation de la réservation');
    }
  }

  /// Vérifie si un jour a des créneaux disponibles
  Future<bool> hasAvailableSlots(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await firestore
          .collection(_slotsCollection)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'available')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw handleFirestoreException(e, 'vérification des créneaux disponibles');
    }
  }
}
