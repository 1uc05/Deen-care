import 'package:cloud_firestore/cloud_firestore.dart';
import 'text_segment.dart';

class ArabicText {
  final String id;
  final String title;
  final List<TextSegment> segments;
  final int totalSegments;
  final DateTime createdAt;
  
  const ArabicText({
    required this.id,
    required this.title,
    required this.segments,
    required this.totalSegments,
    required this.createdAt,
  });

  // Constructeur depuis Firestore
  factory ArabicText.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final segmentsList = data['segments'] as List<dynamic>? ?? [];
    final segments = segmentsList
        .map((segmentData) => TextSegment.fromMap(segmentData as Map<String, dynamic>))
        .toList();
    
    return ArabicText(
      id: doc.id,
      title: data['title'] as String? ?? '',
      segments: segments,
      totalSegments: segments.length,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'segments': segments.map((segment) => segment.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  // Méthode utilitaire : obtenir le texte à afficher selon le nombre de segments révélés
  String getDisplayText(int segmentCount, bool showFrench) {
    if (segments.isEmpty) return '';
    
    final visibleSegments = segments.take(segmentCount).toList();
    final buffer = StringBuffer();
    
    for (int i = 0; i < visibleSegments.length; i++) {
      final segment = visibleSegments[i];
      
      // Texte arabe
      buffer.write(segment.arabic);
      
      // Texte français si demandé
      if (showFrench && segment.french.isNotEmpty) {
        buffer.write('\n');
        buffer.write(segment.french);
      }
      
      // Saut de ligne entre segments (sauf dernier)
      if (i < visibleSegments.length - 1) {
        buffer.write('\n\n');
      }
    }
    
    return buffer.toString();
  }
  
  // Propriété utilitaire : vérifier si le texte est complètement révélé
  bool get isCompleted => totalSegments > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArabicText &&
        other.id == id &&
        other.title == title &&
        other.totalSegments == totalSegments &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        totalSegments.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'ArabicText(id: $id, title: $title, totalSegments: $totalSegments, createdAt: $createdAt)';
  }
}
