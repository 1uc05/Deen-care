class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final String? currentSessionId;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.currentSessionId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      currentSessionId: json['currentSessionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'currentSessionId': currentSessionId,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    String? currentSessionId,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      currentSessionId: currentSessionId ?? this.currentSessionId,
    );
  }
}
