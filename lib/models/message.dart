import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
  });

  /// Factory depuis Firestore DocumentSnapshot
  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      text: data['text'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Factory depuis Map (pour compatibilité)
  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      text: map['text'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Conversion vers Map pour Firestore (sans l'id)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Helpers utilitaires
  bool get isEmpty => text.trim().isEmpty;
  bool get isNotEmpty => text.trim().isNotEmpty;
  
  /// Vérifie si le message appartient à l'utilisateur donné
  bool isFromUser(String userId) => senderId == userId;
  
  /// Formatage du timestamp en string lisible
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inDays > 0) {
      return '${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}min';
    } else {
      return 'maintenant';
    }
  }

  /// copyWith pour modifications
  Message copyWith({
    String? id,
    String? text,
    String? senderId,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, text: "${text.length > 50 ? "${text.substring(0, 50)}..." : text}")';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
