import 'package:cloud_firestore/cloud_firestore.dart';

// Constantes pour les statuts
class SessionStatus {
  static const String scheduled = 'scheduled';
  static const String active = 'active';
  static const String completed = 'completed';
}

class Session {
  final String id;
  final String userId;
  final String coachId;
  final String slotId;
  final String status;
  final Timestamp? startedAt;
  final String agoraChannelId;

  const Session({
    required this.id,
    required this.userId,
    required this.coachId,
    required this.slotId,
    required this.status,
    this.startedAt,
    required this.agoraChannelId,
  });

  // Factory depuis Firestore
  factory Session.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Session(
      id: doc.id,
      userId: data['userId'] ?? '',
      coachId: data['coachId'] ?? '',
      slotId: data['slotId'] ?? '',
      status: data['status'] ?? 'scheduled',
      startedAt: data['startedAt'],
      agoraChannelId: data['agoraChannelId'] ?? '',
    );
  }

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'coachId': coachId,
      'slotId': slotId,
      'status': status,
      'agoraChannelId': agoraChannelId,
    };
    
    if (startedAt != null) {
      map['startedAt'] = startedAt!;
    }
    
    return map;
  }



  // Helpers pour les statuts
  bool get isScheduled => status == SessionStatus.scheduled;
  bool get isActive => status == SessionStatus.active;
  bool get isCompleted => status == SessionStatus.completed;

  // copyWith pour modifications
  Session copyWith({
    String? id,
    String? userId,
    String? coachId,
    String? slotId,
    String? status,
    Timestamp? startedAt,
    String? agoraChannelId,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      coachId: coachId ?? this.coachId,
      slotId: slotId ?? this.slotId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      agoraChannelId: agoraChannelId ?? this.agoraChannelId,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, status: $status, slotId: $slotId)';
  }
}