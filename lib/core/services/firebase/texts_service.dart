import '../firebase_service.dart';
import '../../../models/arabic_text.dart';


class TextsService extends FirebaseService {
  static final TextsService _instance = TextsService._internal();
  factory TextsService() => _instance;
  TextsService._internal();

  static const String _textsCollection = 'texts';

  /// Récupère tous les textes ordonnés par ID
  Future<List<ArabicText>> getTexts() async {
    try {
      final snapshot = await firestore
          .collection(_textsCollection)
          .get();
          
      final texts = snapshot.docs
          .map((doc) => ArabicText.fromFirestore(doc))
          .toList();
      
      texts.sort((a, b) {
        final idA = int.tryParse(a.id) ?? 0;
        final idB = int.tryParse(b.id) ?? 0;
        return idA.compareTo(idB);
      });
      
      return texts;
    } catch (e) {
      setError('Erreur lors du chargement des textes: $e');
      return [];
    }
  }

  /// Récupère un texte spécifique par son ID
  Future<ArabicText?> getTextById(String textId) async {
    try {
      final doc = await firestore.collection(_textsCollection).doc(textId).get();

      if (!doc.exists) {
        return null;
      }
      
      return ArabicText.fromFirestore(doc);
    } catch (e) {
      setError('Erreur lors du chargement du texte: $e');
      return null;
    }
  }
}
