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
  final String status;
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

  // Helpers pour les statuts
  bool get isScheduled => status == SessionStatus.scheduled;
  bool get isInProgress => status == SessionStatus.inProgress;
  bool get isCompleted => status == SessionStatus.completed;

  // Helpers pour les horaires
  Duration get duration => endTime.difference(startTime);
  bool get isNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
  bool get isPast => DateTime.now().isAfter(endTime);
  bool get isFuture => DateTime.now().isBefore(startTime);

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
    return 'Session(id: $id, status: $status, slotId: $slotId, startTime: $startTime, endTime: $endTime)';
  }
}
