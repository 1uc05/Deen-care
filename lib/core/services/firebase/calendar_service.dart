import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import '../../../models/slot.dart';

class CalendarService extends BaseFirebaseService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  static const String _slotsCollection = 'slots';
  static const String _bookingsCollection = 'bookings';

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

      // Filtrer seulement les créneaux disponibles et futurs
      query = query
          .where('status', isEqualTo: 'available')
          .where('startTime', isGreaterThan: Timestamp.now())
          .orderBy('startTime');

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

  /// Réserve un créneau avec transaction pour éviter les double-réservations
  Future<bool> bookSlot(String slotId) async {
    validateCurrentUser();
    
    final userId = currentFirebaseUser!.uid;
    final now = DateTime.now();

    try {
      return await firestore.runTransaction<bool>((transaction) async {
        // 1. Récupérer le slot
        final slotRef = firestore.collection(_slotsCollection).doc(slotId);
        final slotDoc = await transaction.get(slotRef);

        if (!slotDoc.exists) {
          throw Exception('Créneau introuvable');
        }

        final slot = Slot.fromMap(slotDoc.data()!, slotId);

        // 2. Vérifications
        if (!slot.isAvailable) {
          throw Exception('Créneau déjà réservé');
        }
        
        if (slot.isPast) {
          throw Exception('Créneau dans le passé');
        }

        // 3. Vérifier qu'il n'a pas déjà une réservation active
        final existingReservations = await firestore
            .collection(_slotsCollection)
            .where('reservedBy', isEqualTo: userId)
            .where('status', isEqualTo: 'reserved')
            .where('startTime', isGreaterThan: Timestamp.now())
            .limit(1)
            .get();

        if (existingReservations.docs.isNotEmpty) {
          throw Exception('Vous avez déjà une réservation active');
        }

        // 4. Réserver le slot (SEULE opération nécessaire)
        transaction.update(slotRef, {
          'status': 'reserved',
          'reservedBy': userId,
          'updatedAt': Timestamp.fromDate(now),
        });

        return true;
      });
    } catch (e) {
      throw handleFirestoreException(e, 'réservation du créneau');
    }
  }


  /// Récupère les réservations d'un utilisateur
  Stream<List<Slot>> getUserBookings(String userId) {
    try {
      validateUserId(userId);
      
      return firestore
          .collection(_slotsCollection)
          .where('reservedBy', isEqualTo: userId)
          .where('status', isEqualTo: 'reserved')
          .orderBy('startTime')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Slot.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      throw handleFirestoreException(e, 'récupération des réservations');
    }
  }

  /// Annule une réservation
  Future<bool> cancelBooking(String slotId) async {
    validateCurrentUser();
    
    final userId = currentFirebaseUser!.uid;
    final now = DateTime.now();

    try {
      return await firestore.runTransaction<bool>((transaction) async {
        final slotRef = firestore.collection(_slotsCollection).doc(slotId);
        final slotDoc = await transaction.get(slotRef);

        if (!slotDoc.exists) {
          throw Exception('Créneau introuvable');
        }

        final slot = Slot.fromMap(slotDoc.data()!, slotId);

        if (slot.reservedBy != userId) {
          throw Exception('Vous ne pouvez pas annuler cette réservation');
        }

        // Libérer le slot
        transaction.update(slotRef, {
          'status': 'available',
          'reservedBy': null,
          'updatedAt': Timestamp.fromDate(now),
        });

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
