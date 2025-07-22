class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final bool isFromCoach;

  const Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.isFromCoach,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      senderId: json['senderId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFromCoach: json['isFromCoach'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'isFromCoach': isFromCoach,
    };
  }

  Message copyWith({
    String? id,
    String? text,
    String? senderId,
    DateTime? timestamp,
    bool? isFromCoach,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      isFromCoach: isFromCoach ?? this.isFromCoach,
    );
  }
}
