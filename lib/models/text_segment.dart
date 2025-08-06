class TextSegment {
  final String arabic;
  final String french;
  
  const TextSegment({
    required this.arabic,
    required this.french,
  });

  // Constructeur depuis JSON
  factory TextSegment.fromJson(Map<String, dynamic> json) {
    return TextSegment(
      arabic: json['arabic'] as String? ?? '',
      french: json['french'] as String? ?? '',
    );
  }

  // Constructeur depuis Map
  factory TextSegment.fromMap(Map<String, dynamic> map) {
    return TextSegment(
      arabic: map['arabic'] as String? ?? '',
      french: map['french'] as String? ?? '',
    );
  }

  // Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'arabic': arabic,
      'french': french,
    };
  }

  // Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'arabic': arabic,
      'french': french,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSegment &&
        other.arabic == arabic &&
        other.french == french;
  }

  @override
  int get hashCode => arabic.hashCode ^ french.hashCode;

  @override
  String toString() => 'TextSegment(arabic: $arabic, french: $french)';
}
