class WeddingTable {
  final String id;
  final String label;
  final int capacity;
  final DateTime createdAt;

  WeddingTable({
    required this.id,
    required this.label,
    required this.capacity,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WeddingTable.fromJson(Map<String, dynamic> json) {
    return WeddingTable(
      id: json['id'] as String,
      label: json['label'] as String,
      capacity: json['capacity'] as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'capacity': capacity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WeddingTable copyWith({String? label, int? capacity}) {
    return WeddingTable(
      id: id,
      label: label ?? this.label,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt,
    );
  }
}
