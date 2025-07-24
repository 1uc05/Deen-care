import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_service.dart';
import '../../../models/slot.dart';
import '../../../models/session.dart';
import 'sessions_service.dart';

class SlotsService extends FirebaseService {
  static final SlotsService _instance = SlotsService._internal();
  factory SlotsService() => _instance;
  SlotsService._internal();

  static const String _slotsCollection = 'slots';

  final SessionsService _sessionsService = SessionsService();

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

  /// Réserve un créneau et crée une session
  Future<void> bookSlot(String slotId) async {
    validateCurrentUser();
    
    final userId = currentFirebaseUser!.uid;
    final now = DateTime.now();

    try {
      await firestore.runTransaction<void>((transaction) async {
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

        // 4. Créer la session (hors transaction pour éviter les conflits)
        final sessionId = await _createSessionForSlot(slot, userId, slot.createdBy);

        // 5. Réserver le slot avec sessionId
        transaction.update(slotRef, {
          'status': 'reserved',
          'reservedBy': userId,
          'sessionId': sessionId,
          'reservedAt': Timestamp.fromDate(now),
        });

        // 6. Mettre à jour currentSessionId dans user
        final userRef = firestore.collection('users').doc(userId);
        transaction.update(userRef, {
          'currentSessionId': sessionId,
        });

      });
    } catch (e) {
      throw handleFirestoreException(e, 'réservation du créneau');
    }
  }

  /// Crée une session pour un slot
  Future<String> _createSessionForSlot(Slot slot, String userId, String coachId) async {

    // Générer un channel Agora unique
    final agoraChannelId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    final session = Session(
      id: '', // Sera généré par Firestore
      userId: userId,
      coachId: coachId,
      slotId: slot.id!,
      status: SessionStatus.scheduled,
      startedAt: Timestamp.fromDate(slot.startTime),
      agoraChannelId: agoraChannelId,
    );

    return await _sessionsService.createSession(session);
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

  /// Récupère un slot spécifique par son ID
  Future<Slot?> getSlotById(String slotId) async {
    try {
      final slotDoc = await firestore
          .collection(_slotsCollection)
          .doc(slotId)
          .get();

      if (!slotDoc.exists) return null;

      return Slot.fromMap(slotDoc.data()!, slotDoc.id);
      
    } catch (e) {
      throw handleFirestoreException(e, 'récupération du slot');
    }
  }


  /// Annule une réservation et supprime la session
  Future<bool> cancelBooking(String slotId) async {
    validateCurrentUser();
    
    final userId = currentFirebaseUser!.uid;

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

        // Supprimer la session si elle existe
        if (slot.hasSession) {
          await _sessionsService.deleteSession(slot.sessionId!);
        }

        // Libérer le slot
        transaction.update(slotRef, {
          'status': 'available',
          'reservedBy': null,
          'sessionId': null,
          'reservedAt': null,
        });

        // Nettoyer currentSessionId dans user
        final userRef = firestore.collection('users').doc(userId);
        transaction.update(userRef, {
          'currentSessionId': null,
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
