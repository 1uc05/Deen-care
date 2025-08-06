import 'package:cloud_firestore/cloud_firestore.dart';
import 'text_sentence.dart';

class ArabicText {
  final String id;
  final String numberSentence;
  final String titleArabic;
  final String titleFrench;
  final List<TextSentence> sentences;
  final DateTime createdAt;

  const ArabicText({
    required this.id,
    required this.numberSentence,
    required this.titleArabic,
    required this.titleFrench,
    required this.sentences,
    required this.createdAt,
  });

  factory ArabicText.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final sentencesData = data['sentences'] as List<dynamic>? ?? [];
    final sentences = sentencesData
        .map((sentenceData) => TextSentence.fromMap(sentenceData as Map<String, dynamic>))
        .toList();

    return ArabicText(
      id: data['id'] ?? '',
      numberSentence: data['number'] ?? '',
      titleArabic: data['titleArabic'] ?? '',
      titleFrench: data['titleFrench'] ?? '',
      sentences: sentences,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'number': numberSentence,
      'titleArabic': titleArabic,
      'titleFrench': titleFrench,
      'sentences': sentences.map((sentence) => sentence.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Méthodes utilitaires
  int get totalSentences => sentences.length;

  TextSentence getSentenceAt(int index) {
    if (index < 0 || index >= sentences.length) {
      throw IndexError.withLength(index, sentences.length);
    }
    return sentences[index];
  }

  List<String> getWordsForSentence(int sentenceIndex) {
    if (sentenceIndex < 0 || sentenceIndex >= sentences.length) {
      return [];
    }
    
    final sentence = sentences[sentenceIndex];
    return sentence.phoneticArabic
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArabicText && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
