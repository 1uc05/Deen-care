class TextSentence {
  final String phoneticArabic;
  final String french;
  final String arabic;

  const TextSentence({
    required this.phoneticArabic,
    required this.french,
    required this.arabic,
  });

  factory TextSentence.fromMap(Map<String, dynamic> map) {
    return TextSentence(
      phoneticArabic: map['phoneticArabic'] ?? '',
      french: map['french'] ?? '',
      arabic: map['arabic'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneticArabic': phoneticArabic,
      'french': french,
      'arabic': arabic,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSentence &&
        other.phoneticArabic == phoneticArabic &&
        other.french == french &&
        other.arabic == arabic;
  }

  @override
  int get hashCode => phoneticArabic.hashCode ^ french.hashCode ^ arabic.hashCode;
}
