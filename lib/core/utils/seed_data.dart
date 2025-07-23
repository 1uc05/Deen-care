import 'package:cloud_firestore/cloud_firestore.dart';

class SeedData {
  static Future<void> createTestSlots() async {
    final firestore = FirebaseFirestore.instance;
    final now = Timestamp.now();
    
    final slots = [
      {
        'startTime': Timestamp.fromDate(DateTime.now().add(Duration(days: 1, hours: 14))),
        'endTime': Timestamp.fromDate(DateTime.now().add(Duration(days: 1, hours: 15))),
        'status': 'available',
        'reservedBy': null,
        'createdBy': 'admin',      // ✅ Ajouté
        'createdAt': now,
        'updatedAt': now,          // ✅ Ajouté
      },
      {
        'startTime': Timestamp.fromDate(DateTime.now().add(Duration(days: 1, hours: 16))),
        'endTime': Timestamp.fromDate(DateTime.now().add(Duration(days: 1, hours: 17))),
        'status': 'available',
        'reservedBy': null,
        'createdBy': 'admin',      // ✅ Ajouté
        'createdAt': now,
        'updatedAt': now,          // ✅ Ajouté
      },
      {
        'startTime': Timestamp.fromDate(DateTime.now().add(Duration(days: 2, hours: 10))),
        'endTime': Timestamp.fromDate(DateTime.now().add(Duration(days: 2, hours: 11))),
        'status': 'available',
        'reservedBy': null,
        'createdBy': 'admin',      // ✅ Ajouté
        'createdAt': now,
        'updatedAt': now,          // ✅ Ajouté
      },
    ];

    // Supprime d'abord les anciens créneaux de test
    final existing = await firestore.collection('slots').get();
    final batch = firestore.batch();
    
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    
    for (final slot in slots) {
      final docRef = firestore.collection('slots').doc();
      batch.set(docRef, slot);
    }
    
    await batch.commit();
    print('✅ ${slots.length} créneaux créés avec succès !');
  }
}
