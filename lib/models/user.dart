import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  client('client'),
  coach('coach'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.value == role,
      orElse: () => UserRole.client,
    );
  }

  @override
  String toString() => value;
}

class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final String? currentSessionId;
  final UserRole role;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.currentSessionId,
    required this.role,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      currentSessionId: data['currentSessionId'] as String?,
      role: UserRole.fromString(data['role'] as String? ?? 'client'),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      currentSessionId: json['currentSessionId'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'client'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentSessionId': currentSessionId,
      'role': role.value,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'currentSessionId': currentSessionId,
      'role': role.value,
    };
  }

  bool get isClient => role == UserRole.client;
  bool get isCoach => role == UserRole.coach;
  bool get isAdmin => role == UserRole.admin;
  bool get hasActiveSession => currentSessionId != null;

  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    String? currentSessionId,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role, currentSessionId: $currentSessionId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
