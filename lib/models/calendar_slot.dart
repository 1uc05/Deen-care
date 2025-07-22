class CalendarSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool available;
  final String? eventUrl;

  const CalendarSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.available,
    this.eventUrl,
  });

  factory CalendarSlot.fromJson(Map<String, dynamic> json) {
    return CalendarSlot(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      available: json['available'] as bool,
      eventUrl: json['eventUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'available': available,
      'eventUrl': eventUrl,
    };
  }

  CalendarSlot copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    bool? available,
    String? eventUrl,
  }) {
    return CalendarSlot(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      available: available ?? this.available,
      eventUrl: eventUrl ?? this.eventUrl,
    );
  }
}
