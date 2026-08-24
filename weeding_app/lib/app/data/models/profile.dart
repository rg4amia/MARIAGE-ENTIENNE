class Profile {
  final String id;
  final String role;
  final String fullName;
  final String? phone;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.role = 'admin',
    required this.fullName,
    this.phone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'admin',
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? fullName,
    String? phone,
    String? role,
  }) {
    return Profile(
      id: id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}
