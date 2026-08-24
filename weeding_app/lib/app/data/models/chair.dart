class Chair {
  final String id;
  final String tableId;
  final int chairNumber;
  final bool isAssigned;
  final DateTime createdAt;

  Chair({
    required this.id,
    required this.tableId,
    required this.chairNumber,
    this.isAssigned = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Chair.fromJson(Map<String, dynamic> json) {
    return Chair(
      id: json['id'] as String,
      tableId: json['table_id'] as String,
      chairNumber: json['chair_number'] as int,
      isAssigned: json['is_assigned'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_id': tableId,
      'chair_number': chairNumber,
      'is_assigned': isAssigned,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Chair copyWith({bool? isAssigned}) {
    return Chair(
      id: id,
      tableId: tableId,
      chairNumber: chairNumber,
      isAssigned: isAssigned ?? this.isAssigned,
      createdAt: createdAt,
    );
  }
}
