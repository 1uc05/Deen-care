import 'package:cloud_firestore/cloud_firestore.dart';

// Constantes pour les statuts
class SessionStatus {
  static const String scheduled = 'scheduled';
  static const String inProgress = 'inProgress';
  static const String completed = 'completed';
}

class Session {
  final String id;
  final String userId;
  final String coachId;
  final String slotId;
  final String status; // Status officiel en DB
  final Timestamp? startedAt;
  final String agoraChannelId;
  final DateTime startTime;
  final DateTime endTime;

  const Session({
    required this.id,
    required this.userId,
    required this.coachId,
    required this.slotId,
    required this.status,
    this.startedAt,
    required this.agoraChannelId,
    required this.startTime,
    required this.endTime,
  });

  // Status calculé basé sur l'heure + status DB
  String get effectiveStatus {
    final now = DateTime.now();
    
    // Si la session est terminée en DB, elle reste terminée
    if (status == SessionStatus.completed) {
      return SessionStatus.completed;
    }
    
    // Calcul basé sur l'heure actuelle
    if (now.isBefore(startTime)) {
      return SessionStatus.scheduled;
    } else if (now.isAfter(endTime)) {
      return SessionStatus.completed; // Auto-expire
    } else {
      return SessionStatus.inProgress; // Entre start et end
    }
  }

  // Helpers basés sur le status effectif
  bool get isScheduled => effectiveStatus == SessionStatus.scheduled;
  bool get isInProgress => effectiveStatus == SessionStatus.inProgress;
  bool get isCompleted => effectiveStatus == SessionStatus.completed;

  // Helpers temporels
  Duration get duration => endTime.difference(startTime);
  bool get isNow => isInProgress;
  bool get isPast => isCompleted;
  bool get isFuture => isScheduled;

  // Utilitaire pour sync DB
  bool needsStatusSync() {
    return status != effectiveStatus && effectiveStatus == SessionStatus.completed;
  }

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
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
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
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
    };
    
    if (startedAt != null) {
      map['startedAt'] = startedAt!;
    }
    
    return map;
  }

  // copyWith pour modifications
  Session copyWith({
    String? id,
    String? userId,
    String? coachId,
    String? slotId,
    String? status,
    Timestamp? startedAt,
    String? agoraChannelId,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      coachId: coachId ?? this.coachId,
      slotId: slotId ?? this.slotId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      agoraChannelId: agoraChannelId ?? this.agoraChannelId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, status: $status->$effectiveStatus, slotId: $slotId, startTime: $startTime, endTime: $endTime)';
  }
}
