class Chair {
  final String id;
  final String tableId;
  final int chairNumber;
  final String? guestId;
  final DateTime createdAt;

  Chair({
    required this.id,
    required this.tableId,
    required this.chairNumber,
    this.guestId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Chair.fromJson(Map<String, dynamic> json) {
    return Chair(
      id: json['id'] as String,
      tableId: json['table_id'] as String,
      chairNumber: json['chair_number'] as int,
      guestId: json['guest_id'] as String?,
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
      'guest_id': guestId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isAssigned => guestId != null;

  Chair copyWith({String? guestId}) {
    return Chair(
      id: id,
      tableId: tableId,
      chairNumber: chairNumber,
      guestId: guestId ?? this.guestId,
      createdAt: createdAt,
    );
  }
}
