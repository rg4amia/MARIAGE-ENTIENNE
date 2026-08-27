class WeddingTable {
  final String id;
  final String label;
  final int capacity;
  final int assignedSeats;
  final DateTime createdAt;

  WeddingTable({
    required this.id,
    required this.label,
    required this.capacity,
    this.assignedSeats = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get occupancy => capacity > 0 ? assignedSeats / capacity : 0.0;

  factory WeddingTable.fromJson(Map<String, dynamic> json) {
    return WeddingTable(
      id: json['id'] as String,
      label: json['label'] as String,
      capacity: json['capacity'] as int,
      assignedSeats: json['assigned_seats'] as int? ?? 0,
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
      'assigned_seats': assignedSeats,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WeddingTable copyWith({String? label, int? capacity, int? assignedSeats}) {
    return WeddingTable(
      id: id,
      label: label ?? this.label,
      capacity: capacity ?? this.capacity,
      assignedSeats: assignedSeats ?? this.assignedSeats,
      createdAt: createdAt,
    );
  }
}
