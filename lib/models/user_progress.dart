import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  final String textId;
  final String title;
  final int currentSegment;
  final DateTime lastAccessedAt;
  
  const UserProgress({
    required this.textId,
    required this.title,
    required this.currentSegment,
    required this.lastAccessedAt,
  });

  // Constructeur depuis Firestore
  factory UserProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserProgress(
      textId: doc.id,
      title: data['title'] as String? ?? '',
      currentSegment: data['currentSegment'] as int? ?? 0,
      lastAccessedAt: (data['lastAccessedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'currentSegment': currentSegment,
      'lastAccessedAt': Timestamp.fromDate(lastAccessedAt),
    };
  }

  // Méthode copyWith pour immutabilité
  UserProgress copyWith({
    String? textId,
    String? title,
    int? currentSegment,
    DateTime? lastAccessedAt,
  }) {
    return UserProgress(
      textId: textId ?? this.textId,
      title: title ?? this.title,
      currentSegment: currentSegment ?? this.currentSegment,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProgress &&
        other.textId == textId &&
        other.title == title &&
        other.currentSegment == currentSegment &&
        other.lastAccessedAt == lastAccessedAt;
  }

  @override
  int get hashCode {
    return textId.hashCode ^
        title.hashCode ^
        currentSegment.hashCode ^
        lastAccessedAt.hashCode;
  }

  @override
  String toString() {
    return 'UserProgress(textId: $textId, title: $title, currentSegment: $currentSegment, lastAccessedAt: $lastAccessedAt)';
  }
}
