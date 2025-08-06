import 'package:cloud_firestore/cloud_firestore.dart';

class TextProgress {
  final String textId;
  final int currentSentence;
  final DateTime lastAccessedAt;

  const TextProgress({
    required this.textId,
    required this.currentSentence,
    required this.lastAccessedAt,
  });

  factory TextProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TextProgress(
      textId: data['textId'] ?? '',
      currentSentence: data['currentSentence'] ?? 0,
      lastAccessedAt: (data['lastAccessedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'textId': textId,
      'currentSentence': currentSentence,
      'lastAccessedAt': Timestamp.fromDate(lastAccessedAt),
    };
  }

  TextProgress copyWith({
    String? textId,
    int? currentSentence,
    DateTime? lastAccessedAt,
  }) {
    return TextProgress(
      textId: textId ?? this.textId,
      currentSentence: currentSentence ?? this.currentSentence,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextProgress &&
        other.textId == textId &&
        other.currentSentence == currentSentence;
  }

  @override
  int get hashCode => textId.hashCode ^ currentSentence.hashCode;
}
