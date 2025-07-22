enum SessionStatus { scheduled, active, completed }

class Session {
  final String id;
  final String coachId;
  final String userId;
  final DateTime scheduledAt;
  final SessionStatus status;
  final String agoraChannelId;
  final DateTime createdAt;

  const Session({
    required this.id,
    required this.coachId,
    required this.userId,
    required this.scheduledAt,
    required this.status,
    required this.agoraChannelId,
    required this.createdAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      coachId: json['coachId'] as String,
      userId: json['userId'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SessionStatus.scheduled,
      ),
      agoraChannelId: json['agoraChannelId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coachId': coachId,
      'userId': userId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': status.name,
      'agoraChannelId': agoraChannelId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Session copyWith({
    String? id,
    String? coachId,
    String? userId,
    DateTime? scheduledAt,
    SessionStatus? status,
    String? agoraChannelId,
    DateTime? createdAt,
  }) {
    return Session(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      userId: userId ?? this.userId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      agoraChannelId: agoraChannelId ?? this.agoraChannelId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
