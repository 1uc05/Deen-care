import 'package:cloud_firestore/cloud_firestore.dart';

enum SlotStatus {
  available('available'),
  reserved('reserved'),
  completed('completed'),
  cancelled('cancelled');

  const SlotStatus(this.value);
  final String value;

  static SlotStatus fromString(String status) {
    return SlotStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => SlotStatus.available,
    );
  }

  @override
  String toString() => value;
}

class Slot {
  final String? id;
  final DateTime startTime;
  final DateTime endTime;
  final SlotStatus status;
  final String? reservedBy;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Slot({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.reservedBy,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Constructeur depuis les données Firestore
  factory Slot.fromMap(Map<String, dynamic> data, String docId) {
    return Slot(
      id: docId,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: SlotStatus.fromString(data['status'] as String? ?? 'available'),
      reservedBy: data['reservedBy'] as String?,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status.value,
      'reservedBy': reservedBy,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Méthodes utilitaires améliorées
  bool get isAvailable => status == SlotStatus.available && reservedBy == null;
  bool get isReserved => status == SlotStatus.reserved && reservedBy != null;
  bool get isCompleted => status == SlotStatus.completed;
  bool get isCancelled => status == SlotStatus.cancelled;
  bool get isPast => endTime.isBefore(DateTime.now());
  
  Duration get duration => endTime.difference(startTime);

  /// Copie avec modification
  Slot copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    SlotStatus? status,
    String? reservedBy,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Slot(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      reservedBy: reservedBy ?? this.reservedBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }


  @override
  String toString() {
    return 'Slot(id: $id, startTime: $startTime, endTime: $endTime, status: $status, reservedBy: $reservedBy)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Slot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
