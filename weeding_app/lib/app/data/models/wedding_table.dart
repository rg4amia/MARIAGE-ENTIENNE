class WeddingTable {
  final String id;
  final String name;
  final String? description;
  final int capacity;
  final DateTime createdAt;

  WeddingTable({
    required this.id,
    required this.name,
    this.description,
    required this.capacity,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WeddingTable.fromJson(Map<String, dynamic> json) {
    return WeddingTable(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      capacity: json['capacity'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'capacity': capacity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WeddingTable copyWith({
    String? name,
    String? description,
    int? capacity,
  }) {
    return WeddingTable(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt,
    );
  }
}
